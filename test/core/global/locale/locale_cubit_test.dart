// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:locale/locale.dart';
import 'package:mocktail/mocktail.dart';

/// Mock HydratedStorage
class MockHydratedStorage extends Mock implements HydratedStorage {}

/// LocaleCubit TDD测试
///
/// TDD流程：
/// 1. 写测试 - 验证失败
/// 2. 实现 - 验证通过
void main() {
  group('LocaleState', () {
    test('携带Locale信息', () {
      final state = LocaleState(locale: Locale('zh'));
      expect(state.locale.languageCode, equals('zh'));
    });

    test('copyWith可修改locale', () {
      final state = LocaleState(locale: Locale('zh'));
      final newState = state.copyWith(locale: Locale('en'));
      expect(newState.locale.languageCode, equals('en'));
    });
  });

  group('LocaleCubit', () {
    late MockHydratedStorage mockStorage;

    setUp(() {
      mockStorage = MockHydratedStorage();
      HydratedBloc.storage = mockStorage;
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
      when(() => mockStorage.read(any())).thenReturn(null);
    });

    blocTest<LocaleCubit, LocaleState>(
      '初始状态为中文',
      build: () => LocaleCubit(),
      verify: (cubit) {
        expect(cubit.state.locale.languageCode, equals('zh'));
      },
    );

    blocTest<LocaleCubit, LocaleState>(
      'setLocale切换语言',
      build: () => LocaleCubit(),
      act: (cubit) => cubit.setLocale(Locale('en')),
      expect: () => [
        LocaleState(locale: Locale('en')),
      ],
    );

    test('fromJson正确恢复语言设置', () {
      final cubit = LocaleCubit();
      final state = cubit.fromJson({'locale': 'en'});
      expect(state, isNotNull);
      expect(state!.locale.languageCode, equals('en'));
    });

    test('fromJson返回null处理无效数据', () {
      final cubit = LocaleCubit();
      expect(cubit.fromJson(<String, dynamic>{}), isNull);
    });

    test('toJson正确序列化语言设置', () {
      final cubit = LocaleCubit();
      final json = cubit.toJson(LocaleState(locale: Locale('en')));
      expect(json, equals({'locale': 'en'}));
    });

    blocTest<LocaleCubit, LocaleState>(
      'resetToDefault切换回中文',
      build: () => LocaleCubit(),
      act: (cubit) => cubit.resetToDefault(),
      expect: () => [
        LocaleState(locale: Locale('zh')),
      ],
    );
  });
}
