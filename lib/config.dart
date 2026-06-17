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
  /// 必须在 .env.* 配置. dev 环境无值时 fallback 到 placeholder (IDE 启动场景),
  /// prod 环境**无 fallback**, 启动期 assert 验证.
  /// (8.15 修复: 之前无 defaultValue, IDE 启动会抛 StateError, 改用兜底)
  static const _apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'dev-host.placeholder.invalid',
  );

  /// API 访问密钥 (用于请求签名).
  /// 替代原 HttpConstant.AccessKeyId 硬编码值.
  /// 必须在 .env.* 配置. dev/staging 无值时为空 (签名关闭), prod 必须非空.
  static const _apiAccessKeyId = String.fromEnvironment('API_ACCESS_KEY_ID');

  /// OSS Bucket 名.
  /// 替代原 AliyunOSSConstant.BucketName 硬编码值.
  /// 必须在 .env.* 配置. dev 无值时 fallback (IDE 启动), prod 必须非空.
  static const _ossBucket = String.fromEnvironment(
    'OSS_BUCKET',
    defaultValue: 'dev-bucket.placeholder.invalid',
  );

  /// OSS Endpoint.
  /// 替代原 AliyunOSSConstant.Endpoint 硬编码值.
  /// 必须在 .env.* 配置. dev 无值时 fallback (IDE 启动), prod 必须非空.
  static const _ossEndpoint = String.fromEnvironment(
    'OSS_ENDPOINT',
    defaultValue: 'https://oss-cn-zhangjiakou.aliyuncs.com',
  );

  /// OSS 访问密钥.
  /// 替代原 AliyunOSSConstant.AccessKey.
  /// 必须在 .env.* 配置. dev/staging 无值时为空, prod 必须非空.
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
  /// dev/staging: 启动期日志警告, 仍允许运行 (使用 placeholder).
  /// prod: 启动抛 StateError (fail-fast).
  /// (8.15 修复: 之前 dev 也抛错, IDE 启动场景无法用, 改警告而非崩溃)
  static String get apiHost {
    if (isProd) {
      return _require(_apiHost, 'API_HOST', allowEmpty: false);
    }
    if (_isPlaceholder(_apiHost)) {
      _warnPlaceholder('API_HOST', 'dev-host.placeholder.invalid');
    }
    return _apiHost;
  }

  /// API 访问密钥.
  /// dev/staging: 可空 (签名关闭).
  /// prod: 必须非空.
  static String get apiAccessKeyId {
    if (isProd) {
      return _require(_apiAccessKeyId, 'API_ACCESS_KEY_ID', allowEmpty: false);
    }
    return _apiAccessKeyId;
  }

  /// OSS Bucket.
  /// dev/staging: 可用 placeholder fallback.
  /// prod: 必须非空.
  static String get ossBucket {
    if (isProd) {
      return _require(_ossBucket, 'OSS_BUCKET', allowEmpty: false);
    }
    if (_isPlaceholder(_ossBucket)) {
      _warnPlaceholder('OSS_BUCKET', 'dev-bucket.placeholder.invalid');
    }
    return _ossBucket;
  }

  /// OSS Endpoint.
  /// dev/staging: 有默认 OSS 域名 (不抛错).
  /// prod: 必须非空.
  static String get ossEndpoint {
    if (isProd) {
      return _require(_ossEndpoint, 'OSS_ENDPOINT', allowEmpty: false);
    }
    return _ossEndpoint;
  }

  /// OSS 访问密钥.
  /// dev/staging: 可空.
  /// prod: 必须非空.
  static String get ossAccessKey {
    if (isProd) {
      return _require(_ossAccessKey, 'OSS_ACCESS_KEY', allowEmpty: false);
    }
    return _ossAccessKey;
  }

  /// 检查值是否为 IDE 启动占位符.
  /// 避免误把 placeholder 当真实值使用.
  static bool _isPlaceholder(String value) {
    return value.contains('placeholder.invalid') || value.isEmpty;
  }

  /// 占位符警告: 启动时显眼提示, 但不崩溃.
  /// (仅在 dev/staging 调用一次, prod 走 _require 抛错)
  static bool _warned = false;
  static void _warnPlaceholder(String name, String value) {
    if (_warned) return;
    _warned = true;
    // 用 print 跳过 sl/AppLogger 依赖 (与 launcher 修复同思路)
    // ignore: avoid_print
    print(''
        '\n'
        '╔══════════════════════════════════════════════════════════════╗\n'
        '║  ⚠️  EnvironmentConfig: $name 使用占位符 (IDE 启动)        ║\n'
        '║                                                              ║\n'
        '║  当前值: $value\n'
        '║                                                              ║\n'
        '║  推荐启动方式 (CLI):                                         ║\n'
        '║    make run-dev                                              ║\n'
        '║    或: fvm flutter run --dart-define-from-file=env/.env.dev  ║\n'
        '║                                                              ║\n'
        '║  IDE 启动需在 Run config 加上述参数.                          ║\n'
        '║  生产环境 (prod) 会立即抛 StateError, 不会用占位符.           ║\n'
        '╚══════════════════════════════════════════════════════════════╝\n');
  }

  /// 校验环境变量非空. prod 必填, dev/staging 可空.
  /// 用于替代原 HttpConstant 的硬编码回退 (fn.jzfeng.com 等).
  static String _require(String value, String name, {bool allowEmpty = true}) {
    if (allowEmpty) return value;
    if (value.isEmpty || _isPlaceholder(value)) {
      throw StateError(
        'EnvironmentConfig: 必需字段 $name 未配置 (生产环境). '
        '请通过 --dart-define-from-file=env/.env.prod 注入, '
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