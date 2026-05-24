import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/detail_cubit.dart';
import '../ui/detail_page.dart';

class DetailRouteModule extends RouteModule {
  final DetailCubit Function() createCubit;

  const DetailRouteModule(
    super.ctx, {
    required this.createCubit,
  });

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/detail',
        pageBuilder: (context, state) {
          Widget page = BlocProvider(
            create: (_) => createCubit(),
            child: const DetailPage(),
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return MaterialPage(child: page);
        },
      ),
      GoRoute(
        path: '/detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          Widget page = BlocProvider(
            create: (_) => createCubit(),
            child: DetailPage(id: id),
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
