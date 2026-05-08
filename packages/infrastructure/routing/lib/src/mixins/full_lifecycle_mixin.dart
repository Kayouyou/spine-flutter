import 'dart:ui' show AppExitResponse, ViewFocusEvent;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;

import '../route_observer.dart';

/// 完整生命周期 mixin（RouteAware + WidgetsBindingObserver）
///
/// 职责：监听路由事件 + App 前后台切换
/// 使用：State 类 mixin FullLifecycleMixin<T>
/// 适用：视频播放器、计时器、实时数据等需要完整监听的页面
mixin FullLifecycleMixin<T extends StatefulWidget> on State<T>
    implements RouteAware, WidgetsBindingObserver {
  // RouteAware 回调（路由事件）
  void onPageEnter() {}
  void onPageLeave() {}
  void onPageCovered() {}
  void onPageRevealed() {}

  // WidgetsBindingObserver 回调（前后台切换）
  void onAppPaused() {}
  void onAppResumed() {}
  void onAppInactive() {}

  // RouteAware 实现
  @override
  void didPush() => onPageEnter();
  @override
  void didPop() => onPageLeave();
  @override
  void didPushNext() => onPageCovered();
  @override
  void didPopNext() => onPageRevealed();

  // WidgetsBindingObserver 实现
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
  void didChangeMetrics() {}
  @override
  void didChangeTextScaleFactor() {}
  @override
  void didChangePlatformBrightness() {}
  @override
  void didChangeLocales(List<Locale>? locales) {}
  @override
  void didHaveMemoryPressure() {}
  @override
  void didChangeAccessibilityFeatures() {}
  @override
  Future<bool> didPopRoute() => Future<bool>.value(false);
  @override
  Future<bool> didPushRoute(String route) => Future<bool>.value(false);
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) =>
      Future<bool>.value(false);

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouteObserver.instance.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    AppRouteObserver.instance.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
