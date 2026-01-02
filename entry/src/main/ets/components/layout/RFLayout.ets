/**
 * RepoFlow 响应式布局组件
 * 
 * 提供多种响应式布局容器:
 * - RFResponsiveContainer: 根据设备自适应的容器
 * - RFSplitView: 分栏视图 (主从布局)
 * - RFMasterDetail: 主详情视图
 * - RFGrid: 响应式网格
 */

import { ThemeColors, DarkColors } from '../../theme/Colors';
import {
  Spacing,
  BorderRadius,
  DeviceType,
  LayoutMode,
  Breakpoint
} from '../../theme/DesignTokens';

// =====================================================
// 响应式容器
// =====================================================

@Component
export struct RFResponsiveContainer {
  /** 设备类型 */
  @Prop deviceType: DeviceType = DeviceType.PHONE;
  /** 布局模式 */
  @Prop layoutMode: LayoutMode = LayoutMode.SINGLE;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 最大内容宽度 */
  @Prop maxWidth: number | string = '100%';
  /** 是否居中 */
  @Prop centered: boolean = true;
  /** 内边距 (避免与系统 padding 方法冲突) */
  @Prop contentPadding: number = Spacing.MD;
  /** 内容 */
  @BuilderParam content: () => void;
  
  private getMaxWidth(): string | number {
    if (typeof this.maxWidth === 'number') {
      return this.maxWidth;
    }
    
    // 根据设备类型自动计算最大宽度
    switch (this.deviceType) {
      case DeviceType.DESKTOP:
        return 1200;
      case DeviceType.TABLET:
        return 900;
      case DeviceType.FOLDABLE:
        return 800;
      default:
        return '100%';
    }
  }
  
  build() {
    Column() {
      Column() {
        if (this.content) {
          this.content();
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: this.getMaxWidth() })
      .padding(this.contentPadding)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
    .alignItems(this.centered ? HorizontalAlign.Center : HorizontalAlign.Start)
  }
}

// =====================================================
// 分栏视图 (主从布局)
// =====================================================

@Component
export struct RFSplitView {
  /** 布局模式 */
  @Prop layoutMode: LayoutMode = LayoutMode.SINGLE;
  /** 主栏宽度 (仅双栏模式有效) */
  @Prop primaryWidth: number = 320;
  /** 第二栏宽度 (仅三栏模式有效) */
  @Prop secondaryWidth: number = 280;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 显示分割线 */
  @Prop showDivider: boolean = true;
  /** 主栏内容 */
  @BuilderParam primaryContent: () => void;
  /** 详情栏内容 */
  @BuilderParam detailContent?: () => void;
  /** 第三栏内容 (仅三栏模式) */
  @BuilderParam tertiaryContent?: () => void;
  
  build() {
    if (this.layoutMode === LayoutMode.SINGLE) {
      // 单栏模式
      Column() {
        if (this.primaryContent) {
          this.primaryContent();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.colors.bgPrimary)
    } else if (this.layoutMode === LayoutMode.DOUBLE) {
      // 双栏模式
      Row() {
        // 主栏
        Column() {
          if (this.primaryContent) {
            this.primaryContent();
          }
        }
        .width(this.primaryWidth)
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
        
        // 分割线
        if (this.showDivider) {
          Divider()
            .vertical(true)
            .strokeWidth(1)
            .color(this.colors.border)
            .height('100%')
        }
        
        // 详情栏
        Column() {
          if (this.detailContent) {
            this.detailContent();
          }
        }
        .layoutWeight(1)
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
      }
      .width('100%')
      .height('100%')
    } else {
      // 三栏模式
      Row() {
        // 主栏
        Column() {
          if (this.primaryContent) {
            this.primaryContent();
          }
        }
        .width(this.primaryWidth)
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
        
        // 分割线
        if (this.showDivider) {
          Divider()
            .vertical(true)
            .strokeWidth(1)
            .color(this.colors.border)
            .height('100%')
        }
        
        // 第二栏
        Column() {
          if (this.detailContent) {
            this.detailContent();
          }
        }
        .width(this.secondaryWidth)
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
        
        // 分割线
        if (this.showDivider) {
          Divider()
            .vertical(true)
            .strokeWidth(1)
            .color(this.colors.border)
            .height('100%')
        }
        
        // 第三栏
        Column() {
          if (this.tertiaryContent) {
            this.tertiaryContent();
          }
        }
        .layoutWeight(1)
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
      }
      .width('100%')
      .height('100%')
    }
  }
}

// =====================================================
// 主详情视图 (带动画切换)
// =====================================================

@Component
export struct RFMasterDetail {
  /** 布局模式 */
  @Prop layoutMode: LayoutMode = LayoutMode.SINGLE;
  /** 主栏宽度 */
  @Prop masterWidth: number = 360;
  /** 是否显示详情 (单栏模式下用于控制显示哪个) */
  @Link showDetail: boolean;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 主视图内容 */
  @BuilderParam masterContent: () => void;
  /** 详情视图内容 */
  @BuilderParam detailContent: () => void;
  /** 空状态内容 */
  @BuilderParam emptyContent?: () => void;
  
  build() {
    if (this.layoutMode === LayoutMode.SINGLE) {
      // 单栏模式 - 使用导航切换
      Stack() {
        // 主视图
        Column() {
          if (this.masterContent) {
            this.masterContent();
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
        .visibility(this.showDetail ? Visibility.Hidden : Visibility.Visible)
        .translate({ x: this.showDetail ? '-100%' : '0%' })
        .animation({
          duration: 250,
          curve: Curve.EaseInOut
        })
        
        // 详情视图
        Column() {
          if (this.detailContent) {
            this.detailContent();
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
        .visibility(this.showDetail ? Visibility.Visible : Visibility.Hidden)
        .translate({ x: this.showDetail ? '0%' : '100%' })
        .animation({
          duration: 250,
          curve: Curve.EaseInOut
        })
      }
      .width('100%')
      .height('100%')
      .clip(true)
    } else {
      // 多栏模式 - 并排显示
      Row() {
        // 主视图
        Column() {
          if (this.masterContent) {
            this.masterContent();
          }
        }
        .width(this.masterWidth)
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
        .border({
          width: { right: 1 },
          color: this.colors.border
        })
        
        // 详情视图
        Column() {
          if (this.showDetail && this.detailContent) {
            this.detailContent();
          } else if (this.emptyContent) {
            this.emptyContent();
          } else {
            // 默认空状态
            Column({ space: Spacing.MD }) {
              Image($r('app.media.ic_folder'))
                .width(64)
                .height(64)
                .fillColor(this.colors.textTertiary)
                .opacity(0.5)
              
              Text($r('app.string.select_item_to_view'))
                .fontSize(14)
                .fontColor(this.colors.textTertiary)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .width('100%')
            .height('100%')
          }
        }
        .layoutWeight(1)
        .height('100%')
        .backgroundColor(this.colors.bgPrimary)
      }
      .width('100%')
      .height('100%')
    }
  }
}

// =====================================================
// 响应式网格
// =====================================================

@Component
export struct RFGrid {
  /** 列数 */
  @Prop columns: number = 1;
  /** 间距 */
  @Prop gap: number = Spacing.MD;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 内容项 */
  @BuilderParam items: () => void;
  
  private getColumnsTemplate(): string {
    return Array(this.columns).fill('1fr').join(' ');
  }
  
  build() {
    Grid() {
      if (this.items) {
        this.items();
      }
    }
    .width('100%')
    .columnsTemplate(this.getColumnsTemplate())
    .columnsGap(this.gap)
    .rowsGap(this.gap)
  }
}

// =====================================================
// 页面头部
// =====================================================

@Component
export struct RFPageHeader {
  /** 标题 */
  @Prop title: string = '';
  /** 副标题 */
  @Prop subtitle: ResourceStr = '';
  /** 显示返回按钮 */
  @Prop showBack: boolean = false;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 返回回调 */
  onBack?: () => void;
  /** 右侧操作区 */
  @BuilderParam actions?: () => void;
  
  build() {
    Row({ space: Spacing.MD }) {
      // 返回按钮
      if (this.showBack) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.colors.textPrimary)
          .onClick(() => {
            if (this.onBack) {
              this.onBack();
            }
          })
      }
      
      // 标题区域
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
        
        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor(this.colors.textSecondary)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 右侧操作区
      if (this.actions) {
        Row({ space: Spacing.SM }) {
          this.actions();
        }
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.MD, right: Spacing.MD })
    .backgroundColor(this.colors.bgPrimary)
  }
}

// =====================================================
// 滚动容器
// =====================================================

@Component
export struct RFScrollView {
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 内边距 (避免与系统 padding 方法冲突) */
  @Prop contentPadding: number = Spacing.MD;
  /** 是否显示滚动条 */
  @Prop showScrollBar: boolean = false;
  /** 刷新回调 */
  onRefresh?: () => Promise<void>;
  /** 内容 */
  @BuilderParam content: () => void;
  
  @State isRefreshing: boolean = false;
  
  build() {
    if (this.onRefresh) {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column() {
            if (this.content) {
              this.content();
            }
          }
          .width('100%')
          .padding(this.contentPadding)
        }
        .width('100%')
        .height('100%')
        .scrollBar(this.showScrollBar ? BarState.Auto : BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .onRefreshing(async () => {
        if (this.onRefresh) {
          await this.onRefresh();
        }
        this.isRefreshing = false;
      })
    } else {
      Scroll() {
        Column() {
          if (this.content) {
            this.content();
          }
        }
        .width('100%')
        .padding(this.contentPadding)
      }
      .width('100%')
      .height('100%')
      .scrollBar(this.showScrollBar ? BarState.Auto : BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
  }
}
