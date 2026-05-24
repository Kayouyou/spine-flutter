import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:feature_{{name.snakeCase()}}/feature_{{name.snakeCase()}}.dart';

class Mock{{name.pascalCase()}}Repository extends Mock implements {{name.pascalCase()}}Repository {}

void main() {
  group('{{name.pascalCase()}}Cubit', () {
    late {{name.pascalCase()}}Cubit cubit;
    late Mock{{name.pascalCase()}}Repository mockRepository;

    setUp(() {
      mockRepository = Mock{{name.pascalCase()}}Repository();
      cubit = {{name.pascalCase()}}Cubit(mockRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('初始状态是 {{name.pascalCase()}}Initial', () {
      expect(cubit.state, const {{name.pascalCase()}}State.initial());
    });

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'loadData 发出 loading 然后 loaded（成功）',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => Result.success({'test': 'data'}));
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(data: {'test': 'data'}),
      ],
    );

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'loadData 发出 loading 然后 error（失败）',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => Result.failure(const NetworkException('网络错误')));
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.error(errorCode: '网络错误'),
      ],
    );
  });
}
