/**
 * 本地 OAuth 配置模板
 * 
 * 使用说明：
 * 1. 复制此文件并重命名为 local.config.ets
 * 2. 在 GitHub 创建 OAuth App: https://github.com/settings/developers
 * 3. 设置 Authorization callback URL 为: repoflow.autyan.app://auth/callback
 * 4. 将获取到的 Client ID 和 Client Secret 填入 local.config.ets
 * 
 * ⚠️ 注意：local.config.ets 已被 .gitignore 忽略，不会被提交到版本控制
 */

export const LOCAL_OAUTH_CONFIG = {
  /**
   * GitHub OAuth App Client ID
   */
  clientId: 'YOUR_CLIENT_ID_HERE',

  /**
   * GitHub OAuth App Client Secret
   * ⚠️ 仅用于本地开发测试
   * 生产环境请配置 tokenEndpoint，不要在客户端存储 secret
   */
  clientSecret: 'YOUR_CLIENT_SECRET_HERE',

  /**
   * Cloudflare Worker Token 交换端点（推荐）
   * 部署 workers/github-oauth 后填入 Worker URL
   * 例如: https://repoflow-oauth.your-subdomain.workers.dev/token
   * 
   * 配置此项后，clientSecret 可留空
   */
  tokenEndpoint: '',

  /**
   * OAuth 回调地址
   */
  callbackUrl: 'repoflow.autyan.app://auth/callback',

  /**
   * 请求的权限范围
   */
  scope: 'read:user user:email notifications public_repo'
};
