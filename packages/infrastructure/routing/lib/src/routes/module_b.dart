import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:feature_auth/feature_auth.dart';
import 'route_context.dart';
import 'route_module.dart';

/// Module B — Auth routes (login/register)
class ModuleBRouteModule extends RouteModule {
  ModuleBRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      // TODO: 添加 Settings 路由（设置页面开发完成后）
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
