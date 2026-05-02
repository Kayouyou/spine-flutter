// Flutter imports:
import 'package:flutter/foundation.dart';

/// 环境配置
///
/// CHANNEL/DEBUG 来自编译时环境变量，按惯例使用大写下划线命名。
// ignore_for_file: constant_identifier_names
class EnvironmentConfig {
  static const CHANNEL = String.fromEnvironment('CHANNEL');
  static const DEBUG = String.fromEnvironment('DEBUG');
}

/// Application configuration
class AppConfig {
  static const String appName = 'My App';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.example.myapp';
  static const String appChannel = 'stable';
  static bool isDebug = kDebugMode;
}
