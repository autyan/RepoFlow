import HomePage from './HomePage';
import ReposPage from './ReposPage';
import NotificationsPage from './NotificationsPage';
import ProfilePage from './ProfilePage';
import { tabState } from '../common/state/TabState';

// 品牌色
const ACCENT_COLOR = '#F28C28'; // 橙黄色主题
const TEXT_SECONDARY = '#656D76';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State private slideOffset: number = 0;
  private tabController: TabsController = new TabsController();

  aboutToAppear(): void {
    // 监听全局 Tab 切换事件
    tabState.addListener((index: number) => {
      this.switchTab(index);
    });
  }

  switchTab(index: number): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.currentIndex = index;
      this.tabController.changeIndex(index);
    });
  }

  @Builder
  TabBarItem(title: Resource, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? ACCENT_COLOR : TEXT_SECONDARY)
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })
      Text(title)
        .fontSize(11)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? ACCENT_COLOR : TEXT_SECONDARY)
        .margin({ top: 4 })
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.switchTab(index);
    })
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabController }) {
        TabContent() {
          HomePage()
        }
        .tabBar(this.TabBarItem($r('app.string.tab_home'), $r('app.media.ic_home'), 0))

        TabContent() {
          ReposPage()
        }
        .tabBar(this.TabBarItem($r('app.string.tab_repos'), $r('app.media.ic_repo'), 1))

        TabContent() {
          NotificationsPage()
        }
        .tabBar(this.TabBarItem($r('app.string.tab_notifications'), $r('app.media.ic_bell'), 2))

        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBarItem($r('app.string.tab_profile'), $r('app.media.ic_profile'), 3))
      }
      .onChange((index: number) => {
        this.currentIndex = index;
        tabState.currentIndex = index;
      })
      .scrollable(true)
      .animationDuration(300)
      .barBackgroundColor('#FFFFFF')
      .barMode(BarMode.Fixed)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}