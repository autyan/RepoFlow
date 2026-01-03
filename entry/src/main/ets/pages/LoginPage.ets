import { webview } from '@kit.ArkWeb';
import { authManager } from '../services/AuthManager';
import { promptAction } from '@kit.ArkUI';
import { ThemeManager, ThemeColors } from '../theme';
import { Spacing, FontSize } from '../theme/DesignTokens';
import { UIHelper } from '../common/ui';

@Entry
@Component
struct LoginPage {
  @State isLoading: boolean = true;
  @State loadProgress: number = 0;
  @State private colors: ThemeColors = ThemeManager.colors;
  private controller: webview.WebviewController = new webview.WebviewController();
  private authUrl: string = '';

  aboutToAppear(): void {
    this.authUrl = authManager.getAuthUrl();
    console.info('OAuth URL:', this.authUrl);

    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean) => {
      this.colors = colors;
    });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Text($r('app.string.cancel'))
            .fontSize(FontSize.BODY)
            .fontColor(this.colors.primary)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          UIHelper.goBack(this);
        })

        Text($r('app.string.login_github'))
          .fontSize(FontSize.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位
        Text('')
          .width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.MD, right: Spacing.MD })
      .backgroundColor(this.colors.surface)

      // 加载进度条
      if (this.isLoading) {
        Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color(this.colors.primary)
      }

      // WebView
      Web({ src: this.authUrl, controller: this.controller })
        .layoutWeight(1)
        .width('100%')
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onProgressChange((event) => {
          if (event) {
            this.loadProgress = event.newProgress;
            this.isLoading = event.newProgress < 100;
          }
        })
        .onPageEnd(() => {
          this.isLoading = false;
        })
        .onLoadIntercept((event) => {
          const url = event?.data?.toString() ?? '';
          console.info('WebView navigating to:', url);

          // 检查是否是 OAuth 回调
          if (url.startsWith('repoflow.autyan.app://auth/callback')) {
            console.info('Intercepted OAuth callback');
            this.handleOAuthCallback(url);
            return true; // 拦截此 URL
          }
          return false;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }

  private handleOAuthCallback(url: string): void {
    // 解析 URL 获取 code 和 state
    const queryIndex = url.indexOf('?');
    const query = queryIndex >= 0 ? url.substring(queryIndex + 1) : '';
    const params = this.parseQuery(query);
    const code = params.get('code') ?? '';
    const state = params.get('state') ?? '';

    console.info('OAuth callback - code:', code ? 'received' : 'missing', ', state:', state ? 'received' : 'missing');

    if (!code) {
      console.error('No authorization code received');
      UIHelper.showToast(this, $r('app.string.auth_failed_no_code'), 'Auth failed: no code');
      UIHelper.goBack(this);
      return;
    }

    // 显示加载提示
    this.isLoading = true;

    // 处理回调
    authManager.handleCallback(code, state)
      .then((success) => {
        console.info('OAuth callback result:', success ? 'success' : 'failed');
        if (success) {
          UIHelper.showToast(this, $r('app.string.login_success'), 'Login success');
        } else {
          UIHelper.showToast(this, $r('app.string.login_failed'), 'Login failed');
        }
        // 返回设置页
        UIHelper.goBack(this);
      })
      .catch((err: Error) => {
        console.error('OAuth callback error:', JSON.stringify(err));
        const errorMsg = UIHelper.getString(this, $r('app.string.login_error'), 'Login error: ') + 
          (err.message || UIHelper.getString(this, $r('app.string.unknown_error'), 'Unknown error'));
        UIHelper.showToast(this, null, errorMsg);
        UIHelper.goBack(this);
      });
  }

  private parseQuery(query: string): Map<string, string> {
    const map = new Map<string, string>();
    if (!query) {
      return map;
    }
    query.split('&').forEach((pair) => {
      if (!pair) {
        return;
      }
      const equalsIndex = pair.indexOf('=');
      const rawKey = equalsIndex >= 0 ? pair.substring(0, equalsIndex) : pair;
      const rawValue = equalsIndex >= 0 ? pair.substring(equalsIndex + 1) : '';
      if (rawKey) {
        map.set(decodeURIComponent(rawKey), decodeURIComponent(rawValue));
      }
    });
    return map;
  }
}
