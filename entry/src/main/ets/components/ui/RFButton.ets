/**
 * RepoFlow 按钮组件
 * 
 * 支持多种样式变体:
 * - primary: 主要操作按钮
 * - secondary: 次要操作按钮
 * - outline: 边框按钮
 * - ghost: 无背景按钮
 * - danger: 危险操作按钮
 * 
 * 支持多种尺寸:
 * - sm: 小尺寸
 * - md: 中等尺寸 (默认)
 * - lg: 大尺寸
 */

import { ThemeColors, DarkColors, LightColors } from '../../theme/Colors';
import { Spacing, BorderRadius, FontSize, AnimationDuration } from '../../theme/DesignTokens';

// =====================================================
// 类型定义
// =====================================================

export type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';

// =====================================================
// 按钮组件
// =====================================================

@Component
export struct RFButton {
  /** 按钮文本 - 支持字符串或资源引用 */
  @Prop text: ResourceStr = '';
  /** 按钮变体 */
  @Prop variant: ButtonVariant = 'primary';
  /** 按钮尺寸 */
  @Prop buttonSize: ButtonSize = 'md';
  /** 是否禁用 */
  @Prop disabled: boolean = false;
  /** 是否加载中 */
  @Prop loading: boolean = false;
  /** 是否全宽 */
  @Prop fullWidth: boolean = false;
  /** 左侧图标 */
  @Prop leftIcon: ResourceStr | null = null;
  /** 右侧图标 */
  @Prop rightIcon: ResourceStr | null = null;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 点击回调 */
  onTap?: () => void;
  
  @State isPressed: boolean = false;
  @State isHovered: boolean = false;
  
  // 获取按钮高度
  private getHeight(): number {
    switch (this.buttonSize) {
      case 'sm': return 32;
      case 'lg': return 48;
      default: return 40;
    }
  }
  
  // 获取水平内边距
  private getPaddingH(): number {
    switch (this.buttonSize) {
      case 'sm': return Spacing.SM;
      case 'lg': return Spacing.LG;
      default: return Spacing.MD;
    }
  }
  
  // 获取字体大小
  private getFontSize(): number {
    switch (this.buttonSize) {
      case 'sm': return FontSize.SM;
      case 'lg': return FontSize.LG;
      default: return FontSize.MD;
    }
  }
  
  // 获取图标大小
  private getIconSize(): number {
    switch (this.buttonSize) {
      case 'sm': return 14;
      case 'lg': return 20;
      default: return 16;
    }
  }
  
  // 获取背景颜色
  private getBackgroundColor(): string {
    if (this.disabled) {
      return this.colors.bgTertiary;
    }
    
    const baseColor = this.getBaseBackgroundColor();
    
    if (this.isPressed) {
      return this.getActiveColor();
    }
    
    if (this.isHovered) {
      return this.getHoverColor();
    }
    
    return baseColor;
  }
  
  private getBaseBackgroundColor(): string {
    switch (this.variant) {
      case 'primary':
        return this.colors.brandPrimary;
      case 'secondary':
        return this.colors.bgSecondary;
      case 'outline':
      case 'ghost':
        return 'transparent';
      case 'danger':
        return this.colors.error;
      default:
        return this.colors.brandPrimary;
    }
  }
  
  private getHoverColor(): string {
    switch (this.variant) {
      case 'primary':
        return this.colors.brandHover;
      case 'secondary':
        return this.colors.bgTertiary;
      case 'outline':
      case 'ghost':
        return this.colors.bgSecondary;
      case 'danger':
        return this.colors.errorBg;
      default:
        return this.colors.brandHover;
    }
  }
  
  private getActiveColor(): string {
    switch (this.variant) {
      case 'primary':
        return this.colors.brandActive;
      case 'secondary':
        return this.colors.bgTertiary;
      case 'outline':
      case 'ghost':
        return this.colors.bgTertiary;
      case 'danger':
        return this.colors.error;
      default:
        return this.colors.brandActive;
    }
  }
  
  // 获取文字颜色
  private getTextColor(): string {
    if (this.disabled) {
      return this.colors.textDisabled;
    }
    
    switch (this.variant) {
      case 'primary':
        return '#FFFFFF';
      case 'secondary':
        return this.colors.textPrimary;
      case 'outline':
        return this.colors.brandPrimary;
      case 'ghost':
        return this.colors.textSecondary;
      case 'danger':
        return '#FFFFFF';
      default:
        return '#FFFFFF';
    }
  }
  
  // 获取边框颜色
  private getBorderColor(): string {
    if (this.disabled) {
      return this.colors.border;
    }
    
    if (this.variant === 'outline') {
      return this.colors.brandPrimary;
    }
    
    return 'transparent';
  }
  
  build() {
    Row({ space: Spacing.XS }) {
      // 加载动画
      if (this.loading) {
        LoadingProgress()
          .width(this.getIconSize())
          .height(this.getIconSize())
          .color(this.getTextColor())
      }
      
      // 左侧图标
      if (this.leftIcon && !this.loading) {
        Image(this.leftIcon)
          .width(this.getIconSize())
          .height(this.getIconSize())
          .fillColor(this.getTextColor())
      }
      
      // 文本
      if (this.text) {
        Text(this.text)
          .fontSize(this.getFontSize())
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor())
      }
      
      // 右侧图标
      if (this.rightIcon) {
        Image(this.rightIcon)
          .width(this.getIconSize())
          .height(this.getIconSize())
          .fillColor(this.getTextColor())
      }
    }
    .height(this.getHeight())
    .padding({ left: this.getPaddingH(), right: this.getPaddingH() })
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(BorderRadius.MD)
    .borderWidth(this.variant === 'outline' ? 1 : 0)
    .borderColor(this.getBorderColor())
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width(this.fullWidth ? '100%' : undefined)
    .enabled(!this.disabled && !this.loading)
    .animation({
      duration: AnimationDuration.FAST,
      curve: Curve.EaseOut
    })
    .onTouch((event: TouchEvent) => {
      if (this.disabled || this.loading) return;
      
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onHover((isHover: boolean) => {
      if (this.disabled || this.loading) return;
      this.isHovered = isHover;
    })
    .onClick(() => {
      if (!this.disabled && !this.loading && this.onTap) {
        this.onTap();
      }
    })
  }
}

// =====================================================
// 图标按钮组件
// =====================================================

@Component
export struct RFIconButton {
  /** 图标资源 */
  @Prop icon: ResourceStr = '';
  /** 按钮变体 */
  @Prop variant: ButtonVariant = 'ghost';
  /** 按钮尺寸 */
  @Prop buttonSize: ButtonSize = 'md';
  /** 是否禁用 */
  @Prop disabled: boolean = false;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 点击回调 */
  onTap?: () => void;
  
  @State isPressed: boolean = false;
  @State isHovered: boolean = false;
  
  private getButtonSize(): number {
    switch (this.buttonSize) {
      case 'sm': return 32;
      case 'lg': return 48;
      default: return 40;
    }
  }
  
  private getIconSize(): number {
    switch (this.buttonSize) {
      case 'sm': return 16;
      case 'lg': return 24;
      default: return 20;
    }
  }
  
  private getBackgroundColor(): string {
    if (this.disabled) return 'transparent';
    if (this.isPressed) return this.colors.bgTertiary;
    if (this.isHovered) return this.colors.bgSecondary;
    return 'transparent';
  }
  
  private getIconColor(): string {
    if (this.disabled) return this.colors.textDisabled;
    return this.colors.textSecondary;
  }
  
  build() {
    Stack() {
      Image(this.icon)
        .width(this.getIconSize())
        .height(this.getIconSize())
        .fillColor(this.getIconColor())
    }
    .width(this.getButtonSize())
    .height(this.getButtonSize())
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(BorderRadius.FULL)
    .alignContent(Alignment.Center)
    .enabled(!this.disabled)
    .animation({
      duration: AnimationDuration.FAST,
      curve: Curve.EaseOut
    })
    .onTouch((event: TouchEvent) => {
      if (this.disabled) return;
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onHover((isHover: boolean) => {
      if (this.disabled) return;
      this.isHovered = isHover;
    })
    .onClick(() => {
      if (!this.disabled && this.onTap) {
        this.onTap();
      }
    })
  }
}
