import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/home_cubit.dart';
import '../ui/home_page.dart';

/// 首页路由模块
///
/// 包含路径: /home
class HomeRouteModule extends RouteModule {
  const HomeRouteModule(super.ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          Widget page = BlocProvider(
            create: (_) => GetIt.instance<HomeCubit>(),
            child: const HomePage(),
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
