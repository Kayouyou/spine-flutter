import 'package:sentry_flutter/sentry_flutter.dart';
import 'error_reporter.dart';

/// Sentry 错误上报实现
///
/// 当配置了 DSN 时，通过 AppErrorHandler 自动注册；
/// DSN 为空时 Sentry SDK 自动禁用，无副作用。
class SentryReporter implements ErrorReporter {
  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stack,
      withScope: (scope) {
        scope.level = isFatal ? SentryLevel.fatal : SentryLevel.error;
        if (context != null) {
          scope.setContexts('extra', context);
        }
      },
    );
  }
}