import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:locale/locale.dart';
import 'package:mocktail/mocktail.dart';

/// Mock HydratedStorage for testing
class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockHydratedStorage mockStorage;

  setUp(() {
    mockStorage = MockHydratedStorage();
    HydratedBloc.storage = mockStorage;
    when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
    when(() => mockStorage.read(any())).thenReturn(null);
  });

  group('LocaleCubit smoke test', () {
    test('can be instantiated', () {
      final cubit = LocaleCubit();
      expect(cubit, isNotNull);
    });

    test('has initial state', () {
      final cubit = LocaleCubit();
      expect(cubit.state, isNotNull);
      expect(cubit.state, isA<LocaleState>());
    });

    test('initial locale is correct (zh)', () {
      final cubit = LocaleCubit();
      expect(cubit.state.locale.languageCode, equals('zh'));
    });
  });
}