import 'package:flutter/material.dart';
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
        break;
    }
  }

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
