import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { userState } from '../common/state/UserState';
import { tabState } from '../common/state/TabState';
import { GitHubUser, GitHubRepo, GitHubEvent, GitHubOrg } from '../models/GitHubModels';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';
const ICON_COLOR = '#57606A';

// 语言颜色映射
const LANGUAGE_COLORS: Record<string, string> = {
  'TypeScript': '#3178C6',
  'JavaScript': '#F7DF1E',
  'Python': '#3776AB',
  'Java': '#B07219',
  'Go': '#00ADD8',
  'Rust': '#DEA584',
  'C++': '#F34B7D',
  'C': '#555555',
  'Swift': '#FA7343',
  'Kotlin': '#A97BFF',
  'Ruby': '#CC342D',
  'PHP': '#777BB4',
  'C#': '#239120',
  'Dart': '#00B4AB',
  'Shell': '#89E051',
  'HTML': '#E34C26',
  'CSS': '#563D7C',
  'Vue': '#41B883',
  'Scala': '#C22D40',
  'Lua': '#000080'
};

interface LanguageStat {
  name: string;
  count: number;
  percentage: number;
  color: string;
}

@Component
export default struct ProfilePage {
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

  aboutToAppear(): void {
    this.syncState();
    userState.addListener(() => {
      this.syncState();
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

  async loadPinnedRepos(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api || !this.user) return;

    this.loadingRepos = true;
    try {
      const repos = await api.getUserRepos(1, 6);
      this.pinnedRepos = repos;
      // 计算语言统计
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
        color: LANGUAGE_COLORS[lang] || '#8B8B8B'
      });
    }
    
    // 按数量排序
    stats.sort((a, b) => b.count - a.count);
    this.languageStats = stats.slice(0, 5); // 只取前5个
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
    try {
      await router.pushUrl({ url: 'pages/LoginPage' });
    } catch (error) {
      console.error('Login navigation failed:', JSON.stringify(error));
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('个人资料')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(PRIMARY_TEXT)
        Blank()
        Row() {
          Image($r('app.media.ic_settings'))
            .width(22)
            .height(22)
            .fillColor(ICON_COLOR)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/SettingsPage' });
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 12 })

      Scroll() {
        Column({ space: 16 }) {
          if (this.isLoading) {
            Row({ space: 12 }) {
              LoadingProgress()
                .width(32)
                .height(32)
                .color(ACCENT)
              Text('加载中...')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 40, bottom: 40 })
          } else if (this.isLoggedIn && this.user) {
            // 用户信息卡片
            Column({ space: 16 }) {
              Row({ space: 16 }) {
                Image(this.user.avatar_url)
                  .width(72)
                  .height(72)
                  .borderRadius(36)
                  .border({ width: 3, color: ACCENT })
                
                Column({ space: 4 }) {
                  Text(this.user.name || this.user.login)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(PRIMARY_TEXT)
                  
                  Text(`@${this.user.login}`)
                    .fontSize(14)
                    .fontColor(SECONDARY_TEXT)
                  
                  if (this.user.bio) {
                    Text(this.user.bio)
                      .fontSize(13)
                      .fontColor(SECONDARY_TEXT)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 4 })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')

              if (this.user.company || this.user.location || this.user.blog) {
                Column({ space: 8 }) {
                  if (this.user.company) {
                    Row({ space: 8 }) {
                      Image($r('app.media.ic_company'))
                        .width(16)
                        .height(16)
                        .fillColor(ICON_COLOR)
                      Text(this.user.company)
                        .fontSize(13)
                        .fontColor(SECONDARY_TEXT)
                    }
                  }
                  if (this.user.location) {
                    Row({ space: 8 }) {
                      Image($r('app.media.ic_location'))
                        .width(16)
                        .height(16)
                        .fillColor(ICON_COLOR)
                      Text(this.user.location)
                        .fontSize(13)
                        .fontColor(SECONDARY_TEXT)
                    }
                  }
                  if (this.user.blog) {
                    Row({ space: 8 }) {
                      Image($r('app.media.ic_link'))
                        .width(16)
                        .height(16)
                        .fillColor(ICON_COLOR)
                      Text(this.user.blog)
                        .fontSize(13)
                        .fontColor(ACCENT)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding({ top: 8 })
              }

              // 统计信息
              Row() {
                this.ClickableStatItem(this.user.public_repos, '公开仓库', () => {
                  tabState.switchToRepos();
                })
                Divider().vertical(true).height(32).color('#D0D7DE')
                this.ClickableStatItem(this.user.followers, '关注者', () => {
                  router.pushUrl({ 
                    url: 'pages/FollowListPage',
                    params: { username: this.user?.login, type: 'followers' }
                  });
                })
                Divider().vertical(true).height(32).color('#D0D7DE')
                this.ClickableStatItem(this.user.following, '正在关注', () => {
                  router.pushUrl({ 
                    url: 'pages/FollowListPage',
                    params: { username: this.user?.login, type: 'following' }
                  });
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              .padding({ top: 8, bottom: 8 })
              .backgroundColor('#F0F6FC')
              .borderRadius(12)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(12)

            // 热门仓库
            Column({ space: 12 }) {
              Row() {
                Text('热门仓库')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(PRIMARY_TEXT)
                Blank()
                Text('查看全部')
                  .fontSize(13)
                  .fontColor(ACCENT)
              }
              .width('100%')

              if (this.loadingRepos) {
                Row() {
                  LoadingProgress().width(20).height(20)
                  Text('加载中...')
                    .fontSize(13)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ left: 8 })
                }
              } else if (this.pinnedRepos.length === 0) {
                Text('暂无仓库')
                  .fontSize(13)
                  .fontColor(SECONDARY_TEXT)
              } else {
                Column({ space: 8 }) {
                  ForEach(this.pinnedRepos, (repo: GitHubRepo) => {
                    this.MiniRepoCard(repo)
                  }, (repo: GitHubRepo) => repo.id.toString())
                }
                .width('100%')
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            // 最近活动
            Column({ space: 12 }) {
              Text('最近活动')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(PRIMARY_TEXT)
                .width('100%')

              if (this.loadingActivity) {
                Row() {
                  LoadingProgress().width(20).height(20)
                  Text('加载中...')
                    .fontSize(13)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ left: 8 })
                }
              } else if (this.recentActivity.length === 0) {
                Text('暂无活动')
                  .fontSize(13)
                  .fontColor(SECONDARY_TEXT)
              } else {
                Column({ space: 0 }) {
                  ForEach(this.recentActivity.slice(0, 5), (event: GitHubEvent, index: number) => {
                    this.ActivityItem(event)
                    if (index < Math.min(this.recentActivity.length, 5) - 1) {
                      Divider().color('#E1E4E8').margin({ left: 32 })
                    }
                  }, (event: GitHubEvent) => event.id)
                }
                .width('100%')
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            // 语言统计
            if (this.languageStats.length > 0) {
              Column({ space: 12 }) {
                Text('语言统计')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(PRIMARY_TEXT)
                  .width('100%')

                // 条形图
                Column({ space: 8 }) {
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
                  .borderRadius(4)
                  .clip(true)

                  // 图例
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.languageStats, (stat: LanguageStat) => {
                      Row({ space: 4 }) {
                        Circle({ width: 10, height: 10 })
                          .fill(stat.color)
                        Text(`${stat.name} ${stat.percentage}%`)
                          .fontSize(12)
                          .fontColor(SECONDARY_TEXT)
                      }
                      .margin({ right: 12, bottom: 6 })
                    }, (stat: LanguageStat) => stat.name)
                  }
                  .width('100%')
                }
                .width('100%')
              }
              .width('100%')
              .padding(16)
              .backgroundColor(CARD_BG)
              .borderRadius(12)
              .alignItems(HorizontalAlign.Start)
            }

            // Star 过的仓库
            Column({ space: 12 }) {
              Row() {
                Text('Star 过的仓库')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(PRIMARY_TEXT)
                Blank()
                Text('查看全部')
                  .fontSize(13)
                  .fontColor(ACCENT)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/StarredReposPage' });
                  })
              }
              .width('100%')

              if (this.loadingStarred) {
                Row() {
                  LoadingProgress().width(20).height(20)
                  Text('加载中...')
                    .fontSize(13)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ left: 8 })
                }
              } else if (this.starredRepos.length === 0) {
                Text('暂无 Star 的仓库')
                  .fontSize(13)
                  .fontColor(SECONDARY_TEXT)
              } else {
                Column({ space: 8 }) {
                  ForEach(this.starredRepos, (repo: GitHubRepo) => {
                    this.MiniRepoCard(repo)
                  }, (repo: GitHubRepo) => repo.id.toString())
                }
                .width('100%')
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            // 组织
            Column({ space: 12 }) {
              Text('组织')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(PRIMARY_TEXT)
                .width('100%')

              if (this.loadingOrgs) {
                Row() {
                  LoadingProgress().width(20).height(20)
                  Text('加载中...')
                    .fontSize(13)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ left: 8 })
                }
              } else if (this.organizations.length === 0) {
                Text('暂未加入任何组织')
                  .fontSize(13)
                  .fontColor(SECONDARY_TEXT)
              } else {
                Row({ space: 12 }) {
                  ForEach(this.organizations, (org: GitHubOrg) => {
                    Column({ space: 4 }) {
                      Image(org.avatar_url)
                        .width(48)
                        .height(48)
                        .borderRadius(8)
                      Text(org.login)
                        .fontSize(11)
                        .fontColor(SECONDARY_TEXT)
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
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

          } else {
            // 未登录状态
            Column({ space: 20 }) {
              Image($r('app.media.github_mark'))
                .width(80)
                .height(80)
                .fillColor('#24292F')

              Text('登录 GitHub')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(PRIMARY_TEXT)

              Text('登录后可以访问您的仓库、通知、关注列表和个人信息')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
                .textAlign(TextAlign.Center)
                .padding({ left: 20, right: 20 })

              Button() {
                Row({ space: 8 }) {
                  Image($r('app.media.github_mark'))
                    .width(20)
                    .height(20)
                    .fillColor('#FFFFFF')
                  Text('使用 GitHub 登录')
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                }
              }
              .width('80%')
              .height(50)
              .backgroundColor('#24292F')
              .borderRadius(8)
              .margin({ top: 12 })
              .onClick(() => {
                this.handleLogin();
              })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 60, bottom: 60 })
          }
        }
        .padding(20)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ClickableStatItem(count: number | undefined, label: string, onClick: () => void) {
    Column({ space: 4 }) {
      Text((count ?? 0).toString())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(PRIMARY_TEXT)
      Text(label)
        .fontSize(12)
        .fontColor(SECONDARY_TEXT)
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .onClick(onClick)
  }

  @Builder
  MiniRepoCard(repo: GitHubRepo) {
    Row({ space: 10 }) {
      Image($r('app.media.ic_repo'))
        .width(16)
        .height(16)
        .fillColor(ICON_COLOR)
      
      Column({ space: 2 }) {
        Text(repo.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(ACCENT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        if (repo.description) {
          Text(repo.description)
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Row({ space: 4 }) {
        Image($r('app.media.ic_star'))
          .width(12)
          .height(12)
          .fillColor(ICON_COLOR)
        Text(this.formatNumber(repo.stargazers_count))
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: { owner: repo.owner.login, repo: repo.name }
      });
    })
  }

  @Builder
  ActivityItem(event: GitHubEvent) {
    Row({ space: 10 }) {
      Image(this.getEventIcon(event.type))
        .width(18)
        .height(18)
        .fillColor(ICON_COLOR)
      
      Column({ space: 2 }) {
        Text(this.getEventDescription(event))
          .fontSize(13)
          .fontColor(PRIMARY_TEXT)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(this.formatTime(event.created_at))
          .fontSize(11)
          .fontColor(SECONDARY_TEXT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
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

  getEventDescription(event: GitHubEvent): string {
    const repo = event.repo.name;
    switch (event.type) {
      case 'PushEvent':
        const commits = event.payload.size ?? 0;
        return `推送了 ${commits} 个提交到 ${repo}`;
      case 'CreateEvent':
        const refType = event.payload.ref_type ?? 'repository';
        return `创建了 ${refType} 在 ${repo}`;
      case 'WatchEvent':
        return `Star 了 ${repo}`;
      case 'ForkEvent':
        return `Fork 了 ${repo}`;
      case 'IssuesEvent':
        return `${event.payload.action ?? '操作'} Issue 在 ${repo}`;
      case 'PullRequestEvent':
        return `${event.payload.action ?? '操作'} PR 在 ${repo}`;
      default:
        return `活动于 ${repo}`;
    }
  }

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
      return `${minutes} 分钟前`;
    } else if (hours < 24) {
      return `${hours} 小时前`;
    } else {
      const days = Math.floor(hours / 24);
      if (days < 30) {
        return `${days} 天前`;
      }
      return date.toLocaleDateString();
    }
  }
}
