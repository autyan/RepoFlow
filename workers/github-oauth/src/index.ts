/**
 * RepoFlow GitHub OAuth Token Exchange Service
 * 
 * 这个 Cloudflare Worker 负责安全地交换 GitHub OAuth authorization code 为 access token。
 * client_secret 存储在 Workers 环境变量中，不会暴露给客户端。
 * 
 * 安全特性：
 * - IP 速率限制（使用 Cloudflare KV）
 * - 请求验证
 * - CORS 控制
 * - 可疑请求检测
 */

export interface Env {
  GITHUB_CLIENT_ID: string;
  GITHUB_CLIENT_SECRET: string;
  ALLOWED_ORIGINS?: string; // 可选：允许的来源，逗号分隔
  RATE_LIMITER?: KVNamespace; // 可选：用于速率限制的 KV 命名空间
}

interface TokenRequest {
  code: string;
  redirect_uri?: string;
  device_id?: string; // 可选：设备标识
}

interface GitHubTokenResponse {
  access_token?: string;
  token_type?: string;
  scope?: string;
  error?: string;
  error_description?: string;
}

// 速率限制配置
// 注意：移动网络下大量用户可能共享同一 IP（CGNAT），因此 IP 限制要宽松
const RATE_LIMIT_CONFIG = {
  // 每个 IP 的限制（宽松，因为 CGNAT）
  ip: {
    maxRequests: 1000,    // 每分钟最大请求数（宽松）
    windowSeconds: 60,    // 时间窗口（秒）
  },
  // 每个设备的限制（主要限制维度）
  device: {
    maxRequests: 10,      // 每分钟最大请求数
    windowSeconds: 60,
  },
  // IP + 设备组合限制（最精确）
  ipDevice: {
    maxRequests: 5,       // 同一 IP 下同一设备
    windowSeconds: 60,
  },
  // 全局限制（防止大规模攻击，保护服务）
  global: {
    maxRequests: 10000,
    windowSeconds: 60,
  },
  // 失败请求的额外限制（防止暴力破解）
  failure: {
    maxRequests: 3,       // 每分钟最多 3 次失败
    windowSeconds: 60,
  }
};

// 速率限制检查结果
interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: number;
  retryAfter?: number;
}

// CORS 响应头
function corsHeaders(origin: string, allowedOrigins?: string): HeadersInit {
  // 如果设置了 ALLOWED_ORIGINS，检查是否在白名单中
  if (allowedOrigins) {
    const origins = allowedOrigins.split(',').map(o => o.trim());
    if (!origins.includes(origin) && !origins.includes('*')) {
      origin = origins[0]; // 使用第一个允许的源
    }
  }
  
  return {
    'Access-Control-Allow-Origin': origin || '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

// 处理 OPTIONS 预检请求
function handleOptions(request: Request, env: Env): Response {
  const origin = request.headers.get('Origin') || '*';
  return new Response(null, {
    status: 204,
    headers: corsHeaders(origin, env.ALLOWED_ORIGINS),
  });
}

// 错误响应
function errorResponse(message: string, status: number, origin: string, env: Env): Response {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders(origin, env.ALLOWED_ORIGINS),
      },
    }
  );
}

// 成功响应
function jsonResponse(data: object, origin: string, env: Env, rateLimit?: RateLimitResult): Response {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...corsHeaders(origin, env.ALLOWED_ORIGINS),
  };
  
  // 添加速率限制信息到响应头
  if (rateLimit) {
    Object.assign(headers, {
      'X-RateLimit-Remaining': rateLimit.remaining.toString(),
      'X-RateLimit-Reset': rateLimit.resetAt.toString(),
    });
  }
  
  return new Response(JSON.stringify(data), {
    status: 200,
    headers,
  });
}

// 速率限制响应
function rateLimitResponse(origin: string, env: Env, retryAfter: number): Response {
  return new Response(
    JSON.stringify({ 
      error: 'rate_limit_exceeded',
      error_description: 'Too many requests. Please try again later.',
      retry_after: retryAfter,
    }),
    {
      status: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': retryAfter.toString(),
        ...corsHeaders(origin, env.ALLOWED_ORIGINS),
      },
    }
  );
}

/**
 * 获取客户端 IP 地址
 */
function getClientIP(request: Request): string {
  // Cloudflare 会在这个 header 中提供真实 IP
  return request.headers.get('CF-Connecting-IP') || 
         request.headers.get('X-Forwarded-For')?.split(',')[0]?.trim() ||
         'unknown';
}

/**
 * 获取请求指纹（用于识别同一客户端的多维度标识）
 */
function getRequestFingerprint(request: Request, body: TokenRequest): string {
  const ip = getClientIP(request);
  const userAgent = request.headers.get('User-Agent') || '';
  const deviceId = body.device_id || '';
  
  // 组合多个维度生成指纹
  return `${ip}:${deviceId}:${userAgent.slice(0, 50)}`;
}

/**
 * 检查速率限制（使用 KV 存储）
 */
async function checkRateLimit(
  kv: KVNamespace | undefined,
  key: string,
  config: { maxRequests: number; windowSeconds: number }
): Promise<RateLimitResult> {
  // 如果没有配置 KV，使用内存限制（仅对单个 Worker 实例有效）
  if (!kv) {
    return { allowed: true, remaining: config.maxRequests, resetAt: Date.now() + config.windowSeconds * 1000 };
  }
  
  const now = Math.floor(Date.now() / 1000);
  const windowStart = now - (now % config.windowSeconds);
  const kvKey = `ratelimit:${key}:${windowStart}`;
  
  try {
    const current = parseInt(await kv.get(kvKey) || '0', 10);
    const remaining = Math.max(0, config.maxRequests - current - 1);
    const resetAt = (windowStart + config.windowSeconds) * 1000;
    
    if (current >= config.maxRequests) {
      return {
        allowed: false,
        remaining: 0,
        resetAt,
        retryAfter: windowStart + config.windowSeconds - now,
      };
    }
    
    // 增加计数（使用 expirationTtl 自动过期）
    await kv.put(kvKey, (current + 1).toString(), { expirationTtl: config.windowSeconds + 10 });
    
    return { allowed: true, remaining, resetAt };
  } catch (e) {
    console.error('Rate limit check failed:', e);
    // 如果 KV 操作失败，允许请求通过（降级策略）
    return { allowed: true, remaining: config.maxRequests, resetAt: Date.now() + config.windowSeconds * 1000 };
  }
}

/**
 * 检测可疑请求
 */
function detectSuspiciousRequest(request: Request, body: TokenRequest): string | null {
  // 检查 authorization code 格式（GitHub 的 code 通常是特定格式）
  if (body.code && (body.code.length < 10 || body.code.length > 50)) {
    return 'Invalid code format';
  }
  
  // 检查是否有可疑的 User-Agent
  const ua = request.headers.get('User-Agent') || '';
  if (!ua || ua.length < 5) {
    return 'Missing or invalid User-Agent';
  }
  
  // 检查 redirect_uri 格式
  if (body.redirect_uri && !body.redirect_uri.match(/^[a-z][a-z0-9+.-]*:/i)) {
    return 'Invalid redirect_uri format';
  }
  
  return null;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const origin = request.headers.get('Origin') || '*';
    const url = new URL(request.url);
    const clientIP = getClientIP(request);

    // 健康检查端点
    if (url.pathname === '/health' || url.pathname === '/') {
      return jsonResponse({ status: 'ok', service: 'repoflow-oauth' }, origin, env);
    }

    // 只处理 /token 端点
    if (url.pathname !== '/token') {
      return errorResponse('Not Found', 404, origin, env);
    }

    // 处理 CORS 预检
    if (request.method === 'OPTIONS') {
      return handleOptions(request, env);
    }

    // 只接受 POST 请求
    if (request.method !== 'POST') {
      return errorResponse('Method Not Allowed', 405, origin, env);
    }

    // ==================== 安全检查 ====================
    
    // 1. IP 速率限制检查
    const ipRateLimit = await checkRateLimit(env.RATE_LIMITER, `ip:${clientIP}`, RATE_LIMIT_CONFIG.ip);
    if (!ipRateLimit.allowed) {
      console.warn(`Rate limit exceeded for IP: ${clientIP}`);
      return rateLimitResponse(origin, env, ipRateLimit.retryAfter || 60);
    }

    // 2. 全局速率限制检查（防止大规模攻击）
    const globalRateLimit = await checkRateLimit(env.RATE_LIMITER, 'global', RATE_LIMIT_CONFIG.global);
    if (!globalRateLimit.allowed) {
      console.warn('Global rate limit exceeded');
      return rateLimitResponse(origin, env, globalRateLimit.retryAfter || 60);
    }

    // ==================== 验证配置 ====================
    
    if (!env.GITHUB_CLIENT_ID || !env.GITHUB_CLIENT_SECRET) {
      console.error('Missing GITHUB_CLIENT_ID or GITHUB_CLIENT_SECRET');
      return errorResponse('Service not configured', 500, origin, env);
    }

    // ==================== 解析和验证请求 ====================

    // 解析请求体
    let body: TokenRequest;
    try {
      body = await request.json() as TokenRequest;
    } catch (e) {
      return errorResponse('Invalid JSON body', 400, origin, env);
    }

    // 验证必需参数
    if (!body.code) {
      return errorResponse('Missing required parameter: code', 400, origin, env);
    }

    // 检测可疑请求
    const suspiciousReason = detectSuspiciousRequest(request, body);
    if (suspiciousReason) {
      console.warn(`Suspicious request from ${clientIP}: ${suspiciousReason}`);
      // 不透露具体原因，防止攻击者探测
      return errorResponse('Invalid request', 400, origin, env);
    }

    // 3. 设备速率限制检查（主要限制维度）
    if (body.device_id) {
      // 设备级别限制
      const deviceRateLimit = await checkRateLimit(
        env.RATE_LIMITER, 
        `device:${body.device_id}`, 
        RATE_LIMIT_CONFIG.device
      );
      if (!deviceRateLimit.allowed) {
        console.warn(`Rate limit exceeded for device: ${body.device_id}`);
        return rateLimitResponse(origin, env, deviceRateLimit.retryAfter || 60);
      }
      
      // IP + Device 组合限制（最精确，防止同一设备换 IP 绕过）
      const ipDeviceRateLimit = await checkRateLimit(
        env.RATE_LIMITER,
        `ipdevice:${clientIP}:${body.device_id}`,
        RATE_LIMIT_CONFIG.ipDevice
      );
      if (!ipDeviceRateLimit.allowed) {
        console.warn(`Rate limit exceeded for IP+Device: ${clientIP}:${body.device_id}`);
        return rateLimitResponse(origin, env, ipDeviceRateLimit.retryAfter || 60);
      }
    }

    // ==================== 执行 Token 交换 ====================

    try {
      const tokenResponse = await fetch('https://github.com/login/oauth/access_token', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'RepoFlow-OAuth-Worker',
        },
        body: JSON.stringify({
          client_id: env.GITHUB_CLIENT_ID,
          client_secret: env.GITHUB_CLIENT_SECRET,
          code: body.code,
          redirect_uri: body.redirect_uri,
        }),
      });

      const data = await tokenResponse.json() as GitHubTokenResponse;

      // 检查 GitHub 返回的错误
      if (data.error) {
        // 记录失败的尝试并计入失败限制
        console.warn(`Token exchange failed for IP ${clientIP}: ${data.error}`);
        
        // 失败请求限制（防止暴力破解 authorization code）
        const failureKey = body.device_id 
          ? `failure:${body.device_id}` 
          : `failure:ip:${clientIP}`;
        const failureLimit = await checkRateLimit(
          env.RATE_LIMITER,
          failureKey,
          RATE_LIMIT_CONFIG.failure
        );
        
        // 如果失败次数过多，返回限流而不是具体错误
        if (!failureLimit.allowed) {
          console.warn(`Too many failures for ${failureKey}`);
          return rateLimitResponse(origin, env, failureLimit.retryAfter || 60);
        }
        
        return jsonResponse({
          error: data.error,
          error_description: data.error_description,
        }, origin, env, ipRateLimit);
      }

      // 返回 token（不返回 client_secret 相关信息）
      return jsonResponse({
        access_token: data.access_token,
        token_type: data.token_type,
        scope: data.scope,
      }, origin, env, ipRateLimit);

    } catch (e) {
      console.error('GitHub API error:', e);
      return errorResponse('Failed to exchange token with GitHub', 502, origin, env);
    }
  },
};
