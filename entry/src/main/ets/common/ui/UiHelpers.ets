// Centralized UI helper utilities compatible with ArkUI SDK surface.
// Typings stay permissive; runtime guards handle Promise/void behaviors.

type SafeValue = string | number | boolean | object | null | undefined;
type SafeRecord = Record<string, SafeValue>;
type MaybePromise<T> = T | Promise<T>;

export interface RouterOptions {
  url: string;
  params?: SafeRecord;
}

interface RouterLike {
  pushUrl(options: RouterOptions): void | Promise<void>;
  replaceUrl(options: RouterOptions): void | Promise<void>;
  back(): void;
  back(options: RouterOptions): void;
  back(index: number, params?: SafeRecord): void;
  getParams(): SafeRecord | undefined;
}

interface ResourceManagerLike {
  getStringSync(resourceId: number, ...args: Array<string | number>): string;
}

interface HostContextLike {
  resourceManager: ResourceManagerLike;
}

interface PromptActionLike {
  showToast(options: { message: string }): void;
  showDialog?(options: SafeRecord): Promise<SafeValue | void>;
  showActionMenu?(options: SafeRecord): Promise<SafeValue | void>;
}

interface UIContextAccessor {
  getRouter(): RouterLike;
  getHostContext(): HostContextLike;
  getPromptAction(): PromptActionLike;
}

interface UIComponentLike {
  getUIContext(): UIContextAccessor;
}

function logError(prefix: string, error: SafeValue): void {
  try {
    console.error(prefix, JSON.stringify(error));
  } catch (_) {
    console.error(prefix, error);
  }
}

function isPromise<T>(ret: MaybePromise<T>): ret is Promise<T> {
  return typeof ret === 'object' && ret !== null && typeof (ret as { then?: SafeValue }).then === 'function';
}

export function safeGetParams<T>(component: UIComponentLike): T | undefined {
  try {
    return component.getUIContext().getRouter().getParams() as T | undefined;
  } catch (error) {
    logError('getParams failed', error as SafeValue);
    return undefined;
  }
}

export function safePush(component: UIComponentLike, options: RouterOptions): void {
  try {
    const ret = component.getUIContext().getRouter().pushUrl(options) as MaybePromise<void>;
    if (isPromise(ret)) {
      ret.catch((err: SafeValue): void => logError('pushUrl failed', err));
    }
  } catch (error) {
    logError('pushUrl exception', error as SafeValue);
  }
}

export function safeReplace(component: UIComponentLike, options: RouterOptions): void {
  try {
    const ret = component.getUIContext().getRouter().replaceUrl(options) as MaybePromise<void>;
    if (isPromise(ret)) {
      ret.catch((err: SafeValue): void => logError('replaceUrl failed', err));
    }
  } catch (error) {
    logError('replaceUrl exception', error as SafeValue);
  }
}

// SDK back() overloads return void; do not attach .catch.
export function safeBack(component: UIComponentLike, arg1?: RouterOptions | number, arg2?: SafeRecord): void {
  try {
    const router = component.getUIContext().getRouter();
    if (typeof arg1 === 'number') {
      router.back(arg1, arg2 ?? {});
    } else {
      router.back(arg1);
    }
  } catch (error) {
    logError('back exception', error as SafeValue);
  }
}

export function safeGetString(component: UIComponentLike, res: Resource, ...args: Array<string | number>): string {
  try {
    const hostContext = component.getUIContext().getHostContext();
    return hostContext.resourceManager.getStringSync(res.id, ...args);
  } catch (error) {
    logError('getString failed', error as SafeValue);
    return '';
  }
}

export function safeToast(component: UIComponentLike, message: string): void {
  if (!message) return;
  try {
    component.getUIContext().getPromptAction().showToast({ message });
  } catch (error) {
    logError('showToast failed', error as SafeValue);
  }
}

export async function safeDialog(component: UIComponentLike, options: SafeRecord): Promise<SafeValue | void> {
  try {
    const action = component.getUIContext().getPromptAction();
    if (typeof action.showDialog === 'function') {
      return await action.showDialog(options);
    }
  } catch (error) {
    logError('showDialog failed', error as SafeValue);
  }
  return undefined;
}

export async function safeActionMenu(component: UIComponentLike, options: SafeRecord): Promise<SafeValue | void> {
  try {
    const action = component.getUIContext().getPromptAction();
    if (typeof action.showActionMenu === 'function') {
      return await action.showActionMenu(options);
    }
  } catch (error) {
    logError('showActionMenu failed', error as SafeValue);
  }
  return undefined;
}

// Optional bound helpers to avoid passing `this` repeatedly.
export function ui(component: UIComponentLike) {
  return {
    push: (opts: RouterOptions): void => safePush(component, opts),
    replace: (opts: RouterOptions): void => safeReplace(component, opts),
    back: (opts?: RouterOptions | number, params?: SafeRecord): void => safeBack(component, opts, params),
    backTo: (index: number, params?: SafeRecord): void => safeBack(component, index, params),
    toast: (msg: string): void => safeToast(component, msg),
    str: (res: Resource, ...args: Array<string | number>): string => safeGetString(component, res, ...args),
    params: <T>(): T | undefined => safeGetParams<T>(component),
  };
}
