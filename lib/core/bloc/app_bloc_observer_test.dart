// lib/core/bloc/app_bloc_observer_test.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:error/error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'app_bloc_observer.dart';

class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);
}

class _NullReporter implements ErrorReporter {
  final List<Object> errors = [];
  final List<StackTrace?> stacks = [];
  final List<Map<String, dynamic>?> contexts = [];

  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    errors.add(error);
    stacks.add(stack);
    contexts.add(context);
  }
}

void main() {
  group('AppBlocObserver.onError', () {
    late _NullReporter reporter;

    setUp(() {
      reporter = _NullReporter();
      AppErrorHandler.instance.setReporter(reporter);
    });

    test('forwards cubit error with bloc/source context', () {
      final observer = AppBlocObserver();
      final cubit = _TestCubit();
      final stack = StackTrace.current;

      observer.onError(cubit, StateError('boom from cubit'), stack);

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first, isA<StateError>());
      expect(reporter.stacks.first, same(stack));
      expect(reporter.contexts.first, {
        'source': 'bloc',
        'bloc': '_TestCubit',
      });
    });
  });
}
