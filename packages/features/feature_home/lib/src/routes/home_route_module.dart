import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/home_cubit.dart';
import '../ui/home_page.dart';

class HomeRouteModule extends RouteModule {
  final HomeCubit Function() createCubit;
  final VoidCallback? onOpenDebugInspector;

  const HomeRouteModule(
    super.ctx, {
    required this.createCubit,
    this.onOpenDebugInspector,
  });

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          Widget page = BlocProvider(
            create: (_) => createCubit(),
            child: HomePage(
              onOpenDebugInspector: onOpenDebugInspector,
            ),
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return MaterialPage(child: page);
        },
      ),
    ];
  }
}
