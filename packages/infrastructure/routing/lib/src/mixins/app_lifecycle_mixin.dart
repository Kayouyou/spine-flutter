import 'package:flutter/material.dart';

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
}
