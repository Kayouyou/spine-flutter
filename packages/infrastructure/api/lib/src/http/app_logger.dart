import 'package:flutter/foundation.dart';

/// Token续期日志级别（api包内部使用）
///
/// 注意：此枚举与主应用LogLevel分离，避免命名冲突
enum TokenLogLevel {
  debug,
  info,
  warning,
  error,
}

/// 抽象日志接口 — 用于打破api包与主应用的依赖循环
/// 主应用的AppLogger实现此接口
abstract class AppLoggerInterface {
  /// 输出调试日志
  void debug(String message);

  /// 输出信息日志
  void info(String message);

  /// 输出警告日志
  void warning(String message);

  /// 输出错误日志
  void error(String message, [dynamic error]);
}

/// 默认日志实现 — 当未注入Logger时使用
///
/// 使用debugPrint输出，仅在Debug模式生效
class DefaultLogger implements AppLoggerInterface {
  @override
  void debug(String message) {
    if (kDebugMode) {
      debugPrint('[TokenRenewal] [DEBUG] $message');
    }
  }

  @override
  void info(String message) {
    if (kDebugMode) {
      debugPrint('[TokenRenewal] [INFO] $message');
    }
  }

  @override
  void warning(String message) {
    if (kDebugMode) {
      debugPrint('[TokenRenewal] [WARNING] $message');
    }
  }

  @override
  void error(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('[TokenRenewal] [ERROR] $message');
      if (error != null) {
        debugPrint('  错误详情: ${error.toString()}');
      }
    }
  }
}