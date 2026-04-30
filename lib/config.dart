import 'package:flutter/foundation.dart';

/// Environment configuration
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
