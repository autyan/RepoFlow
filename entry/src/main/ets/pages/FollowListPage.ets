/**
 * 关注者/正在关注列表页面
 * 
 * 功能:
 * - 显示用户的关注者或正在关注的用户
 * - 支持分页加载
 * - 支持响应式布局和主题切换
 */

import { authManager } from '../services/AuthManager';
import { GitHubUser } from '../models/GitHubModels';
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
  RFAvatar,
  RFSplitView,
} from '../components';
import { UIHelper } from '../common/ui';

interface RouteParams {
  username: string;
  type: 'followers' | 'following';
}

// =====================================================
// 关注列表页面
// =====================================================
@Entry
@Component
struct FollowListPage {
  // 数据状态
  @State users: GitHubUser[] = [];
  @State isLoading: boolean = true;
  @State error: string = '';
  @State hasMore: boolean = true;
  @State selectedUser: GitHubUser | null = null;

  private username: string = '';
  private type: 'followers' | 'following' = 'followers';
  private page: number = 1;

  private t(res: Resource, ...args: Array<string | number>): string {
    try {
      const rm = this.getUIContext()!.getHostContext()!.resourceManager!;
      return rm.getStringSync(res.id, ...args);
    } catch (error) {
      console.error('Resource loading failed:', error);
      return '';
    }
  }

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

    const params = this.getUIContext()!.getRouter()!.getParams() as RouteParams | undefined;
    if (params) {
      this.username = params.username;
      this.type = params.type;
      this.loadUsers();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadUsers(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = this.t($r('app.string.please_login'));
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
      this.error = this.t($r('app.string.load_failed'));
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

  handleUserClick(user: GitHubUser): void {
    if (this.layoutMode !== LayoutMode.SINGLE) {
      this.selectedUser = user;
    } else {
      UIHelper.pushUrl(this, 'pages/UserProfilePage', { username: user.login });
    }
  }

  getTitle(): ResourceStr {
    return this.type === 'followers' ? $r('app.string.followers') : $r('app.string.following');
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
        UIHelper.goBack(this);
      })

      Text(this.getTitle())
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row().width(40).height(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 用户卡片
  @Builder
  UserCard(user: GitHubUser) {
    Row({ space: Spacing.MD }) {
      RFAvatar({
        src: user.avatar_url,
        alt: user.login,
        avatarSize: 'md',
        colors: this.colors
      })

      Column({ space: 4 }) {
        Text(user.name || user.login)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`@${user.login}`)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)

        if (user.bio) {
          Text(user.bio)
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .fillColor(this.colors.textSecondary)
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.selectedUser?.id === user.id ? this.colors.bgTertiary : this.colors.surface)
    .borderRadius(BorderRadius.MD)
    .border({
      width: this.selectedUser?.id === user.id ? 1 : 0,
      color: this.colors.brandPrimary
    })
    .onClick((): void => {
      this.handleUserClick(user);
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

  // 错误状态
  @Builder
  ErrorView() {
    Column({ space: Spacing.SM }) {
      Image($r('app.media.ic_error'))
        .width(48)
        .height(48)
        .fillColor(this.colors.textSecondary)
      Text(this.error)
        .fontSize(FontSize.LG)
        .fontColor(this.colors.textSecondary)
      RFButton({
        text: $r('app.string.retry'),
        variant: 'secondary',
        buttonSize: 'md',
        colors: this.colors,
        onTap: (): void => {
          this.isLoading = true;
          this.error = '';
          this.loadUsers();
        }
      })
        .margin({ top: Spacing.MD })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 空状态
  @Builder
  EmptyView() {
    Column({ space: Spacing.SM }) {
      Image($r('app.media.ic_user'))
        .width(48)
        .height(48)
        .fillColor(this.colors.textSecondary)
      Text(this.type === 'followers' ? $r('app.string.no_followers') : $r('app.string.no_following'))
        .fontSize(FontSize.LG)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 用户列表
  @Builder
  UserList() {
    List({ space: Spacing.SM }) {
      ForEach(this.users, (user: GitHubUser) => {
        ListItem() {
          this.UserCard(user)
        }
      }, (user: GitHubUser) => user.id.toString())

      if (this.hasMore) {
        ListItem() {
          Row() {
            if (this.isLoading) {
              LoadingProgress().width(20).height(20)
              Text($r('app.string.loading'))
                .fontSize(FontSize.MD)
                .fontColor(this.colors.textSecondary)
                .margin({ left: Spacing.SM })
            } else {
              Text($r('app.string.load_more'))
                .fontSize(FontSize.MD)
                .fontColor(this.colors.brandPrimary)
            }
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.Center)
          .onClick((): void => {
            this.loadMore();
          })
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  // 列表内容
  @Builder
  ListContent() {
    Column() {
      if (this.error) {
        this.ErrorView()
      } else if (this.isLoading && this.users.length === 0) {
        this.LoadingView()
      } else if (this.users.length === 0) {
        this.EmptyView()
      } else {
        Column() {
          this.UserList()
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.MD })
      }
    }
    .width('100%')
    .height('100%')
  }

  // 详情面板
  @Builder
  DetailPanel() {
    if (this.selectedUser) {
      Column({ space: Spacing.LG }) {
        // 头像
        Column({ space: Spacing.MD }) {
          RFAvatar({
            src: this.selectedUser.avatar_url,
            alt: this.selectedUser.login,
            avatarSize: 'xxl',
            colors: this.colors
          })

          Text(this.selectedUser.name || this.selectedUser.login)
            .fontSize(FontSize.XXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)

          Text(`@${this.selectedUser.login}`)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }
        .alignItems(HorizontalAlign.Center)

        // Bio
        if (this.selectedUser.bio) {
          Text(this.selectedUser.bio)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
            .textAlign(TextAlign.Center)
        }

        // 查看详情按钮
        RFButton({
          text: $r('app.string.view_profile'),
          variant: 'primary',
          buttonSize: 'lg',
          fullWidth: true,
          colors: this.colors,
          onTap: (): void => {
            UIHelper.pushUrl(this, 'pages/UserProfilePage', { username: this.selectedUser!.login });
          }
        })
      }
      .width('100%')
      .height('100%')
      .padding(Spacing.LG)
      .backgroundColor(this.colors.bgPrimary)
    } else {
      Column({ space: Spacing.SM }) {
        Image($r('app.media.ic_user'))
          .width(64)
          .height(64)
          .fillColor(this.colors.textTertiary)
          .opacity(0.5)
        Text($r('app.string.select_user_to_view'))
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
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}
