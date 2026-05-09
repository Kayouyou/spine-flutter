// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'app_colors.dart';

/// 亮色主题
ThemeData get appLightTheme => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.light,
).copyWith(extensions: [AppColors.light]);

/// 深色主题
ThemeData get appDarkTheme => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.dark,
).copyWith(extensions: [AppColors.dark]);