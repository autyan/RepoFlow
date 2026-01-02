/**
 * 用户个人主页
 * 
 * 功能:
 * - 显示其他用户的详细信息
 * - 显示用户的仓库和组织
 * - 支持响应式布局和主题切换
 */

import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { GitHubUser, GitHubRepo, GitHubOrg } from '../models/GitHubModels';
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
  RFAvatar,
  RFSplitView,
} from '../components';

interface RouteParams {
  username: string;
}

// =====================================================
// 用户个人主页
// =====================================================
@Entry
@Component
struct UserProfilePage {
  // 数据状态
  @State username: string = '';
  @State user: GitHubUser | null = null;
  @State repos: GitHubRepo[] = [];
  @State orgs: GitHubOrg[] = [];
  @State isLoading: boolean = true;
  @State activeTab: number = 0;
  @State selectedRepo: GitHubRepo | null = null;

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

    const params = router.getParams() as RouteParams;
    if (params?.username) {
      this.username = params.username;
      this.loadUserData();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadUserData(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoading = true;
    try {
      const results = await Promise.all([
        api.getUser(this.username),
        api.getReposForUser(this.username, 1, 10),
        api.getUserOrgs(this.username)
      ]);
      this.user = results[0] as GitHubUser;
      this.repos = results[1] as GitHubRepo[];
      this.orgs = results[2] as GitHubOrg[];
    } catch (error) {
      console.error('Failed to load user data:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  handleRepoClick(repo: GitHubRepo): void {
    if (this.layoutMode !== LayoutMode.SINGLE) {
      this.selectedRepo = repo;
    } else {
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: {
          owner: repo.owner?.login || this.username,
          repo: repo.name
        }
      });
    }
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
        router.back();
      })

      Text(this.username)
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ left: Spacing.MD })
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.MD })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 用户信息卡片
  @Builder
  UserInfoCard() {
    if (this.user) {
      Column({ space: Spacing.MD }) {
        Row({ space: Spacing.MD }) {
          RFAvatar({
            src: this.user.avatar_url,
            alt: this.user.login,
            avatarSize: 'xxl',
            colors: this.colors
          })

          Column({ space: 4 }) {
            Text(this.user.name || this.user.login)
              .fontSize(FontSize.XXL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)

            Text(`@${this.user.login}`)
              .fontSize(FontSize.MD)
              .fontColor(this.colors.textSecondary)

            if (this.user.bio) {
              Text(this.user.bio)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        // 用户元数据
        Column({ space: Spacing.SM }) {
          if (this.user.company) {
            Row({ space: Spacing.SM }) {
              Image($r('app.media.ic_company'))
                .width(16)
                .height(16)
                .fillColor(this.colors.textSecondary)
              Text(this.user.company)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
            }
          }
          if (this.user.location) {
            Row({ space: Spacing.SM }) {
              Image($r('app.media.ic_location'))
                .width(16)
                .height(16)
                .fillColor(this.colors.textSecondary)
              Text(this.user.location)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.textSecondary)
            }
          }
          if (this.user.blog) {
            Row({ space: Spacing.SM }) {
              Image($r('app.media.ic_link'))
                .width(16)
                .height(16)
                .fillColor(this.colors.textSecondary)
              Text(this.user.blog)
                .fontSize(FontSize.SM)
                .fontColor(this.colors.brandPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 统计数据
        Row() {
          this.StatItem('仓库', this.user.public_repos ?? 0, 'repos')
          Divider().vertical(true).height(32).color(this.colors.border)
          this.StatItem('关注者', this.user.followers ?? 0, 'followers')
          Divider().vertical(true).height(32).color(this.colors.border)
          this.StatItem('关注中', this.user.following ?? 0, 'following')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: Spacing.MD, bottom: Spacing.MD })
        .backgroundColor(this.colors.primaryContainer)
        .borderRadius(BorderRadius.MD)
      }
      .width('100%')
      .padding(Spacing.MD)
      .backgroundColor(this.colors.surface)
      .borderRadius(BorderRadius.LG)
    }
  }

  // 统计项
  @Builder
  StatItem(label: string, value: number, type: string) {
    Column({ space: 4 }) {
      Text(value.toString())
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)
      Text(label)
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textSecondary)
    }
    .onClick((): void => {
      if (type === 'followers') {
        router.pushUrl({
          url: 'pages/FollowListPage',
          params: { username: this.username, type: 'followers' }
        });
      } else if (type === 'following') {
        router.pushUrl({
          url: 'pages/FollowListPage',
          params: { username: this.username, type: 'following' }
        });
      }
    })
  }

  // Tab 按钮
  @Builder
  TabButton(label: string | Resource, index: number) {
    Text(label)
      .fontSize(FontSize.MD)
      .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.activeTab === index ? '#FFFFFF' : this.colors.textSecondary)
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor(this.activeTab === index ? this.colors.brandPrimary : Color.Transparent)
      .borderRadius(BorderRadius.SM)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick((): void => {
        this.activeTab = index;
      })
  }

  // 仓库卡片
  @Builder
  RepoCard(repo: GitHubRepo) {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        Image($r('app.media.ic_repo'))
          .width(16)
          .height(16)
          .fillColor(this.colors.textSecondary)
        Text(repo.name)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.brandPrimary)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

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
              .fill(getLanguageColor(repo.language))
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
          Text(this.formatNumber(repo.stargazers_count ?? 0))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_fork'))
            .width(12)
            .height(12)
            .fillColor(this.colors.textSecondary)
          Text(this.formatNumber(repo.forks_count ?? 0))
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

  // 组织卡片
  @Builder
  OrgCard(org: GitHubOrg) {
    Row({ space: Spacing.MD }) {
      Image(org.avatar_url)
        .width(48)
        .height(48)
        .borderRadius(BorderRadius.MD)

      Column({ space: 4 }) {
        Text(org.login)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
        if (org.description) {
          Text(org.description)
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.colors.surface)
    .borderRadius(BorderRadius.MD)
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

  // 主内容区域
  @Builder
  MainContent() {
    if (this.user) {
      Scroll() {
        Column({ space: Spacing.MD }) {
          // 用户信息卡片
          this.UserInfoCard()

          // Tab 切换
          Row() {
            this.TabButton($r('app.string.repositories'), 0)
            this.TabButton($r('app.string.organizations'), 1)
          }
          .width('100%')
          .backgroundColor(this.colors.bgSecondary)
          .borderRadius(BorderRadius.MD)
          .padding(4)

          // Tab 内容
          if (this.activeTab === 0) {
            Column({ space: Spacing.SM }) {
              if (this.repos.length === 0) {
                Text($r('app.string.no_public_repos'))
                  .fontSize(FontSize.MD)
                  .fontColor(this.colors.textSecondary)
                  .margin({ top: Spacing.LG })
              } else {
                ForEach(this.repos, (repo: GitHubRepo) => {
                  this.RepoCard(repo)
                }, (repo: GitHubRepo) => repo.id.toString())
              }
            }
            .width('100%')
          } else {
            Column({ space: Spacing.SM }) {
              if (this.orgs.length === 0) {
                Text($r('app.string.no_public_orgs'))
                  .fontSize(FontSize.MD)
                  .fontColor(this.colors.textSecondary)
                  .margin({ top: Spacing.LG })
              } else {
                ForEach(this.orgs, (org: GitHubOrg) => {
                  this.OrgCard(org)
                }, (org: GitHubOrg) => org.id.toString())
              }
            }
            .width('100%')
          }
        }
        .padding(Spacing.MD)
      }
      .layoutWeight(1)
    } else {
      Column({ space: Spacing.MD }) {
        Text($r('app.string.user_not_found'))
          .fontSize(FontSize.LG)
          .fontColor(this.colors.textSecondary)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
  }

  // 详情面板
  @Builder
  DetailPanel() {
    if (this.selectedRepo) {
      Column({ space: Spacing.MD }) {
        // 仓库信息
        Row({ space: Spacing.SM }) {
          Image(this.selectedRepo.owner?.avatar_url || '')
            .width(32)
            .height(32)
            .borderRadius(8)
          Column({ space: 2 }) {
            Text(this.selectedRepo.owner?.login || '')
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
            Text(this.formatNumber(this.selectedRepo.stargazers_count ?? 0))
              .fontSize(FontSize.XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)
            Text($r('app.string.stars'))
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
          }
          .alignItems(HorizontalAlign.Center)

          Column({ space: 4 }) {
            Text(this.formatNumber(this.selectedRepo.forks_count ?? 0))
              .fontSize(FontSize.XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)
            Text($r('app.string.forks'))
              .fontSize(FontSize.SM)
              .fontColor(this.colors.textSecondary)
          }
          .alignItems(HorizontalAlign.Center)
        }
        .justifyContent(FlexAlign.SpaceAround)
        .width('100%')
        .padding({ top: Spacing.MD, bottom: Spacing.MD })
        .backgroundColor(this.colors.bgSecondary)
        .borderRadius(BorderRadius.MD)

        Blank()

        // 查看详情按钮
        RFButton({
          text: $r('app.string.view_repo_details'),
          variant: 'primary',
          buttonSize: 'lg',
          fullWidth: true,
          colors: this.colors,
          onTap: (): void => {
            router.pushUrl({
              url: 'pages/RepoDetailPage',
              params: {
                owner: this.selectedRepo!.owner?.login || this.username,
                repo: this.selectedRepo!.name
              }
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
      // 页面头部
      this.PageHeader()

      // 内容区域
      if (this.isLoading) {
        this.LoadingView()
      } else if (this.layoutMode === LayoutMode.SINGLE) {
        this.MainContent()
      } else {
        RFSplitView({
          layoutMode: this.layoutMode,
          primaryWidth: this.layoutMode === LayoutMode.TRIPLE ? 400 : 450,
          colors: this.colors,
          showDivider: true,
          primaryContent: (): void => this.MainContent(),
          detailContent: (): void => this.DetailPanel()
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgSecondary)
  }
}
