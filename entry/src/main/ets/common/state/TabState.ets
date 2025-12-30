/**
 * 全局 Tab 状态管理
 * 用于在子页面中切换主 Tab
 */

type TabChangeCallback = (index: number) => void;

class TabState {
  private listeners: TabChangeCallback[] = [];
  private _currentIndex: number = 0;

  get currentIndex(): number {
    return this._currentIndex;
  }

  set currentIndex(value: number) {
    this._currentIndex = value;
  }

  addListener(callback: TabChangeCallback): void {
    this.listeners.push(callback);
  }

  removeListener(callback: TabChangeCallback): void {
    const index = this.listeners.indexOf(callback);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  switchToTab(index: number): void {
    this._currentIndex = index;
    this.listeners.forEach(listener => {
      listener(index);
    });
  }

  // 便捷方法
  switchToHome(): void {
    this.switchToTab(0);
  }

  switchToRepos(): void {
    this.switchToTab(1);
  }

  switchToNotifications(): void {
    this.switchToTab(2);
  }

  switchToProfile(): void {
    this.switchToTab(3);
  }
}

export const tabState = new TabState();
