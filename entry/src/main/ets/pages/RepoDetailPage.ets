import router from '@ohos.router';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import { authManager } from '../services/AuthManager';
import { GitHubRepo } from '../models/GitHubModels';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';
const ICON_COLOR = '#57606A';

interface RouteParams {
  owner: string;
  repo: string;
}

@Entry
@Component
struct RepoDetailPage {
  @State repo: GitHubRepo | null = null;
  @State isLoading: boolean = true;
  @State error: string = '';
  @State readme: string = '';
  @State loadingReadme: boolean = false;
  
  // Markdown 控制器
  private markdownController: MarkdownController = new MarkdownController();

  private owner: string = '';
  private repoName: string = '';

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
      .setTableBackgroundColor('#FFFFFF')
      .setTableTitleBackgroundColor('#F6F8FA')
      .setCodeCopyListener((code: string) => {
        this.copyToClipboard(code);
      });
    
    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      this.loadRepoDetail();
    }
  }

  async copyToClipboard(text: string): Promise<void> {
    try {
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteboardData);
      promptAction.showToast({ message: '已复制到剪贴板' });
    } catch (err) {
      promptAction.showToast({ message: '复制失败' });
      console.error('Copy failed:', JSON.stringify(err));
    }
  }

  async loadRepoDetail(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = '请先登录';
      this.isLoading = false;
      return;
    }

    try {
      this.repo = await api.getRepo(this.owner, this.repoName);
      this.loadReadme();
    } catch (err) {
      this.error = '加载仓库信息失败';
      console.error('Load repo failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  async loadReadme(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.loadingReadme = true;
    try {
      this.readme = await api.getRepoReadme(this.owner, this.repoName);
    } catch (err) {
      console.info('No README found');
      this.readme = '';
    } finally {
      this.loadingReadme = false;
    }
  }

  formatDate(dateStr: string | undefined): string {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
  }

  formatNumber(num: number | undefined): string {
    if (num === undefined) return '0';
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'k';
    }
    return num.toString();
  }

  build() {
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

        Text(this.repoName || '仓库详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()
          .width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#D0D7DE' })

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
          Image($r('app.media.ic_error'))
            .width(48)
            .height(48)
            .fillColor(SECONDARY_TEXT)
          Text(this.error)
            .fontSize(16)
            .fontColor(SECONDARY_TEXT)
            .margin({ top: 12 })
          Button('返回')
            .margin({ top: 20 })
            .onClick(() => router.back())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.repo) {
        Scroll() {
          Column({ space: 16 }) {
            // 仓库基本信息
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Image(this.repo.owner?.avatar_url || '')
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                Column({ space: 2 }) {
                  Text(this.repo.full_name)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(PRIMARY_TEXT)
                  if (this.repo.private) {
                    Row({ space: 4 }) {
                      Image($r('app.media.ic_lock'))
                        .width(12)
                        .height(12)
                        .fillColor(SECONDARY_TEXT)
                      Text('私有仓库')
                        .fontSize(12)
                        .fontColor(SECONDARY_TEXT)
                    }
                  }
                }
                .alignItems(HorizontalAlign.Start)
              }

              if (this.repo.description) {
                Text(this.repo.description)
                  .fontSize(14)
                  .fontColor(SECONDARY_TEXT)
                  .lineHeight(22)
              }

              // 统计信息
              Row({ space: 20 }) {
                this.StatItem($r('app.media.ic_star'), this.formatNumber(this.repo.stargazers_count), 'Stars')
                this.StatItem($r('app.media.ic_fork'), this.formatNumber(this.repo.forks_count), 'Forks')
                this.StatItem($r('app.media.ic_eye'), this.formatNumber(this.repo.watchers_count), 'Watchers')
              }
              .margin({ top: 8 })

              // 语言和更新时间
              Row({ space: 16 }) {
                if (this.repo.language) {
                  Row({ space: 4 }) {
                    Circle({ width: 10, height: 10 })
                      .fill(this.getLanguageColor(this.repo.language))
                    Text(this.repo.language)
                      .fontSize(13)
                      .fontColor(SECONDARY_TEXT)
                  }
                }
                Text('更新于 ' + this.formatDate(this.repo.updated_at))
                  .fontSize(13)
                  .fontColor(SECONDARY_TEXT)
              }
              .margin({ top: 4 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(12)

            // 快捷操作
            Column({ space: 8 }) {
              // 查看代码
              Row({ space: 12 }) {
                Image($r('app.media.ic_code'))
                  .width(20)
                  .height(20)
                  .fillColor(ICON_COLOR)
                Column({ space: 2 }) {
                  Text('查看代码')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(PRIMARY_TEXT)
                  Text('浏览仓库文件')
                    .fontSize(12)
                    .fontColor(SECONDARY_TEXT)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(SECONDARY_TEXT)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/CodeBrowserPage',
                  params: { owner: this.owner, repo: this.repoName }
                });
              })

              // Issues
              Row({ space: 12 }) {
                Image($r('app.media.ic_issue'))
                  .width(20)
                  .height(20)
                  .fillColor(ICON_COLOR)
                Column({ space: 2 }) {
                  Text('Issues')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(PRIMARY_TEXT)
                  Text((this.repo.open_issues_count ?? 0) + ' 个开放中')
                    .fontSize(12)
                    .fontColor(SECONDARY_TEXT)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(SECONDARY_TEXT)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/IssuesPage',
                  params: { owner: this.owner, repo: this.repoName }
                });
              })

              this.ActionRow($r('app.media.ic_pr'), 'Pull Requests', '查看合并请求')
              this.ActionRow($r('app.media.ic_tag'), 'Releases', '查看发布版本')
            }
            .width('100%')
            .padding(12)
            .backgroundColor(CARD_BG)
            .borderRadius(12)

            // README 预览
            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Image($r('app.media.ic_readme'))
                  .width(18)
                  .height(18)
                  .fillColor(ACCENT)
                Text('README')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ACCENT)
              }

              if (this.loadingReadme) {
                Row() {
                  LoadingProgress()
                    .width(16)
                    .height(16)
                  Text('加载中...')
                    .fontSize(13)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ left: 8 })
                }
              } else if (this.readme.length > 0) {
                Markdown({
                  controller: this.markdownController,
                  text: this.readme
                })
                  .width('100%')
              } else {
                Text('暂无 README')
                  .fontSize(13)
                  .fontColor(SECONDARY_TEXT)
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
          }
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  StatItem(icon: Resource, value: string, label: string) {
    Column({ space: 2 }) {
      Row({ space: 4 }) {
        Image(icon)
          .width(14)
          .height(14)
          .fillColor(ICON_COLOR)
        Text(value)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PRIMARY_TEXT)
      }
      Text(label)
        .fontSize(11)
        .fontColor(SECONDARY_TEXT)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ActionRow(icon: Resource, title: string, subtitle: string) {
    Row({ space: 12 }) {
      Image(icon)
        .width(20)
        .height(20)
        .fillColor(ICON_COLOR)
      Column({ space: 2 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
        Text(subtitle)
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .fillColor(SECONDARY_TEXT)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  getLanguageColor(language: string): string {
    const colors: Record<string, string> = {
      'JavaScript': '#F1E05A',
      'TypeScript': '#3178C6',
      'Python': '#3572A5',
      'Java': '#B07219',
      'Go': '#00ADD8',
      'Rust': '#DEA584',
      'C++': '#F34B7D',
      'C': '#555555',
      'Swift': '#F05138',
      'Kotlin': '#A97BFF',
      'Ruby': '#701516',
      'PHP': '#4F5D95',
      'C#': '#178600',
      'Shell': '#89E051',
      'HTML': '#E34C26',
      'CSS': '#563D7C',
      'Vue': '#41B883',
      'Dart': '#00B4AB'
    };
    return colors[language] || '#8B8B8B';
  }
}
