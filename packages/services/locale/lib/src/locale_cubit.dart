import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'locale_state.dart';

/// 语言管理Cubit
///
/// 职责：管理应用语言设置，持久化用户语言偏好
/// 使用：
///   - 获取当前语言：context.read<LocaleCubit>().state.locale
///   - 切换语言：context.read<LocaleCubit>().setLocale(Locale('en'))
/// 持久化：通过HydratedCubit自动持久化，App重启后恢复
class LocaleCubit extends HydratedCubit<LocaleState> {
  static const String _storagePrefix = 'LocaleCubit';

  LocaleCubit() : super(LocaleState(locale: Locale('zh')));

  @override
  String get storagePrefix => _storagePrefix;

  @override
  LocaleState? fromJson(Map<String, dynamic> json) {
    final localeCode = json['locale'] as String?;
    if (localeCode != null) {
      return LocaleState(locale: Locale(localeCode));
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(LocaleState state) {
    return {'locale': state.locale.languageCode};
  }

  /// 设置语言
  ///
  /// 切换应用语言，自动通过HydratedCubit持久化
  /// 支持的语言：zh（中文）、en（英文）
  Future<void> setLocale(Locale locale) async {
    emit(LocaleState(locale: locale));
  }

  /// 重置为默认语言（中文）
  Future<void> resetToDefault() async {
    emit(LocaleState(locale: Locale('zh')));
  }
}
