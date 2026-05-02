import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_home/feature_home.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository mockRepo;

  setUp(() {
    mockRepo = MockHomeRepository();
  });

  group('HomeCubit', () {
    blocTest<HomeCubit, HomeState>(
      'loadData 成功时发出 [loading, loaded]',
      build: () {
        when(() => mockRepo.getHomeData()).thenAnswer(
          (_) async => <String, dynamic>{},
        );
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'loadData 失败时发出 [loading, error]',
      build: () {
        when(() => mockRepo.getHomeData()).thenThrow(
          const NetworkException('连接失败'),
        );
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>(),
      ],
    );
  });
}
