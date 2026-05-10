import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/login_cubit.dart';
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
          final page = BlocProvider(
            create: (_) => GetIt.instance<LoginCubit>(),
            child: LoginPage(redirect: redirect),
          );
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final page = BlocProvider(
            create: (_) => GetIt.instance<LoginCubit>(),
            child: RegisterPage(redirect: redirect),
          );
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
    ];
  }
}
