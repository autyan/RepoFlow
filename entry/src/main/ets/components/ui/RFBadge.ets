/**
 * RepoFlow 徽标组件
 * 
 * 支持多种类型:
 * - count: 数字徽标
 * - dot: 小红点
 * - label: 标签徽标
 * - status: 状态徽标
 * 
 * 支持多种颜色:
 * - primary, success, warning, error, info
 */

import { ThemeColors, DarkColors } from '../../theme/Colors';
import { FontSize, BorderRadius, Spacing } from '../../theme/DesignTokens';

// =====================================================
// 类型定义
// =====================================================

export type BadgeType = 'count' | 'dot' | 'label' | 'status';
export type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'info' | 'neutral';
export type BadgeSize = 'sm' | 'md' | 'lg';

// =====================================================
// 徽标组件
// =====================================================

@Component
export struct RFBadge {
  /** 徽标类型 */
  @Prop type: BadgeType = 'count';
  /** 数字或文本 */
  @Prop value: number | string = 0;
  /** 最大数字 (超过显示 max+) */
  @Prop max: number = 99;
  /** 颜色 */
  @Prop color: BadgeColor = 'error';
  /** 尺寸 (避免与系统 size 方法冲突) */
  @Prop badgeSize: BadgeSize = 'md';
  /** 是否隐藏 (count为0时) */
  @Prop hideZero: boolean = true;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  
  private getBgColor(): string {
    switch (this.color) {
      case 'primary': return this.colors.brandPrimary;
      case 'success': return this.colors.success;
      case 'warning': return this.colors.warning;
      case 'error': return this.colors.error;
      case 'info': return this.colors.info;
      case 'neutral': return this.colors.bgTertiary;
      default: return this.colors.error;
    }
  }
  
  private getTextColor(): string {
    if (this.color === 'neutral') {
      return this.colors.textSecondary;
    }
    return '#FFFFFF';
  }
  
  private getDisplayValue(): string {
    if (typeof this.value === 'string') {
      return this.value;
    }
    
    if (this.value > this.max) {
      return `${this.max}+`;
    }
    
    return this.value.toString();
  }
  
  private getHeight(): number {
    switch (this.badgeSize) {
      case 'sm': return 16;
      case 'lg': return 24;
      default: return 20;
    }
  }
  
  private getFontSize(): number {
    switch (this.badgeSize) {
      case 'sm': return FontSize.XXS;
      case 'lg': return FontSize.SM;
      default: return FontSize.XS;
    }
  }
  
  private getDotSize(): number {
    switch (this.badgeSize) {
      case 'sm': return 6;
      case 'lg': return 10;
      default: return 8;
    }
  }
  
  private shouldShow(): boolean {
    if (this.type === 'dot' || this.type === 'label' || this.type === 'status') {
      return true;
    }
    
    if (typeof this.value === 'string') {
      return this.value.length > 0;
    }
    
    if (this.hideZero && this.value === 0) {
      return false;
    }
    
    return true;
  }
  
  build() {
    if (this.shouldShow()) {
      if (this.type === 'dot') {
        // 小红点
        Circle()
          .width(this.getDotSize())
          .height(this.getDotSize())
          .fill(this.getBgColor())
      } else if (this.type === 'status') {
        // 状态徽标
        Row({ space: 4 }) {
          Circle()
            .width(8)
            .height(8)
            .fill(this.getBgColor())
          
          if (this.value) {
            Text(this.getDisplayValue())
              .fontSize(this.getFontSize())
              .fontColor(this.colors.textSecondary)
          }
        }
      } else {
        // count 或 label
        Row() {
          Text(this.getDisplayValue())
            .fontSize(this.getFontSize())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getTextColor())
        }
        .height(this.getHeight())
        .padding({ left: Spacing.XS, right: Spacing.XS })
        .constraintSize({ minWidth: this.getHeight() })
        .backgroundColor(this.getBgColor())
        .borderRadius(this.getHeight() / 2)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
    }
  }
}

// =====================================================
// 带徽标的容器组件
// =====================================================

@Component
export struct RFBadgeWrapper {
  /** 徽标类型 */
  @Prop type: BadgeType = 'count';
  /** 数字或文本 */
  @Prop value: number | string = 0;
  /** 最大数字 */
  @Prop max: number = 99;
  /** 颜色 */
  @Prop color: BadgeColor = 'error';
  /** 尺寸 (避免与系统 size 方法冲突) */
  @Prop badgeSize: BadgeSize = 'sm';
  /** 是否隐藏零 */
  @Prop hideZero: boolean = true;
  /** 偏移量 (避免与系统 offset 方法冲突) */
  @Prop badgeOffset: number[] = [0, 0];
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 子内容 */
  @BuilderParam content: () => void;
  
  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 子内容
      if (this.content) {
        this.content();
      }
      
      // 徽标
      RFBadge({
        type: this.type,
        value: this.value,
        max: this.max,
        color: this.color,
        badgeSize: this.badgeSize,
        hideZero: this.hideZero,
        colors: this.colors
      })
        .offset({ x: this.badgeOffset[0], y: this.badgeOffset[1] })
    }
  }
}

// =====================================================
// 标签徽标组件 (如: issue 标签, PR 状态等)
// =====================================================

@Component
export struct RFLabel {
  /** 文本 */
  @Prop text: string = '';
  /** 颜色 */
  @Prop color: BadgeColor = 'neutral';
  /** 尺寸 (避免与系统 size 方法冲突) */
  @Prop badgeSize: BadgeSize = 'md';
  /** 是否显示圆点 */
  @Prop showDot: boolean = false;
  /** 左侧图标 */
  @Prop leftIcon: ResourceStr | null = null;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  
  private getBgColor(): string {
    switch (this.color) {
      case 'primary': return this.colors.primaryContainer;
      case 'success': return this.colors.successBg;
      case 'warning': return this.colors.warningBg;
      case 'error': return this.colors.errorBg;
      case 'info': return this.colors.infoBg;
      case 'neutral': return this.colors.bgTertiary;
      default: return this.colors.bgTertiary;
    }
  }
  
  private getTextColor(): string {
    switch (this.color) {
      case 'primary': return this.colors.brandPrimary;
      case 'success': return this.colors.success;
      case 'warning': return this.colors.warning;
      case 'error': return this.colors.error;
      case 'info': return this.colors.info;
      case 'neutral': return this.colors.textSecondary;
      default: return this.colors.textSecondary;
    }
  }
  
  private getDotColor(): string {
    switch (this.color) {
      case 'primary': return this.colors.brandPrimary;
      case 'success': return this.colors.success;
      case 'warning': return this.colors.warning;
      case 'error': return this.colors.error;
      case 'info': return this.colors.info;
      case 'neutral': return this.colors.textTertiary;
      default: return this.colors.textTertiary;
    }
  }
  
  private getHeight(): number {
    switch (this.badgeSize) {
      case 'sm': return 20;
      case 'lg': return 28;
      default: return 24;
    }
  }
  
  private getFontSize(): number {
    switch (this.badgeSize) {
      case 'sm': return FontSize.XS;
      case 'lg': return FontSize.MD;
      default: return FontSize.SM;
    }
  }
  
  private getIconSize(): number {
    switch (this.badgeSize) {
      case 'sm': return 12;
      case 'lg': return 16;
      default: return 14;
    }
  }
  
  build() {
    Row({ space: 4 }) {
      // 圆点
      if (this.showDot) {
        Circle()
          .width(6)
          .height(6)
          .fill(this.getDotColor())
      }
      
      // 左侧图标
      if (this.leftIcon) {
        Image(this.leftIcon)
          .width(this.getIconSize())
          .height(this.getIconSize())
          .fillColor(this.getTextColor())
      }
      
      // 文本
      Text(this.text)
        .fontSize(this.getFontSize())
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getTextColor())
    }
    .height(this.getHeight())
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.getBgColor())
    .borderRadius(BorderRadius.SM)
  }
}
