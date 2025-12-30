/**
 * GitHub 用户信息
 */
export interface GitHubUser {
  id: number;
  login: string;
  avatar_url: string;
  name: string | null;
  company: string | null;
  blog: string | null;
  location: string | null;
  email: string | null;
  bio: string | null;
  public_repos: number;
  public_gists: number;
  followers: number;
  following: number;
  created_at: string;
  updated_at: string;
}

/**
 * GitHub 仓库信息
 */
export interface GitHubRepo {
  id: number;
  name: string;
  full_name: string;
  owner: GitHubRepoOwner;
  private: boolean;
  description: string | null;
  fork: boolean;
  html_url: string;
  language: string | null;
  stargazers_count: number;
  watchers_count: number;
  forks_count: number;
  open_issues_count: number;
  default_branch: string;
  created_at: string;
  updated_at: string;
  pushed_at: string;
}

export interface GitHubRepoOwner {
  id: number;
  login: string;
  avatar_url: string;
}

/**
 * GitHub 通知
 */
export interface GitHubNotification {
  id: string;
  unread: boolean;
  reason: string;
  updated_at: string;
  subject: GitHubNotificationSubject;
  repository: GitHubNotificationRepo;
}

export interface GitHubNotificationSubject {
  title: string;
  url: string | null;
  type: string;
}

export interface GitHubNotificationRepo {
  id: number;
  name: string;
  full_name: string;
  owner: GitHubRepoOwner;
}

/**
 * GitHub 事件/活动
 */
export interface GitHubEvent {
  id: string;
  type: string;
  actor: GitHubEventActor;
  repo: GitHubEventRepo;
  payload: GitHubEventPayload;
  public: boolean;
  created_at: string;
}

export interface GitHubEventActor {
  id: number;
  login: string;
  avatar_url: string;
}

export interface GitHubEventRepo {
  id: number;
  name: string;
  url: string;
}

export interface GitHubEventPayload {
  action?: string;
  ref?: string;
  ref_type?: string;
  commits?: GitHubEventCommit[];
  size?: number;
  distinct_size?: number;
}

export interface GitHubEventCommit {
  sha: string;
  message: string;
}

/**
 * GitHub 组织
 */
export interface GitHubOrg {
  id: number;
  login: string;
  avatar_url: string;
  description: string | null;
  url: string;
}

/**
 * GitHub Issue
 */
export interface GitHubIssue {
  id: number;
  number: number;
  title: string;
  body: string | null;
  state: 'open' | 'closed';
  user: GitHubUser;
  labels: GitHubLabel[];
  assignees: GitHubUser[];
  comments: number;
  created_at: string;
  updated_at: string;
  closed_at: string | null;
  html_url: string;
  pull_request?: object;  // 如果存在，表示这是一个 PR 而不是 Issue
}

export interface GitHubLabel {
  id: number;
  name: string;
  color: string;
  description: string | null;
}

/**
 * GitHub Issue 评论
 */
export interface GitHubComment {
  id: number;
  body: string;
  user: GitHubUser;
  created_at: string;
  updated_at: string;
  html_url: string;
}

/**
 * GitHub 仓库文件树
 */
export interface GitHubTreeItem {
  path: string;
  mode: string;
  type: 'blob' | 'tree';
  sha: string;
  size?: number;
  url: string;
}

export interface GitHubTree {
  sha: string;
  url: string;
  tree: GitHubTreeItem[];
  truncated: boolean;
}

/**
 * GitHub 文件内容
 */
export interface GitHubFileContent {
  name: string;
  path: string;
  sha: string;
  size: number;
  url: string;
  html_url: string;
  git_url: string;
  download_url: string | null;
  type: 'file' | 'dir';
  content?: string;
  encoding?: string;
}

/**
 * GitHub 分支提交信息
 */
export interface GitHubBranchCommit {
  sha: string;
  url: string;
}

/**
 * GitHub 分支
 */
export interface GitHubBranch {
  name: string;
  commit: GitHubBranchCommit;
  protected: boolean;
}
