import 'package:domain/domain.dart';
import '../../config.dart';

/// 环境配置实现 — 将 EnvironmentConfig 包装为 IAppConfig 接口
///
/// 职责：读取 EnvironmentConfig 的静态属性，通过接口暴露给应用各层
/// 这是唯一直接读取 EnvironmentConfig 的地方
class EnvAppConfig implements IAppConfig {
  @override
  bool get isDev => EnvironmentConfig.isDev;

  @override
  bool get isProd => EnvironmentConfig.isProd;

  @override
  bool get enableDebugLog => EnvironmentConfig.enableDebugLog;

  @override
  bool get enableAuthGuard => EnvironmentConfig.enableAuthGuard;

  @override
  String get apiBaseUrl => EnvironmentConfig.apiBaseUrl;

  @override
  int get networkTimeout => EnvironmentConfig.networkTimeout;

  @override
  String get sentryDsn => EnvironmentConfig.sentryDsn;

  @override
  String get appStoreId => EnvironmentConfig.appStoreId;
}
