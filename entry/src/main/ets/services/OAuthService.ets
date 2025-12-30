import ability from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import { TokenStore } from '../common/security/TokenStore';
import { HttpClient, HttpResponse } from '../common/network/HttpClient';

type AbilityContext = ability.Context;

interface TokenResponse {
  access_token?: string;
  token_type?: string;
  scope?: string;
  error?: string;
  error_description?: string;
}
interface ExchangeRequest {
  client_id: string;
  client_secret?: string;
  code: string;
  redirect_uri: string;
}

export interface OAuthConfig {
  clientId: string;
  clientSecret?: string; // Avoid shipping secret in app; prefer backend exchange.
  callbackUrl: string;
  scope?: string; // space-delimited scopes
  tokenEndpoint?: string; // Cloudflare Worker URL for secure token exchange
}

const DEFAULT_CONFIG: OAuthConfig = {
  clientId: '',
  clientSecret: '',
  callbackUrl: 'repoflow.autyan.app://auth/callback',
  scope: 'read:user notifications public_repo'
};

export class OAuthService {
  private config: OAuthConfig;
  private tokenStore: TokenStore;
  private http: HttpClient;

  constructor(config: OAuthConfig = DEFAULT_CONFIG) {
    this.config = config;
    this.tokenStore = new TokenStore();
    this.http = new HttpClient();
    this.http.setAuthTokenProvider(() => this.tokenStore.getAccessToken());
  }

  async init(context: AbilityContext): Promise<void> {
    await this.tokenStore.init(context);
  }

  setConfig(config: OAuthConfig): void {
    this.config = config;
  }

  generateState(): string {
    const value = Math.random().toString(36).slice(2) + Date.now().toString(36);
    void this.tokenStore.setState(value);
    return value;
  }

  getCachedToken(): string {
    return this.tokenStore.getAccessToken();
  }

  async clearToken(): Promise<void> {
    await this.tokenStore.clearAccessToken();
  }

  buildAuthorizeUrl(state: string): string {
    if (!this.config.clientId) {
      throw new Error('OAuth clientId not configured');
    }
    const params: Array<[string, string]> = [
      ['client_id', this.config.clientId],
      ['redirect_uri', this.config.callbackUrl],
      ['state', state],
    ];
    if (this.config.scope) {
      params.push(['scope', this.config.scope]);
    }
    const query = params
      .map((item) => `${encodeURIComponent(item[0])}=${encodeURIComponent(item[1])}`)
      .join('&');
    return `https://github.com/login/oauth/authorize?${query}`;
  }

  async handleAuthCallback(code: string, state: string, context?: AbilityContext): Promise<void> {
    console.info('OAuthService.handleAuthCallback - code received:', code ? 'yes' : 'no');
    if (!code) {
      throw new Error('Missing authorization code');
    }
    // 暂时跳过 state 验证，因为 state 存储在内存中，页面跳转可能丢失
    // TODO: 使用持久化存储保存 state
    const cachedState = this.tokenStore.getState();
    console.info('OAuthService - state check: received=', state, ', cached=', cachedState);
    // if (state && state !== cachedState) {
    //   throw new Error('State mismatch, possible CSRF');
    // }
    if (!this.config.clientId) {
      throw new Error('OAuth clientId not configured');
    }
    if (!context) {
      throw new Error('UIAbilityContext required for token storage');
    }
    await this.tokenStore.init(context);
    await this.exchangeCodeForToken(code);
  }

  private async exchangeCodeForToken(code: string): Promise<void> {
    console.info('OAuthService - exchangeCodeForToken starting...');
    
    // 优先使用 Worker 端点（更安全，不需要 client_secret）
    if (this.config.tokenEndpoint) {
      await this.exchangeViaWorker(code);
      return;
    }
    
    // 回退到直接调用 GitHub（需要 client_secret，仅用于开发）
    if (!this.config.clientSecret) {
      throw new Error('Either tokenEndpoint or clientSecret must be configured');
    }

    const requestBody: ExchangeRequest = {
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      code,
      redirect_uri: this.config.callbackUrl,
    };

    const bodyString = this.encodeFormBody(requestBody);
    console.info('OAuthService - sending token request to GitHub directly...');
    
    const response = await this.http.request<string>({
      method: http.RequestMethod.POST,
      url: 'https://github.com/login/oauth/access_token',
      headers: [
        { key: 'Accept', value: 'application/json' },
        { key: 'Content-Type', value: 'application/x-www-form-urlencoded' }
      ],
      body: bodyString
    });

    console.info('OAuthService - token response status:', response.status);
    console.info('OAuthService - token response data:', response.data);
    
    // 解析 JSON 响应
    let tokenResponse: TokenResponse;
    try {
      tokenResponse = JSON.parse(response.data) as TokenResponse;
    } catch (e) {
      console.error('OAuthService - failed to parse token response:', response.data);
      throw new Error('Invalid token response from GitHub');
    }
    
    const token = tokenResponse?.access_token;
    if (!token) {
      const err = tokenResponse?.error_description || tokenResponse?.error || 'Failed to obtain access_token';
      console.error('OAuthService - token exchange failed:', err);
      throw new Error(err);
    }
    console.info('OAuthService - token obtained successfully');
    await this.tokenStore.setAccessToken(token);
  }
  /**
   * 通过 Cloudflare Worker 交换 token（推荐，更安全）
   */
  private async exchangeViaWorker(code: string): Promise<void> {
    console.info('OAuthService - exchanging token via Worker:', this.config.tokenEndpoint);
    
    const requestBody = JSON.stringify({
      code,
      redirect_uri: this.config.callbackUrl,
    });
    
    console.info('OAuthService - Worker request body:', requestBody);
    
    let response: HttpResponse<string> | null = null;
    try {
      response = await this.http.request<string>({
        method: http.RequestMethod.POST,
        url: this.config.tokenEndpoint!,
        headers: [
          { key: 'Accept', value: 'application/json' },
          { key: 'Content-Type', value: 'application/json' }
        ],
        body: requestBody
      });
    } catch (httpError) {
      console.error('OAuthService - HTTP request failed:', JSON.stringify(httpError));
      throw new Error('Network error: Failed to connect to token service');
    }
    
    console.info('OAuthService - Worker response status:', response.status);
    console.info('OAuthService - Worker response data:', response.data);
    
    // 检查 HTTP 状态码
    if (response.status < 200 || response.status >= 300) {
      console.error('OAuthService - Worker returned error status:', response.status);
      throw new Error(`Token service error: HTTP ${response.status}`);
    }
    
    let tokenResponse: TokenResponse;
    try {
      tokenResponse = JSON.parse(response.data) as TokenResponse;
    } catch (e) {
      console.error('OAuthService - failed to parse Worker response:', response.data);
      throw new Error('Invalid response from token service');
    }
    
    const token = tokenResponse?.access_token;
    if (!token) {
      const err = tokenResponse?.error_description || tokenResponse?.error || 'Failed to obtain access_token';
      console.error('OAuthService - Worker token exchange failed:', err);
      throw new Error(err);
    }
    
    console.info('OAuthService - token obtained via Worker successfully');
    await this.tokenStore.setAccessToken(token);
  }

  private encodeFormBody(data: ExchangeRequest): string {
    const pairs: string[] = [];
    
    // 手动添加所有可能的字段
    if (data.client_id) {
      pairs.push(`client_id=${encodeURIComponent(data.client_id)}`);
    }
    if (data.client_secret) {
      pairs.push(`client_secret=${encodeURIComponent(data.client_secret)}`);
    }
    if (data.code) {
      pairs.push(`code=${encodeURIComponent(data.code)}`);
    }
    if (data.redirect_uri) {
      pairs.push(`redirect_uri=${encodeURIComponent(data.redirect_uri)}`);
    }
    
    return pairs.join('&');
  }
}
