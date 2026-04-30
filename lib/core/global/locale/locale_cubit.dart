import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'locale_state.dart';

/// 语言管理Cubit
///
/// 职责：管理应用语言设置，持久化用户语言偏好
/// 使用：
///   - 获取当前语言：context.read<LocaleCubit>().state.locale
///   - 切换语言：context.read<LocaleCubit>().setLocale(Locale('en'))
/// 持久化：语言设置保存到KeyValueStorage，App重启后恢复
class LocaleCubit extends Cubit<LocaleState> {
  /// KeyValueStorage用于持久化语言设置
  final KeyValueStorage _storage;

  /// 语言设置存储key
  static const String _localeKey = 'app_locale';

  LocaleCubit(this._storage) : super(LocaleState(locale: Locale('zh'))) {
    // 启动时加载已保存的语言设置
    _loadSavedLocale();
  }

  /// 加载保存的语言设置
  ///
  /// 从KeyValueStorage读取用户上次选择的语言
  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storage.getString(_localeKey);
    if (savedLocale != null) {
      emit(LocaleState(locale: Locale(savedLocale)));
    }
  }

  /// 设置语言
  ///
  /// 切换应用语言并持久化保存
  /// 支持的语言：zh（中文）、en（英文）
  Future<void> setLocale(Locale locale) async {
    // 持久化保存
    await _storage.putString(_localeKey, locale.languageCode);
    // 更新状态
    emit(LocaleState(locale: locale));
  }

  /// 重置为默认语言（中文）
  Future<void> resetToDefault() async {
    await setLocale(Locale('zh'));
  }
}