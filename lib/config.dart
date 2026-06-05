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

  /// Sentry DSN（从环境文件读取，生产环境需要配置）
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// App Store ID（从环境文件读取，生产环境需要配置）
  static const appStoreId = String.fromEnvironment('APP_STORE_ID');

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

  static const String appName = 'My App';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.example.myapp';
}