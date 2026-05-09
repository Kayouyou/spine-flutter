import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../ui/login_page.dart';
import '../ui/register_page.dart';

/// 认证路由模块
///
/// 包含路径: /login, /register
class AuthRouteModule extends RouteModule {
  const AuthRouteModule(super.ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final page = LoginPage(redirect: redirect);
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final page = RegisterPage(redirect: redirect);
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
    ];
  }
}
