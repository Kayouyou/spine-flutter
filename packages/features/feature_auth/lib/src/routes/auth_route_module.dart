import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/login_cubit.dart';
import '../ui/login_page.dart';
import '../ui/register_page.dart';

class AuthRouteModule extends RouteModule {
  final LoginCubit Function() createCubit;

  const AuthRouteModule(
    super.ctx, {
    required this.createCubit,
  });

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final page = BlocProvider(
            create: (_) => createCubit(),
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
            create: (_) => createCubit(),
            child: RegisterPage(redirect: redirect),
          );
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
    ];
  }
}
