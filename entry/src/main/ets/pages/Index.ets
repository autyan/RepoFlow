import HomePage from './HomePage';
import ReposPage from './ReposPage';
import NotificationsPage from './NotificationsPage';
import ProfilePage from './ProfilePage';
import { tabState } from '../common/state/TabState';
import { userState } from '../common/state/UserState';
import { ThemeManager, ThemeColors, ResponsiveManager, ResponsiveState } from '../theme';
import { AnimationDuration, NavigationMode, DeviceType } from '../theme/DesignTokens';
import { RFAdaptiveNavigation, NavItem } from '../components/layout';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State private colors: ThemeColors = ThemeManager.colors;
  @State private navigationMode: NavigationMode = ResponsiveManager.navigationMode;
  @State private isFoldableExpanded: boolean = ResponsiveManager.isFoldableExpanded;
  @State private deviceType: DeviceType = ResponsiveManager.deviceType;
  @State private userAvatar: string = '';

  // 导航项配置
  private navItems: NavItem[] = [
    { key: 'home', label: $r('app.string.tab_home'), icon: $r('app.media.ic_home') },
    { key: 'repos', label: $r('app.string.tab_repos'), icon: $r('app.media.ic_repo') },
    { key: 'notifications', label: $r('app.string.tab_notifications'), icon: $r('app.media.ic_bell'), badge: 0 },
    { key: 'profile', label: $r('app.string.tab_profile'), icon: $r('app.media.ic_profile') }
  ];

  aboutToAppear(): void {
    // 监听全局 Tab 切换事件
    tabState.addListener((index: number) => {
      this.currentIndex = index;
    });

    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean) => {
      this.colors = colors;
    });

    // 订阅响应式状态变化
    ResponsiveManager.subscribe((state: ResponsiveState) => {
      this.navigationMode = state.navigationMode;
      this.isFoldableExpanded = state.isFoldableExpanded;
      this.deviceType = state.deviceType;
    });

    // 订阅用户状态
    userState.addListener(() => {
      if (userState.user) {
        this.userAvatar = userState.user.avatar_url;
      }
    });
    
    // 初始化时同步当前用户状态
    if (userState.user) {
      this.userAvatar = userState.user.avatar_url;
    }
  }

  @Builder
  pageContent() {
    if (this.currentIndex === 0) {
      HomePage()
    } else if (this.currentIndex === 1) {
      ReposPage()
    } else if (this.currentIndex === 2) {
      NotificationsPage()
    } else {
      ProfilePage()
    }
  }

  build() {
    Column() {
      RFAdaptiveNavigation({
        items: this.navItems,
        currentIndex: this.currentIndex,
        navigationMode: this.navigationMode,
        colors: this.colors,
        avatar: this.userAvatar ? this.userAvatar : null,
        appName: 'RepoFlow',
        userName: userState.user?.login ?? '',
        onChange: (index: number, key: string) => {
          this.currentIndex = index;
          tabState.currentIndex = index;
        },
        content: () => {
          this.pageContent();
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}