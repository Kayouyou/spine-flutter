import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:feature_home/src/cubit/home_state.dart';
import 'package:domain/domain.dart';

class MockHomeRepo extends Mock implements HomeRepository {}

void main() {
  group('HomeCubit with caching', () {
    late MockHomeRepo mockRepo;

    setUp(() {
      mockRepo = MockHomeRepo();
    });

    blocTest<HomeCubit, HomeState>(
      'loadData emits loading then loaded on success',
      build: () {
        when(() => mockRepo.getHomeData())
            .thenAnswer((_) async => Result.success<HomeData, DomainException>(
                const HomeData(title: 'cached'),),);
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
      verify: (cubit) {
        final loadedState = cubit.state as HomeLoaded;
        expect(loadedState.data.title, 'cached');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'refreshData emits loading then loaded on refresh',
      build: () {
        when(() => mockRepo.refreshHomeData())
            .thenAnswer((_) async => Result.success<HomeData, DomainException>(
                const HomeData(title: 'refreshed'),),);
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.refreshData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
      verify: (cubit) {
        expect((cubit.state as HomeLoaded).data.title, 'refreshed');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'loadData emits loading then error on failure',
      build: () {
        when(() => mockRepo.getHomeData())
            .thenAnswer((_) async => Result.failure<HomeData, DomainException>(
              const NetworkException('server error', statusCode: 500),),);
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>(),
      ],
      verify: (cubit) {
        expect(cubit.state, isA<HomeError>());
      },
    );
  });
}
