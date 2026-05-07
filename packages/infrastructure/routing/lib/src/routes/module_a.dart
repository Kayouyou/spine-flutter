import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:feature_home/feature_home.dart';

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
          Widget page = BlocProvider(
            create: (_) => ctx.homeCubitFactory!(),
            child: const HomePage(),
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
