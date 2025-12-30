import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { GitHubIssue, GitHubLabel } from '../models/GitHubModels';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#F28C28';
const BORDER_COLOR = '#D0D7DE';
const OPEN_COLOR = '#1A7F37';
const CLOSED_COLOR = '#8250DF';

interface RouteParams {
  owner: string;
  repo: string;
}

@Entry
@Component
struct IssuesPage {
  @State isLoading: boolean = true;
  @State error: string = '';
  @State issues: GitHubIssue[] = [];
  @State filterState: 'open' | 'closed' | 'all' = 'open';
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;

  private owner: string = '';
  private repoName: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      this.loadIssues();
    }
  }

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
      this.error = '请先登录';
      this.isLoading = false;
      return;
    }

    try {
      const newIssues = await api.getRepoIssues(this.owner, this.repoName, this.filterState, this.currentPage);
      
      // 过滤掉 Pull Request（GitHub API 会在 issues 中包含 PR）
      const filteredIssues = newIssues.filter(issue => {
        // GitHub Issues API 中 pull_request 字段存在时表示这是一个 PR
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
      this.error = '加载 Issue 列表失败';
      console.error('Load issues failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
      this.isLoadingMore = false;
    }
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) {
      const hours = Math.floor(diff / (1000 * 60 * 60));
      if (hours === 0) {
        const minutes = Math.floor(diff / (1000 * 60));
        return `${minutes} 分钟前`;
      }
      return `${hours} 小时前`;
    } else if (days < 30) {
      return `${days} 天前`;
    } else {
      return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
    }
  }

  getLabelColor(color: string): string {
    // 确保颜色格式正确
    if (color.startsWith('#')) {
      return color;
    }
    return `#${color}`;
  }

  isLightColor(hexColor: string): boolean {
    // 判断颜色是否是浅色，以决定文字颜色
    const hex = hexColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;
    return brightness > 128;
  }

  @Builder
  FilterTabs() {
    Row({ space: 0 }) {
      ForEach(['open', 'closed', 'all'] as ('open' | 'closed' | 'all')[], (state: 'open' | 'closed' | 'all') => {
        Column() {
          Text(state === 'open' ? '开放' : state === 'closed' ? '已关闭' : '全部')
            .fontSize(14)
            .fontColor(this.filterState === state ? ACCENT : SECONDARY_TEXT)
            .fontWeight(this.filterState === state ? FontWeight.Medium : FontWeight.Normal)

          Row()
            .width(40)
            .height(2)
            .backgroundColor(this.filterState === state ? ACCENT : 'transparent')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .height(44)
        .justifyContent(FlexAlign.End)
        .onClick(() => {
          if (this.filterState !== state) {
            this.filterState = state;
            this.loadIssues();
          }
        })
      }, (state: string) => state)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: BORDER_COLOR })
  }

  @Builder
  IssueItem(issue: GitHubIssue) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        // 状态图标
        Image(issue.state === 'open' ? $r('app.media.ic_issue_open') : $r('app.media.ic_check_circle'))
          .width(18)
          .height(18)
          .fillColor(issue.state === 'open' ? OPEN_COLOR : CLOSED_COLOR)

        // 标题
        Text(issue.title)
          .fontSize(15)
          .fontColor(PRIMARY_TEXT)
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
      Row({ space: 16 }) {
        Text(`#${issue.number}`)
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)

        Text(`由 ${issue.user.login} 创建于 ${this.formatDate(issue.created_at)}`)
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (issue.comments > 0) {
          Row({ space: 4 }) {
            Image($r('app.media.ic_comment'))
              .width(14)
              .height(14)
              .fillColor(SECONDARY_TEXT)
            Text(issue.comments.toString())
              .fontSize(12)
              .fontColor(SECONDARY_TEXT)
          }
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: BORDER_COLOR })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/IssueDetailPage',
        params: {
          owner: this.owner,
          repo: this.repoName,
          issueNumber: issue.number
        }
      });
    })
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

        Text('Issues')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)

        // 新建 Issue 按钮
        Row() {
          Text('+')
            .fontSize(24)
            .fontColor(ACCENT)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/CreateIssuePage',
            params: {
              owner: this.owner,
              repo: this.repoName
            }
          });
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: BORDER_COLOR })

      // 筛选标签
      this.FilterTabs()

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
      } else if (this.error) {
        Column() {
          Text(this.error)
            .fontSize(14)
            .fontColor(SECONDARY_TEXT)
          Button('重试')
            .height(36)
            .fontSize(14)
            .margin({ top: 16 })
            .onClick(() => this.loadIssues())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.issues.length === 0) {
        Column() {
          Text('🎉')
            .fontSize(48)
          Text(this.filterState === 'open' ? '没有开放的 Issue' : this.filterState === 'closed' ? '没有已关闭的 Issue' : '没有 Issue')
            .fontSize(14)
            .fontColor(SECONDARY_TEXT)
            .margin({ top: 12 })
          Text('提示：GitHub 的 Issue 数量统计包含 PR')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })
            .fontColor(SECONDARY_TEXT)
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.issues, (issue: GitHubIssue) => {
            ListItem() {
              this.IssueItem(issue)
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
              .height(48)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (!this.isLoadingMore) {
                  this.loadIssues(true);
                }
              })
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CARD_BG)
  }
}
