/**
 * RepoFlow 头像组件
 * 
 * 支持:
 * - 图片头像
 * - 文字头像 (首字母)
 * - 图标头像
 * - 多种尺寸
 * - 状态徽标
 */

import { ThemeColors, DarkColors } from '../../theme/Colors';
import { AvatarSize, FontSize, BorderRadius } from '../../theme/DesignTokens';

// =====================================================
// 类型定义
// =====================================================

export type AvatarSizeType = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl';
export type AvatarShape = 'circle' | 'square';
export type StatusType = 'online' | 'offline' | 'away' | 'busy' | 'none';

// =====================================================
// 头像组件
// =====================================================

@Component
export struct RFAvatar {
  /** 图片地址 */
  @Prop src: string = '';
  /** 备用文字 (用于生成首字母头像) */
  @Prop alt: string = '';
  /** 尺寸 */
  @Prop avatarSize: AvatarSizeType = 'md';
  /** 形状 */
  @Prop shape: AvatarShape = 'circle';
  /** 状态 */
  @Prop status: StatusType = 'none';
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 自定义背景色 (用于文字头像) */
  @Prop bgColor: string = '';
  /** 点击回调 */
  onTap?: () => void;
  
  @State imageLoadFailed: boolean = false;
  
  private getAvatarSize(): number {
    switch (this.avatarSize) {
      case 'xs': return AvatarSize.XS;
      case 'sm': return AvatarSize.SM;
      case 'lg': return AvatarSize.LG;
      case 'xl': return AvatarSize.XL;
      case 'xxl': return AvatarSize.XXL;
      default: return AvatarSize.MD;
    }
  }
  
  private getFontSize(): number {
    const size = this.getAvatarSize();
    return Math.floor(size * 0.4);
  }
  
  private getStatusSize(): number {
    const size = this.getAvatarSize();
    return Math.max(8, Math.floor(size * 0.25));
  }
  
  private getBorderRadius(): number {
    if (this.shape === 'square') {
      return BorderRadius.MD;
    }
    return this.getAvatarSize() / 2;
  }
  
  private getInitials(): string {
    if (!this.alt) return '';
    const words = this.alt.trim().split(/\s+/);
    if (words.length === 1) {
      return words[0].substring(0, 2).toUpperCase();
    }
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }
  
  private getDefaultBgColor(): string {
    if (this.bgColor) return this.bgColor;
    
    // 根据 alt 文字生成一个一致的颜色
    if (this.alt) {
      const colors = [
        '#3B82F6', '#10B981', '#F59E0B', '#EF4444',
        '#8B5CF6', '#EC4899', '#06B6D4', '#84CC16'
      ];
      let hash = 0;
      for (let i = 0; i < this.alt.length; i++) {
        hash = this.alt.charCodeAt(i) + ((hash << 5) - hash);
      }
      return colors[Math.abs(hash) % colors.length];
    }
    
    return this.colors.bgTertiary;
  }
  
  private getStatusColor(): string {
    switch (this.status) {
      case 'online': return this.colors.success;
      case 'offline': return this.colors.textTertiary;
      case 'away': return this.colors.warning;
      case 'busy': return this.colors.error;
      default: return 'transparent';
    }
  }
  
  @Builder
  AvatarContent() {
    if (this.src && !this.imageLoadFailed) {
      // 图片头像
      Image(this.src)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .onError(() => {
          this.imageLoadFailed = true;
        })
    } else if (this.alt) {
      // 文字头像
      Text(this.getInitials())
        .fontSize(this.getFontSize())
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
    } else {
      // 默认图标头像
      Image($r('app.media.ic_user'))
        .width('60%')
        .height('60%')
        .fillColor(this.colors.textTertiary)
    }
  }
  
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 头像主体
      Stack() {
        this.AvatarContent()
      }
      .width(this.getAvatarSize())
      .height(this.getAvatarSize())
      .borderRadius(this.getBorderRadius())
      .backgroundColor(this.src && !this.imageLoadFailed ? 'transparent' : this.getDefaultBgColor())
      .clip(true)
      .alignContent(Alignment.Center)
      
      // 状态徽标
      if (this.status !== 'none') {
        Circle()
          .width(this.getStatusSize())
          .height(this.getStatusSize())
          .fill(this.getStatusColor())
          .stroke(this.colors.bgPrimary)
          .strokeWidth(2)
      }
    }
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }
}

// =====================================================
// 头像数据接口
// =====================================================

export interface AvatarData {
  src?: string;
  alt?: string;
}

// =====================================================
// 头像组组件 (堆叠显示多个头像)
// =====================================================

@Component
export struct RFAvatarGroup {
  /** 头像数据列表 */
  @Prop avatars: Array<AvatarData> = [];
  /** 最大显示数量 */
  @Prop max: number = 3;
  /** 尺寸 */
  @Prop avatarSize: AvatarSizeType = 'sm';
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  
  private getAvatarSize(): number {
    switch (this.avatarSize) {
      case 'xs': return AvatarSize.XS;
      case 'sm': return AvatarSize.SM;
      case 'lg': return AvatarSize.LG;
      default: return AvatarSize.MD;
    }
  }
  
  private getOverlap(): number {
    return this.getAvatarSize() * 0.3;
  }
  
  build() {
    Row() {
      ForEach(this.avatars.slice(0, this.max), (avatar: AvatarData, index: number) => {
        Stack() {
          RFAvatar({
            src: avatar.src || '',
            alt: avatar.alt || '',
            avatarSize: this.avatarSize,
            colors: this.colors
          })
        }
        .margin({ left: index === 0 ? 0 : -this.getOverlap() })
        .zIndex(this.max - index)
        .border({
          width: 2,
          color: this.colors.bgPrimary,
          radius: this.getAvatarSize() / 2
        })
      })
      
      // 剩余数量
      if (this.avatars.length > this.max) {
        Stack() {
          Text(`+${this.avatars.length - this.max}`)
            .fontSize(FontSize.XS)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textSecondary)
        }
        .width(this.getAvatarSize())
        .height(this.getAvatarSize())
        .borderRadius(this.getAvatarSize() / 2)
        .backgroundColor(this.colors.bgTertiary)
        .alignContent(Alignment.Center)
        .margin({ left: -this.getOverlap() })
        .border({
          width: 2,
          color: this.colors.bgPrimary,
          radius: this.getAvatarSize() / 2
        })
      }
    }
  }
}
