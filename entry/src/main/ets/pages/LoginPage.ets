import { webview } from '@kit.ArkWeb';
import { authManager } from '../services/AuthManager';
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

const PRIMARY_TEXT = '#1F2328';
const ACCENT = '#0969DA';

@Entry
@Component
struct LoginPage {
  @State isLoading: boolean = true;
  @State loadProgress: number = 0;
  private controller: webview.WebviewController = new webview.WebviewController();
  private authUrl: string = '';

  aboutToAppear(): void {
    this.authUrl = authManager.getAuthUrl();
    console.info('OAuth URL:', this.authUrl);
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Text('取消')
            .fontSize(16)
            .fontColor(ACCENT)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

        Text('登录 GitHub')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位
        Text('')
          .width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 加载进度条
      if (this.isLoading) {
        Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color(ACCENT)
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
        .onUrlLoadIntercept((event) => {
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
    .backgroundColor('#FFFFFF')
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
      promptAction.showToast({ message: '授权失败：未获取到授权码' });
      router.back();
      return;
    }

    // 显示加载提示
    this.isLoading = true;

    // 处理回调
    authManager.handleCallback(code, state)
      .then((success) => {
        console.info('OAuth callback result:', success ? 'success' : 'failed');
        if (success) {
          promptAction.showToast({ message: '登录成功' });
        } else {
          promptAction.showToast({ message: '登录失败' });
        }
        // 返回设置页
        router.back();
      })
      .catch((err: Error) => {
        console.error('OAuth callback error:', JSON.stringify(err));
        promptAction.showToast({ message: '登录失败：' + (err.message || '未知错误') });
        router.back();
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
