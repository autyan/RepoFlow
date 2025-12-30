import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { GitHubRepo } from '../models/GitHubModels';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';
const ICON_COLOR = '#57606A';

@Entry
@Component
struct StarredReposPage {
  @State repos: GitHubRepo[] = [];
  @State isLoading: boolean = true;
  @State hasMore: boolean = true;
  
  private page: number = 1;

  aboutToAppear(): void {
    this.loadRepos();
  }

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

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor(PRIMARY_TEXT)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.back();
        })

        Text('Star 过的仓库')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading && this.repos.length === 0) {
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
      } else if (this.repos.length === 0) {
        Column({ space: 12 }) {
          Image($r('app.media.ic_star'))
            .width(48)
            .height(48)
            .fillColor(SECONDARY_TEXT)
          Text('暂无 Star 的仓库')
            .fontSize(16)
            .fontColor(SECONDARY_TEXT)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
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
                  Text('加载中...')
                    .fontSize(14)
                    .fontColor(SECONDARY_TEXT)
                    .margin({ left: 8 })
                } else {
                  Text('加载更多')
                    .fontSize(14)
                    .fontColor(ACCENT)
                }
              }
              .width('100%')
              .height(56)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.loadMore();
              })
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 12 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  RepoCard(repo: GitHubRepo) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Image(repo.owner.avatar_url)
          .width(20)
          .height(20)
          .borderRadius(4)
        Text(repo.full_name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ACCENT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')

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
            .fillColor(ICON_COLOR)
          Text(this.formatNumber(repo.stargazers_count))
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_fork'))
            .width(12)
            .height(12)
            .fillColor(ICON_COLOR)
          Text(this.formatNumber(repo.forks_count))
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(12)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: { owner: repo.owner.login, repo: repo.name }
      });
    })
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

  formatNumber(num: number): string {
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'k';
    }
    return num.toString();
  }
}
