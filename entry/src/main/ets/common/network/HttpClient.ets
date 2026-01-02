import http from '@ohos.net.http';
interface HeaderItem {
  key: string;
  value: string;
}

export interface HttpRequestOptions {
  method: http.RequestMethod;
  url: string;
  headers?: Array<HeaderItem>;
  body?: string;
  timeout?: number; // ms
}

export interface HttpResponse<T = string> {
  status: number;
  data: T;
  headers: Array<HeaderItem>;
}

export class HttpClient {
  private authTokenProvider?: () => string;

  setAuthTokenProvider(provider: () => string): void {
    this.authTokenProvider = provider;
  }

  async request<T = string>(options: HttpRequestOptions): Promise<HttpResponse<T>> {
    const authToken = this.authTokenProvider ? this.authTokenProvider() : '';
    const headerEntries: Array<HeaderItem> = options.headers ? [...options.headers] : [];
    if (authToken) {
      headerEntries.push({ key: 'Authorization', value: `Bearer ${authToken}` } as HeaderItem);
    }
    const headerObject: Record<string, string> = {};
    headerEntries.forEach((item) => {
      headerObject[item.key] = item.value;
    });

    const httpRequest = http.createHttp();
    try {
      const requestOptions: http.HttpRequestOptions = {
        method: options.method,
        header: headerObject,
        extraData: options.body,
        readTimeout: options.timeout ?? 10000,
        connectTimeout: options.timeout ?? 10000,
      };
      const response: http.HttpResponse = await httpRequest.request(options.url, requestOptions);
      const parsedHeaders: Array<HeaderItem> = [];
      if (response.header) {
        Object.keys(response.header).forEach((key) => {
          const value = response.header?.[key] as string | string[] | undefined;
          if (Array.isArray(value)) {
            parsedHeaders.push({ key, value: value.join(',') } as HeaderItem);
          } else if (value !== undefined) {
            parsedHeaders.push({ key, value: String(value) } as HeaderItem);
          }
        });
      }
      const resultData: T = response.result as T;
      return {
        status: response.responseCode,
        data: resultData,
        headers: parsedHeaders,
      };
    } catch (error) {
      console.error('HttpClient request failed', JSON.stringify(error));
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }
}
