/**
 * 仓库详情页面
 * 
 * 功能:
 * - 显示仓库详细信息
 * - 显示 README
 * - 快捷操作入口
 * - 支持响应式布局和主题切换
 */

import router from '@ohos.router';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import { authManager } from '../services/AuthManager';
import { GitHubRepo } from '../models/GitHubModels';
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
  getLanguageColor,
} from '../theme';
import {
  RFCard,
  RFButton,
  RFSplitView,
} from '../components';

interface RouteParams {
  owner: string;
  repo: string;
}

// =====================================================
// 仓库详情页面
// =====================================================
@Entry
@Component
struct RepoDetailPage {
  // 数据状态
  @State repo: GitHubRepo | null = null;
  @State isLoading: boolean = true;
  @State error: string = '';
  @State readme: string = '';
  @State loadingReadme: boolean = false;

  private markdownController: MarkdownController = new MarkdownController();
  private owner: string = '';
  private repoName: string = '';

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
        .setInlineCodeBackgroundColor(colors.bgSecondary)
        .setTableBackgroundColor(colors.bgPrimary)
        .setTableTitleBackgroundColor(colors.bgTertiary);
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
      .setTableBackgroundColor(this.colors.bgPrimary)
      .setTableTitleBackgroundColor(this.colors.bgTertiary)
      .setCodeCopyListener((code: string): void => {
        this.copyToClipboard(code);
      });

    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      this.loadRepoDetail();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async copyToClipboard(text: string): Promise<void> {
    try {
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteboardData);
      promptAction.showToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.copied_to_clipboard').id) });
    } catch (err) {
      promptAction.showToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.copy_failed').id) });
      console.error('Copy failed:', JSON.stringify(err));
    }
  }

  async loadRepoDetail(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = getContext(this).resourceManager.getStringSync($r('app.string.please_login').id);
      this.isLoading = false;
      return;
    }

    try {
      this.repo = await api.getRepo(this.owner, this.repoName);
      this.loadReadme();
    } catch (err) {
      this.error = getContext(this).resourceManager.getStringSync($r('app.string.load_repo_failed').id);
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

  // =====================================================
  // 工具方法
  // =====================================================

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
        router.back();
      })

      Text(this.repoName || getContext(this).resourceManager.getStringSync($r('app.string.repo_details').id))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank()
        .width(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.MD })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 统计项
  @Builder
  StatItem(icon: Resource, value: string, label: string) {
    Column({ space: 2 }) {
      Row({ space: Spacing.XXS }) {
        Image(icon)
          .width(14)
          .height(14)
          .fillColor(this.colors.textSecondary)
        Text(value)
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
      }
      Text(label)
        .fontSize(FontSize.XS)
        .fontColor(this.colors.textSecondary)
    }
    .alignItems(HorizontalAlign.Center)
  }

  // 操作项
  @Builder
  ActionRow(icon: Resource, title: string | Resource, subtitle: string | Resource, onClick?: () => void) {
    Row({ space: Spacing.SM }) {
      Image(icon)
        .width(20)
        .height(20)
        .fillColor(this.colors.textSecondary)
      Column({ space: 2 }) {
        Text(title)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
        Text(subtitle)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .fillColor(this.colors.textSecondary)
    }
    .width('100%')
    .padding(Spacing.SM)
    .backgroundColor(this.colors.bgTertiary)
    .borderRadius(BorderRadius.SM)
    .onClick((): void => {
      if (onClick) {
        onClick();
      }
    })
  }

  // 仓库信息卡片
  @Builder
  RepoInfoCard() {
    if (this.repo) {
      Column({ space: Spacing.SM }) {
        Row({ space: Spacing.SM }) {
          Image(this.repo.owner?.avatar_url || '')
            .width(40)
            .height(40)
            .borderRadius(20)
          Column({ space: 2 }) {
            Text(this.repo.full_name)
              .fontSize(FontSize.XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)
            if (this.repo.private) {
              Row({ space: Spacing.XXS }) {
                Image($r('app.media.ic_lock'))
                  .width(12)
                  .height(12)
                  .fillColor(this.colors.textSecondary)
                Text($r('app.string.private_repo'))
                  .fontSize(FontSize.SM)
                  .fontColor(this.colors.textSecondary)
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
        }

        if (this.repo.description) {
          Text(this.repo.description)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
            .lineHeight(22)
        }

        // 统计信息
        Row({ space: Spacing.LG }) {
          this.StatItem($r('app.media.ic_star'), this.formatNumber(this.repo.stargazers_count), 'Stars')
          this.StatItem($r('app.media.ic_fork'), this.formatNumber(this.repo.forks_count), 'Forks')
          this.StatItem($r('app.media.ic_eye'), this.formatNumber(this.repo.watchers_count), 'Watchers')
        }
        .margin({ top: Spacing.SM })

        // 语言和更新时间
        Row({ space: Spacing.MD }) {
          if (this.repo.language) {
            Row({ space: Spacing.XXS }) {
              Circle({ width: 10, height: 10 })
                .fill(getLanguageColor(this.repo.language))
              Text(this.repo.language)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
            }
          }
          Text(getContext(this).resourceManager.getStringSync($r('app.string.updated_at').id)
            .replace('%s', this.formatDate(this.repo.updated_at)))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
        .margin({ top: Spacing.XXS })
      }
      .width('100%')
      .padding(Spacing.MD)
      .backgroundColor(this.colors.surface)
      .borderRadius(BorderRadius.MD)
    }
  }

  // 快捷操作
  @Builder
  QuickActions() {
    Column({ space: Spacing.SM }) {
      this.ActionRow($r('app.media.ic_code'), $r('app.string.browse_code'), $r('app.string.browse_repo_files'), (): void => {
        router.pushUrl({
          url: 'pages/CodeBrowserPage',
          params: { owner: this.owner, repo: this.repoName }
        });
      })

      this.ActionRow($r('app.media.ic_issue_open'), $r('app.string.issues'), `${this.repo?.open_issues_count ?? 0}`, (): void => {
        router.pushUrl({
          url: 'pages/IssuesPage',
          params: { owner: this.owner, repo: this.repoName }
        });
      })

      this.ActionRow($r('app.media.ic_pr'), $r('app.string.pull_requests'), $r('app.string.view_pull_requests'), (): void => {})
      this.ActionRow($r('app.media.ic_release'), $r('app.string.releases'), $r('app.string.view_releases'), (): void => {})
    }
    .width('100%')
    .padding(Spacing.SM)
    .backgroundColor(this.colors.surface)
    .borderRadius(BorderRadius.MD)
  }

  // README 内容
  @Builder
  ReadmeSection() {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        Image($r('app.media.ic_readme'))
          .width(18)
          .height(18)
          .fillColor(this.colors.brandPrimary)
        Text($r('app.string.readme_title'))
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.brandPrimary)
      }

      if (this.loadingReadme) {
        Row({ space: Spacing.SM }) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color(this.colors.brandPrimary)
          Text($r('app.string.loading'))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
      } else if (this.readme.length > 0) {
        Markdown({
          controller: this.markdownController,
          text: this.readme
        })
          .width('100%')
      } else {
        Text($r('app.string.no_readme'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      }
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.colors.surface)
    .borderRadius(BorderRadius.MD)
    .alignItems(HorizontalAlign.Start)
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
      Image($r('app.media.ic_error'))
        .width(48)
        .height(48)
        .fillColor(this.colors.textSecondary)
      Text(this.error)
        .fontSize(FontSize.LG)
        .fontColor(this.colors.textSecondary)
      RFButton({
        text: $r('app.string.go_back'),
        variant: 'secondary',
        buttonSize: 'md',
        colors: this.colors,
        onTap: (): void => {
          router.back();
        }
      })
        .margin({ top: Spacing.LG })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 主内容区域 - 单列模式
  @Builder
  SingleColumnContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        this.RepoInfoCard()
        this.QuickActions()
        this.ReadmeSection()
      }
      .padding(Spacing.MD)
    }
    .layoutWeight(1)
  }

  // 主内容区域 - 分栏模式侧边栏
  @Builder
  SidebarContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        this.RepoInfoCard()
        this.QuickActions()
      }
      .padding(Spacing.MD)
    }
    .width('100%')
    .height('100%')
  }

  // 主内容区域 - 分栏模式详情
  @Builder
  DetailContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        this.ReadmeSection()
      }
      .padding(Spacing.MD)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Column() {
      // 页面头部
      this.PageHeader()

      // 内容区域
      if (this.isLoading) {
        this.LoadingView()
      } else if (this.error) {
        this.ErrorView()
      } else if (this.repo) {
        if (this.layoutMode === LayoutMode.SINGLE) {
          this.SingleColumnContent()
        } else {
          RFSplitView({
            layoutMode: this.layoutMode,
            primaryWidth: this.layoutMode === LayoutMode.TRIPLE ? 360 : 400,
            colors: this.colors,
            showDivider: true,
            primaryContent: (): void => this.SidebarContent(),
            detailContent: (): void => this.DetailContent()
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgSecondary)
  }
}
