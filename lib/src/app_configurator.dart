import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// Application Configurator — global configuration
class AppConfigurator {
  AppConfigurator._();

  static void configureEasyLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorSize = 30.0
      ..radius = 8.0
      ..backgroundColor = Colors.black87
      ..textColor = Colors.white
      ..indicatorColor = Colors.white
      ..maskType = EasyLoadingMaskType.black
      ..maskColor = Colors.transparent;
  }
}
