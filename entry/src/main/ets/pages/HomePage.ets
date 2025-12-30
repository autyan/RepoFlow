import router from '@ohos.router';
import { userState } from '../common/state/UserState';
import { authManager } from '../services/AuthManager';
import { GitHubUser, GitHubRepo } from '../models/GitHubModels';
import { tabState } from '../common/state/TabState';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';

@Component
export default struct HomePage {
  @State user: GitHubUser | null = null;
  @State isLoggedIn: boolean = false;
  @State recentRepos: GitHubRepo[] = [];
  @State isLoading: boolean = false;

  aboutToAppear(): void {
    this.syncState();
    userState.addListener(() => {
      this.syncState();
    });
  }

  syncState(): void {
    this.user = userState.user;
    this.isLoggedIn = userState.isLoggedIn;
    if (this.isLoggedIn && this.recentRepos.length === 0) {
      this.loadRecentRepos();
    }
  }

  async loadRecentRepos(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoading = true;
    try {
      this.recentRepos = await api.getUserRepos(1, 5);
    } catch (error) {
      console.error('Failed to load repos:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 用户欢迎区
        Row({ space: 12 }) {
          if (this.isLoggedIn && this.user) {
            Image(this.user.avatar_url)
              .width(56)
              .height(56)
              .borderRadius(28)
              .border({ width: 2, color: ACCENT })
          } else {
            Column() {
              Image($r('app.media.github_mark'))
                .width(32)
                .height(32)
                .fillColor(SECONDARY_TEXT)
            }
            .width(56)
            .height(56)
            .borderRadius(28)
            .backgroundColor(CARD_BG)
            .justifyContent(FlexAlign.Center)
          }
          Column({ space: 4 }) {
            if (this.isLoggedIn && this.user) {
              Text(`你好，${this.user.name || this.user.login}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(PRIMARY_TEXT)
              Text('欢迎回来')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
            } else {
              Text('RepoFlow')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(PRIMARY_TEXT)
              Text('您的 GitHub 移动助手')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        // 未登录引导
        if (!this.isLoggedIn) {
          Column({ space: 12 }) {
            Text('开始使用')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ACCENT)
            Text('登录您的 GitHub 账号，随时随地管理仓库、查看通知、追踪 Issue')
              .fontSize(14)
              .fontColor(SECONDARY_TEXT)
              .lineHeight(22)
            Button('登录 GitHub')
              .width('100%')
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(ACCENT)
              .borderRadius(8)
              .margin({ top: 4 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/LoginPage' });
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#F0F6FC')
          .borderRadius(12)
        }

        // 最近仓库
        Column({ space: 12 }) {
          Row() {
            Text('最近仓库')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ACCENT)
            Blank()
            if (this.isLoggedIn) {
              Text('查看全部')
                .fontSize(13)
                .fontColor(ACCENT)
                .onClick(() => {
                  tabState.switchToRepos();
                })
            }
          }
          .width('100%')

          if (!this.isLoggedIn) {
            Text('登录后显示您最近访问的仓库')
              .fontSize(14)
              .fontColor(SECONDARY_TEXT)
          } else if (this.isLoading) {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
              Text('加载中...')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
                .margin({ left: 8 })
            }
          } else if (this.recentRepos.length === 0) {
            Text('暂无仓库')
              .fontSize(14)
              .fontColor(SECONDARY_TEXT)
          } else {
            ForEach(this.recentRepos, (repo: GitHubRepo) => {
              this.RepoItem(repo)
            }, (repo: GitHubRepo) => repo.id.toString())
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(CARD_BG)
        .borderRadius(12)

        // 用户统计（仅登录后显示）
        if (this.isLoggedIn && this.user) {
          Column({ space: 12 }) {
            Text('账户概览')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ACCENT)
            Row() {
              this.StatCard('仓库', (this.user.public_repos ?? 0).toString(), () => {
                // 跳转到仓库页（Tab 1）
                tabState.switchToRepos();
              })
              this.StatCard('关注者', (this.user.followers ?? 0).toString(), () => {
                router.pushUrl({
                  url: 'pages/FollowListPage',
                  params: { username: this.user!.login, type: 'followers' }
                });
              })
              this.StatCard('关注中', (this.user.following ?? 0).toString(), () => {
                router.pushUrl({
                  url: 'pages/FollowListPage',
                  params: { username: this.user!.login, type: 'following' }
                });
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(CARD_BG)
          .borderRadius(12)
        }
      }
      .padding(20)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  RepoItem(repo: GitHubRepo) {
    Row({ space: 10 }) {
      Image($r('app.media.ic_repo'))
        .width(16)
        .height(16)
        .fillColor(SECONDARY_TEXT)
      Column({ space: 2 }) {
        Text(repo.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
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
          .fillColor(SECONDARY_TEXT)
        Text((repo.stargazers_count ?? 0).toString())
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)
      }
      Image($r('app.media.ic_chevron_right'))
        .width(14)
        .height(14)
        .fillColor(SECONDARY_TEXT)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: {
          owner: repo.owner?.login || '',
          repo: repo.name
        }
      });
    })
  }

  @Builder
  StatCard(label: string, value: string, onTap?: () => void) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(PRIMARY_TEXT)
      Text(label)
        .fontSize(12)
        .fontColor(SECONDARY_TEXT)
    }
    .width('30%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (onTap) {
        onTap();
      }
    })
  }
}
