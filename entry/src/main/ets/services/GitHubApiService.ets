import http from '@ohos.net.http';
import { HttpClient, HttpResponse } from '../common/network/HttpClient';
import { GitHubUser, GitHubRepo, GitHubNotification, GitHubEvent, GitHubOrg, GitHubIssue, GitHubComment, GitHubTree, GitHubFileContent, GitHubBranch } from '../models/GitHubModels';

const GITHUB_API_BASE = 'https://api.github.com';

/**
 * GitHub API 服务
 * 封装常用 GitHub REST API 调用
 */
export class GitHubApiService {
  private http: HttpClient;

  constructor(tokenProvider: () => string) {
    this.http = new HttpClient();
    this.http.setAuthTokenProvider(tokenProvider);
  }

  /**
   * 获取当前认证用户信息
   */
  async getCurrentUser(): Promise<GitHubUser> {
    const response = await this.get<string>('/user');
    return JSON.parse(response.data) as GitHubUser;
  }

  /**
   * 获取指定用户的公开信息
   */
  async getUser(username: string): Promise<GitHubUser> {
    const response = await this.get<string>(`/users/${username}`);
    return JSON.parse(response.data) as GitHubUser;
  }

  /**
   * 获取当前用户的仓库列表
   */
  async getUserRepos(page: number = 1, perPage: number = 30): Promise<GitHubRepo[]> {
    const response = await this.get<string>(`/user/repos?page=${page}&per_page=${perPage}&sort=updated`);
    return JSON.parse(response.data) as GitHubRepo[];
  }

  /**
   * 获取指定用户的公开仓库
   */
  async getReposForUser(username: string, page: number = 1, perPage: number = 30): Promise<GitHubRepo[]> {
    const response = await this.get<string>(`/users/${username}/repos?page=${page}&per_page=${perPage}&sort=updated`);
    return JSON.parse(response.data) as GitHubRepo[];
  }

  /**
   * 获取当前用户的通知
   */
  async getNotifications(all: boolean = false, page: number = 1, perPage: number = 50): Promise<GitHubNotification[]> {
    const response = await this.get<string>(`/notifications?all=${all}&page=${page}&per_page=${perPage}`);
    return JSON.parse(response.data) as GitHubNotification[];
  }

  /**
   * 标记通知为已读
   */
  async markNotificationAsRead(threadId: string): Promise<void> {
    await this.patch(`/notifications/threads/${threadId}`, '');
  }

  /**
   * 搜索仓库
   */
  async searchRepos(query: string, page: number = 1, perPage: number = 30): Promise<GitHubSearchResult<GitHubRepo>> {
    const q = encodeURIComponent(query);
    const response = await this.get<string>(`/search/repositories?q=${q}&page=${page}&per_page=${perPage}`);
    return JSON.parse(response.data) as GitHubSearchResult<GitHubRepo>;
  }

  /**
   * 获取仓库详情
   */
  async getRepo(owner: string, repo: string): Promise<GitHubRepo> {
    const response = await this.get<string>(`/repos/${owner}/${repo}`);
    return JSON.parse(response.data) as GitHubRepo;
  }

  /**
   * 获取仓库 README
   */
  async getRepoReadme(owner: string, repo: string): Promise<string> {
    const response = await this.http.request<string>({
      method: http.RequestMethod.GET,
      url: `${GITHUB_API_BASE}/repos/${owner}/${repo}/readme`,
      headers: [
        { key: 'Accept', value: 'application/vnd.github.raw+json' },
        { key: 'User-Agent', value: 'RepoFlow-HarmonyOS' }
      ]
    });
    return response.data;
  }

  /**
   * 获取用户的关注者列表
   */
  async getFollowers(username: string, page: number = 1, perPage: number = 30): Promise<GitHubUser[]> {
    const response = await this.get<string>(`/users/${username}/followers?page=${page}&per_page=${perPage}`);
    return JSON.parse(response.data) as GitHubUser[];
  }

  /**
   * 获取用户正在关注的人
   */
  async getFollowing(username: string, page: number = 1, perPage: number = 30): Promise<GitHubUser[]> {
    const response = await this.get<string>(`/users/${username}/following?page=${page}&per_page=${perPage}`);
    return JSON.parse(response.data) as GitHubUser[];
  }

  /**
   * 获取用户的公开事件/活动
   */
  async getUserEvents(username: string, page: number = 1, perPage: number = 30): Promise<GitHubEvent[]> {
    const response = await this.get<string>(`/users/${username}/events/public?page=${page}&per_page=${perPage}`);
    return JSON.parse(response.data) as GitHubEvent[];
  }

  /**
   * 获取当前用户 Star 过的仓库
   */
  async getStarredRepos(page: number = 1, perPage: number = 30): Promise<GitHubRepo[]> {
    const response = await this.get<string>(`/user/starred?page=${page}&per_page=${perPage}&sort=updated`);
    return JSON.parse(response.data) as GitHubRepo[];
  }

  /**
   * 获取用户所属的组织列表
   */
  async getUserOrgs(username: string): Promise<GitHubOrg[]> {
    const response = await this.get<string>(`/users/${username}/orgs`);
    return JSON.parse(response.data) as GitHubOrg[];
  }

  // ============ Issue 相关 API ============

  /**
   * 获取仓库的 Issue 列表
   */
  async getRepoIssues(owner: string, repo: string, state: 'open' | 'closed' | 'all' = 'open', page: number = 1, perPage: number = 30): Promise<GitHubIssue[]> {
    const response = await this.get<string>(`/repos/${owner}/${repo}/issues?state=${state}&page=${page}&per_page=${perPage}`);
    return JSON.parse(response.data) as GitHubIssue[];
  }

  /**
   * 获取单个 Issue 详情
   */
  async getIssue(owner: string, repo: string, issueNumber: number): Promise<GitHubIssue> {
    const response = await this.get<string>(`/repos/${owner}/${repo}/issues/${issueNumber}`);
    return JSON.parse(response.data) as GitHubIssue;
  }

  /**
   * 获取 Issue 评论
   */
  async getIssueComments(owner: string, repo: string, issueNumber: number, page: number = 1, perPage: number = 30): Promise<GitHubComment[]> {
    const response = await this.get<string>(`/repos/${owner}/${repo}/issues/${issueNumber}/comments?page=${page}&per_page=${perPage}`);
    return JSON.parse(response.data) as GitHubComment[];
  }

  /**
   * 添加 Issue 评论
   */
  async addIssueComment(owner: string, repo: string, issueNumber: number, body: string): Promise<GitHubComment> {
    const payload: Record<string, string> = {};
    payload.body = body;
    const response = await this.post<string>(`/repos/${owner}/${repo}/issues/${issueNumber}/comments`, JSON.stringify(payload));
    return JSON.parse(response.data) as GitHubComment;
  }

  /**
   * 创建新 Issue
   */
  async createIssue(owner: string, repo: string, title: string, body?: string): Promise<GitHubIssue> {
    const payload: Record<string, string> = {};
    payload.title = title;
    if (body) {
      payload.body = body;
    }
    const response = await this.post<string>(`/repos/${owner}/${repo}/issues`, JSON.stringify(payload));
    return JSON.parse(response.data) as GitHubIssue;
  }

  // ============ 代码浏览 API ============

  /**
   * 获取仓库分支列表
   */
  async getRepoBranches(owner: string, repo: string): Promise<GitHubBranch[]> {
    const response = await this.get<string>(`/repos/${owner}/${repo}/branches`);
    return JSON.parse(response.data) as GitHubBranch[];
  }

  /**
   * 获取仓库目录内容（使用 contents API，更稳定）
   */
  async getRepoContents(owner: string, repo: string, path: string = '', ref?: string): Promise<GitHubFileContent[]> {
    const url = ref 
      ? `/repos/${owner}/${repo}/contents/${path}?ref=${ref}` 
      : `/repos/${owner}/${repo}/contents/${path}`;
    const response = await this.get<string>(url);
    const data: GitHubFileContent[] | GitHubFileContent = JSON.parse(response.data) as GitHubFileContent[] | GitHubFileContent;
    // contents API 返回数组或单个对象
    if (Array.isArray(data)) {
      return data;
    }
    return [data];
  }

  /**
   * 获取仓库文件树（使用 git trees API）
   * 注意：treeSha 可以是分支名或 commit sha
   */
  async getRepoTree(owner: string, repo: string, treeSha: string, recursive: boolean = false): Promise<GitHubTree> {
    const url = `/repos/${owner}/${repo}/git/trees/${treeSha}${recursive ? '?recursive=1' : ''}`;
    const response = await this.get<string>(url);
    return JSON.parse(response.data) as GitHubTree;
  }

  /**
   * 获取文件内容
   */
  async getFileContent(owner: string, repo: string, path: string, ref?: string): Promise<GitHubFileContent> {
    const url = ref ? `/repos/${owner}/${repo}/contents/${path}?ref=${ref}` : `/repos/${owner}/${repo}/contents/${path}`;
    const response = await this.get<string>(url);
    return JSON.parse(response.data) as GitHubFileContent;
  }

  /**
   * 获取文件原始内容
   */
  async getRawFileContent(owner: string, repo: string, path: string, ref?: string): Promise<string> {
    const branch = ref || 'main';
    const response = await this.http.request<string>({
      method: http.RequestMethod.GET,
      url: `https://raw.githubusercontent.com/${owner}/${repo}/${branch}/${path}`,
      headers: [
        { key: 'User-Agent', value: 'RepoFlow-HarmonyOS' }
      ]
    });
    return response.data;
  }

  // ============ 私有方法 ============

  private async get<T>(path: string): Promise<HttpResponse<T>> {
    return this.http.request<T>({
      method: http.RequestMethod.GET,
      url: `${GITHUB_API_BASE}${path}`,
      headers: [
        { key: 'Accept', value: 'application/vnd.github+json' },
        { key: 'User-Agent', value: 'RepoFlow-HarmonyOS' },
        { key: 'X-GitHub-Api-Version', value: '2022-11-28' }
      ]
    });
  }

  private async patch(path: string, body: string): Promise<HttpResponse<string>> {
    // Note: HarmonyOS http module may not support PATCH, using POST with X-HTTP-Method-Override
    return this.http.request<string>({
      method: http.RequestMethod.POST,
      url: `${GITHUB_API_BASE}${path}`,
      headers: [
        { key: 'Accept', value: 'application/vnd.github+json' },
        { key: 'User-Agent', value: 'RepoFlow-HarmonyOS' },
        { key: 'X-GitHub-Api-Version', value: '2022-11-28' },
        { key: 'Content-Type', value: 'application/json' },
        { key: 'X-HTTP-Method-Override', value: 'PATCH' }
      ],
      body
    });
  }

  private async post<T>(path: string, body: string): Promise<HttpResponse<T>> {
    return this.http.request<T>({
      method: http.RequestMethod.POST,
      url: `${GITHUB_API_BASE}${path}`,
      headers: [
        { key: 'Accept', value: 'application/vnd.github+json' },
        { key: 'User-Agent', value: 'RepoFlow-HarmonyOS' },
        { key: 'X-GitHub-Api-Version', value: '2022-11-28' },
        { key: 'Content-Type', value: 'application/json' }
      ],
      body
    });
  }
}

/**
 * GitHub 搜索结果
 */
export interface GitHubSearchResult<T> {
  total_count: number;
  incomplete_results: boolean;
  items: T[];
}
