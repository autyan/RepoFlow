/**
 * 个人资料页面
 * 
 * 功能:
 * - 用户信息展示
 * - 热门仓库
 * - 最近活动
 * - Star 的仓库
 * - 组织信息
 * - 语言统计
 * - 支持响应式布局和主题切换
 */

import { authManager } from '../services/AuthManager';
import { userState } from '../common/state/UserState';
import { tabState } from '../common/state/TabState';
import { GitHubUser, GitHubRepo, GitHubEvent, GitHubOrg } from '../models/GitHubModels';
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
  RFButton,
  RFAvatar,
  RFSplitView,
  RFPageHeader,
} from '../components';
import { UIHelper } from '../common/ui';

// =====================================================
// 类型定义
// =====================================================
interface LanguageStat {
  name: string;
  count: number;
  percentage: number;
  color: string;
}

// =====================================================
// 个人资料页面
// =====================================================
@Component
export default struct ProfilePage {
  // 数据状态
  @State isLoggedIn: boolean = false;
  @State isLoading: boolean = false;
  @State user: GitHubUser | null = null;
  @State pinnedRepos: GitHubRepo[] = [];
  @State recentActivity: GitHubEvent[] = [];
  @State starredRepos: GitHubRepo[] = [];
  @State organizations: GitHubOrg[] = [];
  @State languageStats: LanguageStat[] = [];
  @State loadingRepos: boolean = false;
  @State loadingActivity: boolean = false;
  @State loadingStarred: boolean = false;
  @State loadingOrgs: boolean = false;

  private t(res: Resource, ...args: Array<string | number>): string {
    try {
      const rm = this.getUIContext()!.getHostContext()!.resourceManager!;
      return rm.getStringSync(res.id, ...args);
    } catch (error) {
      console.error('Resource loading failed:', error);
      return '';
    }
  }

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

  onPageShow(): void {
    this.syncState();
  }

  syncState(): void {
    this.isLoggedIn = userState.isLoggedIn;
    this.isLoading = userState.isLoading;
    this.user = userState.user;

    if (this.isLoggedIn && this.user && this.pinnedRepos.length === 0) {
      this.loadPinnedRepos();
      this.loadRecentActivity();
      this.loadStarredRepos();
      this.loadOrganizations();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadPinnedRepos(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api || !this.user) return;

    this.loadingRepos = true;
    try {
      const repos = await api.getUserRepos(1, 6);
      this.pinnedRepos = repos;
      this.calculateLanguageStats(repos);
    } catch (error) {
      console.error('Failed to load repos:', JSON.stringify(error));
    } finally {
      this.loadingRepos = false;
    }
  }

  calculateLanguageStats(repos: GitHubRepo[]): void {
    const langCount: Record<string, number> = {};
    let total = 0;

    for (const repo of repos) {
      if (repo.language) {
        langCount[repo.language] = (langCount[repo.language] || 0) + 1;
        total++;
      }
    }

    const stats: LanguageStat[] = [];
    for (const lang of Object.keys(langCount)) {
      stats.push({
        name: lang,
        count: langCount[lang],
        percentage: Math.round((langCount[lang] / total) * 100),
        color: getLanguageColor(lang)
      });
    }

    stats.sort((a: LanguageStat, b: LanguageStat): number => b.count - a.count);
    this.languageStats = stats.slice(0, 5);
  }

  async loadRecentActivity(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api || !this.user) return;

    this.loadingActivity = true;
    try {
      const events = await api.getUserEvents(this.user.login, 1, 10);
      this.recentActivity = events;
    } catch (error) {
      console.error('Failed to load activity:', JSON.stringify(error));
    } finally {
      this.loadingActivity = false;
    }
  }

  async loadStarredRepos(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.loadingStarred = true;
    try {
      const repos = await api.getStarredRepos(1, 4);
      this.starredRepos = repos;
    } catch (error) {
      console.error('Failed to load starred repos:', JSON.stringify(error));
    } finally {
      this.loadingStarred = false;
    }
  }

  async loadOrganizations(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api || !this.user) return;

    this.loadingOrgs = true;
    try {
      const orgs = await api.getUserOrgs(this.user.login);
      this.organizations = orgs;
    } catch (error) {
      console.error('Failed to load organizations:', JSON.stringify(error));
    } finally {
      this.loadingOrgs = false;
    }
  }

  async handleLogin(): Promise<void> {
    UIHelper.pushUrl(this, 'pages/LoginPage');
  }

  // =====================================================
  // 工具方法
  // =====================================================

  formatNumber(num: number | undefined): string {
    if (num === undefined) return '0';
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'k';
    }
    return num.toString();
  }

  formatTime(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));

    if (hours < 1) {
      const minutes = Math.floor(diff / (1000 * 60));
      return this.t($r('app.string.minutes_ago'), minutes);
    } else if (hours < 24) {
      return this.t($r('app.string.hours_ago'), hours);
    } else {
      const days = Math.floor(hours / 24);
      if (days < 30) {
        return this.t($r('app.string.days_ago'), days);
      }
      const month = date.getMonth() + 1;
      const day = date.getDate();
      return this.t($r('app.string.date_md'), month, day);
    }
  }

  getEventIcon(type: string): Resource {
    switch (type) {
      case 'PushEvent':
        return $r('app.media.ic_code');
      case 'CreateEvent':
        return $r('app.media.ic_repo');
      case 'WatchEvent':
        return $r('app.media.ic_star');
      case 'ForkEvent':
        return $r('app.media.ic_fork');
      case 'IssuesEvent':
        return $r('app.media.ic_issue');
      case 'PullRequestEvent':
        return $r('app.media.ic_pr');
      default:
        return $r('app.media.ic_bell');
    }
  }

  getEventDescription(event: GitHubEvent): ResourceStr {
    const repo = event.repo.name;
    switch (event.type) {
      case 'PushEvent':
        const commits = event.payload.size ?? 0;
        return $r('app.string.push_commits', commits, repo);
      case 'CreateEvent':
        const refType = event.payload.ref_type ?? 'repository';
        return $r('app.string.create_ref', refType, repo);
      case 'WatchEvent':
        return $r('app.string.starred_repo', repo);
      case 'ForkEvent':
        return $r('app.string.forked_repo', repo);
      case 'IssuesEvent':
        return $r('app.string.action_issue', event.payload.action ?? 'action', repo);
      case 'PullRequestEvent':
        return $r('app.string.action_pr', event.payload.action ?? 'action', repo);
      default:
        return $r('app.string.event_in_repo', event.type, repo);
    }
  }

  // =====================================================
  // UI 构建器
  // =====================================================

  // 页面头部
  @Builder
  PageHeader() {
    Row() {
      Text($r('app.string.profile'))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)
      Blank()
      Row() {
        Image($r('app.media.ic_settings'))
          .width(22)
          .height(22)
          .fillColor(this.colors.textSecondary)
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .onClick((): void => {
        UIHelper.pushUrl(this, 'pages/SettingsPage');
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.SM })
  }

  // 用户信息卡片
  @Builder
  UserInfoCard() {
    RFCard({
      variant: 'filled',
      colors: this.colors,
      content: (): void => this.UserInfoContent()
    })
  }

  @Builder
  UserInfoContent() {
    Column({ space: Spacing.MD }) {
      // 头像和基本信息
      Row({ space: Spacing.MD }) {
        RFAvatar({
          src: this.user!.avatar_url,
          avatarSize: 'xxl',
          colors: this.colors
        })

        Column({ space: Spacing.XXS }) {
          Text(this.user!.name || this.user!.login)
            .fontSize(FontSize.XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)

          Text(`@${this.user!.login}`)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)

          if (this.user!.bio) {
            Text(this.user!.bio)
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: Spacing.XXS })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 联系信息
      if (this.user!.company || this.user!.location || this.user!.blog) {
        Column({ space: Spacing.XS }) {
          if (this.user!.company) {
            Row({ space: Spacing.XS }) {
              Image($r('app.media.ic_company'))
                .width(16)
                .height(16)
                .fillColor(this.colors.textTertiary)
              Text(this.user!.company)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
            }
          }
          if (this.user!.location) {
            Row({ space: Spacing.XS }) {
              Image($r('app.media.ic_location'))
                .width(16)
                .height(16)
                .fillColor(this.colors.textTertiary)
              Text(this.user!.location)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
            }
          }
          if (this.user!.blog) {
            Row({ space: Spacing.XS }) {
              Image($r('app.media.ic_link'))
                .width(16)
                .height(16)
                .fillColor(this.colors.textTertiary)
              Text(this.user!.blog)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.brandPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 统计信息
      Row() {
        this.StatItem(this.user!.public_repos, $r('app.string.public_repos'), (): void => {
          tabState.switchToRepos();
        })
        Divider().vertical(true).height(32).color(this.colors.divider)
        this.StatItem(this.user!.followers, $r('app.string.followers'), (): void => {
          UIHelper.pushUrl(this, 'pages/FollowListPage', { username: this.user?.login, type: 'followers' });
        })
        Divider().vertical(true).height(32).color(this.colors.divider)
        this.StatItem(this.user!.following, $r('app.string.following'), (): void => {
          UIHelper.pushUrl(this, 'pages/FollowListPage', { username: this.user?.login, type: 'following' });
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ top: Spacing.SM, bottom: Spacing.SM })
      .backgroundColor(this.colors.bgTertiary)
      .borderRadius(BorderRadius.MD)
    }
    .width('100%')
  }

  // 统计项
  @Builder
  StatItem(count: number | undefined, label: Resource, onClick: () => void) {
    Column({ space: Spacing.XXS }) {
      Text((count ?? 0).toString())
        .fontSize(FontSize.XXL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)
      Text(label)
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textSecondary)
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
    .onClick(onClick)
  }

  // 热门仓库卡片
  @Builder
  PopularReposCard() {
    RFCard({
      variant: 'filled',
      colors: this.colors,
      content: (): void => this.PopularReposContent()
    })
  }

  @Builder
  PopularReposContent() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text($r('app.string.popular_repos'))
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
        Blank()
        Text($r('app.string.view_all'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.brandPrimary)
          .onClick((): void => {
            tabState.switchToRepos();
          })
      }
      .width('100%')

      if (this.loadingRepos) {
        this.LoadingRow()
      } else if (this.pinnedRepos.length === 0) {
        Text($r('app.string.no_repos'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      } else {
        Column({ space: Spacing.XS }) {
          ForEach(this.pinnedRepos, (repo: GitHubRepo) => {
            this.MiniRepoCard(repo)
          }, (repo: GitHubRepo) => repo.id.toString())
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 仓库卡片
  @Builder
  MiniRepoCard(repo: GitHubRepo) {
    Row({ space: Spacing.SM }) {
      Image($r('app.media.ic_repo'))
        .width(16)
        .height(16)
        .fillColor(this.colors.textTertiary)

      Column({ space: 2 }) {
        Text(repo.name)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.brandPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (repo.description) {
          Text(repo.description)
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: Spacing.XXS }) {
        Image($r('app.media.ic_star'))
          .width(12)
          .height(12)
          .fillColor(this.colors.warning)
        Text(this.formatNumber(repo.stargazers_count))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      }
    }
    .width('100%')
    .padding(Spacing.SM)
    .backgroundColor(this.colors.bgTertiary)
    .borderRadius(BorderRadius.SM)
    .onClick((): void => {
      UIHelper.pushUrl(this, 'pages/RepoDetailPage', { owner: repo.owner.login, repo: repo.name });
    })
  }

  // 最近活动卡片
  @Builder
  RecentActivityCard() {
    RFCard({
      variant: 'filled',
      colors: this.colors,
      content: (): void => this.RecentActivityContent()
    })
  }

  @Builder
  RecentActivityContent() {
    Column({ space: Spacing.SM }) {
      Text($r('app.string.recent_activity'))
        .fontSize(FontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .width('100%')

      if (this.loadingActivity) {
        this.LoadingRow()
      } else if (this.recentActivity.length === 0) {
        Text($r('app.string.no_activity'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      } else {
        Column({ space: 0 }) {
          ForEach(this.recentActivity.slice(0, 5), (event: GitHubEvent, index: number) => {
            this.ActivityItem(event)
            if (index < Math.min(this.recentActivity.length, 5) - 1) {
              Divider().color(this.colors.divider).margin({ left: 32 })
            }
          }, (event: GitHubEvent) => event.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 活动项
  @Builder
  ActivityItem(event: GitHubEvent) {
    Row({ space: Spacing.SM }) {
      Image(this.getEventIcon(event.type))
        .width(18)
        .height(18)
        .fillColor(this.colors.textTertiary)

      Column({ space: 2 }) {
        Text(this.getEventDescription(event))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.formatTime(event.created_at))
          .fontSize(FontSize.XS)
          .fontColor(this.colors.textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
  }

  // 语言统计卡片
  @Builder
  LanguageStatsCard() {
    if (this.languageStats.length > 0) {
      RFCard({
        variant: 'filled',
        colors: this.colors,
        content: (): void => this.LanguageStatsContent()
      })
    }
  }

  @Builder
  LanguageStatsContent() {
    Column({ space: Spacing.SM }) {
      Text($r('app.string.language_stats'))
        .fontSize(FontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .width('100%')

      Column({ space: Spacing.XS }) {
        // 进度条
        Row() {
          ForEach(this.languageStats, (stat: LanguageStat) => {
            Row()
              .width(`${stat.percentage}%`)
              .height(8)
              .backgroundColor(stat.color)
          }, (stat: LanguageStat) => stat.name)
        }
        .width('100%')
        .borderRadius(BorderRadius.XS)
        .clip(true)

        // 图例
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.languageStats, (stat: LanguageStat) => {
            Row({ space: Spacing.XXS }) {
              Circle({ width: 10, height: 10 })
                .fill(stat.color)
              Text(`${stat.name} ${stat.percentage}%`)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
            }
            .margin({ right: Spacing.SM, bottom: Spacing.XS })
          }, (stat: LanguageStat) => stat.name)
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // Star 的仓库卡片
  @Builder
  StarredReposCard() {
    RFCard({
      variant: 'filled',
      colors: this.colors,
      content: (): void => this.StarredReposContent()
    })
  }

  @Builder
  StarredReposContent() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text($r('app.string.starred_repos'))
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
        Blank()
        Text($r('app.string.view_all'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.brandPrimary)
          .onClick((): void => {
            UIHelper.pushUrl(this, 'pages/StarredReposPage');
          })
      }
      .width('100%')

      if (this.loadingStarred) {
        this.LoadingRow()
      } else if (this.starredRepos.length === 0) {
        Text($r('app.string.no_starred_repos'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      } else {
        Column({ space: Spacing.XS }) {
          ForEach(this.starredRepos, (repo: GitHubRepo) => {
            this.MiniRepoCard(repo)
          }, (repo: GitHubRepo) => repo.id.toString())
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 组织卡片
  @Builder
  OrganizationsCard() {
    RFCard({
      variant: 'filled',
      colors: this.colors,
      content: (): void => this.OrganizationsContent()
    })
  }

  @Builder
  OrganizationsContent() {
    Column({ space: Spacing.SM }) {
      Text($r('app.string.organizations'))
        .fontSize(FontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .width('100%')

      if (this.loadingOrgs) {
        this.LoadingRow()
      } else if (this.organizations.length === 0) {
        Text($r('app.string.no_organizations'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      } else {
        Row({ space: Spacing.SM }) {
          ForEach(this.organizations, (org: GitHubOrg) => {
            Column({ space: Spacing.XXS }) {
              Image(org.avatar_url)
                .width(48)
                .height(48)
                .borderRadius(BorderRadius.SM)
              Text(org.login)
                .fontSize(FontSize.XS)
                .fontColor(this.colors.textSecondary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 60 })
            }
            .alignItems(HorizontalAlign.Center)
          }, (org: GitHubOrg) => org.id.toString())
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 加载行
  @Builder
  LoadingRow() {
    Row({ space: Spacing.SM }) {
      LoadingProgress()
        .width(20)
        .height(20)
        .color(this.colors.brandPrimary)
      Text($r('app.string.loading'))
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textSecondary)
    }
  }

  // 未登录状态
  @Builder
  NotLoggedInView() {
    Column({ space: Spacing.LG }) {
      Image($r('app.media.github_mark'))
        .width(80)
        .height(80)
        .fillColor(this.colors.textPrimary)

      Text($r('app.string.login_github'))
        .fontSize(FontSize.XXL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)

      Text($r('app.string.login_description'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
        .textAlign(TextAlign.Center)
        .padding({ left: Spacing.LG, right: Spacing.LG })

      RFButton({
        text: $r('app.string.login_github'),
        variant: 'primary',
        buttonSize: 'lg',
        colors: this.colors,
        onTap: (): void => {
          this.handleLogin();
        }
      })
        .width('80%')
        .margin({ top: Spacing.SM })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 60, bottom: 60 })
  }

  // 已登录内容 (单栏)
  @Builder
  LoggedInContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        this.UserInfoCard()
        this.PopularReposCard()
        this.RecentActivityCard()
        this.LanguageStatsCard()
        this.StarredReposCard()
        this.OrganizationsCard()
      }
      .padding(Spacing.LG)
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  // 侧边栏内容 (多栏模式)
  @Builder
  SideContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        this.UserInfoCard()
        this.LanguageStatsCard()
        this.OrganizationsCard()
      }
      .padding(Spacing.MD)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  // 详情内容 (多栏模式)
  @Builder
  DetailContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        this.PopularReposCard()
        this.RecentActivityCard()
        this.StarredReposCard()
      }
      .padding(Spacing.MD)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Column() {
      // 页面头部
      this.PageHeader()

      if (this.isLoading) {
        // 加载中
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
      } else if (this.isLoggedIn && this.user) {
        // 已登录
        if (this.layoutMode === LayoutMode.SINGLE) {
          this.LoggedInContent()
        } else {
          RFSplitView({
            layoutMode: this.layoutMode,
            primaryWidth: this.layoutMode === LayoutMode.TRIPLE ? 360 : 400,
            colors: this.colors,
            showDivider: true,
            primaryContent: (): void => this.SideContent(),
            detailContent: (): void => this.DetailContent()
          })
        }
      } else {
        // 未登录
        this.NotLoggedInView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}
