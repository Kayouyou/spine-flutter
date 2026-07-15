// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:component_library/component_library.dart';

/// 亮色主题
ThemeData get appLightTheme => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.light,
).copyWith(extensions: [AppColors.light, AppTextStyles.light]);

/// 深色主题
ThemeData get appDarkTheme => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.dark,
).copyWith(extensions: [AppColors.dark, AppTextStyles.dark]);