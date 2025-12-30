import ability from '@ohos.app.ability.common';
import { OAuthService, OAuthConfig } from './OAuthService';
import { GitHubApiService } from './GitHubApiService';
import { TokenStore } from '../common/security/TokenStore';
import { userState } from '../common/state/UserState';
import { LOCAL_OAUTH_CONFIG } from '../config/local.config';

type AbilityContext = ability.Context;

/**
 * 认证管理服务
 * 统一管理登录、登出、用户信息获取
 */
export class AuthManager {
  private static instance: AuthManager | null = null;
  private oauth: OAuthService;
  private tokenStore: TokenStore;
  private githubApi: GitHubApiService | null = null;
  private context: AbilityContext | null = null;

  private constructor() {
    this.oauth = new OAuthService();
    this.tokenStore = new TokenStore();
  }

  static getInstance(): AuthManager {
    if (!AuthManager.instance) {
      AuthManager.instance = new AuthManager();
    }
    return AuthManager.instance;
  }

  /**
   * 初始化（需在 EntryAbility 中调用）
   * 自动从 local.config.ets 加载 OAuth 配置
   */
  async init(context: AbilityContext, config?: OAuthConfig): Promise<void> {
    this.context = context;
    await this.tokenStore.init(context);
    await this.oauth.init(context);
    
    // 优先使用传入的配置，否则使用本地配置
    const oauthConfig: OAuthConfig = config || {
      clientId: LOCAL_OAUTH_CONFIG.clientId,
      clientSecret: LOCAL_OAUTH_CONFIG.clientSecret,
      callbackUrl: LOCAL_OAUTH_CONFIG.callbackUrl,
      scope: LOCAL_OAUTH_CONFIG.scope,
      tokenEndpoint: LOCAL_OAUTH_CONFIG.tokenEndpoint // 添加 Cloudflare Worker 端点
    };
    this.oauth.setConfig(oauthConfig);
    
    // 创建 GitHub API 服务
    this.githubApi = new GitHubApiService(() => this.tokenStore.getAccessToken());
    // 检查是否已登录
    await this.checkLoginStatus();
  }

  /**
   * 检查登录状态并加载用户信息
   */
  async checkLoginStatus(): Promise<boolean> {
    const token = this.tokenStore.getAccessToken();
    if (!token) {
      userState.setUser(null);
      return false;
    }
    try {
      userState.setLoading(true);
      const user = await this.githubApi!.getCurrentUser();
      userState.setUser(user);
      return true;
    } catch (error) {
      console.error('Failed to fetch user info:', JSON.stringify(error));
      // Token 可能失效
      userState.setUser(null);
      return false;
    } finally {
      userState.setLoading(false);
    }
  }

  /**
   * 获取授权 URL（用于打开浏览器登录）
   */
  getAuthUrl(): string {
    const state = this.oauth.generateState();
    return this.oauth.buildAuthorizeUrl(state);
  }

  /**
   * 打开登录页面（在系统浏览器中）
   */
  async openLoginPage(): Promise<void> {
    if (!this.context) {
      throw new Error('AuthManager not initialized');
    }
    const authUrl = this.getAuthUrl();
    console.info('Opening auth URL:', authUrl);
    // 使用 UIAbilityContext.openLink 打开系统浏览器
    const uiContext = this.context as ability.UIAbilityContext;
    await uiContext.openLink(authUrl, {
      appLinkingOnly: false
    });
  }

  /**
   * 处理 OAuth 回调
   */
  async handleCallback(code: string, state: string): Promise<boolean> {
    if (!this.context) {
      throw new Error('AuthManager not initialized');
    }
    try {
      console.info('AuthManager - handleCallback starting...');
      userState.setLoading(true);
      await this.oauth.handleAuthCallback(code, state, this.context);
      // Reload token from persistent storage after OAuth saved it
      await this.tokenStore.init(this.context);
      console.info('AuthManager - token after reload:', this.tokenStore.getAccessToken() ? 'present' : 'missing');
      console.info('AuthManager - token exchange completed, fetching user info...');
      // 获取用户信息
      const user = await this.githubApi!.getCurrentUser();
      console.info('AuthManager - user info received:', user?.login);
      userState.setUser(user);
      return true;
    } catch (error) {
      console.error('OAuth callback failed:', JSON.stringify(error));
      console.error('OAuth callback error message:', (error as Error)?.message);
      userState.setUser(null);
      return false;
    } finally {
      userState.setLoading(false);
    }
  }

  /**
   * 登出
   */
  async logout(): Promise<void> {
    await this.oauth.clearToken();
    userState.clear();
  }

  /**
   * 获取 GitHub API 服务
   */
  getGitHubApi(): GitHubApiService | null {
    return this.githubApi;
  }

  /**
   * 是否已登录
   */
  isLoggedIn(): boolean {
    return userState.isLoggedIn;
  }
}

// 导出单例
export const authManager = AuthManager.getInstance();
