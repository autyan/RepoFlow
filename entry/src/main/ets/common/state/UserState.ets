import { GitHubUser } from '../../models/GitHubModels';

/**
 * 全局用户状态
 * 使用 AppStorage 实现跨页面状态共享
 */
export class UserState {
  private static instance: UserState | null = null;
  private _user: GitHubUser | null = null;
  private _isLoading: boolean = false;
  private listeners: Array<() => void> = [];

  private constructor() {}

  static getInstance(): UserState {
    if (!UserState.instance) {
      UserState.instance = new UserState();
    }
    return UserState.instance;
  }

  get user(): GitHubUser | null {
    return this._user;
  }

  get isLoggedIn(): boolean {
    return this._user !== null;
  }

  get isLoading(): boolean {
    return this._isLoading;
  }

  setUser(user: GitHubUser | null): void {
    this._user = user;
    this.notifyListeners();
  }

  setLoading(loading: boolean): void {
    this._isLoading = loading;
    this.notifyListeners();
  }

  addListener(listener: () => void): void {
    this.listeners.push(listener);
  }

  removeListener(listener: () => void): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(): void {
    this.listeners.forEach((listener) => {
      listener();
    });
  }

  clear(): void {
    this._user = null;
    this._isLoading = false;
    this.notifyListeners();
  }
}

// 导出单例
export const userState = UserState.getInstance();
