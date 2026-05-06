import 'package:flutter/material.dart';
import '../route_observer.dart';

/// 页面生命周期 mixin（RouteAware）
///
/// 职责：监听路由事件（页面进入/离开）
/// 使用：State 类 mixin LifecycleMixin<T>
/// 回调：onPageEnter、onPageLeave、onPageCovered、onPageRevealed
mixin LifecycleMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  void onPageEnter() {}
  void onPageLeave() {}
  void onPageCovered() {}
  void onPageRevealed() {}

  @override
  void didPush() => onPageEnter();
  @override
  void didPop() => onPageLeave();
  @override
  void didPushNext() => onPageCovered();
  @override
  void didPopNext() => onPageRevealed();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouteObserver.instance.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AppRouteObserver.instance.unsubscribe(this);
    super.dispose();
  }
}
