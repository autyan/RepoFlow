/**
 * 仓库列表页面
 * 
 * 功能:
 * - 显示用户仓库列表
 * - 全站仓库搜索
 * - 支持响应式布局和主题切换
 */

import router from '@ohos.router';
import { userState } from '../common/state/UserState';
import { authManager } from '../services/AuthManager';
import { GitHubRepo, GitHubSearchResult } from '../models/GitHubModels';
import { LoginPrompt } from '../components/LoginPrompt';
import {
  ThemeManager,
  ThemeColors,
  ResponsiveManager,
  ResponsiveState,
  getLanguageColor,
  Spacing,
  BorderRadius,
  FontSize,
  LayoutMode,
  DeviceType,
} from '../theme';
import {
  RFCard,
  RFSearchInput,
  RFSplitView,
} from '../components';

// =====================================================
// 类型定义
// =====================================================
type SearchMode = 'my' | 'global';

// =====================================================
// 仓库列表页面
// =====================================================
@Component
export default struct ReposPage {
  // 数据状态
  @State isLoggedIn: boolean = false;
  @State repos: GitHubRepo[] = [];
  @State searchResults: GitHubRepo[] = [];
  @State isLoading: boolean = false;
  @State isSearching: boolean = false;
  @State searchText: string = '';
  @State searchMode: SearchMode = 'my';
  @State showLoginPrompt: boolean = true;
  @State selectedRepo: GitHubRepo | null = null;

  // 主题状态
  @State colors: ThemeColors = ThemeManager.colors;
  @State isDark: boolean = ThemeManager.isDark;

  // 响应式状态
  @State layoutMode: LayoutMode = ResponsiveManager.state.layoutMode;
  @State deviceType: DeviceType = ResponsiveManager.state.deviceType;

  private searchTimer: number = 0;

  // =====================================================
  // 生命周期
  // =====================================================

  aboutToAppear(): void {
    this.syncState();

    userState.addListener((): void => {
      this.syncState();
    });

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
  }

  syncState(): void {
    this.isLoggedIn = userState.isLoggedIn;
    if (this.isLoggedIn && this.repos.length === 0) {
      this.loadRepos();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadRepos(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoading = true;
    try {
      this.repos = await api.getUserRepos(1, 30);
    } catch (error) {
      console.error('Failed to load repos:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  async searchGlobalRepos(query: string): Promise<void> {
    if (!query.trim()) {
      this.searchResults = [];
      return;
    }
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isSearching = true;
    try {
      const result: GitHubSearchResult<GitHubRepo> = await api.searchRepos(query, 1, 30);
      this.searchResults = result.items;
    } catch (error) {
      console.error('Failed to search repos:', JSON.stringify(error));
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  onSearchTextChange(value: string): void {
    this.searchText = value;
    if (this.searchMode === 'global') {
      clearTimeout(this.searchTimer);
      this.searchTimer = setTimeout((): void => {
        this.searchGlobalRepos(value);
      }, 500);
    }
  }

  getFilteredRepos(): GitHubRepo[] {
    if (this.searchMode === 'global') {
      return this.searchResults;
    }
    if (!this.searchText) {
      return this.repos;
    }
    const keyword = this.searchText.toLowerCase();
    return this.repos.filter((repo: GitHubRepo): boolean =>
      repo.name.toLowerCase().includes(keyword) ||
      (repo.description?.toLowerCase().includes(keyword) ?? false)
    );
  }

  navigateToRepo(repo: GitHubRepo): void {
    if (this.layoutMode !== LayoutMode.SINGLE) {
      this.selectedRepo = repo;
    } else {
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: {
          owner: repo.owner?.login || '',
          repo: repo.name
        }
      });
    }
  }

  // =====================================================
  // UI 构建器
  // =====================================================

  // 搜索模式切换
  @Builder
  ModeTab(label: Resource, mode: SearchMode) {
    Text(label)
      .fontSize(FontSize.MD)
      .fontWeight(this.searchMode === mode ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.searchMode === mode ? this.colors.onPrimary : this.colors.textSecondary)
      .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
      .backgroundColor(this.searchMode === mode ? this.colors.brandPrimary : Color.Transparent)
      .borderRadius(BorderRadius.SM)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick((): void => {
        if (this.searchMode !== mode) {
          this.searchMode = mode;
          this.searchText = '';
          this.searchResults = [];
        }
      })
  }

  // 搜索栏
  @Builder
  SearchBar() {
    Column({ space: Spacing.SM }) {
      // 模式切换
      Row() {
        this.ModeTab($r('app.string.all_repos'), 'my')
        this.ModeTab($r('app.string.explore'), 'global')
      }
      .width('100%')
      .backgroundColor(this.colors.bgSecondary)
      .borderRadius(BorderRadius.SM)
      .padding(Spacing.XXS)

      // 搜索输入
      Row() {
        Image($r('app.media.ic_search'))
          .width(18)
          .height(18)
          .fillColor(this.colors.textSecondary)
          .margin({ right: Spacing.SM })

        TextInput({
          placeholder: this.searchMode === 'my' ? $r('app.string.search_my_repos') : $r('app.string.search_all_repos'),
          text: this.searchText
        })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.Transparent)
          .placeholderColor(this.colors.textTertiary)
          .fontColor(this.colors.textPrimary)
          .caretColor(this.colors.brandPrimary)
          .onChange((value: string): void => {
            this.onSearchTextChange(value);
          })
          .onSubmit((): void => {
            if (this.searchMode === 'global') {
              this.searchGlobalRepos(this.searchText);
            }
          })

        if (this.searchText) {
          Image($r('app.media.ic_close'))
            .width(18)
            .height(18)
            .fillColor(this.colors.textSecondary)
            .onClick((): void => {
              this.searchText = '';
              this.searchResults = [];
            })
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: Spacing.MD, right: Spacing.MD })
      .backgroundColor(this.colors.bgSecondary)
      .borderRadius(BorderRadius.SM)
      .border({ width: 1, color: this.colors.border })
    }
    .width('100%')
  }

  // 仓库卡片
  @Builder
  RepoCard(repo: GitHubRepo) {
    Column({ space: Spacing.XS }) {
      // 仓库名称
      Row() {
        if (repo.private) {
          Image($r('app.media.ic_lock'))
            .width(14)
            .height(14)
            .fillColor(this.colors.textSecondary)
            .margin({ right: Spacing.XXS })
        }
        Text(repo.full_name)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')

      // 描述
      if (repo.description) {
        Text(repo.description)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 元数据
      Row({ space: Spacing.MD }) {
        if (repo.language) {
          Row({ space: Spacing.XXS }) {
            Circle({ width: 10, height: 10 })
              .fill(getLanguageColor(repo.language))
            Text(repo.language)
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
          }
        }
        Row({ space: Spacing.XXS }) {
          Image($r('app.media.ic_star'))
            .width(14)
            .height(14)
            .fillColor(this.colors.warning)
          Text(repo.stargazers_count.toString())
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
        Row({ space: Spacing.XXS }) {
          Image($r('app.media.ic_fork'))
            .width(14)
            .height(14)
            .fillColor(this.colors.textSecondary)
          Text(repo.forks_count.toString())
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
      }
      .margin({ top: Spacing.XXS })
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.selectedRepo?.id === repo.id
      ? this.colors.primaryContainer
      : this.colors.surface)
    .borderRadius(BorderRadius.MD)
    .border({
      width: this.selectedRepo?.id === repo.id ? 1 : 0,
      color: this.colors.brandPrimary
    })
    .onClick((): void => {
      this.navigateToRepo(repo);
    })
  }

  // 加载状态
  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.colors.brandPrimary)
      Text($r('app.string.loading'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
        .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 空状态
  @Builder
  EmptyView() {
    Column({ space: Spacing.SM }) {
      Image($r('app.media.ic_search'))
        .width(48)
        .height(48)
        .fillColor(this.colors.textTertiary)
      Text($r('app.string.no_data'))
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
      ForEach(this.getFilteredRepos(), (repo: GitHubRepo) => {
        ListItem() {
          this.RepoCard(repo)
        }
      }, (repo: GitHubRepo) => repo.id.toString())
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  // 主列表内容
  @Builder
  ListContent() {
    Column() {
      // 搜索栏
      this.SearchBar()

      // 内容区域
      if (this.isLoading || this.isSearching) {
        this.LoadingView()
      } else if (this.searchMode === 'global' && this.searchText && this.searchResults.length === 0) {
        this.EmptyView()
      } else if (this.getFilteredRepos().length === 0) {
        this.EmptyView()
      } else {
        this.RepoList()
      }
    }
    .width('100%')
    .height('100%')
    .padding(Spacing.MD)
  }

  // 详情面板 (仅多栏模式)
  @Builder
  DetailPanel() {
    if (this.selectedRepo) {
      Column() {
        // 仓库详情预览
        Column({ space: Spacing.MD }) {
          Text(this.selectedRepo.full_name)
            .fontSize(FontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)

          if (this.selectedRepo.description) {
            Text(this.selectedRepo.description)
              .fontSize(FontSize.MD)
              .fontColor(this.colors.textSecondary)
          }

          // 打开详情按钮
          Button($r('app.string.view_details'))
            .width('100%')
            .height(44)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.onPrimary)
            .backgroundColor(this.colors.brandPrimary)
            .borderRadius(BorderRadius.SM)
            .onClick((): void => {
              router.pushUrl({
                url: 'pages/RepoDetailPage',
                params: {
                  owner: this.selectedRepo!.owner?.login || '',
                  repo: this.selectedRepo!.name
                }
              });
            })
        }
        .width('100%')
        .padding(Spacing.LG)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.colors.bgPrimary)
    } else {
      // 空状态
      Column({ space: Spacing.SM }) {
        Image($r('app.media.ic_repo'))
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
      if (!this.isLoggedIn && this.showLoginPrompt) {
        // 未登录提示
        LoginPrompt({
          title: $r('app.string.view_your_repos'),
          subtitle: $r('app.string.login_to_view_repos'),
          onDismiss: (): void => {
            this.showLoginPrompt = false;
          }
        })
      } else if (!this.isLoggedIn) {
        // 已关闭登录提示
        Column({ space: Spacing.MD }) {
          Text($r('app.string.repositories'))
            .fontSize(FontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)
          Text($r('app.string.repos_login_hint'))
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.layoutMode === LayoutMode.SINGLE) {
        // 单栏模式
        this.ListContent()
      } else {
        // 多栏模式
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
