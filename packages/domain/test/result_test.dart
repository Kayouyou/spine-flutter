import 'package:test/test.dart';
import 'package:domain/domain.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('isSuccess returns true', () {
        const result = Success<int, Exception>(42);
        expect(result.isSuccess, true);
      });

      test('isFailure returns false', () {
        const result = Success<int, Exception>(42);
        expect(result.isFailure, false);
      });

      test('when calls success callback', () {
        const result = Success<int, Exception>(42);
        final value = result.when(
          success: (data) => data * 2,
          failure: (error) => -1,
        );
        expect(value, 84);
      });

      test('getOrElse returns data', () {
        const result = Success<int, Exception>(42);
        expect(result.getOrElse(0), 42);
      });

      test('map transforms data', () {
        const result = Success<int, Exception>(21);
        final mapped = result.map((data) => data * 2);
        expect(mapped, const Success<int, Exception>(42));
      });

      test('dataOrThrow returns data', () {
        const result = Success<int, Exception>(42);
        expect(result.dataOrThrow, 42);
      });
    });

    group('Failure', () {
      test('isSuccess returns false', () {
        final result = Failure<int, Exception>(Exception('error'));
        expect(result.isSuccess, false);
      });

      test('isFailure returns true', () {
        final result = Failure<int, Exception>(Exception('error'));
        expect(result.isFailure, true);
      });

      test('when calls failure callback', () {
        final error = Exception('test error');
        final result = Failure<int, Exception>(error);
        final value = result.when(
          success: (data) => -1,
          failure: (e) => e.toString(),
        );
        expect(value, 'Exception: test error');
      });

      test('getOrElse returns default', () {
        final result = Failure<int, Exception>(Exception('error'));
        expect(result.getOrElse(42), 42);
      });

      test('mapError transforms error', () {
        final error = Exception('original');
        final result = Failure<int, Exception>(error);
        final mapped =
            result.mapError((e) => Exception('transformed: ${e.toString()}'));
        expect(
          (mapped as Failure).error.toString(),
          'Exception: transformed: Exception: original',
        );
      });

      test('dataOrThrow throws', () {
        final result = Failure<int, Exception>(Exception('error'));
        expect(() => result.dataOrThrow, throwsException);
      });
    });

    group('type safety', () {
      test('Success instances are equal if same values', () {
        const s1 = Success<int, Exception>(42);
        const s2 = Success<int, Exception>(42);
        expect(s1, equals(s2));
      });

      test('Success instances are not equal for different values', () {
        const s1 = Success<int, Exception>(42);
        const s2 = Success<int, Exception>(0);
        expect(s1, isNot(equals(s2)));
      });

      test('Failure delegates equality to wrapped error', () {
        final error = Exception('error');
        final f1 = Failure<int, Exception>(error);
        final f2 = Failure<int, Exception>(error);
        // Same error instance => identical => equal
        expect(f1, equals(f2));
      });
    });
  });
}
