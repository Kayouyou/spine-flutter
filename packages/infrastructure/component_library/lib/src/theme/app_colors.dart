import 'package:flutter/material.dart';

/// 应用颜色主题扩展
///
/// 使用：context.colors.primary
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color cardBackground;
  final Color scaffoldBackground;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.cardBackground,
    required this.scaffoldBackground,
  });

  /// 亮色主题颜色
  static const AppColors light = AppColors(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF26A69A),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF9800),
    error: Color(0xFFF44336),
    info: Color(0xFF2196F3),
    backgroundLight: Color(0xFFF5F5F5),
    backgroundDark: Color(0xFF121212),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    textHint: Color(0xFF9E9E9E),
    border: Color(0xFFE0E0E0),
    divider: Color(0xFFEEEEEE),
    cardBackground: Color(0xFFFFFFFF),
    scaffoldBackground: Color(0xFFF5F5F5),
  );

  /// 深色主题颜色
  static const AppColors dark = AppColors(
    primary: Color(0xFF42A5F5),
    secondary: Color(0xFF4DB6AC),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFE57373),
    info: Color(0xFF64B5F6),
    backgroundLight: Color(0xFF1E1E1E),
    backgroundDark: Color(0xFF000000),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF9E9E9E),
    textHint: Color(0xFF616161),
    border: Color(0xFF424242),
    divider: Color(0xFF303030),
    cardBackground: Color(0xFF2C2C2C),
    scaffoldBackground: Color(0xFF121212),
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? cardBackground,
    Color? scaffoldBackground,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      cardBackground: cardBackground ?? this.cardBackground,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
    );
  }
}

/// BuildContext 扩展，便捷访问颜色主题
extension AppColorsExtension on BuildContext {
  /// 获取当前主题颜色
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
