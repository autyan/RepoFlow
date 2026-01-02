/**
 * RepoFlow 输入组件
 * 
 * 支持:
 * - 单行文本输入
 * - 多行文本输入
 * - 搜索输入
 * - 密码输入
 * - 带图标输入
 * - 错误状态
 */

import { ThemeColors, DarkColors } from '../../theme/Colors';
import { Spacing, BorderRadius, FontSize, AnimationDuration } from '../../theme/DesignTokens';

// =====================================================
// 类型定义
// =====================================================

export type InputType = 'text' | 'password' | 'email' | 'number' | 'search';
export type InputSize = 'sm' | 'md' | 'lg';

// =====================================================
// 输入框组件
// =====================================================

@Component
export struct RFInput {
  /** 占位符 */
  @Prop placeholder: string = '';
  /** 输入值 */
  @Link value: string;
  /** 输入类型 */
  @Prop type: InputType = 'text';
  /** 尺寸 */
  @Prop inputSize: InputSize = 'md';
  /** 是否禁用 */
  @Prop disabled: boolean = false;
  /** 错误状态 */
  @Prop error: boolean = false;
  /** 错误信息 */
  @Prop errorMessage: string = '';
  /** 左侧图标 */
  @Prop leftIcon: ResourceStr | null = null;
  /** 右侧图标 */
  @Prop rightIcon: ResourceStr | null = null;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 最大长度 */
  @Prop maxLength: number = -1;
  /** 输入变化回调 */
  onChange?: (value: string) => void;
  /** 提交回调 */
  onSubmit?: (value: string) => void;
  /** 右侧图标点击回调 */
  onRightIconClick?: () => void;
  
  @State isFocused: boolean = false;
  @State showPassword: boolean = false;
  
  private getHeight(): number {
    switch (this.inputSize) {
      case 'sm': return 36;
      case 'lg': return 48;
      default: return 42;
    }
  }
  
  private getFontSize(): number {
    switch (this.inputSize) {
      case 'sm': return FontSize.SM;
      case 'lg': return FontSize.LG;
      default: return FontSize.MD;
    }
  }
  
  private getIconSize(): number {
    switch (this.inputSize) {
      case 'sm': return 16;
      case 'lg': return 22;
      default: return 18;
    }
  }
  
  private getBorderColor(): string {
    if (this.error) return this.colors.error;
    if (this.isFocused) return this.colors.brandPrimary;
    return this.colors.border;
  }
  
  private getBgColor(): string {
    if (this.disabled) return this.colors.bgTertiary;
    return this.colors.bgSecondary;
  }
  
  private getInputType(): InputType {
    if (this.type === 'password' && this.showPassword) {
      return 'text';
    }
    return this.type;
  }
  
  build() {
    Column({ space: Spacing.XS }) {
      Row({ space: Spacing.SM }) {
        // 左侧图标
        if (this.leftIcon) {
          Image(this.leftIcon)
            .width(this.getIconSize())
            .height(this.getIconSize())
            .fillColor(this.isFocused ? this.colors.brandPrimary : this.colors.textTertiary)
        }
        
        // 搜索图标
        if (this.type === 'search' && !this.leftIcon) {
          Image($r('app.media.ic_search'))
            .width(this.getIconSize())
            .height(this.getIconSize())
            .fillColor(this.isFocused ? this.colors.brandPrimary : this.colors.textTertiary)
        }
        
        // 输入框
        if (this.type === 'password') {
          TextInput({ placeholder: this.placeholder, text: this.value })
            .type(this.showPassword ? InputType.Normal : InputType.Password)
            .layoutWeight(1)
            .fontSize(this.getFontSize())
            .fontColor(this.colors.textPrimary)
            .placeholderColor(this.colors.textTertiary)
            .backgroundColor('transparent')
            .padding(0)
            .enabled(!this.disabled)
            .maxLength(this.maxLength > 0 ? this.maxLength : undefined)
            .onChange((value: string) => {
              this.value = value;
              if (this.onChange) {
                this.onChange(value);
              }
            })
            .onFocus(() => {
              this.isFocused = true;
            })
            .onBlur(() => {
              this.isFocused = false;
            })
            .onSubmit(() => {
              if (this.onSubmit) {
                this.onSubmit(this.value);
              }
            })
        } else {
          TextInput({ placeholder: this.placeholder, text: this.value })
            .type(this.type === 'number' ? InputType.Number : InputType.Normal)
            .layoutWeight(1)
            .fontSize(this.getFontSize())
            .fontColor(this.colors.textPrimary)
            .placeholderColor(this.colors.textTertiary)
            .backgroundColor('transparent')
            .padding(0)
            .enabled(!this.disabled)
            .maxLength(this.maxLength > 0 ? this.maxLength : undefined)
            .onChange((value: string) => {
              this.value = value;
              if (this.onChange) {
                this.onChange(value);
              }
            })
            .onFocus(() => {
              this.isFocused = true;
            })
            .onBlur(() => {
              this.isFocused = false;
            })
            .onSubmit(() => {
              if (this.onSubmit) {
                this.onSubmit(this.value);
              }
            })
        }
        
        // 清除按钮 (搜索模式)
        if (this.type === 'search' && this.value.length > 0) {
          Image($r('app.media.ic_close'))
            .width(this.getIconSize())
            .height(this.getIconSize())
            .fillColor(this.colors.textTertiary)
            .onClick(() => {
              this.value = '';
              if (this.onChange) {
                this.onChange('');
              }
            })
        }
        
        // 密码切换按钮
        if (this.type === 'password') {
          Image($r('app.media.ic_eye'))
            .width(this.getIconSize())
            .height(this.getIconSize())
            .fillColor(this.colors.textTertiary)
            .onClick(() => {
              this.showPassword = !this.showPassword;
            })
        }
        
        // 右侧图标
        if (this.rightIcon && this.type !== 'password' && this.type !== 'search') {
          Image(this.rightIcon)
            .width(this.getIconSize())
            .height(this.getIconSize())
            .fillColor(this.colors.textTertiary)
            .onClick(() => {
              if (this.onRightIconClick) {
                this.onRightIconClick();
              }
            })
        }
      }
      .width('100%')
      .height(this.getHeight())
      .padding({ left: Spacing.MD, right: Spacing.MD })
      .backgroundColor(this.getBgColor())
      .borderRadius(BorderRadius.MD)
      .borderWidth(1)
      .borderColor(this.getBorderColor())
      .animation({
        duration: AnimationDuration.FAST,
        curve: Curve.EaseOut
      })
      
      // 错误信息
      if (this.error && this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(FontSize.XS)
          .fontColor(this.colors.error)
      }
    }
    .width('100%')
  }
}

// =====================================================
// 多行文本输入组件
// =====================================================

@Component
export struct RFTextArea {
  /** 占位符 */
  @Prop placeholder: string = '';
  /** 输入值 */
  @Link value: string;
  /** 最小行数 */
  @Prop minLines: number = 3;
  /** 最大行数 */
  @Prop maxLines: number = 6;
  /** 是否禁用 */
  @Prop disabled: boolean = false;
  /** 错误状态 */
  @Prop error: boolean = false;
  /** 错误信息 */
  @Prop errorMessage: string = '';
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 最大长度 */
  @Prop maxLength: number = -1;
  /** 显示字数统计 */
  @Prop showCount: boolean = false;
  /** 输入变化回调 */
  onChange?: (value: string) => void;
  
  @State isFocused: boolean = false;
  
  private getBorderColor(): string {
    if (this.error) return this.colors.error;
    if (this.isFocused) return this.colors.brandPrimary;
    return this.colors.border;
  }
  
  private getBgColor(): string {
    if (this.disabled) return this.colors.bgTertiary;
    return this.colors.bgSecondary;
  }
  
  private getMinHeight(): number {
    return this.minLines * 24 + Spacing.MD * 2;
  }
  
  build() {
    Column({ space: Spacing.XS }) {
      Column() {
        TextArea({ placeholder: this.placeholder, text: this.value })
          .width('100%')
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textPrimary)
          .placeholderColor(this.colors.textTertiary)
          .backgroundColor('transparent')
          .padding(Spacing.MD)
          .enabled(!this.disabled)
          .maxLength(this.maxLength > 0 ? this.maxLength : undefined)
          .onChange((value: string) => {
            this.value = value;
            if (this.onChange) {
              this.onChange(value);
            }
          })
          .onFocus(() => {
            this.isFocused = true;
          })
          .onBlur(() => {
            this.isFocused = false;
          })
        
        // 字数统计
        if (this.showCount && this.maxLength > 0) {
          Row() {
            Blank()
            Text(`${this.value.length}/${this.maxLength}`)
              .fontSize(FontSize.XS)
              .fontColor(this.colors.textTertiary)
          }
          .width('100%')
          .padding({ right: Spacing.SM, bottom: Spacing.XS })
        }
      }
      .width('100%')
      .constraintSize({ minHeight: this.getMinHeight() })
      .backgroundColor(this.getBgColor())
      .borderRadius(BorderRadius.MD)
      .borderWidth(1)
      .borderColor(this.getBorderColor())
      .animation({
        duration: AnimationDuration.FAST,
        curve: Curve.EaseOut
      })
      
      // 错误信息
      if (this.error && this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(FontSize.XS)
          .fontColor(this.colors.error)
      }
    }
    .width('100%')
  }
}

// =====================================================
// 搜索输入组件
// =====================================================

@Component
export struct RFSearchInput {
  /** 占位符 */
  @Prop placeholder: string = 'Search...';
  /** 输入值 */
  @Link value: string;
  /** 尺寸 */
  @Prop inputSize: InputSize = 'md';
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 输入变化回调 */
  onChange?: (value: string) => void;
  /** 提交回调 */
  onSubmit?: (value: string) => void;
  
  build() {
    RFInput({
      placeholder: this.placeholder,
      value: this.value,
      type: 'search',
      inputSize: this.inputSize,
      colors: this.colors,
      onChange: this.onChange,
      onSubmit: this.onSubmit
    })
  }
}
