/**
 * RepoFlow 卡片组件
 * 
 * 支持多种样式:
 * - filled: 填充背景
 * - outlined: 边框样式
 * - elevated: 阴影样式
 * 
 * 支持可选的:
 * - 头部区域
 * - 底部操作区域
 * - 点击效果
 */

import { ThemeColors, DarkColors } from '../../theme/Colors';
import { Spacing, BorderRadius, Shadow, AnimationDuration } from '../../theme/DesignTokens';

// =====================================================
// 类型定义
// =====================================================

export type CardVariant = 'filled' | 'outlined' | 'elevated';

// =====================================================
// 卡片组件
// =====================================================

@Component
export struct RFCard {
  /** 卡片变体 */
  @Prop variant: CardVariant = 'filled';
  /** 内边距 (避免与系统 padding 方法冲突) */
  @Prop contentPadding: number = Spacing.MD;
  /** 是否可点击 */
  @Prop clickable: boolean = false;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 自定义背景色 */
  @Prop customBgColor: string = '';
  /** 点击回调 */
  onTap?: () => void;
  /** 卡片内容 */
  @BuilderParam content: () => void;
  
  @State isPressed: boolean = false;
  @State isHovered: boolean = false;
  
  private getBackgroundColor(): string {
    if (this.customBgColor) {
      return this.customBgColor;
    }
    
    if (this.clickable) {
      if (this.isPressed) return this.colors.bgTertiary;
      if (this.isHovered) return this.colors.bgHover;
    }
    
    switch (this.variant) {
      case 'filled':
        return this.colors.bgSecondary;
      case 'outlined':
        return 'transparent';
      case 'elevated':
        return this.colors.bgSecondary;
      default:
        return this.colors.bgSecondary;
    }
  }
  
  private getBorderWidth(): number {
    return this.variant === 'outlined' ? 1 : 0;
  }
  
  private getBorderColor(): string {
    return this.colors.border;
  }
  
  private getShadow(): ShadowOptions | null {
    if (this.variant === 'elevated') {
      return {
        radius: Shadow.MD.radius,
        color: Shadow.MD.color,
        offsetX: Shadow.MD.offsetX,
        offsetY: Shadow.MD.offsetY
      };
    }
    return null;
  }
  
  build() {
    Column() {
      if (this.content) {
        this.content();
      }
    }
    .width('100%')
    .padding(this.contentPadding)
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(BorderRadius.LG)
    .borderWidth(this.getBorderWidth())
    .borderColor(this.getBorderColor())
    .shadow(this.getShadow())
    .animation({
      duration: AnimationDuration.FAST,
      curve: Curve.EaseOut
    })
    .onTouch((event: TouchEvent) => {
      if (!this.clickable) return;
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onHover((isHover: boolean) => {
      if (!this.clickable) return;
      this.isHovered = isHover;
    })
    .onClick(() => {
      if (this.clickable && this.onTap) {
        this.onTap();
      }
    })
  }
}

// =====================================================
// 带头部的卡片组件
// =====================================================

@Component
export struct RFCardWithHeader {
  /** 标题 */
  @Prop title: string = '';
  /** 副标题 */
  @Prop subtitle: string = '';
  /** 卡片变体 */
  @Prop variant: CardVariant = 'filled';
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 右侧操作区域 */
  @BuilderParam headerAction?: () => void;
  /** 卡片内容 */
  @BuilderParam content: () => void;
  
  build() {
    Column({ space: Spacing.MD }) {
      // 头部
      Row() {
        Column({ space: Spacing.XXS }) {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textPrimary)
          
          if (this.subtitle) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor(this.colors.textSecondary)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        if (this.headerAction) {
          this.headerAction();
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      
      // 分割线
      Divider()
        .strokeWidth(1)
        .color(this.colors.border)
      
      // 内容
      if (this.content) {
        this.content();
      }
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.colors.bgSecondary)
    .borderRadius(BorderRadius.LG)
    .borderWidth(this.variant === 'outlined' ? 1 : 0)
    .borderColor(this.colors.border)
  }
}

// =====================================================
// 列表项卡片组件
// =====================================================

@Component
export struct RFListCard {
  /** 标题 */
  @Prop title: string = '';
  /** 副标题 */
  @Prop subtitle: string = '';
  /** 描述 */
  @Prop description: string = '';
  /** 左侧图标 */
  @Prop leftIcon: ResourceStr | null = null;
  /** 显示右箭头 */
  @Prop showArrow: boolean = true;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 点击回调 */
  onTap?: () => void;
  
  @State isPressed: boolean = false;
  @State isHovered: boolean = false;
  
  private getBackgroundColor(): string {
    if (this.isPressed) return this.colors.bgTertiary;
    if (this.isHovered) return this.colors.bgHover;
    return this.colors.bgSecondary;
  }
  
  build() {
    Row({ space: Spacing.MD }) {
      // 左侧图标
      if (this.leftIcon) {
        Image(this.leftIcon)
          .width(24)
          .height(24)
          .fillColor(this.colors.textSecondary)
      }
      
      // 内容
      Column({ space: Spacing.XXS }) {
        Row({ space: Spacing.XS }) {
          Text(this.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textPrimary)
          
          if (this.subtitle) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor(this.colors.textTertiary)
          }
        }
        
        if (this.description) {
          Text(this.description)
            .fontSize(13)
            .fontColor(this.colors.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 右箭头
      if (this.showArrow) {
        Image($r('app.media.ic_chevron_right'))
          .width(16)
          .height(16)
          .fillColor(this.colors.textTertiary)
      }
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(BorderRadius.MD)
    .animation({
      duration: AnimationDuration.FAST,
      curve: Curve.EaseOut
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onHover((isHover: boolean) => {
      this.isHovered = isHover;
    })
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }
}
