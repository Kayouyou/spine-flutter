import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_{{name}}/src/cubit/{{name}}_cubit.dart';
import 'package:feature_{{name}}/src/ui/{{name}}_page.dart';

/// {{name.pascalCase()}} 路由模块
class {{name.pascalCase()}}RouteModule extends RouteModule {
  final {{name.pascalCase()}}Cubit Function() createCubit;

  const {{name.pascalCase()}}RouteModule(
    super.ctx, {
    required this.createCubit,
  });

  @override
  List<RouteBase> build() => [
    GoRoute(
      path: '/{{name.snakeCase()}}',
      pageBuilder: (context, state) {
        Widget page = BlocProvider(
          create: (_) => createCubit(),
          child: const {{name.pascalCase()}}Page(),
        );
        if (ctx.routeWrapper != null) {
          page = ctx.routeWrapper!(page);
        }
        return MaterialPage(child: page);
      },
    ),
  ];
}
