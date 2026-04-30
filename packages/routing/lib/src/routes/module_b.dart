import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Settings Tab')),
          ),
        ),
      ),
    ];
  }
}
