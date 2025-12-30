import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { GitHubUser, GitHubRepo, GitHubOrg } from '../models/GitHubModels';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';
const ICON_COLOR = '#57606A';

interface RouteParams {
  username: string;
}

@Entry
@Component
struct UserProfilePage {
  @State username: string = '';
  @State user: GitHubUser | null = null;
  @State repos: GitHubRepo[] = [];
  @State orgs: GitHubOrg[] = [];
  @State isLoading: boolean = true;
  @State activeTab: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams;
    if (params?.username) {
      this.username = params.username;
      this.loadUserData();
    }
  }

  async loadUserData(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoading = true;
    try {
      // 并行加载用户信息、仓库和组织
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

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(PRIMARY_TEXT)
          .onClick(() => router.back())

        Text(this.username)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .margin({ left: 16 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

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
      } else if (this.user) {
        Scroll() {
          Column({ space: 16 }) {
            // 用户基本信息卡片
            Column({ space: 12 }) {
              Row({ space: 16 }) {
                Image(this.user.avatar_url)
                  .width(80)
                  .height(80)
                  .borderRadius(40)
                  .border({ width: 2, color: ACCENT })

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

              // 统计数据
              Row() {
                this.StatItem('仓库', this.user.public_repos ?? 0)
                Divider().vertical(true).height(32).color('#D0D7DE')
                this.StatItem('关注者', this.user.followers ?? 0)
                Divider().vertical(true).height(32).color('#D0D7DE')
                this.StatItem('关注中', this.user.following ?? 0)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceEvenly)
              .padding({ top: 12, bottom: 12 })
              .backgroundColor('#F0F6FC')
              .borderRadius(8)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)

            // Tab 切换
            Row() {
              this.TabButton('仓库', 0)
              this.TabButton('组织', 1)
            }
            .width('100%')
            .backgroundColor(CARD_BG)
            .borderRadius(8)
            .padding(4)

            // Tab 内容
            if (this.activeTab === 0) {
              // 仓库列表
              Column({ space: 12 }) {
                if (this.repos.length === 0) {
                  Text('暂无公开仓库')
                    .fontSize(14)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ top: 20 })
                } else {
                  ForEach(this.repos, (repo: GitHubRepo) => {
                    this.RepoCard(repo)
                  }, (repo: GitHubRepo) => repo.id.toString())
                }
              }
              .width('100%')
            } else {
              // 组织列表
              Column({ space: 12 }) {
                if (this.orgs.length === 0) {
                  Text('暂无公开组织')
                    .fontSize(14)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ top: 20 })
                } else {
                  ForEach(this.orgs, (org: GitHubOrg) => {
                    this.OrgCard(org)
                  }, (org: GitHubOrg) => org.id.toString())
                }
              }
              .width('100%')
            }
          }
          .padding(16)
        }
        .layoutWeight(1)
      } else {
        Column({ space: 16 }) {
          Text('用户不存在')
            .fontSize(16)
            .fontColor(SECONDARY_TEXT)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CARD_BG)
  }

  @Builder
  StatItem(label: string, value: number) {
    Column({ space: 4 }) {
      Text(value.toString())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PRIMARY_TEXT)
      Text(label)
        .fontSize(12)
        .fontColor(SECONDARY_TEXT)
    }
    .onClick(() => {
      if (label === '关注者') {
        router.pushUrl({
          url: 'pages/FollowListPage',
          params: { username: this.username, type: 'followers' }
        });
      } else if (label === '关注中') {
        router.pushUrl({
          url: 'pages/FollowListPage',
          params: { username: this.username, type: 'following' }
        });
      }
    })
  }

  @Builder
  TabButton(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.activeTab === index ? '#FFFFFF' : SECONDARY_TEXT)
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor(this.activeTab === index ? ACCENT : Color.Transparent)
      .borderRadius(6)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.activeTab = index;
      })
  }

  @Builder
  RepoCard(repo: GitHubRepo) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Image($r('app.media.ic_repo'))
          .width(16)
          .height(16)
          .fillColor(SECONDARY_TEXT)
        Text(repo.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ACCENT)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (repo.description) {
        Text(repo.description)
          .fontSize(13)
          .fontColor(SECONDARY_TEXT)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Row({ space: 16 }) {
        if (repo.language) {
          Row({ space: 4 }) {
            Circle({ width: 10, height: 10 })
              .fill(this.getLanguageColor(repo.language))
            Text(repo.language)
              .fontSize(12)
              .fontColor(SECONDARY_TEXT)
          }
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_star'))
            .width(12)
            .height(12)
            .fillColor(SECONDARY_TEXT)
          Text((repo.stargazers_count ?? 0).toString())
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_fork'))
            .width(12)
            .height(12)
            .fillColor(SECONDARY_TEXT)
          Text((repo.forks_count ?? 0).toString())
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: {
          owner: repo.owner?.login || this.username,
          repo: repo.name
        }
      });
    })
  }

  @Builder
  OrgCard(org: GitHubOrg) {
    Row({ space: 12 }) {
      Image(org.avatar_url)
        .width(48)
        .height(48)
        .borderRadius(8)

      Column({ space: 4 }) {
        Text(org.login)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
        if (org.description) {
          Text(org.description)
            .fontSize(13)
            .fontColor(SECONDARY_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

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
}
