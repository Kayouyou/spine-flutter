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
        expect(cubit.state, isA<DetailInitial>());
      },
    );

    blocTest<DetailCubit, DetailState>(
      'loadData emits loading then loaded on success',
      build: () {
        when(() => mockRepo.getDetailData('1'))
            .thenAnswer((_) async => Result.success<DetailData, DomainException>(
                const DetailData(id: '1', title: 'detail'),),);
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>(),
      ],
      verify: (cubit) {
        final loadedState = cubit.state as DetailLoaded;
        expect(loadedState.data.id, '1');
        expect(loadedState.data.title, 'detail');
      },
    );

    blocTest<DetailCubit, DetailState>(
      'loadData emits loading then error on failure',
      build: () {
        when(() => mockRepo.getDetailData('1'))
            .thenAnswer((_) async => Result.failure<DetailData, DomainException>(const NotFoundException()));
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailError>(),
      ],
      verify: (cubit) {
        expect(cubit.state, isA<DetailError>());
      },
    );

    blocTest<DetailCubit, DetailState>(
      'retry calls loadData with same id',
      build: () {
        when(() => mockRepo.getDetailData('42'))
            .thenAnswer((_) async => Result.success<DetailData, DomainException>(
                const DetailData(id: '42', title: 'retry'),),);
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.retry('42'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>(),
      ],
      verify: (cubit) {
        expect((cubit.state as DetailLoaded).data.id, '42');
      },
    );
  });
}
