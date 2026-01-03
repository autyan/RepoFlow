/**
 * Issue 详情页面
 * 
 * 功能:
 * - 显示 Issue 详细信息
 * - 显示评论列表
 * - 支持添加评论
 * - 支持响应式布局和主题切换
 */

import pasteboard from '@ohos.pasteboard';
import resmgr from '@ohos.resourceManager';
import { authManager } from '../services/AuthManager';
import { GitHubIssue, GitHubComment, GitHubLabel } from '../models/GitHubModels';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import {
  ThemeManager,
  ThemeColors,
  ResponsiveManager,
  ResponsiveState,
  Spacing,
  BorderRadius,
  FontSize,
  LayoutMode,
  DeviceType,
} from '../theme';
import {
  RFCard,
  RFButton,
  RFAvatar,
  RFSplitView,
} from '../components';
import { UIHelper } from '../common/ui';

interface RouteParams {
  owner: string;
  repo: string;
  issueNumber: number;
}

// =====================================================
// Issue 详情页面
// =====================================================
@Entry
@Component
struct IssueDetailPage {
  // 数据状态
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

  // 主题状态
  @State colors: ThemeColors = ThemeManager.colors;
  @State isDark: boolean = ThemeManager.isDark;

  // 响应式状态
  @State layoutMode: LayoutMode = ResponsiveManager.state.layoutMode;
  @State deviceType: DeviceType = ResponsiveManager.state.deviceType;

  // =====================================================
  // 生命周期
  // =====================================================

  aboutToAppear(): void {
    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean): void => {
      this.colors = colors;
      this.isDark = isDark;
      // 更新 Markdown 样式
      this.markdownController
        .setTitleColor(colors.textPrimary)
        .setTextColor(colors.textSecondary)
        .setCodeBlockTheme(isDark ? 'dark' : 'light')
        .setQuoteBorderColor(colors.brandPrimary)
        .setQuoteBackgroundColor(colors.bgTertiary)
        .setHyperlinkTextColor(colors.brandPrimary)
        .setInlineCodeColor(colors.syntaxKeyword)
        .setInlineCodeBackgroundColor(colors.bgSecondary);
    });

    // 订阅响应式变化
    ResponsiveManager.subscribe((state: ResponsiveState): void => {
      this.layoutMode = state.layoutMode;
      this.deviceType = state.deviceType;
    });

    // 配置 Markdown 样式
    this.markdownController
      .setTitleColor(this.colors.textPrimary)
      .setTextColor(this.colors.textSecondary)
      .setTextSize(14)
      .setCodeBlockTheme(this.isDark ? 'dark' : 'light')
      .setQuoteBorderColor(this.colors.brandPrimary)
      .setQuoteBackgroundColor(this.colors.bgTertiary)
      .setHyperlinkTextColor(this.colors.brandPrimary)
      .setInlineCodeColor(this.colors.syntaxKeyword)
      .setInlineCodeBackgroundColor(this.colors.bgSecondary)
      .setCodeCopyListener((code: string): void => {
        this.copyToClipboard(code);
      });

    const params = this.getUIContext().getRouter().getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      this.issueNumber = params.issueNumber;
      this.loadIssue();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async copyToClipboard(text: string): Promise<void> {
    await UIHelper.copyToClipboard(
      this,
      text,
      $r('app.string.copied_to_clipboard'),
      'Copied',
      $r('app.string.copy_failed'),
      'Copy failed'
    );
  }

  async loadIssue(): Promise<void> {
    this.isLoading = true;
    this.error = '';

    const api = authManager.getGitHubApi();
    if (!api) {
      try {
        this.error = this.getUIContext()!.getHostContext()!.resourceManager!.getStringSync($r('app.string.please_login').id);
      } catch (error) {
        this.error = 'Please login';
      }
      this.isLoading = false;
      return;
    }

    try {
      this.issue = await api.getIssue(this.owner, this.repoName, this.issueNumber);
      this.loadComments();
    } catch (err) {
      try {
        this.error = this.getUIContext()!.getHostContext()!.resourceManager!.getStringSync($r('app.string.load_issue_failed').id);
      } catch (error) {
        this.error = 'Load issue failed';
      }
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
      UIHelper.showToast(this, $r('app.string.enter_comment_content'), 'Enter comment content');
      return;
    }

    this.isSubmitting = true;
    const api = authManager.getGitHubApi();
    if (!api) {
      UIHelper.showToast(this, $r('app.string.please_login'), 'Please login');
      this.isSubmitting = false;
      return;
    }

    try {
      const newComment = await api.addIssueComment(this.owner, this.repoName, this.issueNumber, this.commentText.trim());
      this.comments.push(newComment);
      this.commentText = '';
      this.showCommentInput = false;
      UIHelper.showToast(this, $r('app.string.comment_success'), 'Comment success');
    } catch (err) {
      UIHelper.showToast(this, $r('app.string.comment_failed'), 'Comment failed');
      console.error('Submit comment failed:', JSON.stringify(err));
    } finally {
      this.isSubmitting = false;
    }
  }

  // =====================================================
  // 工具方法
  // =====================================================

  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      const now = new Date();
      const diff = now.getTime() - date.getTime();
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));
      const rm = this.getUIContext()!.getHostContext()!.resourceManager!;

      if (days === 0) {
        const hours = Math.floor(diff / (1000 * 60 * 60));
        if (hours === 0) {
          const minutes = Math.floor(diff / (1000 * 60));
          return rm.getStringSync($r('app.string.minutes_ago').id).replace('%d', minutes.toString());
        }
        return rm.getStringSync($r('app.string.hours_ago').id).replace('%d', hours.toString());
      } else if (days < 30) {
        return rm.getStringSync($r('app.string.days_ago').id).replace('%d', days.toString());
      } else {
        return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
      }
    } catch (error) {
      console.error('Resource loading failed:', error);
      return dateStr;
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

  // =====================================================
  // UI 构建器
  // =====================================================

  // 页面头部
  @Builder
  PageHeader() {
    Row() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.colors.textPrimary)
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .onClick((): void => {
        try {
          this.getUIContext()!.getRouter()!.back();
        } catch (error) {
          console.error('Navigation failed:', error);
        }
      })

      Text(UIHelper.getString(this, $r('app.string.issue_title_with_number', this.issueNumber), `Issue #${this.issueNumber}`))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)

      Blank().width(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.MD })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 评论项
  @Builder
  CommentItem(comment: GitHubComment) {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.SM }) {
        RFAvatar({
          src: comment.user.avatar_url,
          alt: comment.user.login,
          avatarSize: 'sm',
          colors: this.colors
        })

        Column({ space: 2 }) {
          Text(comment.user.login)
            .fontSize(FontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textPrimary)

          Text(this.formatDate(comment.created_at))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
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
    .padding(Spacing.MD)
    .backgroundColor(this.colors.bgSecondary)
    .borderRadius(BorderRadius.MD)
    .margin({ bottom: Spacing.MD })
  }

  // Issue 主体
  @Builder
  IssueBody() {
    if (this.issue) {
      Column({ space: Spacing.MD }) {
        // 状态和标题
        Row({ space: Spacing.SM }) {
          Row() {
            Text(this.issue.state === 'open' ? $r('app.string.issue_state_open') : $r('app.string.issue_state_closed'))
              .fontSize(FontSize.SM)
              .fontColor('#FFFFFF')
          }
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor(this.issue.state === 'open' ? this.colors.githubOpen : this.colors.githubClosed)
        }
        .width('100%')

        Text(this.issue.title)
          .fontSize(FontSize.XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)

        // 作者信息
        Row({ space: Spacing.SM }) {
          RFAvatar({
            src: this.issue.user.avatar_url,
            alt: this.issue.user.login,
            avatarSize: 'sm',
            colors: this.colors
          })

          Text(`Created by ${this.issue.user.login} on ${this.formatDate(this.issue.created_at)}`)
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
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
          Text($r('app.string.no_description'))
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
            .fontStyle(FontStyle.Italic)
        }
      }
      .width('100%')
      .padding(Spacing.MD)
      .backgroundColor(this.colors.bgSecondary)
      .borderRadius(BorderRadius.MD)
    }
  }

  // 评论区
  @Builder
  CommentsSection() {
    if (this.issue && (this.comments.length > 0 || this.isLoadingComments)) {
      Column({ space: Spacing.MD }) {
        Text(`${this.issue.comments} comments`)
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        if (this.isLoadingComments) {
          Row({ space: Spacing.SM }) {
            LoadingProgress()
              .width(16)
              .height(16)
              .color(this.colors.brandPrimary)
            Text($r('app.string.loading_comments'))
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
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
  }

  // 评论输入区
  @Builder
  CommentInput() {
    if (!this.isLoading && !this.error && this.issue) {
      Row({ space: Spacing.MD }) {
        if (this.showCommentInput) {
          TextInput({ placeholder: $r('app.string.add_comment_placeholder'), text: this.commentText })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(this.colors.bgSecondary)
            .borderRadius(BorderRadius.MD)
            .onChange((value: string): void => {
              this.commentText = value;
            })

          if (this.isSubmitting) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(this.colors.brandPrimary)
          } else {
            RFButton({
              text: $r('app.string.send'),
              variant: 'primary',
              buttonSize: 'sm',
              colors: this.colors,
              onTap: (): void => {
                this.submitComment();
              }
            })
          }

          Text($r('app.string.cancel'))
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
            .onClick((): void => {
              this.showCommentInput = false;
              this.commentText = '';
            })
        } else {
          RFButton({
            text: $r('app.string.add_comment'),
            variant: 'primary',
            buttonSize: 'md',
            fullWidth: true,
            colors: this.colors,
            onTap: (): void => {
              this.showCommentInput = true;
            }
          })
        }
      }
      .width('100%')
      .padding(Spacing.MD)
      .backgroundColor(this.colors.bgPrimary)
      .border({ width: { top: 1 }, color: this.colors.border })
    }
  }

  // 加载状态
  @Builder
  LoadingView() {
    Column({ space: Spacing.SM }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.colors.brandPrimary)
      Text($r('app.string.loading'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 错误状态
  @Builder
  ErrorView() {
    Column({ space: Spacing.SM }) {
      Text(this.error)
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
      RFButton({
        text: $r('app.string.retry'),
        variant: 'secondary',
        buttonSize: 'md',
        colors: this.colors,
        onTap: (): void => {
          this.loadIssue();
        }
      })
        .margin({ top: Spacing.MD })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 主内容区域
  @Builder
  MainContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        this.IssueBody()
        this.CommentsSection()
        // 底部留白，给输入框留空间
        Row().height(80)
      }
      .width('100%')
      .padding(Spacing.MD)
    }
    .width('100%')
    .layoutWeight(1)
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Stack() {
      Column() {
        // 页面头部
        this.PageHeader()

        // 内容区域
        if (this.isLoading) {
          this.LoadingView()
        } else if (this.error) {
          this.ErrorView()
        } else {
          // 对于大屏，限制最大宽度
          if (this.layoutMode !== LayoutMode.SINGLE) {
            Row() {
              Blank()
              Column() {
                this.MainContent()
                this.CommentInput()
              }
              .width(800)
              Blank()
            }
            .width('100%')
            .layoutWeight(1)
          } else {
            this.MainContent()
            this.CommentInput()
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.colors.bgPrimary)
    }
    .width('100%')
    .height('100%')
  }
}
