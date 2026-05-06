import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_context.dart';
import 'route_module.dart';

/// Module A — Home tab route
class ModuleARouteModule extends RouteModule {
  ModuleARouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          // 构建页面内容，并用 routeWrapper 包裹以支持 RequestScope 等功能
          Widget page = const Scaffold(
            body: Center(child: Text('Home Tab')),
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
