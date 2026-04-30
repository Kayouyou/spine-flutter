import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 语言状态
///
/// 职责：管理当前应用语言设置
/// 使用：通过LocaleCubit emit切换语言
class LocaleState extends Equatable {
  /// 当前语言
  final Locale locale;

  LocaleState({required this.locale});

  /// 复制并修改
  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }

  @override
  List<Object?> get props => [locale];
}