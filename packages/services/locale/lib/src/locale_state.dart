import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_state.freezed.dart';

/// 语言状态
///
/// 职责：管理当前应用语言设置
/// 使用：通过LocaleCubit emit切换语言
@freezed
class LocaleState with _$LocaleState {
  const factory LocaleState({
    required Locale locale,
  }) = _LocaleState;
}
