import 'package:flutter/material.dart';

/// 全局 RouteObserver 单例
///
/// 职责：为 RouteAware 提供订阅源，监听路由事件
/// 使用：GoRouter.observers 参数注册
/// 使用 `ModalRoute` 泛型以兼容 GoRouter 内部路由机制。
class AppRouteObserver extends RouteObserver<ModalRoute> {
  static final AppRouteObserver _instance = AppRouteObserver._internal();

  AppRouteObserver._internal();

  /// 全局单例访问
  static AppRouteObserver get instance => _instance;
}
