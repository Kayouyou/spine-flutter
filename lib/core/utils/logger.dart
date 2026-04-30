import 'package:flutter/foundation.dart';
import 'package:api/api.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 应用日志器
///
/// 职责：统一日志输出管理，支持级别过滤和生产环境禁用
/// 使用：通过DI获取 `sl<AppLogger>()`
///
/// 实现AppLoggerInterface接口，可注入到api包的Token续期拦截器
class AppLogger implements AppLoggerInterface {
  /// 是否在生产环境启用日志
  final bool enableInProduction;

  /// 最小日志级别
  final LogLevel minLevel;

  AppLogger({
    this.enableInProduction = false,
    this.minLevel = LogLevel.info,
  });

  /// 输出调试日志
  @override
  void debug(String message) => log(LogLevel.debug, message);

  /// 输出信息日志
  @override
  void info(String message) => log(LogLevel.info, message);

  /// 输出警告日志
  @override
  void warning(String message) => log(LogLevel.warning, message);

  /// 输出错误日志
  @override
  void error(String message, [dynamic error]) => log(LogLevel.error, message, error);

  /// 核心日志输出方法
  void log(LogLevel level, String message, [dynamic error]) {
    // 级别过滤
    if (level.index < minLevel.index) return;

    // 生产环境过滤
    if (!enableInProduction && !kDebugMode) return;

    // 格式化输出
    final timestamp = DateTime.now().toString();
    final levelStr = level.name.toUpperCase();
    final output = '[$timestamp] [$levelStr] $message';

    if (kDebugMode) {
      debugPrint(output);
      if (error != null) {
        debugPrint('  错误详情: ${error.toString()}');
      }
    }
  }
}