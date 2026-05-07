import 'package:flutter/foundation.dart';

abstract class ErrorReporter {
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  });
}

class ConsoleReporter implements ErrorReporter {
  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('=== ERROR REPORT ===');
    debugPrint('Fatal: $isFatal');
    debugPrint('Error: $error');
    if (stack != null) debugPrint('Stack: $stack');
    debugPrint('====================');
  }
}
