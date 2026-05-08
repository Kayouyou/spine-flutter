import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_test_mason/feature_test_mason.dart';

class MockTestMasonRepository extends Mock implements TestMasonRepository {}

void main() {
  group('TestMasonCubit', () {
    late TestMasonCubit cubit;
    late MockTestMasonRepository mockRepository;

    setUp(() {
      mockRepository = MockTestMasonRepository();
      cubit = TestMasonCubit(mockRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('初始状态是 TestMasonInitial', () {
      expect(cubit.state, const TestMasonState.initial());
    });

    blocTest<TestMasonCubit, TestMasonState>(
      'loadData 发出 loading 然后 loaded',
      build: () {
        when(() => mockRepository.getTestMasonData())
            .thenAnswer((_) async => {'test': 'data'});
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const TestMasonState.loading(),
        const TestMasonState.loaded(data: {'test': 'data'}),
      ],
      verify: (_) {
        verify(() => mockRepository.getTestMasonData()).called(1);
      },
    );

    blocTest<TestMasonCubit, TestMasonState>(
      'refreshData 发出 loading 然后 loaded',
      build: () {
        when(() => mockRepository.refreshTestMasonData())
            .thenAnswer((_) async => {'test': 'refreshed'});
        return cubit;
      },
      act: (cubit) => cubit.refreshData(),
      expect: () => [
        const TestMasonState.loading(),
        const TestMasonState.loaded(data: {'test': 'refreshed'}),
      ],
      verify: (_) {
        verify(() => mockRepository.refreshTestMasonData()).called(1);
      },
    );

    blocTest<TestMasonCubit, TestMasonState>(
      'retry 调用 loadData',
      build: () {
        when(() => mockRepository.getTestMasonData())
            .thenAnswer((_) async => {'test': 'retry'});
        return cubit;
      },
      act: (cubit) => cubit.retry(),
      expect: () => [
        const TestMasonState.loading(),
        const TestMasonState.loaded(data: {'test': 'retry'}),
      ],
      verify: (_) {
        verify(() => mockRepository.getTestMasonData()).called(1);
      },
    );
  });
}