/// 环境类型
enum AppEnvironment { dev, staging, prod }

/// 环境配置
///
/// 通过编译参数注入（使用 --dart-define-from-file）：
/// ```bash
/// fvm flutter run --dart-define-from-file=env/.env.dev      # 开发环境
/// fvm flutter run --dart-define-from-file=env/.env.staging  # 预发布环境
/// fvm flutter run --dart-define-from-file=env/.env.prod     # 生产环境
/// ```
///
/// 默认为 dev。
class EnvironmentConfig {
  EnvironmentConfig._();

  /// 当前环境名称（从环境文件读取）
  static const _envName = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// API 基础地址（从环境文件读取）
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev-api.example.com',
  );

  /// HTTP 主机（不含协议），用于续期/业务请求 URL 构造.
  /// 替代原 HttpConstant.Http_Host 硬编码值.
  /// 必须在 .env.* 配置, 否则启动抛 StateError (见 launcher.dart).
  static const _apiHost = String.fromEnvironment('API_HOST');

  /// API 访问密钥 (用于请求签名).
  /// 替代原 HttpConstant.AccessKeyId 硬编码值.
  /// 必须在 .env.* 配置, 否则启动抛 StateError.
  static const _apiAccessKeyId = String.fromEnvironment('API_ACCESS_KEY_ID');

  /// OSS Bucket 名.
  /// 替代原 AliyunOSSConstant.BucketName 硬编码值.
  /// 必须在 .env.* 配置, 否则启动抛 StateError.
  static const _ossBucket = String.fromEnvironment('OSS_BUCKET');

  /// OSS Endpoint.
  /// 替代原 AliyunOSSConstant.Endpoint 硬编码值.
  /// 必须在 .env.* 配置, 否则启动抛 StateError.
  static const _ossEndpoint = String.fromEnvironment('OSS_ENDPOINT');

  /// OSS 访问密钥.
  /// 替代原 AliyunOSSConstant.AccessKey.
  /// 必须在 .env.* 配置, 否则启动抛 StateError.
  static const _ossAccessKey = String.fromEnvironment('OSS_ACCESS_KEY');

  /// Sentry DSN（从环境文件读取，生产环境需要配置）
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// App Store ID（从环境文件读取，生产环境需要配置）
  static const appStoreId = String.fromEnvironment('APP_STORE_ID');

  /// 应用版本号（从环境文件读取）
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

  /// 构建号（从环境文件读取）
  static const buildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: '0');

  /// 当前环境
  static AppEnvironment get current {
    switch (_envName) {
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }

  /// 是否是开发环境
  static bool get isDev => current == AppEnvironment.dev;

  /// 是否是生产环境
  static bool get isProd => current == AppEnvironment.prod;

  /// API 基础地址（直接从环境变量读取）
  static String get apiBaseUrl => _apiBaseUrl;

  /// HTTP 主机（不含协议）.
  /// 必须非空, 由 launcher 启动期 assert 验证.
  static String get apiHost => _require(_apiHost, 'API_HOST');

  /// API 访问密钥.
  /// 必须非空, 由 launcher 启动期 assert 验证.
  static String get apiAccessKeyId => _require(_apiAccessKeyId, 'API_ACCESS_KEY_ID');

  /// OSS Bucket.
  /// 必须非空, 由 launcher 启动期 assert 验证.
  static String get ossBucket => _require(_ossBucket, 'OSS_BUCKET');

  /// OSS Endpoint.
  /// 必须非空, 由 launcher 启动期 assert 验证.
  static String get ossEndpoint => _require(_ossEndpoint, 'OSS_ENDPOINT');

  /// OSS 访问密钥.
  /// 必须非空, 由 launcher 启动期 assert 验证.
  static String get ossAccessKey => _require(_ossAccessKey, 'OSS_ACCESS_KEY');

  /// 校验环境变量非空, 为空则抛 StateError.
  /// 用于替代原 HttpConstant 的硬编码回退 (fn.jzfeng.com 等).
  static String _require(String value, String name) {
    if (value.isEmpty) {
      throw StateError(
        'EnvironmentConfig: 必需字段 $name 未配置. '
        '请通过 --dart-define-from-file=env/.env.{dev,staging,prod} 注入, '
        '或在 CI / 部署平台设置. 详见 AGENTS.md R5.',
      );
    }
    return value;
  }

  /// 是否启用调试日志
  static bool get enableDebugLog => !isProd;

  /// 网络请求超时（秒）
  static int get networkTimeout => isProd ? 10 : 30;

  /// 是否启用路由守卫覆盖
  static const _enableAuthGuardStr = String.fromEnvironment('ENABLE_AUTH_GUARD', defaultValue: 'true');
  static bool get enableAuthGuardOverride =>
      _enableAuthGuardStr.toLowerCase() == 'true';

  /// 是否启用路由守卫
  static bool get enableAuthGuard {
    if (isProd) {
      return enableAuthGuardOverride;
    }
    return true; // debug/staging default enabled
  }
}

/// 应用配置
class AppConfig {
  AppConfig._();

  static const String appName = 'Spine Flutter';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.example.myapp';
}