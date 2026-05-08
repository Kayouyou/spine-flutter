import 'dart:ui' show AppExitResponse, ViewFocusEvent;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;

/// App 生命周期 mixin（WidgetsBindingObserver）
///
/// 职责：监听 App 前后台切换
/// 使用：State 类 mixin AppLifecycleMixin<T>
/// 回调：onAppPaused、onAppResumed、onAppInactive
mixin AppLifecycleMixin<T extends StatefulWidget> on State<T> implements WidgetsBindingObserver {
  void onAppPaused() {}
  void onAppResumed() {}
  void onAppInactive() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        onAppPaused();
        break;
      case AppLifecycleState.resumed:
        onAppResumed();
        break;
      case AppLifecycleState.inactive:
        onAppInactive();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // WidgetsBindingObserver default implementations
  @override
  void didChangeMetrics() {}
  @override
  void didChangeTextScaleFactor() {}
  @override
  void didChangePlatformBrightness() {}
  @override
  void didChangeLocales(List<Locale>? locales) {}
  @override
  void didChangeAccessibilityFeatures() {}
  @override
  void didHaveMemoryPressure() {}
  @override
  Future<bool> didPopRoute() => Future<bool>.value(false);
  @override
  Future<bool> didPushRoute(String route) => Future<bool>.value(false);
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) => Future<bool>.value(false);
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) => false;
  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {}
  @override
  void handleCommitBackGesture() {}
  @override
  void handleCancelBackGesture() {}
  @override
  void didChangeViewFocus(ViewFocusEvent event) {}
  @override
  Future<AppExitResponse> didRequestAppExit() async => AppExitResponse.exit;
}
