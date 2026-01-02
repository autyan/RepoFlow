/**
 * RepoFlow 响应式管理器
 * 
 * 提供设备类型检测和响应式布局支持:
 * - 手机 / 折叠屏 / 平板 / 桌面 设备类型检测
 * - 布局模式自动切换
 * - 导航模式适配
 * - 折叠屏状态监听
 */

import { display, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Breakpoint, DeviceType, LayoutMode, NavigationMode } from './DesignTokens';

// =====================================================
// 响应式状态接口
// =====================================================
export interface ResponsiveState {
  /** 屏幕宽度 (vp) */
  screenWidth: number;
  /** 屏幕高度 (vp) */
  screenHeight: number;
  /** 设备类型 */
  deviceType: DeviceType;
  /** 布局模式 */
  layoutMode: LayoutMode;
  /** 导航模式 */
  navigationMode: NavigationMode;
  /** 是否为折叠屏展开状态 */
  isFoldableExpanded: boolean;
  /** 是否为横屏 */
  isLandscape: boolean;
  /** 折叠屏折叠状态 */
  foldStatus: display.FoldStatus;
}

// =====================================================
// 响应式变更回调类型
// =====================================================
export type ResponsiveChangeCallback = (state: ResponsiveState) => void;

// =====================================================
// 响应式管理器类
// =====================================================
class ResponsiveManagerImpl {
  private _state: ResponsiveState = {
    screenWidth: 360,
    screenHeight: 780,
    deviceType: DeviceType.PHONE,
    layoutMode: LayoutMode.SINGLE,
    navigationMode: NavigationMode.BOTTOM,
    isFoldableExpanded: false,
    isLandscape: false,
    foldStatus: display.FoldStatus.FOLD_STATUS_UNKNOWN,
  };
  
  private _listeners: Set<ResponsiveChangeCallback> = new Set();
  private _initialized: boolean = false;
  private _windowStage: window.WindowStage | null = null;
  private _displayCallback: ((status: display.FoldStatus) => void) | null = null;
  
  // =====================================================
  // 初始化
  // =====================================================
  
  /**
   * 初始化响应式管理器
   * @param windowStage 窗口舞台
   */
  async init(windowStage: window.WindowStage): Promise<void> {
    if (this._initialized) return;
    
    this._windowStage = windowStage;
    
    try {
      // 获取主窗口
      const mainWindow = await windowStage.getMainWindow();
      
      // 获取窗口属性
      const properties = await mainWindow.getWindowProperties();
      const rect = properties.windowRect;
      
      // 获取显示器信息以转换为 vp
      const displayInfo = display.getDefaultDisplaySync();
      const density = displayInfo.densityPixels;
      
      // 计算屏幕尺寸 (vp)
      this._state.screenWidth = px2vp(rect.width);
      this._state.screenHeight = px2vp(rect.height);
      
      // 更新设备类型和布局
      this.updateDeviceInfo();
      
      // 监听窗口尺寸变化
      mainWindow.on('windowSizeChange', (size) => {
        this._state.screenWidth = px2vp(size.width);
        this._state.screenHeight = px2vp(size.height);
        this.updateDeviceInfo();
        this.notifyListeners();
      });
      
      // 监听折叠屏状态 (如果是折叠屏设备)
      this.setupFoldableListener();
      
      this._initialized = true;
      
      // 通知初始状态
      this.notifyListeners();
      
    } catch (err) {
      console.error('ResponsiveManager init failed:', JSON.stringify(err));
    }
  }
  
  // =====================================================
  // 属性访问器
  // =====================================================
  
  /** 获取当前响应式状态 */
  get state(): ResponsiveState {
    return this.copyState();
  }
  
  /** 复制当前状态 */
  private copyState(): ResponsiveState {
    return {
      screenWidth: this._state.screenWidth,
      screenHeight: this._state.screenHeight,
      deviceType: this._state.deviceType,
      layoutMode: this._state.layoutMode,
      navigationMode: this._state.navigationMode,
      isFoldableExpanded: this._state.isFoldableExpanded,
      isLandscape: this._state.isLandscape,
      foldStatus: this._state.foldStatus,
    };
  }
  
  /** 获取屏幕宽度 */
  get screenWidth(): number {
    return this._state.screenWidth;
  }
  
  /** 获取屏幕高度 */
  get screenHeight(): number {
    return this._state.screenHeight;
  }
  
  /** 获取设备类型 */
  get deviceType(): DeviceType {
    return this._state.deviceType;
  }
  
  /** 获取布局模式 */
  get layoutMode(): LayoutMode {
    return this._state.layoutMode;
  }
  
  /** 获取导航模式 */
  get navigationMode(): NavigationMode {
    return this._state.navigationMode;
  }
  
  /** 是否为手机 */
  get isPhone(): boolean {
    return this._state.deviceType === DeviceType.PHONE;
  }
  
  /** 是否为折叠屏 */
  get isFoldable(): boolean {
    return this._state.deviceType === DeviceType.FOLDABLE;
  }
  
  /** 是否为平板 */
  get isTablet(): boolean {
    return this._state.deviceType === DeviceType.TABLET;
  }
  
  /** 是否为桌面 */
  get isDesktop(): boolean {
    return this._state.deviceType === DeviceType.DESKTOP;
  }
  
  /** 是否为大屏幕 (平板或桌面) */
  get isLargeScreen(): boolean {
    return this.isTablet || this.isDesktop;
  }
  
  /** 是否折叠屏展开 */
  get isFoldableExpanded(): boolean {
    return this._state.isFoldableExpanded;
  }
  
  /** 是否为横屏 */
  get isLandscape(): boolean {
    return this._state.isLandscape;
  }
  
  // =====================================================
  // 监听器管理
  // =====================================================
  
  /**
   * 订阅响应式状态变化
   * @param callback 回调函数
   * @returns 取消订阅函数
   */
  subscribe(callback: ResponsiveChangeCallback): () => void {
    this._listeners.add(callback);
    // 立即通知当前状态
    callback(this._state);
    // 返回取消订阅函数
    return () => this._listeners.delete(callback);
  }
  
  /**
   * 取消订阅
   * @param callback 回调函数
   */
  unsubscribe(callback: ResponsiveChangeCallback): void {
    this._listeners.delete(callback);
  }
  
  // =====================================================
  // 布局辅助方法
  // =====================================================
  
  /**
   * 根据设备类型返回对应值
   * @param phone 手机值
   * @param foldable 折叠屏值
   * @param tablet 平板值
   * @param desktop 桌面值
   */
  getByDeviceType<T>(phone: T, foldable?: T, tablet?: T, desktop?: T): T {
    switch (this._state.deviceType) {
      case DeviceType.DESKTOP:
        return desktop ?? tablet ?? foldable ?? phone;
      case DeviceType.TABLET:
        return tablet ?? foldable ?? phone;
      case DeviceType.FOLDABLE:
        return foldable ?? phone;
      default:
        return phone;
    }
  }
  
  /**
   * 根据布局模式返回对应值
   * @param single 单栏值
   * @param double 双栏值
   * @param triple 三栏值
   */
  getByLayoutMode<T>(single: T, double?: T, triple?: T): T {
    switch (this._state.layoutMode) {
      case LayoutMode.TRIPLE:
        return triple ?? double ?? single;
      case LayoutMode.DOUBLE:
        return double ?? single;
      default:
        return single;
    }
  }
  
  /**
   * 获取内容最大宽度
   * 大屏幕时限制内容宽度以提高可读性
   */
  getContentMaxWidth(): number | string {
    if (this.isDesktop) {
      return 1200; // 桌面最大 1200vp
    } else if (this.isTablet || (this.isFoldable && this.isFoldableExpanded)) {
      return 900; // 平板/折叠屏展开最大 900vp
    }
    return '100%'; // 手机全宽
  }
  
  /**
   * 获取列表项宽度 (网格布局)
   */
  getGridItemWidth(): string {
    switch (this._state.layoutMode) {
      case LayoutMode.TRIPLE:
        return '33.33%';
      case LayoutMode.DOUBLE:
        return '50%';
      default:
        return '100%';
    }
  }
  
  /**
   * 获取网格列数
   */
  getGridColumns(): number {
    switch (this._state.layoutMode) {
      case LayoutMode.TRIPLE:
        return 3;
      case LayoutMode.DOUBLE:
        return 2;
      default:
        return 1;
    }
  }
  
  /**
   * 获取导航栏宽度
   */
  getNavigationWidth(): number {
    switch (this._state.navigationMode) {
      case NavigationMode.SIDE_EXPANDED:
        return 280;
      case NavigationMode.SIDE_ICON:
        return 72;
      default:
        return 0;
    }
  }
  
  /**
   * 判断是否应该显示侧边导航
   */
  shouldShowSideNavigation(): boolean {
    return this._state.navigationMode !== NavigationMode.BOTTOM;
  }
  
  /**
   * 判断是否应该显示底部导航
   */
  shouldShowBottomNavigation(): boolean {
    return this._state.navigationMode === NavigationMode.BOTTOM;
  }
  
  // =====================================================
  // 私有方法
  // =====================================================
  
  /**
   * 更新设备信息
   */
  private updateDeviceInfo(): void {
    const width = this._state.screenWidth;
    const height = this._state.screenHeight;
    
    // 更新横竖屏状态
    this._state.isLandscape = width > height;
    
    // 更新设备类型
    this._state.deviceType = this.calculateDeviceType(width);
    
    // 更新布局模式
    this._state.layoutMode = this.calculateLayoutMode(width);
    
    // 更新导航模式
    this._state.navigationMode = this.calculateNavigationMode(width);
  }
  
  /**
   * 计算设备类型
   */
  private calculateDeviceType(width: number): DeviceType {
    // 检查是否为折叠屏设备
    if (this._state.foldStatus !== display.FoldStatus.FOLD_STATUS_UNKNOWN) {
      return DeviceType.FOLDABLE;
    }
    
    if (width < Breakpoint.SM) {
      return DeviceType.PHONE;
    } else if (width < Breakpoint.MD) {
      // 可能是大手机或小平板
      return DeviceType.PHONE;
    } else if (width < Breakpoint.LG) {
      return DeviceType.TABLET;
    } else {
      return DeviceType.DESKTOP;
    }
  }
  
  /**
   * 计算布局模式
   */
  private calculateLayoutMode(width: number): LayoutMode {
    if (width >= Breakpoint.LG) {
      return LayoutMode.TRIPLE;
    } else if (width >= Breakpoint.MD) {
      return LayoutMode.DOUBLE;
    } else {
      return LayoutMode.SINGLE;
    }
  }
  
  /**
   * 计算导航模式
   */
  private calculateNavigationMode(width: number): NavigationMode {
    if (width >= Breakpoint.LG) {
      return NavigationMode.SIDE_EXPANDED;
    } else if (width >= Breakpoint.MD) {
      return NavigationMode.SIDE_ICON;
    } else {
      return NavigationMode.BOTTOM;
    }
  }
  
  /**
   * 设置折叠屏监听
   */
  private setupFoldableListener(): void {
    try {
      // 检查是否支持折叠屏
      const isFoldable = display.isFoldable();
      
      if (isFoldable) {
        // 获取当前折叠状态
        const foldStatus = display.getFoldStatus();
        this._state.foldStatus = foldStatus;
        this._state.isFoldableExpanded = foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED;
        this._state.deviceType = DeviceType.FOLDABLE;
        
        // 监听折叠状态变化
        this._displayCallback = (status: display.FoldStatus) => {
          this._state.foldStatus = status;
          this._state.isFoldableExpanded = status === display.FoldStatus.FOLD_STATUS_EXPANDED;
          
          // 重新计算布局模式
          if (status === display.FoldStatus.FOLD_STATUS_EXPANDED) {
            // 展开时使用双栏布局
            this._state.layoutMode = LayoutMode.DOUBLE;
            this._state.navigationMode = NavigationMode.SIDE_ICON;
          } else {
            // 折叠时使用单栏布局
            this._state.layoutMode = LayoutMode.SINGLE;
            this._state.navigationMode = NavigationMode.BOTTOM;
          }
          
          this.notifyListeners();
        };
        
        display.on('foldStatusChange', this._displayCallback);
      }
    } catch (err) {
      // 非折叠屏设备或 API 不支持
      console.info('Foldable detection not available:', JSON.stringify(err));
    }
  }
  
  /**
   * 通知监听器
   */
  private notifyListeners(): void {
    const state = this.state; // 获取副本
    this._listeners.forEach(callback => {
      try {
        callback(state);
      } catch (err) {
        console.error('Responsive listener error:', JSON.stringify(err));
      }
    });
  }
  
  /**
   * 清理资源
   */
  destroy(): void {
    if (this._displayCallback) {
      try {
        display.off('foldStatusChange', this._displayCallback);
      } catch {
        // 忽略
      }
      this._displayCallback = null;
    }
    this._listeners.clear();
    this._initialized = false;
  }
}

// =====================================================
// 导出单例实例
// =====================================================
export const ResponsiveManager = new ResponsiveManagerImpl();

// =====================================================
// 便捷函数导出
// =====================================================

/**
 * 获取当前设备类型
 */
export function getDeviceType(): DeviceType {
  return ResponsiveManager.deviceType;
}

/**
 * 获取当前布局模式
 */
export function getLayoutMode(): LayoutMode {
  return ResponsiveManager.layoutMode;
}

/**
 * 判断是否为大屏幕设备
 */
export function isLargeScreen(): boolean {
  return ResponsiveManager.isLargeScreen;
}
