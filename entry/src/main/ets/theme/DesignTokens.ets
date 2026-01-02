/**
 * RepoFlow 设计令牌系统
 * 基于 design/design-system.md 规范
 * 
 * 本文件定义了应用中所有设计相关的常量值，
 * 包括颜色、字体、间距、圆角、阴影等
 */

// =====================================================
// 间距系统 (Spacing System)
// 基于 8px 基础单位
// =====================================================
export class Spacing {
  /** 0px */
  static readonly NONE: number = 0;
  /** 2px - 极小间距 */
  static readonly XXS: number = 2;
  /** 4px - 最小间距 */
  static readonly XS: number = 4;
  /** 8px - 小间距 */
  static readonly SM: number = 8;
  /** 12px - 默认间距 */
  static readonly MD: number = 12;
  /** 16px - 标准间距 */
  static readonly LG: number = 16;
  /** 20px - 中等间距 */
  static readonly XL: number = 20;
  /** 24px - 大间距 */
  static readonly XXL: number = 24;
  /** 32px - 区块间距 */
  static readonly XXXL: number = 32;
  /** 40px */
  static readonly HUGE: number = 40;
  /** 48px */
  static readonly MASSIVE: number = 48;
  /** 64px */
  static readonly GIANT: number = 64;
}

// =====================================================
// 圆角系统 (Border Radius)
// =====================================================
export class BorderRadius {
  /** 0px - 无圆角 */
  static readonly NONE: number = 0;
  /** 2px - 极小圆角 */
  static readonly XS: number = 2;
  /** 4px - 小圆角 */
  static readonly SM: number = 4;
  /** 8px - 默认圆角 */
  static readonly MD: number = 8;
  /** 12px - 大圆角 */
  static readonly LG: number = 12;
  /** 16px - 超大圆角 */
  static readonly XL: number = 16;
  /** 20px - 更大圆角 */
  static readonly XXL: number = 20;
  /** 9999px - 全圆 */
  static readonly FULL: number = 9999;
}

// =====================================================
// 字体大小 (Font Size)
// =====================================================
export class FontSize {
  /** 10px - 超小 */
  static readonly TINY: number = 10;
  /** 10px - 超小 (别名) */
  static readonly XXS: number = 10;
  /** 12px - 极小/说明文字 */
  static readonly CAPTION: number = 12;
  /** 12px - 极小 (别名) */
  static readonly XS: number = 12;
  /** 13px - 代码字体 */
  static readonly CODE: number = 13;
  /** 14px - 正文 */
  static readonly BODY: number = 14;
  /** 14px - 小 (别名) */
  static readonly SM: number = 14;
  /** 16px - 默认/小标题 */
  static readonly SUBTITLE: number = 16;
  /** 16px - 默认 (别名) */
  static readonly MD: number = 16;
  /** 18px - 标题 */
  static readonly TITLE: number = 18;
  /** 18px - 大 (别名) */
  static readonly LG: number = 18;
  /** 20px - 超大 */
  static readonly HEADLINE: number = 20;
  /** 20px - 超大 (别名) */
  static readonly XL: number = 20;
  /** 24px - 2级标题 */
  static readonly XXL: number = 24;
  /** 30px - 1级标题 */
  static readonly XXXL: number = 30;
  /** 36px - 超大标题 */
  static readonly DISPLAY: number = 36;
}

// =====================================================
// 行高 (Line Height)
// =====================================================
export class LineHeight {
  /** 紧凑行高 1.25 */
  static readonly TIGHT: number = 1.25;
  /** 正常行高 1.5 */
  static readonly NORMAL: number = 1.5;
  /** 宽松行高 1.75 */
  static readonly RELAXED: number = 1.75;
}

// =====================================================
// 阴影配置接口
// =====================================================
export interface ShadowConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

// =====================================================
// 阴影系统 (Shadow System)
// =====================================================
export class Shadow {
  /** 无阴影 */
  static readonly NONE: ShadowConfig = {
    radius: 0,
    color: 'transparent',
    offsetX: 0,
    offsetY: 0,
  };
  /** 小阴影 */
  static readonly SM: ShadowConfig = {
    radius: 2,
    color: 'rgba(0, 0, 0, 0.1)',
    offsetX: 0,
    offsetY: 1,
  };
  /** 中等阴影 */
  static readonly MD: ShadowConfig = {
    radius: 6,
    color: 'rgba(0, 0, 0, 0.15)',
    offsetX: 0,
    offsetY: 4,
  };
  /** 大阴影 */
  static readonly LG: ShadowConfig = {
    radius: 15,
    color: 'rgba(0, 0, 0, 0.2)',
    offsetX: 0,
    offsetY: 10,
  };
}

// =====================================================
// 动画时长 (Animation Duration)
// =====================================================
export class AnimationDuration {
  /** 150ms - 快速 */
  static readonly FAST: number = 150;
  /** 200ms - 标准 */
  static readonly NORMAL: number = 200;
  /** 300ms - 慢速 */
  static readonly SLOW: number = 300;
  /** 500ms - 超慢 */
  static readonly SLOWER: number = 500;
}

// =====================================================
// Z-Index 层级系统
// =====================================================
export class ZIndex {
  /** 基础层 */
  static readonly BASE: number = 0;
  /** 下拉菜单 */
  static readonly DROPDOWN: number = 1000;
  /** 粘性元素 */
  static readonly STICKY: number = 1020;
  /** 固定元素 */
  static readonly FIXED: number = 1030;
  /** 模态框背景 */
  static readonly MODAL_BACKDROP: number = 1040;
  /** 模态框 */
  static readonly MODAL: number = 1050;
  /** 弹出框 */
  static readonly POPOVER: number = 1060;
  /** 提示 */
  static readonly TOOLTIP: number = 1070;
  /** Toast 通知 */
  static readonly TOAST: number = 1080;
}

// =====================================================
// 图标大小
// =====================================================
export class IconSize {
  /** 16px - 超小图标 */
  static readonly XS: number = 16;
  /** 20px - 小图标 */
  static readonly SM: number = 20;
  /** 24px - 默认图标 */
  static readonly MD: number = 24;
  /** 32px - 大图标 */
  static readonly LG: number = 32;
  /** 48px - 超大图标 */
  static readonly XL: number = 48;
  /** 64px - 特大图标 */
  static readonly XXL: number = 64;
}

// =====================================================
// 头像大小
// =====================================================
export class AvatarSize {
  /** 24px - 超小头像 */
  static readonly XS: number = 24;
  /** 32px - 小头像 */
  static readonly SM: number = 32;
  /** 40px - 默认头像 */
  static readonly MD: number = 40;
  /** 48px - 大头像 */
  static readonly LG: number = 48;
  /** 80px - 超大头像 */
  static readonly XL: number = 80;
  /** 120px - 特大头像 */
  static readonly XXL: number = 120;
}

// =====================================================
// 按钮高度
// =====================================================
export class ButtonHeight {
  /** 32px - 小按钮 */
  static readonly SM: number = 32;
  /** 40px - 默认按钮 */
  static readonly MD: number = 40;
  /** 48px - 大按钮 */
  static readonly LG: number = 48;
  /** 56px - 超大按钮 */
  static readonly XL: number = 56;
}

// =====================================================
// 导航栏高度
// =====================================================
export class NavHeight {
  /** 44px - 顶部导航 */
  static readonly TOP: number = 44;
  /** 56px - 底部导航 */
  static readonly BOTTOM: number = 56;
  /** 72px - 侧边栏图标导航 */
  static readonly SIDE_ICON: number = 72;
  /** 240px - 侧边栏展开宽度 */
  static readonly SIDE_EXPANDED: number = 240;
}

// =====================================================
// 触摸目标最小尺寸 (可访问性)
// =====================================================
export class TouchTarget {
  /** 44px - 最小触摸目标 */
  static readonly MIN: number = 44;
}

// =====================================================
// 响应式断点
// =====================================================
export class Breakpoint {
  /** 0px - 超小屏 */
  static readonly XS: number = 0;
  /** 320px - 小屏手机 */
  static readonly SM: number = 320;
  /** 600px - 大屏手机/小平板 */
  static readonly MD: number = 600;
  /** 840px - 平板/折叠屏展开 */
  static readonly LG: number = 840;
  /** 1024px - 小型PC */
  static readonly XL: number = 1024;
  /** 1440px - 大型PC */
  static readonly XXL: number = 1440;
}

// =====================================================
// 设备类型
// =====================================================
export enum DeviceType {
  /** 手机 (< 600vp) */
  PHONE = 'phone',
  /** 折叠屏/小平板 (600-840vp) */
  FOLDABLE = 'foldable',
  /** 平板 (840-1024vp) */
  TABLET = 'tablet',
  /** PC (>= 1024vp) */
  DESKTOP = 'desktop',
}

// =====================================================
// 布局模式
// =====================================================
export enum LayoutMode {
  /** 单列布局 */
  SINGLE = 'single',
  /** 双列布局 */
  DOUBLE = 'double',
  /** 三列布局 */
  TRIPLE = 'triple',
}

// =====================================================
// 导航模式
// =====================================================
export enum NavigationMode {
  /** 底部导航 (手机) */
  BOTTOM = 'bottom',
  /** 侧边图标导航 (折叠屏) */
  SIDE_ICON = 'side_icon',
  /** 侧边展开导航 (PC) */
  SIDE_EXPANDED = 'side_expanded',
}
