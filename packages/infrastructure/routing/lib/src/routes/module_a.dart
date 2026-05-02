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
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Home Tab')),
          ),
        ),
      ),
    ];
  }
}
