/// 应用配置接口
///
/// 职责：定义应用配置的契约，所有配置通过此接口获取
/// 使用：在 app 层实现，通过 DI 注入到各层使用
/// 设计原则：
///   - 只放 feature 层真正需要的配置
///   - 不在接口中暴露 EnvironmentConfig 的实现细节
abstract class IAppConfig {
  /// 是否是开发环境
  bool get isDev;

  /// 是否是生产环境
  bool get isProd;

  /// 是否启用调试日志
  bool get enableDebugLog;

  /// 是否启用路由守卫
  bool get enableAuthGuard;

  /// API 基础地址
  String get apiBaseUrl;

  /// 网络请求超时（秒）
  int get networkTimeout;

  /// Sentry DSN（空字符串表示不启用）
  String get sentryDsn;

  /// App Store ID（空字符串表示不启用更新检查）
  String get appStoreId;
}
