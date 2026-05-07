// packages/services/error/lib/src/error_handler.dart
import 'package:flutter/foundation.dart';
import 'error_reporter.dart';

/// 全局错误边界处理器
///
/// 安装后，所有 Flutter 框架和平台级别的未捕获错误
/// 都会通过 [onError] 回调被统一处理。
///
/// 使用方式：
/// ```dart
/// AppErrorHandler().setup(
///   onError: (error, stack) {
///     logger.error('未处理错误', error, stack);
///   },
/// );
/// ```
class AppErrorHandler {
  ErrorReporter? _reporter;

  // ignore: use_setters_to_change_properties
  void setReporter(ErrorReporter reporter) {
    _reporter = reporter;
  }

  /// 安装全局错误处理器
  ///
  /// 应在 [runApp] 之前调用。
  /// [onError] 接收错误对象和调用栈。
  void setup({required void Function(Object error, StackTrace? stack) onError}) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // 记录到统一日志
      onError(details.exception, details.stack);
      _reporter?.reportError(
        details.exception,
        details.stack,
        isFatal: details.silent != true,
      );
      // 调试模式下保留控制台输出
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      onError(error, stack);
      _reporter?.reportError(error, stack, isFatal: true);
      return true; // 错误已被处理，不崩溃
    };
  }
}
