/**
 * RepoFlow 主题管理器
 * 
 * 提供主题切换功能，支持:
 * - 跟随系统主题
 * - 手动切换亮色/暗色主题
 * - 主题状态持久化
 * - 响应系统主题变化
 */

import { DarkColors, LightColors, ThemeColors } from './Colors';
import { preferences } from '@kit.ArkData';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';

// =====================================================
// 主题模式枚举
// =====================================================
export enum ThemeMode {
  /** 跟随系统 */
  SYSTEM = 'system',
  /** 亮色主题 */
  LIGHT = 'light',
  /** 暗色主题 */
  DARK = 'dark',
}

// =====================================================
// 主题变更回调类型
// =====================================================
export type ThemeChangeCallback = (colors: ThemeColors, isDark: boolean) => void;

// =====================================================
// 主题管理器类
// =====================================================
class ThemeManagerImpl {
  private _currentMode: ThemeMode = ThemeMode.SYSTEM;
  private _isDark: boolean = true;
  private _colors: ThemeColors = DarkColors;
  private _listeners: Set<ThemeChangeCallback> = new Set();
  private _initialized: boolean = false;
  private _context: common.UIAbilityContext | null = null;
  private _preferencesStore: preferences.Preferences | null = null;
  
  private static readonly PREF_NAME = 'theme_preferences';
  private static readonly KEY_THEME_MODE = 'theme_mode';
  
  // =====================================================
  // 初始化
  // =====================================================
  
  /**
   * 初始化主题管理器
   * @param context 应用上下文
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this._initialized) return;
    
    this._context = context;
    
    try {
      // 获取偏好存储
      this._preferencesStore = await preferences.getPreferences(
        context,
        ThemeManagerImpl.PREF_NAME
      );
      
      // 加载保存的主题设置
      await this.loadThemePreference();
      
      // 应用主题
      this.applyTheme();
      
      this._initialized = true;
    } catch (err) {
      console.error('ThemeManager init failed:', JSON.stringify(err));
      // 使用默认暗色主题
      this._colors = DarkColors;
      this._isDark = true;
    }
  }
  
  // =====================================================
  // 属性访问器
  // =====================================================
  
  /** 获取当前主题模式 */
  get currentMode(): ThemeMode {
    return this._currentMode;
  }
  
  /** 获取当前是否为暗色主题 */
  get isDark(): boolean {
    return this._isDark;
  }
  
  /** 获取当前主题颜色 */
  get colors(): ThemeColors {
    return this._colors;
  }
  
  /** 获取是否已初始化 */
  get initialized(): boolean {
    return this._initialized;
  }
  
  // =====================================================
  // 主题切换方法
  // =====================================================
  
  /**
   * 设置主题模式
   * @param mode 主题模式
   */
  async setThemeMode(mode: ThemeMode): Promise<void> {
    if (this._currentMode === mode) return;
    
    this._currentMode = mode;
    
    // 保存到偏好设置
    await this.saveThemePreference();
    
    // 设置系统颜色模式（需要在 applyTheme 之前）
    this.setSystemColorMode(mode);
    
    // 应用主题
    this.applyTheme();
  }
  
  /**
   * 切换主题 (在亮色和暗色之间切换)
   */
  async toggleTheme(): Promise<void> {
    if (this._currentMode === ThemeMode.SYSTEM) {
      // 如果当前是跟随系统，则切换到手动模式
      await this.setThemeMode(this._isDark ? ThemeMode.LIGHT : ThemeMode.DARK);
    } else {
      // 在亮色和暗色之间切换
      await this.setThemeMode(
        this._currentMode === ThemeMode.DARK ? ThemeMode.LIGHT : ThemeMode.DARK
      );
    }
  }
  
  /**
   * 设置为跟随系统
   */
  async setFollowSystem(): Promise<void> {
    await this.setThemeMode(ThemeMode.SYSTEM);
  }
  
  // =====================================================
  // 监听器管理
  // =====================================================
  
  /**
   * 添加主题变更监听器
   * @param callback 回调函数
   * @returns 取消订阅函数
   */
  subscribe(callback: ThemeChangeCallback): () => void {
    this._listeners.add(callback);
    // 立即通知当前状态
    callback(this._colors, this._isDark);
    // 返回取消订阅函数
    return () => this._listeners.delete(callback);
  }
  
  /**
   * 移除主题变更监听器
   * @param callback 回调函数
   */
  unsubscribe(callback: ThemeChangeCallback): void {
    this._listeners.delete(callback);
  }
  
  // =====================================================
  // 系统主题变更处理
  // =====================================================
  
  /**
   * 处理系统主题变更 (由 EntryAbility 调用)
   * @param colorMode 系统颜色模式
   */
  onSystemThemeChange(colorMode: ConfigurationConstant.ColorMode): void {
    if (this._currentMode !== ThemeMode.SYSTEM) return;
    
    // 根据系统主题更新
    this._isDark = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    this._colors = this._isDark ? DarkColors : LightColors;
    
    // 通知监听器
    this.notifyListeners();
  }
  
  // =====================================================
  // 私有方法
  // =====================================================
  
  /**
   * 应用主题
   */
  private applyTheme(): void {
    switch (this._currentMode) {
      case ThemeMode.DARK:
        this._isDark = true;
        this._colors = DarkColors;
        break;
      case ThemeMode.LIGHT:
        this._isDark = false;
        this._colors = LightColors;
        break;
      case ThemeMode.SYSTEM:
        // 检测系统主题
        this._isDark = this.getSystemIsDark();
        this._colors = this._isDark ? DarkColors : LightColors;
        break;
    }
    
    // 通知所有监听器
    this.notifyListeners();
  }
  
  /**
   * 获取系统是否为暗色模式
   */
  private getSystemIsDark(): boolean {
    if (!this._context) return true;
    
    try {
      const config = this._context.config;
      return config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    } catch {
      return true; // 默认暗色
    }
  }
  
  /**
   * 设置系统颜色模式
   */
  private setSystemColorMode(mode: ThemeMode): void {
    if (!this._context) return;
    
    try {
      let colorMode: ConfigurationConstant.ColorMode;
      
      switch (mode) {
        case ThemeMode.DARK:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
          break;
        case ThemeMode.LIGHT:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
          break;
        case ThemeMode.SYSTEM:
        default:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
          break;
      }
      
      this._context.getApplicationContext().setColorMode(colorMode);
    } catch (err) {
      console.error('Failed to set color mode:', JSON.stringify(err));
    }
  }
  
  /**
   * 通知所有监听器
   */
  private notifyListeners(): void {
    this._listeners.forEach(callback => {
      try {
        callback(this._colors, this._isDark);
      } catch (err) {
        console.error('Theme listener error:', JSON.stringify(err));
      }
    });
  }
  
  /**
   * 加载主题偏好设置
   */
  private async loadThemePreference(): Promise<void> {
    if (!this._preferencesStore) return;
    
    try {
      const savedMode = await this._preferencesStore.get(
        ThemeManagerImpl.KEY_THEME_MODE,
        ThemeMode.SYSTEM
      ) as ThemeMode;
      
      this._currentMode = savedMode;
    } catch (err) {
      console.error('Failed to load theme preference:', JSON.stringify(err));
      this._currentMode = ThemeMode.SYSTEM;
    }
  }
  
  /**
   * 保存主题偏好设置
   */
  private async saveThemePreference(): Promise<void> {
    if (!this._preferencesStore) return;
    
    try {
      await this._preferencesStore.put(
        ThemeManagerImpl.KEY_THEME_MODE,
        this._currentMode
      );
      await this._preferencesStore.flush();
    } catch (err) {
      console.error('Failed to save theme preference:', JSON.stringify(err));
    }
  }
}

// =====================================================
// 导出单例实例
// =====================================================
export const ThemeManager = new ThemeManagerImpl();

// =====================================================
// 便捷函数导出
// =====================================================

/**
 * 获取当前主题颜色
 */
export function getColors(): ThemeColors {
  return ThemeManager.colors;
}

/**
 * 获取当前是否为暗色主题
 */
export function isDarkTheme(): boolean {
  return ThemeManager.isDark;
}
