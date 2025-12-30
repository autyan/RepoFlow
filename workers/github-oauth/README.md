# RepoFlow OAuth Worker

这是 RepoFlow 的 GitHub OAuth Token 交换服务，部署在 Cloudflare Workers 上。

## 为什么需要这个服务？

GitHub OAuth 应用需要 `client_secret` 来交换 access token。将 `client_secret` 放在移动端应用中是不安全的，因此我们使用这个 Worker 作为安全的中间层：

```
App → Worker（存储 secret）→ GitHub → Worker → App
```

## 安全特性

### Cloudflare 内置防护（自动启用）
- ✅ **DDoS 防护**：L3/L4/L7 层自动防护
- ✅ **IP 声誉检测**：自动识别恶意 IP
- ✅ **TLS 加密**：所有通信强制 HTTPS

### Worker 应用层防护
- ✅ **多维度速率限制**（针对移动网络 CGNAT 优化）
  - IP 限制：每分钟 1000 次（宽松，因为移动网络共享 IP）
  - 设备限制：每分钟 10 次（主要限制维度，需客户端传递 `device_id`）
  - IP+设备组合限制：每分钟 5 次（最精确识别）
  - 全局限制：每分钟 10000 次（服务保护）
  - 失败请求限制：每分钟 3 次失败（防止暴力破解）
- ✅ **请求验证**
  - authorization code 格式检查
  - User-Agent 必填检查
  - redirect_uri 格式验证
- ✅ **CORS 控制**：可配置允许的来源域名
- ✅ **敏感信息保护**：不在响应中泄露错误细节

### 关于移动网络 CGNAT

移动网络运营商通常使用 CGNAT（运营商级 NAT），导致成千上万用户共享同一个出口 IP。因此：
- IP 限制设置得很宽松（1000次/分钟）
- 主要依赖 `device_id` 进行限流
- 建议客户端生成并持久化一个唯一的设备标识

## 部署步骤

### 1. 安装 Wrangler CLI

```bash
npm install -g wrangler
```

### 2. 登录 Cloudflare

```bash
wrangler login
```

### 3. 安装依赖

```bash
cd workers/github-oauth
npm install
```

### 4. 创建 KV 命名空间（用于速率限制）

```bash
wrangler kv:namespace create RATE_LIMITER
```

输出类似：
```
🌀 Creating namespace with title "repoflow-oauth-RATE_LIMITER"
✨ Success!
Add the following to your configuration file in your kv_namespaces array:
{ binding = "RATE_LIMITER", id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" }
```

将输出的配置添加到 `wrangler.toml` 中的 `kv_namespaces`。

### 5. 配置 GitHub OAuth 凭据

```bash
# 设置 Client ID
wrangler secret put GITHUB_CLIENT_ID
# 输入你的 GitHub OAuth App Client ID

# 设置 Client Secret
wrangler secret put GITHUB_CLIENT_SECRET
# 输入你的 GitHub OAuth App Client Secret
```

### 6. 部署

```bash
# 开发环境测试
npm run dev

# 部署到生产
npm run deploy
```

部署成功后，你会得到一个 URL，类似：
```
https://repoflow-oauth.<your-subdomain>.workers.dev
```

## API 接口

### POST /token

交换 authorization code 为 access token。

**请求：**
```json
{
  "code": "authorization_code_from_github",
  "redirect_uri": "repoflow.autyan.app://auth/callback"
}
```

**成功响应：**
```json
{
  "access_token": "gho_xxxx",
  "token_type": "bearer",
  "scope": "read:user notifications public_repo"
}
```

**错误响应：**
```json
{
  "error": "bad_verification_code",
  "error_description": "The code passed is incorrect or expired."
}
```

### GET /health

健康检查端点。

**响应：**
```json
{
  "status": "ok",
  "service": "repoflow-oauth"
}
```

## 在 RepoFlow 中使用

部署完成后，更新 `local.config.ets` 中的配置：

```typescript
export const LOCAL_OAUTH_CONFIG = {
  clientId: 'your_client_id',
  // clientSecret 不再需要在客户端配置
  callbackUrl: 'repoflow.autyan.app://auth/callback',
  scope: 'read:user notifications public_repo',
  tokenEndpoint: 'https://repoflow-oauth.<your-subdomain>.workers.dev/token'
};
```

## 自定义域名（可选）

如果你想使用自定义域名，编辑 `wrangler.toml`：

```toml
routes = [
  { pattern = "oauth.your-domain.com", custom_domain = true }
]
```

然后在 Cloudflare Dashboard 中配置 DNS。

## 安全说明

- `client_secret` 通过 `wrangler secret` 加密存储，不会出现在代码中
- Worker 支持 CORS，可通过 `ALLOWED_ORIGINS` 环境变量限制来源
- 所有通信使用 HTTPS
- 不记录任何敏感信息

## 免费额度

Cloudflare Workers 免费版：
- 每天 100,000 次请求
- 每月约 300 万次请求
- 足够支撑 **10 万+ 日活用户**
