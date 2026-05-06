import 'package:bloc_test/bloc_test.dart';
import 'package:domain/domain.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDetailRepository extends Mock implements DetailRepository {}

void main() {
  late MockDetailRepository repository;
  late DetailCubit cubit;

  setUp(() {
    repository = MockDetailRepository();
    cubit = DetailCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('DetailCubit', () {
    blocTest<DetailCubit, DetailState>(
      'loadData success emits [DetailLoading, DetailLoaded]',
      build: () {
        when(() => repository.getDetailData(any()))
            .thenAnswer((_) async => <String, dynamic>{'id': '1', 'name': 'test'});
        return cubit;
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>().having(
          (s) => s.data,
          'data',
          {'id': '1', 'name': 'test'},
        ),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'loadData failure emits [DetailLoading, DetailError]',
      build: () {
        when(() => repository.getDetailData(any()))
            .thenThrow(const NetworkException('网络请求失败'));
        return cubit;
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailError>().having(
          (s) => s.errorCode,
          'errorCode',
          '网络请求失败',
        ),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'retry reload emits [DetailLoading, DetailLoaded] after failure',
      build: () {
        when(() => repository.getDetailData(any())).thenAnswer(
          (invocation) async {
            final id = invocation.positionalArguments[0] as String;
            if (id == 'fail') {
              throw const NetworkException('网络请求失败');
            }
            return <String, dynamic>{'id': id, 'name': 'retry success'};
          },
        );
        return cubit;
      },
      act: (cubit) async {
        await cubit.loadData('fail');
        await cubit.retry('success');
      },
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailError>().having(
          (s) => s.errorCode,
          'errorCode',
          '网络请求失败',
        ),
        isA<DetailLoading>(),
        isA<DetailLoaded>().having(
          (s) => s.data,
          'data',
          {'id': 'success', 'name': 'retry success'},
        ),
      ],
    );
  });
}
