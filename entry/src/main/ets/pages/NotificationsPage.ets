import router from '@ohos.router';
import { userState } from '../common/state/UserState';
import { authManager } from '../services/AuthManager';
import { GitHubNotification } from '../models/GitHubModels';
import { LoginPrompt } from '../components/LoginPrompt';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';
const ICON_COLOR = '#57606A';

@Component
export default struct NotificationsPage {
  @State isLoggedIn: boolean = false;
  @State notifications: GitHubNotification[] = [];
  @State isLoading: boolean = false;
  @State showLoginPrompt: boolean = true;

  aboutToAppear(): void {
    this.syncState();
    userState.addListener(() => {
      this.syncState();
    });
  }

  syncState(): void {
    this.isLoggedIn = userState.isLoggedIn;
    if (this.isLoggedIn && this.notifications.length === 0) {
      this.loadNotifications();
    }
  }

  async loadNotifications(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoading = true;
    try {
      this.notifications = await api.getNotifications(false, 1, 50);
    } catch (error) {
      console.error('Failed to load notifications:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      if (!this.isLoggedIn && this.showLoginPrompt) {
        LoginPrompt({
          title: '查看通知',
          subtitle: '登录后可以接收 Issue、PR 和讨论的通知提醒',
          onDismiss: () => {
            this.showLoginPrompt = false;
          }
        })
      } else if (!this.isLoggedIn) {
        Column({ space: 16 }) {
          Image($r('app.media.ic_bell'))
            .width(48)
            .height(48)
            .fillColor(SECONDARY_TEXT)
          Text('通知')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRIMARY_TEXT)
          Text('登录后查看您的通知')
            .fontSize(14)
            .fontColor(SECONDARY_TEXT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          Row() {
            Text('通知')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(PRIMARY_TEXT)
            Blank()
            Text('刷新')
              .fontSize(14)
              .fontColor(ACCENT)
              .onClick(() => {
                this.loadNotifications();
              })
          }
          .width('100%')
          .margin({ bottom: 16 })

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
          } else if (this.notifications.length === 0) {
            Column({ space: 12 }) {
              Image($r('app.media.ic_check_circle'))
                .width(48)
                .height(48)
                .fillColor('#1A7F37')
              Text('没有未读通知 🎉')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(PRIMARY_TEXT)
              Text('您的通知都已处理完毕')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
              Button('刷新')
                .fontSize(14)
                .fontColor(ACCENT)
                .backgroundColor('#F0F6FC')
                .borderRadius(20)
                .padding({ left: 24, right: 24, top: 10, bottom: 10 })
                .margin({ top: 16 })
                .onClick(() => {
                  this.loadNotifications();
                })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List({ space: 12 }) {
              ForEach(this.notifications, (notification: GitHubNotification) => {
                ListItem() {
                  this.NotificationCard(notification)
                }
              }, (notification: GitHubNotification) => notification.id)
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

  @Builder
  NotificationCard(notification: GitHubNotification) {
    Column({ space: 6 }) {
      Row() {
        Image(this.getTypeIcon(notification.subject.type))
          .width(16)
          .height(16)
          .fillColor(this.getTypeColor(notification.subject.type))
        Text(notification.repository.full_name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .margin({ left: 8 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (notification.unread) {
          Circle({ width: 8, height: 8 })
            .fill(ACCENT)
        }
      }
      .width('100%')

      Text(notification.subject.title)
        .fontSize(14)
        .fontColor(SECONDARY_TEXT)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.formatTime(notification.updated_at))
        .fontSize(12)
        .fontColor(SECONDARY_TEXT)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(notification.unread ? '#F0F6FC' : CARD_BG)
    .borderRadius(12)
    .onClick(() => {
      // 跳转到对应仓库
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: {
          owner: notification.repository.owner.login,
          repo: notification.repository.name
        }
      });
      // 标记为已读
      if (notification.unread) {
        this.markAsRead(notification.id);
      }
    })
  }

  async markAsRead(threadId: string): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;
    
    try {
      await api.markNotificationAsRead(threadId);
      // 更新本地状态
      const index = this.notifications.findIndex(n => n.id === threadId);
      if (index >= 0) {
        this.notifications[index].unread = false;
        // 触发重新渲染
        this.notifications = [...this.notifications];
      }
    } catch (error) {
      console.error('Mark as read failed:', JSON.stringify(error));
    }
  }

  getTypeIcon(type: string): Resource {
    switch (type) {
      case 'Issue':
        return $r('app.media.ic_issue_open');
      case 'PullRequest':
        return $r('app.media.ic_pr');
      case 'Release':
        return $r('app.media.ic_release');
      case 'Discussion':
        return $r('app.media.ic_comment');
      default:
        return $r('app.media.ic_bell');
    }
  }

  getTypeColor(type: string): string {
    switch (type) {
      case 'Issue':
        return '#1A7F37';
      case 'PullRequest':
        return '#8250DF';
      case 'Release':
        return '#0969DA';
      case 'Discussion':
        return '#BF8700';
      default:
        return ICON_COLOR;
    }
  }

  formatTime(isoString: string): string {
    try {
      const date = new Date(isoString);
      const now = new Date();
      const diff = now.getTime() - date.getTime();
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const days = Math.floor(hours / 24);

      if (hours < 1) {
        return '刚刚';
      } else if (hours < 24) {
        return hours + ' 小时前';
      } else if (days < 7) {
        return days + ' 天前';
      } else {
        return (date.getMonth() + 1) + '月' + date.getDate() + '日';
      }
    } catch (e) {
      return '';
    }
  }
}
