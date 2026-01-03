/**
 * Star 过的仓库列表页面
 * 
 * 功能:
 * - 显示用户 Star 过的仓库列表
 * - 支持分页加载
 * - 支持响应式布局和主题切换
 */

import { authManager } from '../services/AuthManager';
import { GitHubRepo } from '../models/GitHubModels';
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

// =====================================================
// Star 仓库列表页面
// =====================================================
@Entry
@Component
struct StarredReposPage {
  // 数据状态
  @State repos: GitHubRepo[] = [];
  @State isLoading: boolean = true;
  @State hasMore: boolean = true;
  @State selectedRepo: GitHubRepo | null = null;

  private page: number = 1;

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

    this.loadRepos();
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadRepos(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) {
      this.isLoading = false;
      return;
    }

    try {
      const data = await api.getStarredRepos(this.page, 20);
      if (data.length < 20) {
        this.hasMore = false;
      }
      this.repos = [...this.repos, ...data];
    } catch (error) {
      console.error('Failed to load starred repos:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  loadMore(): void {
    if (!this.hasMore || this.isLoading) return;
    this.page++;
    this.isLoading = true;
    this.loadRepos();
  }

  handleRepoClick(repo: GitHubRepo): void {
    if (this.layoutMode !== LayoutMode.SINGLE) {
      this.selectedRepo = repo;
    } else {
      UIHelper.pushUrl(this, 'pages/RepoDetailPage', { owner: repo.owner.login, repo: repo.name });
    }
  }

  // =====================================================
  // 工具方法
  // =====================================================

  getLanguageColor(language: string): string {
    const colors: Record<string, string> = {
      'TypeScript': '#3178C6',
      'JavaScript': '#F7DF1E',
      'Python': '#3776AB',
      'Java': '#B07219',
      'Go': '#00ADD8',
      'Rust': '#DEA584',
      'C++': '#F34B7D',
      'C': '#555555',
      'Swift': '#FA7343',
      'Kotlin': '#A97BFF'
    };
    return colors[language] || '#8B8B8B';
  }

  formatNumber(num: number): string {
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
        UIHelper.goBack(this);
      })

      Text($r('app.string.starred_repos'))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row().width(40).height(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 仓库卡片
  @Builder
  RepoCard(repo: GitHubRepo) {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        Image(repo.owner.avatar_url)
          .width(20)
          .height(20)
          .borderRadius(4)
        Text(repo.full_name)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.brandPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')

      if (repo.description) {
        Text(repo.description)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Row({ space: Spacing.MD }) {
        if (repo.language) {
          Row({ space: 4 }) {
            Circle({ width: 10, height: 10 })
              .fill(this.getLanguageColor(repo.language))
            Text(repo.language)
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
          }
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_star'))
            .width(12)
            .height(12)
            .fillColor(this.colors.textSecondary)
          Text(this.formatNumber(repo.stargazers_count))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_fork'))
            .width(12)
            .height(12)
            .fillColor(this.colors.textSecondary)
          Text(this.formatNumber(repo.forks_count))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
      }
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.selectedRepo?.id === repo.id ? this.colors.bgTertiary : this.colors.surface)
    .borderRadius(BorderRadius.MD)
    .border({
      width: this.selectedRepo?.id === repo.id ? 1 : 0,
      color: this.colors.brandPrimary
    })
    .onClick((): void => {
      this.handleRepoClick(repo);
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

  // 空状态
  @Builder
  EmptyView() {
    Column({ space: Spacing.SM }) {
      Image($r('app.media.ic_star'))
        .width(48)
        .height(48)
        .fillColor(this.colors.textSecondary)
      Text($r('app.string.no_starred_repos'))
        .fontSize(FontSize.LG)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 仓库列表
  @Builder
  RepoList() {
    List({ space: Spacing.SM }) {
      ForEach(this.repos, (repo: GitHubRepo) => {
        ListItem() {
          this.RepoCard(repo)
        }
      }, (repo: GitHubRepo) => repo.id.toString())

      if (this.hasMore) {
        ListItem() {
          Row() {
            if (this.isLoading) {
              LoadingProgress().width(20).height(20)
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
          .height(56)
          .justifyContent(FlexAlign.Center)
          .onClick((): void => {
            this.loadMore();
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
      if (this.isLoading && this.repos.length === 0) {
        this.LoadingView()
      } else if (this.repos.length === 0) {
        this.EmptyView()
      } else {
        Column() {
          this.RepoList()
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.MD })
      }
    }
    .width('100%')
    .height('100%')
  }

  // 详情面板
  @Builder
  DetailPanel() {
    if (this.selectedRepo) {
      Column({ space: Spacing.MD }) {
        // 仓库信息
        Row({ space: Spacing.SM }) {
          Image(this.selectedRepo.owner.avatar_url)
            .width(32)
            .height(32)
            .borderRadius(8)
          Column({ space: 2 }) {
            Text(this.selectedRepo.owner.login)
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
            Text(this.selectedRepo.name)
              .fontSize(FontSize.XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)
          }
          .alignItems(HorizontalAlign.Start)
        }

        // 描述
        if (this.selectedRepo.description) {
          Text(this.selectedRepo.description)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }

        // 统计信息
        Row({ space: Spacing.LG }) {
          Column({ space: 4 }) {
            Text(this.formatNumber(this.selectedRepo.stargazers_count))
              .fontSize(FontSize.XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)
            Text($r('app.string.stars'))
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
          }
          .alignItems(HorizontalAlign.Center)

          Column({ space: 4 }) {
            Text(this.formatNumber(this.selectedRepo.forks_count))
              .fontSize(FontSize.XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)
            Text($r('app.string.forks'))
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
          }
          .alignItems(HorizontalAlign.Center)

          if (this.selectedRepo.language) {
            Column({ space: 4 }) {
              Row({ space: 4 }) {
                Circle({ width: 12, height: 12 })
                  .fill(this.getLanguageColor(this.selectedRepo.language))
                Text(this.selectedRepo.language)
                  .fontSize(FontSize.MD)
                  .fontColor(this.colors.textPrimary)
              }
              Text($r('app.string.language'))
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
            }
            .alignItems(HorizontalAlign.Center)
          }
        }
        .justifyContent(FlexAlign.SpaceAround)
        .width('100%')
        .padding({ top: Spacing.MD, bottom: Spacing.MD })
        .backgroundColor(this.colors.bgSecondary)
        .borderRadius(BorderRadius.MD)

        // 查看详情按钮 - 紧跟内容
        RFButton({
          text: '查看仓库详情',
          variant: 'primary',
          buttonSize: 'lg',
          fullWidth: true,
          colors: this.colors,
          onTap: (): void => {
            UIHelper.pushUrl(this, 'pages/RepoDetailPage', { owner: this.selectedRepo!.owner.login, repo: this.selectedRepo!.name });
          }
        })
      }
      .width('100%')
      .padding(Spacing.LG)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(this.colors.bgPrimary)
    } else {
      Column({ space: Spacing.SM }) {
        Image($r('app.media.ic_star'))
          .width(64)
          .height(64)
          .fillColor(this.colors.textTertiary)
          .opacity(0.5)
        Text($r('app.string.select_repo_to_view'))
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
    .backgroundColor(this.colors.bgPrimary)
  }
}
