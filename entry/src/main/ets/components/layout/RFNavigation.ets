/**
 * RepoFlow 自适应导航组件
 * 
 * 根据设备类型和屏幕宽度自动切换:
 * - 手机: 底部标签栏导航
 * - 折叠屏展开/平板: 侧边图标导航
 * - 桌面: 侧边展开导航
 * 
 * 支持:
 * - 主题适配
 * - 徽标显示
 * - 动画切换
 */

import router from '@ohos.router';
import { ThemeColors, DarkColors } from '../../theme/Colors';
import {
  Spacing,
  BorderRadius,
  FontSize,
  AnimationDuration,
  NavHeight,
  NavigationMode
} from '../../theme/DesignTokens';
import { RFBadge } from '../ui/RFBadge';

// =====================================================
// 类型定义
// =====================================================

export interface NavItem {
  /** 唯一标识 */
  key: string;
  /** 标签文本 */
  label: string | Resource;
  /** 图标资源 */
  icon: ResourceStr;
  /** 选中状态图标 */
  activeIcon?: ResourceStr;
  /** 徽标数量 */
  badge?: number;
  /** 显示小红点 */
  showDot?: boolean;
}

// =====================================================
// 底部标签栏导航
// =====================================================

@Component
export struct RFBottomTabBar {
  /** 导航项列表 */
  @Prop items: NavItem[] = [];
  /** 当前选中项 */
  @Prop currentIndex: number = 0;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 切换回调 */
  onChange?: (index: number, key: string) => void;
  
  build() {
    Row() {
      ForEach(this.items, (item: NavItem, index: number) => {
        Column({ space: Spacing.XXS }) {
          Stack({ alignContent: Alignment.TopEnd }) {
            Image(index === this.currentIndex && item.activeIcon ? item.activeIcon : item.icon)
              .width(24)
              .height(24)
              .fillColor(index === this.currentIndex ? this.colors.brandPrimary : this.colors.textTertiary)
            
            // 徽标
            if (item.badge && item.badge > 0) {
              RFBadge({
                type: 'count',
                value: item.badge,
                badgeSize: 'sm',
                colors: this.colors
              })
                .offset({ x: 8, y: -4 })
            } else if (item.showDot) {
              RFBadge({
                type: 'dot',
                badgeSize: 'sm',
                colors: this.colors
              })
                .offset({ x: 4, y: -2 })
            }
          }
          
          Text(item.label)
            .fontSize(10)
            .fontWeight(index === this.currentIndex ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(index === this.currentIndex ? this.colors.brandPrimary : this.colors.textTertiary)
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.onChange) {
            this.onChange(index, item.key);
          }
        })
      })
    }
    .width('100%')
    .height(NavHeight.BOTTOM)
    .backgroundColor(this.colors.bgSecondary)
    .border({
      width: { top: 1 },
      color: this.colors.border
    })
    .padding({ bottom: 0 })
  }
}

// =====================================================
// 侧边导航栏 (图标模式)
// =====================================================

@Component
export struct RFSideNavIcon {
  /** 导航项列表 */
  @Prop items: NavItem[] = [];
  /** 当前选中项 */
  @Prop currentIndex: number = 0;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 头像/Logo */
  @Prop avatar: ResourceStr | null = null;
  /** 切换回调 */
  onChange?: (index: number, key: string) => void;
  /** 头像点击回调 */
  onAvatarClick?: () => void;
  
  build() {
    Column({ space: Spacing.XS }) {
      // Logo/头像
      if (this.avatar) {
        Image(this.avatar)
          .width(40)
          .height(40)
          .borderRadius(BorderRadius.FULL)
          .margin({ bottom: Spacing.MD })
          .onClick(() => {
            if (this.onAvatarClick) {
              this.onAvatarClick();
            }
          })
      } else {
        // 默认 Logo
        Text('R')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.brandPrimary)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.primaryContainer)
          .borderRadius(BorderRadius.MD)
          .margin({ bottom: Spacing.MD })
      }
      
      // 导航项
      ForEach(this.items, (item: NavItem, index: number) => {
        Stack({ alignContent: Alignment.TopEnd }) {
          Column() {
            Image(index === this.currentIndex && item.activeIcon ? item.activeIcon : item.icon)
              .width(24)
              .height(24)
              .fillColor(index === this.currentIndex ? this.colors.brandPrimary : this.colors.textSecondary)
          }
          .width(48)
          .height(48)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(index === this.currentIndex ? this.colors.primaryContainer : 'transparent')
          .borderRadius(BorderRadius.MD)
          
          // 徽标
          if (item.badge && item.badge > 0) {
            RFBadge({
              type: 'count',
              value: item.badge,
              badgeSize: 'sm',
              colors: this.colors
            })
              .offset({ x: 4, y: 0 })
          } else if (item.showDot) {
            RFBadge({
              type: 'dot',
              badgeSize: 'sm',
              colors: this.colors
            })
              .offset({ x: 2, y: 2 })
          }
        }
        .onClick(() => {
          if (this.onChange) {
            this.onChange(index, item.key);
          }
        })
      })
      
      Blank()
      
      // 设置图标
      Image($r('app.media.ic_settings'))
        .width(24)
        .height(24)
        .fillColor(this.colors.textTertiary)
        .margin({ bottom: Spacing.MD })
        .onClick(() => {
          router.pushUrl({ url: 'pages/SettingsPage' });
        })
    }
    .width(NavHeight.SIDE_ICON)
    .height('100%')
    .padding({ top: Spacing.MD, bottom: Spacing.MD })
    .backgroundColor(this.colors.bgSecondary)
    .border({
      width: { right: 1 },
      color: this.colors.border
    })
    .alignItems(HorizontalAlign.Center)
  }
}

// =====================================================
// 侧边导航栏 (展开模式)
// =====================================================

@Component
export struct RFSideNavExpanded {
  /** 导航项列表 */
  @Prop items: NavItem[] = [];
  /** 当前选中项 */
  @Prop currentIndex: number = 0;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 头像/Logo */
  @Prop avatar: ResourceStr | null = null;
  /** 应用名称 */
  @Prop appName: string = 'RepoFlow';
  /** 用户名称 */
  @Prop userName: string = '';
  /** 切换回调 */
  onChange?: (index: number, key: string) => void;
  /** 头像点击回调 */
  onAvatarClick?: () => void;
  
  build() {
    Column({ space: Spacing.XS }) {
      // 头部
      Row({ space: Spacing.SM }) {
        if (this.avatar) {
          Image(this.avatar)
            .width(36)
            .height(36)
            .borderRadius(BorderRadius.FULL)
        } else {
          Text('R')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.brandPrimary)
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.colors.primaryContainer)
            .borderRadius(BorderRadius.MD)
        }
        
        Column({ space: 2 }) {
          Text(this.appName)
            .fontSize(FontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textPrimary)
          
          if (this.userName) {
            Text(this.userName)
              .fontSize(FontSize.XS)
              .fontColor(this.colors.textSecondary)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: Spacing.MD, right: Spacing.MD, bottom: Spacing.MD })
      .onClick(() => {
        if (this.onAvatarClick) {
          this.onAvatarClick();
        }
      })
      
      Divider()
        .strokeWidth(1)
        .color(this.colors.border)
        .margin({ bottom: Spacing.SM })
      
      // 导航项
      ForEach(this.items, (item: NavItem, index: number) => {
        Row({ space: Spacing.SM }) {
          Image(index === this.currentIndex && item.activeIcon ? item.activeIcon : item.icon)
            .width(20)
            .height(20)
            .fillColor(index === this.currentIndex ? this.colors.brandPrimary : this.colors.textSecondary)
          
          Text(item.label)
            .fontSize(FontSize.MD)
            .fontWeight(index === this.currentIndex ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(index === this.currentIndex ? this.colors.brandPrimary : this.colors.textPrimary)
            .layoutWeight(1)
          
          // 徽标
          if (item.badge && item.badge > 0) {
            RFBadge({
              type: 'count',
              value: item.badge,
              badgeSize: 'sm',
              colors: this.colors
            })
          } else if (item.showDot) {
            RFBadge({
              type: 'dot',
              badgeSize: 'sm',
              colors: this.colors
            })
          }
        }
        .width('100%')
        .height(44)
        .padding({ left: Spacing.MD, right: Spacing.MD })
        .backgroundColor(index === this.currentIndex ? this.colors.primaryContainer : 'transparent')
        .borderRadius(BorderRadius.MD)
        .margin({ left: Spacing.SM, right: Spacing.SM })
        .onClick(() => {
          if (this.onChange) {
            this.onChange(index, item.key);
          }
        })
      })
      
      Blank()
      
      // 底部设置
      Row({ space: Spacing.SM }) {
        Image($r('app.media.ic_settings'))
          .width(20)
          .height(20)
          .fillColor(this.colors.textSecondary)
        
        Text($r('app.string.settings'))
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textSecondary)
      }
      .width('100%')
      .height(44)
      .padding({ left: Spacing.MD, right: Spacing.MD })
      .margin({ left: Spacing.SM, right: Spacing.SM, bottom: Spacing.MD })
      .borderRadius(BorderRadius.MD)
      .onClick(() => {
        router.pushUrl({ url: 'pages/SettingsPage' });
      })
    }
    .width(NavHeight.SIDE_EXPANDED)
    .height('100%')
    .padding({ top: Spacing.MD })
    .backgroundColor(this.colors.bgSecondary)
    .border({
      width: { right: 1 },
      color: this.colors.border
    })
  }
}

// =====================================================
// 自适应导航组件
// =====================================================

@Component
export struct RFAdaptiveNavigation {
  /** 导航项列表 */
  @Prop items: NavItem[] = [];
  /** 当前选中项 */
  @Link currentIndex: number;
  /** 导航模式 */
  @Prop navigationMode: NavigationMode = NavigationMode.BOTTOM;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 头像/Logo */
  @Prop avatar: ResourceStr | null = null;
  /** 应用名称 */
  @Prop appName: string = 'RepoFlow';
  /** 用户名称 */
  @Prop userName: string = '';
  /** 切换回调 */
  onChange?: (index: number, key: string) => void;
  /** 头像点击回调 */
  onAvatarClick?: () => void;
  /** 页面内容 */
  @BuilderParam content: () => void;
  
  private handleChange(index: number, key: string): void {
    this.currentIndex = index;
    if (this.onChange) {
      this.onChange(index, key);
    }
  }
  
  build() {
    if (this.navigationMode === NavigationMode.BOTTOM) {
      // 底部导航布局
      Column() {
        // 内容区域
        Column() {
          if (this.content) {
            this.content();
          }
        }
        .layoutWeight(1)
        .width('100%')
        
        // 底部导航
        RFBottomTabBar({
          items: this.items,
          currentIndex: this.currentIndex,
          colors: this.colors,
          onChange: (index: number, key: string): void => this.handleChange(index, key)
        })
      }
      .width('100%')
      .height('100%')
    } else if (this.navigationMode === NavigationMode.SIDE_ICON) {
      // 侧边图标导航布局
      Row() {
        RFSideNavIcon({
          items: this.items,
          currentIndex: this.currentIndex,
          colors: this.colors,
          avatar: this.avatar,
          onChange: (index: number, key: string): void => this.handleChange(index, key),
          onAvatarClick: this.onAvatarClick
        })
        
        // 内容区域
        Column() {
          if (this.content) {
            this.content();
          }
        }
        .layoutWeight(1)
        .height('100%')
      }
      .width('100%')
      .height('100%')
    } else {
      // 侧边展开导航布局
      Row() {
        RFSideNavExpanded({
          items: this.items,
          currentIndex: this.currentIndex,
          colors: this.colors,
          avatar: this.avatar,
          appName: this.appName,
          userName: this.userName,
          onChange: (index: number, key: string): void => this.handleChange(index, key),
          onAvatarClick: this.onAvatarClick
        })
        
        // 内容区域
        Column() {
          if (this.content) {
            this.content();
          }
        }
        .layoutWeight(1)
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
  }
}
