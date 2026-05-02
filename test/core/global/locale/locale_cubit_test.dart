// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:locale/locale.dart';
import 'package:mocktail/mocktail.dart';

/// Mock KeyValueStorage
class MockKeyValueStorage extends Mock implements KeyValueStorage {}

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
    late MockKeyValueStorage mockStorage;

    setUp(() {
      mockStorage = MockKeyValueStorage();
      // 默认返回null（无保存的语言设置）
      when(() => mockStorage.getString(any())).thenAnswer((_) async => null);
      when(() => mockStorage.putString(any(), any())).thenAnswer((_) async {});
    });

    blocTest<LocaleCubit, LocaleState>(
      '初始状态为中文',
      build: () => LocaleCubit(mockStorage),
      verify: (cubit) {
        expect(cubit.state.locale.languageCode, equals('zh'));
      },
    );

    blocTest<LocaleCubit, LocaleState>(
      'setLocale切换语言',
      build: () => LocaleCubit(mockStorage),
      act: (cubit) => cubit.setLocale(Locale('en')),
      expect: () => [
        LocaleState(locale: Locale('en')),
      ],
      verify: (cubit) {
        // 验证语言已持久化
        verify(() => mockStorage.putString('app_locale', 'en')).called(1);
      },
    );

    blocTest<LocaleCubit, LocaleState>(
      '加载已保存的语言设置',
      setUp: () {
        // 模拟已保存英文设置
        when(() => mockStorage.getString('app_locale'))
            .thenAnswer((_) async => 'en');
      },
      build: () => LocaleCubit(mockStorage),
      // 构造函数中自动加载
      wait: const Duration(milliseconds: 100),
      expect: () => [
        LocaleState(locale: Locale('en')),
      ],
    );

    blocTest<LocaleCubit, LocaleState>(
      'resetToDefault切换回中文',
      build: () => LocaleCubit(mockStorage),
      act: (cubit) => cubit.resetToDefault(),
      expect: () => [
        LocaleState(locale: Locale('zh')),
      ],
    );
  });
}
