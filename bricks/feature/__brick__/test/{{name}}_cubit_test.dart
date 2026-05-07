import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_{{name}}/feature_{{name}}.dart';

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
      'loadData 发出 loading 然后 loaded',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => {'test': 'data'});
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(data: {'test': 'data'}),
      ],
      verify: (_) {
        verify(() => mockRepository.get{{name.pascalCase()}}Data()).called(1);
      },
    );

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'refreshData 发出 loading 然后 loaded',
      build: () {
        when(() => mockRepository.refresh{{name.pascalCase()}}Data())
            .thenAnswer((_) async => {'test': 'refreshed'});
        return cubit;
      },
      act: (cubit) => cubit.refreshData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(data: {'test': 'refreshed'}),
      ],
      verify: (_) {
        verify(() => mockRepository.refresh{{name.pascalCase()}}Data()).called(1);
      },
    );

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'retry 调用 loadData',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => {'test': 'retry'});
        return cubit;
      },
      act: (cubit) => cubit.retry(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(data: {'test': 'retry'}),
      ],
      verify: (_) {
        verify(() => mockRepository.get{{name.pascalCase()}}Data()).called(1);
      },
    );
  });
}