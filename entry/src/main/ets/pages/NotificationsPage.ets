/**
 * 通知页面
 * 
 * 功能:
 * - 显示 GitHub 通知列表
 * - 标记已读
 * - 支持响应式布局和主题切换
 */

import router from '@ohos.router';
import { userState } from '../common/state/UserState';
import { authManager } from '../services/AuthManager';
import { GitHubNotification } from '../models/GitHubModels';
import { LoginPrompt } from '../components/LoginPrompt';
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
} from '../theme';
import {
  RFCard,
  RFButton,
  RFSplitView,
} from '../components';

// =====================================================
// 通知页面
// =====================================================
@Component
export default struct NotificationsPage {
  // 数据状态
  @State isLoggedIn: boolean = false;
  @State notifications: GitHubNotification[] = [];
  @State isLoading: boolean = false;
  @State showLoginPrompt: boolean = true;
  @State selectedNotification: GitHubNotification | null = null;

  // 主题状态
  @State colors: ThemeColors = ThemeManager.colors;
  @State isDark: boolean = ThemeManager.isDark;

  // 响应式状态
  @State layoutMode: LayoutMode = ResponsiveManager.state.layoutMode;
  @State deviceType: DeviceType = ResponsiveManager.state.deviceType;

  private t(res: Resource, ...args: Array<string | number>): string {
    const rm = getContext(this).resourceManager;
    return rm.getStringSync(res.id, ...args);
  }

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

  syncState(): void {
    this.isLoggedIn = userState.isLoggedIn;
    if (this.isLoggedIn && this.notifications.length === 0) {
      this.loadNotifications();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadNotifications(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoading = true;
    try {
      // 获取所有通知（包括已读的），而不仅是未读的
      this.notifications = await api.getNotifications(true, 1, 50);
      console.info('Loaded notifications:', this.notifications.length);
    } catch (error) {
      console.error('Failed to load notifications:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  async markAsRead(threadId: string): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    try {
      await api.markNotificationAsRead(threadId);
      const index = this.notifications.findIndex((n: GitHubNotification): boolean => n.id === threadId);
      if (index >= 0) {
        this.notifications[index].unread = false;
        this.notifications = [...this.notifications];
      }
    } catch (error) {
      console.error('Mark as read failed:', JSON.stringify(error));
    }
  }

  handleNotificationClick(notification: GitHubNotification): void {
    if (this.layoutMode !== LayoutMode.SINGLE) {
      this.selectedNotification = notification;
    } else {
      router.pushUrl({
        url: 'pages/RepoDetailPage',
        params: {
          owner: notification.repository.owner.login,
          repo: notification.repository.name
        }
      });
    }
    if (notification.unread) {
      this.markAsRead(notification.id);
    }
  }

  // =====================================================
  // 工具方法
  // =====================================================

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
        return this.colors.success;
      case 'PullRequest':
        return this.colors.syntaxKeyword;
      case 'Release':
        return this.colors.brandPrimary;
      case 'Discussion':
        return this.colors.warning;
      default:
        return this.colors.textTertiary;
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
        return this.t($r('app.string.notifications_just_now'));
      } else if (hours < 24) {
        return this.t($r('app.string.hours_ago'), hours);
      } else if (days < 7) {
        return this.t($r('app.string.days_ago'), days);
      } else {
        const month = date.getMonth() + 1;
        const day = date.getDate();
        return this.t($r('app.string.date_md'), month, day);
      }
    } catch (e) {
      return '';
    }
  }

  // =====================================================
  // UI 构建器
  // =====================================================

  // 页面头部
  @Builder
  PageHeader() {
    Row() {
      Text($r('app.string.notif_title'))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)
      Blank()
      Text($r('app.string.refresh'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.brandPrimary)
        .onClick((): void => {
          this.loadNotifications();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.LG, right: Spacing.LG })
  }

  // 通知卡片
  @Builder
  NotificationCard(notification: GitHubNotification) {
    Column({ space: Spacing.XS }) {
      Row() {
        Image(this.getTypeIcon(notification.subject.type))
          .width(18)
          .height(18)
          .fillColor(this.getTypeColor(notification.subject.type))

        Text(notification.repository.full_name)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .margin({ left: Spacing.XS })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (notification.unread) {
          Circle({ width: 8, height: 8 })
            .fill(this.colors.brandPrimary)
        }
      }
      .width('100%')

      Text(notification.subject.title)
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.formatTime(notification.updated_at))
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textTertiary)
        .margin({ top: Spacing.XXS })
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(notification.unread
      ? this.colors.primaryContainer
      : (this.selectedNotification?.id === notification.id ? this.colors.bgTertiary : this.colors.surface))
    .borderRadius(BorderRadius.MD)
    .border({
      width: this.selectedNotification?.id === notification.id ? 1 : 0,
      color: this.colors.brandPrimary
    })
    .onClick((): void => {
      this.handleNotificationClick(notification);
    })
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

  // 空状态
  @Builder
  EmptyView() {
    Column({ space: Spacing.SM }) {
      Image($r('app.media.ic_check_circle'))
        .width(48)
        .height(48)
        .fillColor(this.colors.success)
      Text($r('app.string.no_notifications'))
        .fontSize(FontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
      RFButton({
        text: $r('app.string.refresh'),
        variant: 'secondary',
        buttonSize: 'md',
        colors: this.colors,
        onTap: (): void => {
          this.loadNotifications();
        }
      })
        .margin({ top: Spacing.MD })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 通知列表
  @Builder
  NotificationList() {
    List({ space: Spacing.SM }) {
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

  // 列表内容
  @Builder
  ListContent() {
    Column() {
      if (this.isLoading) {
        this.LoadingView()
      } else if (this.notifications.length === 0) {
        this.EmptyView()
      } else {
        this.NotificationList()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: Spacing.MD, right: Spacing.MD, bottom: Spacing.MD })
  }

  // 详情面板
  @Builder
  DetailPanel() {
    if (this.selectedNotification) {
      Column({ space: Spacing.LG }) {
        // 通知类型图标
        Row({ space: Spacing.SM }) {
          Image(this.getTypeIcon(this.selectedNotification.subject.type))
            .width(24)
            .height(24)
            .fillColor(this.getTypeColor(this.selectedNotification.subject.type))
          Text(this.selectedNotification.subject.type)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }

        // 标题
        Text(this.selectedNotification.subject.title)
          .fontSize(FontSize.XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)

        // 仓库信息
        Row({ space: Spacing.SM }) {
          Image($r('app.media.ic_repo'))
            .width(16)
            .height(16)
            .fillColor(this.colors.textSecondary)
          Text(this.selectedNotification.repository.full_name)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.brandPrimary)
        }

        // 时间
        Text(this.formatTime(this.selectedNotification.updated_at))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textTertiary)

        // 查看按钮 - 紧跟内容
        RFButton({
          text: $r('app.string.view_details'),
          variant: 'primary',
          buttonSize: 'lg',
          fullWidth: true,
          colors: this.colors,
          onTap: (): void => {
            router.pushUrl({
              url: 'pages/RepoDetailPage',
              params: {
                owner: this.selectedNotification!.repository.owner.login,
                repo: this.selectedNotification!.repository.name
              }
            });
          }
        })
      }
      .width('100%')
      .padding(Spacing.LG)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(this.colors.bgPrimary)
    } else {
      Column({ space: Spacing.SM }) {
        Image($r('app.media.ic_bell'))
          .width(64)
          .height(64)
          .fillColor(this.colors.textTertiary)
          .opacity(0.5)
        Text($r('app.string.select_notification'))
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textSecondary)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }

  // 未登录视图
  @Builder
  NotLoggedInView() {
    Column({ space: Spacing.MD }) {
      Image($r('app.media.ic_bell'))
        .width(48)
        .height(48)
        .fillColor(this.colors.textSecondary)
      Text($r('app.string.notif_title'))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)
      Text($r('app.string.notif_login_hint'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Column() {
      if (!this.isLoggedIn && this.showLoginPrompt) {
        // 未登录提示
        LoginPrompt({
          title: $r('app.string.view_notifications'),
          subtitle: $r('app.string.login_to_view_notifications'),
          onDismiss: (): void => {
            this.showLoginPrompt = false;
          }
        })
      } else if (!this.isLoggedIn) {
        this.NotLoggedInView()
      } else {
        // 页面头部
        this.PageHeader()

        // 内容区域
        if (this.layoutMode === LayoutMode.SINGLE) {
          this.ListContent()
        } else {
          RFSplitView({
            layoutMode: this.layoutMode,
            primaryWidth: this.layoutMode === LayoutMode.TRIPLE ? 360 : 400,
            colors: this.colors,
            showDivider: true,
            primaryContent: (): void => this.ListContent(),
            detailContent: (): void => this.DetailPanel()
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}
