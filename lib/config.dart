/// 环境类型
enum AppEnvironment { dev, staging, prod }

/// 环境配置
///
/// 通过编译参数注入：
/// ```bash
/// fvm flutter run --dart-define=ENV=dev      # 开发环境
/// fvm flutter run --dart-define=ENV=staging  # 预发布环境
/// fvm flutter run --dart-define=ENV=prod     # 生产环境
/// ```
///
/// 默认为 dev。
class EnvironmentConfig {
  EnvironmentConfig._();

  static const _envName = String.fromEnvironment('ENV', defaultValue: 'dev');

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

  /// API 基础地址
  static String get apiBaseUrl {
    switch (current) {
      case AppEnvironment.dev:
        return 'https://dev-api.example.com';
      case AppEnvironment.staging:
        return 'https://staging-api.example.com';
      case AppEnvironment.prod:
        return 'https://api.example.com';
    }
  }

  /// 是否启用调试日志
  static bool get enableDebugLog => !isProd;

  /// 网络请求超时（秒）
  static int get networkTimeout => isProd ? 10 : 30;
}

/// 应用配置
class AppConfig {
  AppConfig._();

  static const String appName = 'My App';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.example.myapp';
}
