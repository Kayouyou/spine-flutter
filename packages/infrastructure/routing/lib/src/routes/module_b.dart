import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:feature_auth/feature_auth.dart';
import 'route_context.dart';
import 'route_module.dart';

/// Module B — Settings tab route
class ModuleBRouteModule extends RouteModule {
  ModuleBRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) {
          // 构建页面内容，并用 routeWrapper 包裹以支持 RequestScope 等功能
          Widget page = const Scaffold(
            body: Center(child: Text('Settings Tab')),
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          Widget page = LoginPage(
            redirect: state.uri.queryParameters['redirect'],
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          Widget page = RegisterPage(
            redirect: state.uri.queryParameters['redirect'],
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
    ];
  }
}
