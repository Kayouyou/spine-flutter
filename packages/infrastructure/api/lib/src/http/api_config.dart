import 'package:domain/domain.dart';

/// api 包配置抽象
///
/// 替代原 HttpConstant 中的硬编码字段 (HTTP 主机 / AccessKey / OSS 配置).
/// 通过 createDio(apiConfig: ...) 注入, 不依赖静态字段, 不依赖 dart-define.
///
/// 实现方: 通常由 lib/core/config/api_config_impl.dart 提供 (读取 IAppConfig).
/// 测试方: 测试中可用 _FakeApiConfig 提供固定值.
abstract class ApiConfig {
  /// HTTP 主机 (不含协议). 例如 'api.example.com'.
  String get host;

  /// 是否为生产环境 (true) / 调试环境 (false).
  /// 决定 HTTP/HTTPS 协议选择 + 错误上报详细度.
  bool get isRelease;

  /// AccessKeyId 用于请求签名.
  String get accessKeyId;

  /// OSS Bucket 名.
  String get ossBucket;

  /// OSS Endpoint URL. 例如 'https://oss-cn-zhangjiakou.aliyuncs.com'.
  String get ossEndpoint;

  /// OSS 公开访问 URL 前缀 (Bucket + Endpoint 拼接).
  /// 例如 'https://ovsx-usr.oss-cn-zhangjiakou.aliyuncs.com'.
  String get ossPublicUrl;
}

/// ApiConfig 默认实现 — 委托 IAppConfig (domain 包内已有)
///
/// 启动期 EnvironmentConfig 已 assert 所有字段非空, 此处不再校验.
class EnvApiConfig implements ApiConfig {
  EnvApiConfig(this._appConfig);

  final IAppConfig _appConfig;

  @override
  String get host => _appConfig.apiHost;

  @override
  bool get isRelease => _appConfig.isProd;

  @override
  String get accessKeyId => _appConfig.apiAccessKeyId;

  @override
  String get ossBucket => _appConfig.ossBucket;

  @override
  String get ossEndpoint => _appConfig.ossEndpoint;

  @override
  String get ossPublicUrl =>
      'https://${_appConfig.ossBucket}.${_extractHost(_appConfig.ossEndpoint)}';

  /// 从完整 URL 提取 host (去掉协议).
  /// 例: 'https://oss-cn-zhangjiakou.aliyuncs.com' → 'oss-cn-zhangjiakou.aliyuncs.com'.
  String _extractHost(String url) {
    final uri = Uri.parse(url);
    return uri.host.isEmpty ? url : uri.host;
  }
}