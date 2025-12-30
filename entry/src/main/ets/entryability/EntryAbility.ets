import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { authManager } from '../services/AuthManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    
    // 初始化认证管理器
    await authManager.init(this.context);
    
    this.handleDeepLink(want);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onNewWant(want: Want): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    this.handleDeepLink(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  private handleDeepLink(want: Want): void {
    hilog.info(DOMAIN, 'oauth', 'handleDeepLink called, want.uri: %{public}s', want?.uri ?? 'null');
    
    if (!want || !want.uri) {
      hilog.info(DOMAIN, 'oauth', 'No URI in want');
      return;
    }
    const uri = want.uri;
    hilog.info(DOMAIN, 'oauth', 'Received URI: %{public}s', uri);
    
    const isCallback = uri.startsWith('repoflow.autyan.app://auth/callback');
    if (!isCallback) {
      hilog.info(DOMAIN, 'oauth', 'URI is not auth callback, ignoring');
      return;
    }
    
    hilog.info(DOMAIN, 'oauth', 'Processing OAuth callback...');
    const queryIndex = uri.indexOf('?');
    const query = queryIndex >= 0 ? uri.substring(queryIndex + 1) : '';
    const params = this.parseQuery(query);
    const code = params.get('code') ?? '';
    const state = params.get('state') ?? '';
    
    hilog.info(DOMAIN, 'oauth', 'OAuth code received: %{public}s, state: %{public}s', 
      code ? 'yes' : 'no', state ? 'yes' : 'no');
    
    // 使用 AuthManager 处理回调
    void authManager.handleCallback(code, state)
      .then((success) => {
        if (success) {
          hilog.info(DOMAIN, 'oauth', 'Login successful');
        } else {
          hilog.warn(DOMAIN, 'oauth', 'Login failed');
        }
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN, 'oauth', 'Callback handling failed: %{public}s', JSON.stringify(err));
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