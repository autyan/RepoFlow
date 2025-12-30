import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { GitHubUser } from '../models/GitHubModels';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';

interface RouteParams {
  username: string;
  type: 'followers' | 'following';
}

@Entry
@Component
struct FollowListPage {
  @State users: GitHubUser[] = [];
  @State isLoading: boolean = true;
  @State error: string = '';
  @State hasMore: boolean = true;
  
  private username: string = '';
  private type: 'followers' | 'following' = 'followers';
  private page: number = 1;

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.username = params.username;
      this.type = params.type;
      this.loadUsers();
    }
  }

  async loadUsers(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = '请先登录';
      this.isLoading = false;
      return;
    }

    try {
      let data: GitHubUser[];
      if (this.type === 'followers') {
        data = await api.getFollowers(this.username, this.page, 30);
      } else {
        data = await api.getFollowing(this.username, this.page, 30);
      }
      
      if (data.length < 30) {
        this.hasMore = false;
      }
      this.users = [...this.users, ...data];
    } catch (err) {
      this.error = '加载失败';
      console.error('Load users failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  loadMore(): void {
    if (!this.hasMore || this.isLoading) return;
    this.page++;
    this.isLoading = true;
    this.loadUsers();
  }

  getTitle(): string {
    return this.type === 'followers' ? '关注者' : '正在关注';
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

        Text(this.getTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位
        Row().width(40).height(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')

      if (this.error) {
        Column({ space: 12 }) {
          Image($r('app.media.ic_error'))
            .width(48)
            .height(48)
            .fillColor(SECONDARY_TEXT)
          Text(this.error)
            .fontSize(16)
            .fontColor(SECONDARY_TEXT)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.isLoading && this.users.length === 0) {
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
      } else if (this.users.length === 0) {
        Column({ space: 12 }) {
          Image($r('app.media.ic_user'))
            .width(48)
            .height(48)
            .fillColor(SECONDARY_TEXT)
          Text(this.type === 'followers' ? '暂无关注者' : '暂未关注任何人')
            .fontSize(16)
            .fontColor(SECONDARY_TEXT)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.users, (user: GitHubUser) => {
            ListItem() {
              this.UserItem(user)
            }
          }, (user: GitHubUser) => user.id.toString())
          
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
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 1, color: '#E1E4E8', startMargin: 68, endMargin: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  UserItem(user: GitHubUser) {
    Row({ space: 12 }) {
      Image(user.avatar_url)
        .width(44)
        .height(44)
        .borderRadius(22)
      
      Column({ space: 4 }) {
        Text(user.name || user.login)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(`@${user.login}`)
          .fontSize(13)
          .fontColor(SECONDARY_TEXT)
        
        if (user.bio) {
          Text(user.bio)
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .fillColor(SECONDARY_TEXT)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/UserProfilePage',
        params: { username: user.login }
      });
    })
  }
}
