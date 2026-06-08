// packages/services/error/lib/src/error_handler.dart
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'error_reporter.dart';

/// 全局错误边界处理器
///
/// 安装后，所有 Flutter 框架和平台级别的未捕获错误
/// 都会通过 [onError] 回调被统一处理。
///
/// 业务代码可调用 [reportError] 上报自定义错误，
/// 内部使用 LRU 集(16 项 × 1 秒)对重复上报做去重。
///
/// 使用方式：
/// ```dart
/// AppErrorHandler.instance.setup(
///   onError: (error, stack) {
///     logger.error('未处理错误', error, stack);
///   },
/// );
///
/// // 注册 SentryReporter（DSN 不为空时）
/// if (EnvironmentConfig.sentryDsn.isNotEmpty) {
///   AppErrorHandler.instance.setReporter(SentryReporter());
/// }
///
/// // 业务层上报
/// AppErrorHandler.instance.reportError(
///   err,
///   stack,
///   isFatal: true,
///   context: {'source': 'dio', 'method': 'GET', 'url': '/api/x'},
/// );
/// ```
class AppErrorHandler {
  /// 单例实例
  static final instance = AppErrorHandler._();

  ErrorReporter? _reporter;

  /// LRU 去重表：hash -> 最后上报时间
  /// LinkedHashMap 默认按插入顺序迭代,evict 第一个 key 即最旧
  final LinkedHashMap<int, DateTime> _recentReports = LinkedHashMap();

  /// LRU 容量
  static const int _lruCapacity = 16;

  /// 去重时间窗
  static const Duration _dedupWindow = Duration(seconds: 1);

  /// 私有构造函数（单例模式）
  AppErrorHandler._();

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
      onError(details.exception, details.stack);
      _reporter?.reportError(
        details.exception,
        details.stack,
        isFatal: details.silent != true,
      );
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      onError(error, stack);
      _reporter?.reportError(error, stack, isFatal: true);
      return true;
    };
  }

  /// 上报一个错误到当前 [reporter]。
  ///
  /// 调用方应传入 [context] 标注错误来源(如 `{'source': 'dio'}`)。
  /// 内部用 (runtimeType, toString, stack) 算 hash,
  /// 在 [_dedupWindow] 内同一 hash 只会上报一次,避免 retry / 循环上报刷屏。
  void reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) {
    final hash = Object.hash(
      error.runtimeType,
      error.toString(),
      stack?.toString() ?? '',
    );
    final now = DateTime.now();
    final last = _recentReports[hash];
    if (last != null && now.difference(last) < _dedupWindow) {
      return;
    }
    _recentReports[hash] = now;
    if (_recentReports.length > _lruCapacity) {
      _recentReports.remove(_recentReports.keys.first);
    }
    // fire-and-forget：与 FlutterError.onError 内部行为保持一致
    // ignore: discarded_futures
    _reporter?.reportError(error, stack, isFatal: isFatal, context: context);
  }
}
