import 'package:flutter_test/flutter_test.dart';
import 'package:error/error.dart';

class _TestReporter implements ErrorReporter {
  int callCount = 0;
  Object? lastError;
  StackTrace? lastStack;
  bool? lastFatal;
  Map<String, dynamic>? lastContext;

  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    callCount++;
    lastError = error;
    lastStack = stack;
    lastFatal = isFatal;
    lastContext = context;
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

  group('AppErrorHandler.reportError', () {
    late AppErrorHandler handler;
    late _TestReporter reporter;

    setUp(() {
      handler = AppErrorHandler.instance;
      reporter = _TestReporter();
      handler.setReporter(reporter);
    });

    tearDown(() {
      handler.setReporter(_NullReporter());
    });

    test('forwards error / stack / isFatal / context to reporter', () {
      final stack = StackTrace.current;
      handler.reportError(
        Exception('boom'),
        stack,
        isFatal: true,
        context: {'k': 'v'},
      );
      expect(reporter.callCount, 1);
      expect(reporter.lastError, isA<Exception>());
      expect(reporter.lastStack, same(stack));
      expect(reporter.lastFatal, isTrue);
      expect(reporter.lastContext, {'k': 'v'});
    });

    test('de-duplicates same hash within 1 second', () {
      final err = Exception('dup');
      final stack = StackTrace.current;
      handler.reportError(err, stack);
      handler.reportError(err, stack);
      handler.reportError(err, stack);
      expect(reporter.callCount, 1);
    });

    test('forwards same error after 1 second window', () async {
      final err = Exception('tick');
      handler.reportError(err, StackTrace.current);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      handler.reportError(err, StackTrace.current);
      expect(reporter.callCount, 2);
    });

    test('forwards different errors immediately', () {
      handler.reportError(Exception('a'), StackTrace.current);
      handler.reportError(Exception('b'), StackTrace.current);
      expect(reporter.callCount, 2);
    });
  });
}

class _NullReporter implements ErrorReporter {
  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {}
}
