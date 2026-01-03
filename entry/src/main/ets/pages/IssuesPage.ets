/**
 * Issues 列表页面
 * 
 * 功能:
 * - 显示仓库的 Issue 列表
 * - 支持筛选 (open/closed/all)
 * - 支持响应式布局和主题切换
 */

import { authManager } from '../services/AuthManager';
import { GitHubIssue, GitHubLabel } from '../models/GitHubModels';
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
  RFSplitView,
} from '../components';
import { UIHelper } from '../common/ui';

interface RouteParams {
  owner: string;
  repo: string;
}

// =====================================================
// Issues 页面
// =====================================================
@Entry
@Component
struct IssuesPage {
  // 数据状态
  @State isLoading: boolean = true;
  @State error: string = '';
  @State issues: GitHubIssue[] = [];
  @State filterState: 'open' | 'closed' | 'all' = 'open';
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;
  @State selectedIssue: GitHubIssue | null = null;

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
    });

    // 订阅响应式变化
    ResponsiveManager.subscribe((state: ResponsiveState): void => {
      this.layoutMode = state.layoutMode;
      this.deviceType = state.deviceType;
    });

    const params = this.getUIContext()!.getRouter()!.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      this.loadIssues();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadIssues(loadMore: boolean = false): Promise<void> {
    if (loadMore) {
      this.isLoadingMore = true;
    } else {
      this.isLoading = true;
      this.currentPage = 1;
      this.issues = [];
    }
    this.error = '';

    const api = authManager.getGitHubApi();
    if (!api) {
      try {
        this.error = this.getUIContext()!.getHostContext()!.resourceManager!.getStringSync($r('app.string.please_login').id);
      } catch (e) {
        this.error = 'Please login';
      }
      this.isLoading = false;
      return;
    }

    try {
      const newIssues = await api.getRepoIssues(this.owner, this.repoName, this.filterState, this.currentPage);
      
      // 过滤掉 Pull Request（GitHub API 会在 issues 中包含 PR）
      const filteredIssues = newIssues.filter((issue: GitHubIssue): boolean => {
        return issue.pull_request === undefined;
      });

      if (loadMore) {
        this.issues = this.issues.concat(filteredIssues);
      } else {
        this.issues = filteredIssues;
      }

      this.hasMore = newIssues.length >= 30;
      if (this.hasMore) {
        this.currentPage++;
      }
    } catch (err) {
      try {
        this.error = this.getUIContext()!.getHostContext()!.resourceManager!.getStringSync($r('app.string.load_issues_failed').id);
      } catch (e) {
        this.error = 'Load issues failed';
      }
      console.error('Load issues failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
      this.isLoadingMore = false;
    }
  }

  handleIssueClick(issue: GitHubIssue): void {
    if (this.layoutMode !== LayoutMode.SINGLE) {
      this.selectedIssue = issue;
    } else {
      UIHelper.pushUrl(this, 'pages/IssueDetailPage', {
        owner: this.owner,
        repo: this.repoName,
        issueNumber: issue.number
      });
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
        UIHelper.goBack(this);
      })

      Text($r('app.string.issues_tab_title'))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)

      // 新建 Issue 按钮
      Row() {
        Text(UIHelper.getString(this, $r('app.string.plus_sign'), '+'))
          .fontSize(24)
          .fontColor(this.colors.brandPrimary)
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .onClick((): void => {
        UIHelper.pushUrl(this, 'pages/CreateIssuePage', {
          owner: this.owner,
          repo: this.repoName
        });
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 筛选标签
  @Builder
  FilterTabs() {
    Row({ space: 0 }) {
      ForEach(['open', 'closed', 'all'] as ('open' | 'closed' | 'all')[], (state: 'open' | 'closed' | 'all') => {
        Column() {
          Text(state === 'open' ? $r('app.string.issue_state_open') : state === 'closed' ? $r('app.string.issue_state_closed') : $r('app.string.issue_state_all'))
            .fontSize(FontSize.MD)
            .fontColor(this.filterState === state ? this.colors.brandPrimary : this.colors.textSecondary)
            .fontWeight(this.filterState === state ? FontWeight.Medium : FontWeight.Normal)

          Row()
            .width(40)
            .height(2)
            .backgroundColor(this.filterState === state ? this.colors.brandPrimary : 'transparent')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .height(44)
        .justifyContent(FlexAlign.End)
        .onClick((): void => {
          if (this.filterState !== state) {
            this.filterState = state;
            this.loadIssues();
          }
        })
      }, (state: string) => state)
    }
    .width('100%')
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // Issue 卡片
  @Builder
  IssueCard(issue: GitHubIssue) {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        // 状态图标
        Image(issue.state === 'open' ? $r('app.media.ic_issue_open') : $r('app.media.ic_check_circle'))
          .width(18)
          .height(18)
          .fillColor(issue.state === 'open' ? this.colors.githubOpen : this.colors.githubClosed)

        // 标题
        Text(issue.title)
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 标签
      if (issue.labels && issue.labels.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(issue.labels.slice(0, 5), (label: GitHubLabel) => {
            Text(label.name)
              .fontSize(11)
              .fontColor(this.isLightColor(this.getLabelColor(label.color)) ? '#1F2328' : '#FFFFFF')
              .backgroundColor(this.getLabelColor(label.color))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(10)
              .margin({ right: 4, bottom: 4 })
          }, (label: GitHubLabel) => label.id.toString())
        }
        .width('100%')
      }

      // 元信息
      Row({ space: Spacing.MD }) {
        Text(`#${issue.number}`)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)

        Text(`${issue.user.login} · ${this.formatDate(issue.created_at)}`)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (issue.comments > 0) {
          Row({ space: 4 }) {
            Image($r('app.media.ic_comment'))
              .width(14)
              .height(14)
              .fillColor(this.colors.textSecondary)
            Text(issue.comments.toString())
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
          }
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.selectedIssue?.id === issue.id ? this.colors.bgTertiary : this.colors.surface)
    .borderRadius(BorderRadius.MD)
    .border({
      width: this.selectedIssue?.id === issue.id ? 1 : 0,
      color: this.colors.brandPrimary
    })
    .onClick((): void => {
      this.handleIssueClick(issue);
    })
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
          this.loadIssues();
        }
      })
        .margin({ top: Spacing.MD })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 空状态
  @Builder
  EmptyView() {
    Column({ space: Spacing.SM }) {
      Text('🎉')
        .fontSize(48)
      Text(this.filterState === 'open' ? $r('app.string.no_open_issues') : this.filterState === 'closed' ? $r('app.string.no_closed_issues') : $r('app.string.no_issues'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
      Text($r('app.string.issue_hint_pr'))
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textTertiary)
        .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // Issue 列表
  @Builder
  IssueList() {
    List({ space: Spacing.SM }) {
      ForEach(this.issues, (issue: GitHubIssue) => {
        ListItem() {
          this.IssueCard(issue)
        }
      }, (issue: GitHubIssue) => issue.id.toString())

      // 加载更多
      if (this.hasMore) {
        ListItem() {
          Row() {
            if (this.isLoadingMore) {
              LoadingProgress()
                .width(20)
                .height(20)
              Text($r('app.string.loading'))
                .fontSize(FontSize.MD)
                .fontColor(this.colors.textSecondary)
                .margin({ left: Spacing.SM })
            } else {
              Text($r('app.string.load_more'))
                .fontSize(FontSize.MD)
                .fontColor(this.colors.brandPrimary)
            }
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .onClick((): void => {
            if (!this.isLoadingMore) {
              this.loadIssues(true);
            }
          })
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  // 列表内容
  @Builder
  ListContent() {
    Column() {
      this.FilterTabs()

      if (this.isLoading) {
        this.LoadingView()
      } else if (this.error) {
        this.ErrorView()
      } else if (this.issues.length === 0) {
        this.EmptyView()
      } else {
        Column() {
          this.IssueList()
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM })
      }
    }
    .width('100%')
    .height('100%')
  }

  // 详情面板
  @Builder
  DetailPanel() {
    if (this.selectedIssue) {
      Column({ space: Spacing.MD }) {
        // 状态标签
        Row() {
          Text(this.selectedIssue.state === 'open' ? $r('app.string.issue_state_open') : $r('app.string.issue_state_closed'))
            .fontSize(FontSize.SM)
            .fontColor('#FFFFFF')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor(this.selectedIssue.state === 'open' ? this.colors.githubOpen : this.colors.githubClosed)
        }

        // 标题
        Text(this.selectedIssue.title)
          .fontSize(FontSize.XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)

        // 作者信息
        Row({ space: Spacing.SM }) {
          Image(this.selectedIssue.user.avatar_url)
            .width(24)
            .height(24)
            .borderRadius(12)
          Text(`${this.selectedIssue.user.login} · #${this.selectedIssue.number}`)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }

        // 标签
        if (this.selectedIssue.labels && this.selectedIssue.labels.length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.selectedIssue.labels, (label: GitHubLabel) => {
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

        // 使用 Spacer 推动按钮到底部
        Column()
          .layoutWeight(1)

        // 查看详情按钮
        RFButton({
          text: $r('app.string.view_full_details'),
          variant: 'primary',
          buttonSize: 'lg',
          fullWidth: true,
          colors: this.colors,
          onTap: (): void => {
            UIHelper.pushUrl(this, 'pages/IssueDetailPage', {
              owner: this.owner,
              repo: this.repoName,
              issueNumber: this.selectedIssue!.number
            });
          }
        })
      }
      .width('100%')
      .height('100%')
      .padding(Spacing.LG)
      .backgroundColor(this.colors.bgPrimary)
    } else {
      Column({ space: Spacing.SM }) {
        Image($r('app.media.ic_issue_open'))
          .width(64)
          .height(64)
          .fillColor(this.colors.textTertiary)
          .opacity(0.5)
        Text($r('app.string.select_issue_to_view'))
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textSecondary)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Column() {
      // 页面头部
      this.PageHeader()

      // 内容区域
      if (this.layoutMode === LayoutMode.SINGLE) {
        this.ListContent()
      } else {
        RFSplitView({
          layoutMode: this.layoutMode,
          primaryWidth: this.layoutMode === LayoutMode.TRIPLE ? 360 : 400,
          colors: this.colors,
          showDivider: true,
          primaryContent: (): void => this.ListContent(),
          detailContent: (): void => this.DetailPanel()
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgSecondary)
  }
}
