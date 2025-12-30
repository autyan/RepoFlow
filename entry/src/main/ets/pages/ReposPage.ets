import router from '@ohos.router';
import { userState } from '../common/state/UserState';
import { authManager } from '../services/AuthManager';
import { GitHubRepo } from '../models/GitHubModels';
import { LoginPrompt } from '../components/LoginPrompt';
import { GitHubSearchResult } from '../services/GitHubApiService';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const BORDER_COLOR = '#D0D7DE';
const ACCENT = '#0969DA';

type SearchMode = 'my' | 'global';

@Component
export default struct ReposPage {
  @State isLoggedIn: boolean = false;
  @State repos: GitHubRepo[] = [];
  @State searchResults: GitHubRepo[] = [];
  @State isLoading: boolean = false;
  @State isSearching: boolean = false;
  @State searchText: string = '';
  @State searchMode: SearchMode = 'my';
  @State showLoginPrompt: boolean = true;
  private searchTimer: number = 0;

  aboutToAppear(): void {
    this.syncState();
    userState.addListener(() => {
      this.syncState();
    });
  }

  syncState(): void {
    this.isLoggedIn = userState.isLoggedIn;
    if (this.isLoggedIn && this.repos.length === 0) {
      this.loadRepos();
    }
  }

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
    // 如果是全站搜索模式，延迟搜索
    if (this.searchMode === 'global') {
      clearTimeout(this.searchTimer);
      this.searchTimer = setTimeout(() => {
        this.searchGlobalRepos(value);
      }, 500);
    }
  }

  build() {
    Column() {
      if (!this.isLoggedIn && this.showLoginPrompt) {
        // 未登录提示
        LoginPrompt({
          title: '查看您的仓库',
          subtitle: '登录后可以查看、搜索和管理您的所有 GitHub 仓库',
          onDismiss: () => {
            this.showLoginPrompt = false;
          }
        })
      } else if (!this.isLoggedIn) {
        // 已点击稍后再说，显示简化内容
        Column({ space: 16 }) {
          Text('仓库')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRIMARY_TEXT)
          Text('登录后查看您的仓库列表')
            .fontSize(14)
            .fontColor(SECONDARY_TEXT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 已登录 - 显示仓库列表
        Column() {
          // 搜索模式切换
          Row() {
            this.ModeTab('我的仓库', 'my')
            this.ModeTab('全站搜索', 'global')
          }
          .width('100%')
          .backgroundColor(CARD_BG)
          .borderRadius(8)
          .padding(4)
          .margin({ bottom: 12 })

          // 搜索栏
          Row() {
            Image($r('app.media.ic_search'))
              .width(16)
              .height(16)
              .fillColor(SECONDARY_TEXT)
              .margin({ right: 8 })
            TextInput({
              placeholder: this.searchMode === 'my' ? '搜索我的仓库...' : '搜索所有 GitHub 仓库...',
              text: this.searchText
            })
              .layoutWeight(1)
              .height(40)
              .backgroundColor('transparent')
              .onChange((value) => {
                this.onSearchTextChange(value);
              })
              .onSubmit(() => {
                if (this.searchMode === 'global') {
                  this.searchGlobalRepos(this.searchText);
                }
              })
            if (this.searchText) {
              Image($r('app.media.ic_close'))
                .width(16)
                .height(16)
                .fillColor(SECONDARY_TEXT)
                .onClick(() => {
                  this.searchText = '';
                  this.searchResults = [];
                })
            }
          }
          .width('100%')
          .height(44)
          .padding({ left: 12, right: 12 })
          .backgroundColor(CARD_BG)
          .borderRadius(8)
          .margin({ bottom: 16 })

          if (this.isLoading || this.isSearching) {
            Column() {
              LoadingProgress()
                .width(40)
                .height(40)
              Text(this.isSearching ? '搜索中...' : '加载中...')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
                .margin({ top: 12 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.searchMode === 'global' && this.searchText && this.searchResults.length === 0) {
            Column({ space: 12 }) {
              Image($r('app.media.ic_search'))
                .width(48)
                .height(48)
                .fillColor(SECONDARY_TEXT)
              Text('未找到匹配的仓库')
                .fontSize(16)
                .fontColor(SECONDARY_TEXT)
              Text('尝试其他关键词')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            // 仓库列表
            List({ space: 12 }) {
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
        }
        .width('100%')
        .height('100%')
        .padding(20)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  getFilteredRepos(): GitHubRepo[] {
    // 全站搜索模式
    if (this.searchMode === 'global') {
      return this.searchResults;
    }
    // 本地仓库过滤
    if (!this.searchText) {
      return this.repos;
    }
    const keyword = this.searchText.toLowerCase();
    return this.repos.filter((repo) =>
      repo.name.toLowerCase().includes(keyword) ||
      (repo.description?.toLowerCase().includes(keyword) ?? false)
    );
  }

  @Builder
  ModeTab(label: string, mode: SearchMode) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.searchMode === mode ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.searchMode === mode ? '#FFFFFF' : SECONDARY_TEXT)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.searchMode === mode ? ACCENT : Color.Transparent)
      .borderRadius(6)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        if (this.searchMode !== mode) {
          this.searchMode = mode;
          this.searchText = '';
          this.searchResults = [];
        }
      })
  }

  @Builder
  RepoCard(repo: GitHubRepo) {
    Column({ space: 6 }) {
      Row() {
        if (repo.private) {
          Image($r('app.media.ic_lock'))
            .width(12)
            .height(12)
            .fillColor(SECONDARY_TEXT)
            .margin({ right: 4 })
        }
        Text(repo.full_name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
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
            .fillColor(SECONDARY_TEXT)
          Text(repo.stargazers_count.toString())
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
        Row({ space: 4 }) {
          Image($r('app.media.ic_fork'))
            .width(12)
            .height(12)
            .fillColor(SECONDARY_TEXT)
          Text(repo.forks_count.toString())
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
      }
      .margin({ top: 4 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(12)
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
      'Kotlin': '#A97BFF',
      'Ruby': '#CC342D',
      'PHP': '#777BB4',
      'C#': '#239120',
      'Dart': '#00B4AB'
    };
    return colors[language] || '#8B8B8B';
  }
}
