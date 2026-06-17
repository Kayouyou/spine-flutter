/// HTTP / 业务常量
///
/// ⚠️ 本文件**仅保留业务/技术常量**, 不再存放凭证/主机/OSS 配置.
/// 那些字段已迁移到 env/.env.* + IAppConfig + ApiConfig 注入链.
///
/// 历史背景:
/// - 旧版 Http_Host / AccessKeyId / CompanyIp 等是硬编码的, 违反 AGENTS.md R5
/// - 已在 L-1 修复中迁移到 ApiConfig + dart-define 注入
/// - 旧硬编码 IP (192.168.x.x) 已删除, 这些是开发联调代理地址, 属于个人环境配置
class HttpConstant {
  // ─── 网络超时 (毫秒) — 技术常量, 不属于凭证, 保留源码 ───
  static const int ReceiveTimeout = 15000;
  static const int ConnectTimeout = 15000;
  static const int SendTimeout = 15000;
  static const int Retry_Max_Count = 3;

  // ─── 请求签名 metadata — 协议级常量, 保留源码 ───
  static const String Version = 'v1.0';
  static const int SignType = 101;
  static const int Client = 10;

  // ─── 代理设置 — 仅控制开关, IP/端口由开发者本地 dart-define 提供 ───
  // Charles 抓包是个人调试行为, 不应进脚手架默认值.
  // 如需启用: flutter run --dart-define=PROXY_IP=192.168.1.100
  static const bool Proxy_Enable = false;
  static const int Proxy_Port = 8888;
  // proxyIp 改为 getter, 默认空 (从 dart-define 读, 缺省时不走代理)
  static String get proxyIp =>
      const String.fromEnvironment('PROXY_IP');

  // ─── 业务错误码 — 后端协议约定, 保留源码 ───
  static const int reTokenCode = 1000102; // token续期的code
  static const int reLoginCode = 1000103; // token长失效，重新登录code

  // ─── 通用错误码 — 业务协议, 保留源码 ───
  static const int NetworkErrorCode = -1111; // 网络连接错误
  static const int UnknownErrorCode = -1; // 未知错误
  static const int OssTokenErrorCode = 1111; // OSS Token获取失败
}

/// OSS 配置 — Bucket / Endpoint / Key 已迁移到 ApiConfig 注入
///
/// 保留类以兼容旧引用 (内部只剩业务常量字段).
/// 新代码请使用 ApiConfig (通过 createDio(apiConfig: ...) 注入).
class AliyunOSSConstant {
  // 仅保留: 由环境注入的 AccessKey (向后兼容 — 测试 / 老代码引用)
  // 生产 OSS AccessKey 应通过 dart-define OVSX_OSS_TOKEN 注入 (AGENTS.md R5).
  static const AccessKey = String.fromEnvironment('OVSX_OSS_TOKEN');
}