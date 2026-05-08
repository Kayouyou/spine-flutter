import 'package:flutter/material.dart';
import 'package:auth/auth.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart';

/// 路由上下文 — 封装每个页面构建时需要的依赖
///
/// routeWrapper：由 app 层提供，用于在路由页面外层包裹通用组件
/// （如 RequestScope 实现自动请求取消）
class RouteContext {
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthManager? authManager;
  final bool enableAuthGuard;

  /// 由 app 层提供的页面包装器，用于在每个路由页面上层包裹通用组件
  ///
  /// 典型用途：包装 RequestScope 实现页面级请求自动取消
  final Widget Function(Widget child)? routeWrapper;

  /// Cubit 工厂函数 — 由 app 层从 DI 容器中获取
  final HomeCubit Function()? homeCubitFactory;
  final DetailCubit Function()? detailCubitFactory;

  /// 调试模式标志 — 由 app 层注入，避免 feature 包反向依赖 my_app
  final bool debugMode;

  const RouteContext({
    required this.navigatorKey,
    this.authManager,
    this.enableAuthGuard = true,
    this.routeWrapper,
    this.homeCubitFactory,
    this.detailCubitFactory,
    this.debugMode = false,
  });
}
