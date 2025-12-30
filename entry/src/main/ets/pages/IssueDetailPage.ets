import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { authManager } from '../services/AuthManager';
import { GitHubIssue, GitHubComment, GitHubLabel } from '../models/GitHubModels';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import pasteboard from '@ohos.pasteboard';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#F28C28';
const BORDER_COLOR = '#D0D7DE';
const OPEN_COLOR = '#1A7F37';
const CLOSED_COLOR = '#8250DF';

interface RouteParams {
  owner: string;
  repo: string;
  issueNumber: number;
}

@Entry
@Component
struct IssueDetailPage {
  @State isLoading: boolean = true;
  @State error: string = '';
  @State issue: GitHubIssue | null = null;
  @State comments: GitHubComment[] = [];
  @State isLoadingComments: boolean = false;
  @State commentText: string = '';
  @State isSubmitting: boolean = false;
  @State showCommentInput: boolean = false;

  private owner: string = '';
  private repoName: string = '';
  private issueNumber: number = 0;
  private markdownController: MarkdownController = new MarkdownController();

  aboutToAppear(): void {
    // 配置 Markdown 样式
    this.markdownController
      .setTitleColor(PRIMARY_TEXT)
      .setTextColor(SECONDARY_TEXT)
      .setTextSize(14)
      .setCodeBlockTheme('light')
      .setQuoteBorderColor(ACCENT)
      .setQuoteBackgroundColor('#F6F8FA')
      .setHyperlinkTextColor(ACCENT)
      .setInlineCodeColor('#CF222E')
      .setInlineCodeBackgroundColor('#FFF1F0')
      .setCodeCopyListener((code: string) => {
        this.copyToClipboard(code);
      });

    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      this.issueNumber = params.issueNumber;
      this.loadIssue();
    }
  }

  async copyToClipboard(text: string): Promise<void> {
    try {
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteboardData);
      promptAction.showToast({ message: '已复制到剪贴板' });
    } catch (err) {
      console.error('Copy failed:', JSON.stringify(err));
      promptAction.showToast({ message: '复制失败' });
    }
  }

  async loadIssue(): Promise<void> {
    this.isLoading = true;
    this.error = '';

    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = '请先登录';
      this.isLoading = false;
      return;
    }

    try {
      this.issue = await api.getIssue(this.owner, this.repoName, this.issueNumber);
      this.loadComments();
    } catch (err) {
      this.error = '加载 Issue 失败';
      console.error('Load issue failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  async loadComments(): Promise<void> {
    if (!this.issue || this.issue.comments === 0) return;

    this.isLoadingComments = true;
    const api = authManager.getGitHubApi();
    if (!api) return;

    try {
      this.comments = await api.getIssueComments(this.owner, this.repoName, this.issueNumber);
    } catch (err) {
      console.error('Load comments failed:', JSON.stringify(err));
    } finally {
      this.isLoadingComments = false;
    }
  }

  async submitComment(): Promise<void> {
    if (!this.commentText.trim()) {
      promptAction.showToast({ message: '请输入评论内容' });
      return;
    }

    this.isSubmitting = true;
    const api = authManager.getGitHubApi();
    if (!api) {
      promptAction.showToast({ message: '请先登录' });
      this.isSubmitting = false;
      return;
    }

    try {
      const newComment = await api.addIssueComment(this.owner, this.repoName, this.issueNumber, this.commentText.trim());
      this.comments.push(newComment);
      this.commentText = '';
      this.showCommentInput = false;
      promptAction.showToast({ message: '评论成功' });
    } catch (err) {
      promptAction.showToast({ message: '评论失败' });
      console.error('Submit comment failed:', JSON.stringify(err));
    } finally {
      this.isSubmitting = false;
    }
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) {
      const hours = Math.floor(diff / (1000 * 60 * 60));
      if (hours === 0) {
        const minutes = Math.floor(diff / (1000 * 60));
        return `${minutes} 分钟前`;
      }
      return `${hours} 小时前`;
    } else if (days < 30) {
      return `${days} 天前`;
    } else {
      return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
    }
  }

  getLabelColor(color: string): string {
    if (color.startsWith('#')) {
      return color;
    }
    return `#${color}`;
  }

  isLightColor(hexColor: string): boolean {
    const hex = hexColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;
    return brightness > 128;
  }

  @Builder
  CommentItem(comment: GitHubComment) {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Image(comment.user.avatar_url)
          .width(32)
          .height(32)
          .borderRadius(16)

        Column({ space: 2 }) {
          Text(comment.user.login)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PRIMARY_TEXT)

          Text(this.formatDate(comment.created_at))
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 评论内容
      if (comment.body) {
        Markdown({
          text: comment.body,
          controller: this.markdownController
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        Row() {
          Row() {
            Image($r('app.media.ic_back'))
              .width(24)
              .height(24)
              .fillColor(PRIMARY_TEXT)
          }
          .width(40)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            router.back();
          })

          Text(`Issue #${this.issueNumber}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(PRIMARY_TEXT)
            .layoutWeight(1)

          Blank().width(40)
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 16 })
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 1 }, color: BORDER_COLOR })

        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
            Text('加载中...')
              .fontSize(14)
              .fontColor(SECONDARY_TEXT)
              .margin({ top: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.error) {
          Column() {
            Text(this.error)
              .fontSize(14)
              .fontColor(SECONDARY_TEXT)
            Button('重试')
              .height(36)
              .fontSize(14)
              .margin({ top: 16 })
              .onClick(() => this.loadIssue())
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.issue) {
          Scroll() {
            Column({ space: 16 }) {
              // Issue 主体
              Column({ space: 12 }) {
                // 状态和标题
                Row({ space: 8 }) {
                  Row() {
                    Text(this.issue.state === 'open' ? 'Open' : 'Closed')
                      .fontSize(12)
                      .fontColor('#FFFFFF')
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .backgroundColor(this.issue.state === 'open' ? OPEN_COLOR : CLOSED_COLOR)
                }
                .width('100%')

                Text(this.issue.title)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PRIMARY_TEXT)

                // 作者信息
                Row({ space: 10 }) {
                  Image(this.issue.user.avatar_url)
                    .width(24)
                    .height(24)
                    .borderRadius(12)

                  Text(`${this.issue.user.login} 创建于 ${this.formatDate(this.issue.created_at)}`)
                    .fontSize(13)
                    .fontColor(SECONDARY_TEXT)
                }

                // 标签
                if (this.issue.labels && this.issue.labels.length > 0) {
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.issue.labels, (label: GitHubLabel) => {
                      Text(label.name)
                        .fontSize(11)
                        .fontColor(this.isLightColor(this.getLabelColor(label.color)) ? '#1F2328' : '#FFFFFF')
                        .backgroundColor(this.getLabelColor(label.color))
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .borderRadius(10)
                        .margin({ right: 6, bottom: 6 })
                    }, (label: GitHubLabel) => label.id.toString())
                  }
                  .width('100%')
                }

                // Issue 正文
                if (this.issue.body) {
                  Markdown({
                    text: this.issue.body,
                    controller: this.markdownController
                  })
                } else {
                  Text('暂无描述')
                    .fontSize(14)
                    .fontColor(SECONDARY_TEXT)
                    .fontStyle(FontStyle.Italic)
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)

              // 评论区
              if (this.comments.length > 0 || this.isLoadingComments) {
                Column({ space: 12 }) {
                  Text(`评论 (${this.issue.comments})`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(PRIMARY_TEXT)

                  if (this.isLoadingComments) {
                    Row({ space: 8 }) {
                      LoadingProgress()
                        .width(16)
                        .height(16)
                      Text('加载评论中...')
                        .fontSize(13)
                        .fontColor(SECONDARY_TEXT)
                    }
                  } else {
                    ForEach(this.comments, (comment: GitHubComment) => {
                      this.CommentItem(comment)
                    }, (comment: GitHubComment) => comment.id.toString())
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
              }

              // 底部留白，给输入框留空间
              Row().height(80)
            }
            .width('100%')
            .padding(16)
          }
          .width('100%')
          .layoutWeight(1)
        }

        // 底部评论输入区
        if (!this.isLoading && !this.error && this.issue) {
          Row({ space: 12 }) {
            if (this.showCommentInput) {
              TextInput({ placeholder: '添加评论...', text: this.commentText })
                .layoutWeight(1)
                .height(40)
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.commentText = value;
                })

              if (this.isSubmitting) {
                LoadingProgress()
                  .width(24)
                  .height(24)
              } else {
                Button('发送')
                  .height(40)
                  .fontSize(14)
                  .backgroundColor(ACCENT)
                  .onClick(() => this.submitComment())
              }

              Text('取消')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
                .onClick(() => {
                  this.showCommentInput = false;
                  this.commentText = '';
                })
            } else {
              Button('添加评论')
                .width('100%')
                .height(44)
                .fontSize(14)
                .backgroundColor(ACCENT)
                .onClick(() => {
                  this.showCommentInput = true;
                })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .border({ width: { top: 1 }, color: BORDER_COLOR })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CARD_BG)
    }
    .width('100%')
    .height('100%')
  }
}
