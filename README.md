# RepoFlow (第三方 GitHub 客户端 / Unofficial GitHub Client)

> 这是一个面向个人开发者和小型团队的第三方 GitHub 客户端，重度使用场景优化。非 GitHub 官方产品，不隶属于 GitHub、鸿蒙或华为。

## 目的 / Purpose
- 提供快捷的仓库、Issue、PR、通知等日常高频操作体验。
- 合规、透明地使用 GitHub API，不做数据爬取或再分发。
- 适配 HarmonyOS，支持深色模式、离线稍后读等体验增强。

## 法律与品牌声明 / Legal & Branding
- 本应用为第三方客户端，与 GitHub、鸿蒙/华为无官方关联或背书。
- 不使用 GitHub 官方 Logo、Octocat 或容易造成混淆的图形/配色。
- 使用 GitHub API 时遵守 Developer Terms，仅在用户授权范围内访问数据。
- 用户的访问令牌 (OAuth Token) 仅在本地加密存储，可随时登出/清除。
- 如需引用品牌名称，仅用于描述性目的，不暗示合作或官方身份。

## 主要功能（规划）/ Key Features (Planned)
- OAuth 登录（最小授权，Token 本地加密存储）。
- 首页活动流、通知列表（读写标记）。
- 仓库浏览：README、文件树、分支/Tag、Release。
- Issue/PR：列表、筛选、详情、评论、状态变更。
- 搜索：仓库/用户/Issue/PR，全局过滤与排序。
- 体验增强：离线稍后读、深色/浅色模式、错误与空态优化。

## 隐私与数据 / Privacy & Data
- 不收集与分发用户的个人数据；网络请求仅用于完成 GitHub 授权范围内的功能。
- 本地存储的 Token/缓存可一键清除；前后台切换时遮挡敏感信息。
- 调试日志默认最小化，发布版不启用敏感日志。

## 使用 / Usage
- HarmonyOS Stage 模型应用，使用 Hvigor 构建。
- 需在本地配置 GitHub OAuth App，并设置回调 URL：`repoflow://auth/callback`（示例，可按实际调整）。
- 首次运行前，请在设置页阅读隐私政策与免责声明。

## 许可证 / License
本项目采用 MIT 许可证，详见 [LICENSE](LICENSE)。
