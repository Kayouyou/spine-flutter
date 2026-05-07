import 'package:flutter_test/flutter_test.dart';
import 'package:error/error.dart';

class _TestReporter implements ErrorReporter {
  Object? lastError;
  bool? lastFatal;

  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    lastError = error;
    lastFatal = isFatal;
  }
}

void main() {
  test('ConsoleReporter does not throw', () async {
    final reporter = ConsoleReporter();
    await reporter.reportError(Exception('test'), StackTrace.current);
  });

  test('ErrorReporter interface can be implemented', () {
    final impl = _TestReporter();
    expect(impl, isA<ErrorReporter>());
  });
}
