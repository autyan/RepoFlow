/**
 * UIHelper - UIContext 统一工具类
 * 
 * 提供安全的 UI 操作封装，自动处理异常
 * 包括：资源加载、Toast 显示、导航、剪贴板等
 */

import pasteboard from '@ohos.pasteboard';
import resourceManager from '@ohos.resourceManager';

// 定义组件接口（支持 getUIContext）
interface ComponentContext {
  getUIContext(): UIContext | undefined;
}

export class UIHelper {
  /**
   * 加载字符串资源（带回退）
   * @param context - 组件的 this 引用
   * @param resource - 资源对象 $r('app.string.xxx')
   * @param fallback - 加载失败时的回退文本
   * @param params - 可选的字符串替换参数
   * @returns 本地化字符串或回退文本
   */
  static getString(
    context: ComponentContext,
    resource: Resource | null,
    fallback: string,
    ...params: (string | number)[]
  ): string {
    try {
      const uiContext = context.getUIContext();
      if (!uiContext) {
        console.warn('UIContext not available, using fallback');
        return fallback;
      }
      
      const hostContext = uiContext.getHostContext();
      if (!hostContext) {
        console.warn('HostContext not available, using fallback');
        return fallback;
      }

      const rm = hostContext.resourceManager;
      if (!rm) {
        console.warn('ResourceManager not available, using fallback');
        return fallback;
      }

      if (!resource) {
        return fallback;
      }

      let text = rm.getStringSync(resource.id);
      
      // 处理参数替换
      if (params.length > 0) {
        params.forEach((param: string | number, index: number) => {
          text = text.replace(`%${index + 1}`, String(param))
                    .replace('%s', String(param))
                    .replace('%d', String(param));
        });
      }
      
      return text;
    } catch (error) {
      console.error('Failed to load string resource:', error);
      return fallback;
    }
  }

  /**
   * 显示 Toast 消息（带资源加载回退）
   * @param context - 组件的 this 引用
   * @param resource - 资源对象（可选，传 null 则直接显示 fallback）
   * @param fallback - 回退消息文本
   * @param params - 可选的字符串替换参数
   */
  static showToast(
    context: ComponentContext,
    resource: Resource | null,
    fallback: string,
    ...params: (string | number)[]
  ): void {
    try {
      const uiContext = context.getUIContext();
      if (!uiContext) {
        console.error('UIContext not available, cannot show toast');
        return;
      }

      const promptAction = uiContext.getPromptAction();
      if (!promptAction) {
        console.error('PromptAction not available, cannot show toast');
        return;
      }

      let message = fallback;
      
      // 尝试加载资源文本
      if (resource) {
        try {
          const hostContext = uiContext.getHostContext();
          if (hostContext) {
            const rm = hostContext.resourceManager;
            if (rm) {
              message = rm.getStringSync(resource.id);
              
              // 处理参数替换
              params.forEach((param: string | number, index: number) => {
                message = message.replace(`%${index + 1}`, String(param))
                                .replace('%s', String(param))
                                .replace('%d', String(param));
              });
            }
          }
        } catch (e) {
          console.warn('Failed to load toast resource, using fallback:', e);
        }
      }

      promptAction.showToast({ message });
    } catch (error) {
      console.error('Failed to show toast:', error);
    }
  }

  /**
   * 返回上一页
   * @param context - 组件的 this 引用
   * @param silent - 是否静默失败（不打印错误日志）
   * @returns 是否成功
   */
  static goBack(context: ComponentContext, silent: boolean = false): boolean {
    try {
      const uiContext = context.getUIContext();
      if (!uiContext) {
        if (!silent) console.error('UIContext not available');
        return false;
      }

      const router = uiContext.getRouter();
      if (!router) {
        if (!silent) console.error('Router not available');
        return false;
      }

      router.back();
      return true;
    } catch (error) {
      if (!silent) console.error('Navigation back failed:', error);
      return false;
    }
  }

  /**
   * 跳转到指定页面
   * @param context - 组件的 this 引用
   * @param url - 页面路径
   * @param params - 可选的参数对象
   * @returns 是否成功
   */
  static pushUrl(
    context: ComponentContext,
    url: string,
    params?: ESObject
  ): boolean {
    try {
      const uiContext = context.getUIContext();
      if (!uiContext) {
        console.error('UIContext not available');
        return false;
      }

      const router = uiContext.getRouter();
      if (!router) {
        console.error('Router not available');
        return false;
      }

      router.pushUrl({ url, params });
      return true;
    } catch (error) {
      console.error('Navigation push failed:', error);
      return false;
    }
  }

  /**
   * 替换当前页面（不添加历史记录）
   * @param context - 组件的 this 引用
   * @param url - 页面路径
   * @param params - 可选的参数对象
   * @returns 是否成功
   */
  static replaceUrl(
    context: ComponentContext,
    url: string,
    params?: ESObject
  ): boolean {
    try {
      const uiContext = context.getUIContext();
      if (!uiContext) {
        console.error('UIContext not available');
        return false;
      }

      const router = uiContext.getRouter();
      if (!router) {
        console.error('Router not available');
        return false;
      }

      router.replaceUrl({ url, params });
      return true;
    } catch (error) {
      console.error('Navigation replace failed:', error);
      return false;
    }
  }

  /**
   * 获取路由参数
   * @param context - 组件的 this 引用
   * @returns 参数对象或 null
   */
  static getRouteParams<T = Object>(context: ComponentContext): T | null {
    try {
      const uiContext = context.getUIContext();
      if (!uiContext) {
        console.error('UIContext not available');
        return null;
      }

      const router = uiContext.getRouter();
      if (!router) {
        console.error('Router not available');
        return null;
      }

      return router.getParams() as T;
    } catch (error) {
      console.error('Failed to get route params:', error);
      return null;
    }
  }

  /**
   * 复制文本到剪贴板（带 Toast 提示）
   * @param context - 组件的 this 引用
   * @param text - 要复制的文本
   * @param successResource - 成功提示的资源
   * @param successFallback - 成功提示的回退文本
   * @param failResource - 失败提示的资源
   * @param failFallback - 失败提示的回退文本
   */
  static async copyToClipboard(
    context: ComponentContext,
    text: string,
    successResource: Resource | null = null,
    successFallback: string = 'Copied',
    failResource: Resource | null = null,
    failFallback: string = 'Copy failed'
  ): Promise<void> {
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteboardData = pasteboard.createData(
        pasteboard.MIMETYPE_TEXT_PLAIN,
        text
      );
      await systemPasteboard.setData(pasteboardData);
      
      UIHelper.showToast(context, successResource, successFallback);
    } catch (error) {
      console.error('Copy to clipboard failed:', error);
      UIHelper.showToast(context, failResource, failFallback);
    }
  }

  /**
   * 获取 ResourceManager（供特殊场景使用）
   * @param context - 组件的 this 引用
   * @returns ResourceManager 或 null
   */
  static getResourceManager(context: ComponentContext): resourceManager.ResourceManager | null {
    try {
      const uiContext = context.getUIContext();
      if (!uiContext) {
        console.error('UIContext not available');
        return null;
      }

      const hostContext = uiContext.getHostContext();
      if (!hostContext) {
        console.error('HostContext not available');
        return null;
      }

      return hostContext.resourceManager || null;
    } catch (error) {
      console.error('Failed to get ResourceManager:', error);
      return null;
    }
  }
}
