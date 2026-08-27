import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'font_size.dart';

/// 语义化文字样式 Token（P0-2）
///
/// 痛点：此前 `FontSize` 只提供原子字号（`FontSize.size_16`），字重/颜色散落在各处，
/// 改一次全局字型规范要逐处改 `fontWeight` / `color`。
/// 本扩展把「字号 + 字重 + 颜色」组合成语义化样式，挂在 `ThemeData.extensions` 上，
/// Widget 层通过 `context.textStyles.titleLarge` 引用，**改一处（这里）即全局生效**。
///
/// 所有字号走 `flutter_screenutil` 的 `.sp`，必须在 `ScreenUtilInit(designSize: …)` 之后
/// 才会按设计稿比例缩放（见 `lib/app.dart`）。
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  final TextStyle displayLarge;
  final TextStyle headlineMedium;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  const AppTextStyles({
    required this.displayLarge,
    required this.headlineMedium,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelMedium,
    required this.labelSmall,
  });

  /// 亮色语义样式
  static AppTextStyles light = AppTextStyles(
    displayLarge: TextStyle(
      fontSize: FontSize.size_24,
      fontWeight: FontWeight.w700,
      color: AppColors.light.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: FontSize.size_22,
      fontWeight: FontWeight.w700,
      color: AppColors.light.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: FontSize.size_20,
      fontWeight: FontWeight.w600,
      color: AppColors.light.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: FontSize.size_18,
      fontWeight: FontWeight.w600,
      color: AppColors.light.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: FontSize.size_16,
      fontWeight: FontWeight.w600,
      color: AppColors.light.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: FontSize.size_16,
      fontWeight: FontWeight.w400,
      color: AppColors.light.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: FontSize.size_14,
      fontWeight: FontWeight.w400,
      color: AppColors.light.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: FontSize.size_12,
      fontWeight: FontWeight.w400,
      color: AppColors.light.textHint,
    ),
    labelMedium: TextStyle(
      fontSize: FontSize.size_12,
      fontWeight: FontWeight.w500,
      color: AppColors.light.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: FontSize.size_11,
      fontWeight: FontWeight.w500,
      color: AppColors.light.textHint,
    ),
  );

  /// 深色语义样式
  static AppTextStyles dark = AppTextStyles(
    displayLarge: TextStyle(
      fontSize: FontSize.size_24,
      fontWeight: FontWeight.w700,
      color: AppColors.dark.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: FontSize.size_22,
      fontWeight: FontWeight.w700,
      color: AppColors.dark.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: FontSize.size_20,
      fontWeight: FontWeight.w600,
      color: AppColors.dark.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: FontSize.size_18,
      fontWeight: FontWeight.w600,
      color: AppColors.dark.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: FontSize.size_16,
      fontWeight: FontWeight.w600,
      color: AppColors.dark.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: FontSize.size_16,
      fontWeight: FontWeight.w400,
      color: AppColors.dark.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: FontSize.size_14,
      fontWeight: FontWeight.w400,
      color: AppColors.dark.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: FontSize.size_12,
      fontWeight: FontWeight.w400,
      color: AppColors.dark.textHint,
    ),
    labelMedium: TextStyle(
      fontSize: FontSize.size_12,
      fontWeight: FontWeight.w500,
      color: AppColors.dark.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: FontSize.size_11,
      fontWeight: FontWeight.w500,
      color: AppColors.dark.textHint,
    ),
  );

  @override
  ThemeExtension<AppTextStyles> copyWith({
    TextStyle? displayLarge,
    TextStyle? headlineMedium,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
  }) {
    return AppTextStyles(
      displayLarge: displayLarge ?? this.displayLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  @override
  ThemeExtension<AppTextStyles> lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
    );
  }
}

/// BuildContext 扩展，便捷访问语义文字样式
extension AppTextStylesExtension on BuildContext {
  /// 获取当前主题的语义文字样式
  AppTextStyles get textStyles =>
      Theme.of(this).extension<AppTextStyles>() ?? AppTextStyles.light;
}
