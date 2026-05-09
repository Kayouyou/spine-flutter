import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_detail/src/cubit/detail_cubit.dart';
import 'package:feature_detail/src/cubit/detail_state.dart';
import 'package:domain/domain.dart';

class MockDetailRepo extends Mock implements DetailRepository {}

void main() {
  group('DetailCubit', () {
    late MockDetailRepo mockRepo;

    setUp(() {
      mockRepo = MockDetailRepo();
    });

    blocTest<DetailCubit, DetailState>(
      'initial state is DetailInitial',
      build: () => DetailCubit(mockRepo),
      verify: (cubit) {
        expect(cubit.state, isA<DetailState>());
      },
    );

    blocTest<DetailCubit, DetailState>(
      'loadData emits loading then loaded on success',
      build: () {
        when(() => mockRepo.getDetailData('1'))
            .thenAnswer((_) async => Result.success<Map<String, dynamic>, DomainException>({'title': 'detail'}));
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailState>(),
        isA<DetailState>(),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'loadData emits loading then error on failure',
      build: () {
        when(() => mockRepo.getDetailData('1'))
            .thenAnswer((_) async => Result.failure<Map<String, dynamic>, DomainException>(const NotFoundException()));
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailState>(),
        isA<DetailState>(),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'retry calls loadData with same id',
      build: () {
        when(() => mockRepo.getDetailData('42'))
            .thenAnswer((_) async => Result.success<Map<String, dynamic>, DomainException>({'retry': 'ok'}));
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.retry('42'),
      expect: () => [
        isA<DetailState>(),
        isA<DetailState>(),
      ],
    );
  });
}
