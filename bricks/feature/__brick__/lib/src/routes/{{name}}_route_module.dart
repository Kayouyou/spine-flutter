import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_{{name}}/src/cubit/{{name}}_cubit.dart';
import 'package:feature_{{name}}/src/ui/{{name}}_page.dart';

/// {{name.pascalCase()}} 路由模块
class {{name.pascalCase()}}RouteModule extends RouteModule {
  const {{name.pascalCase()}}RouteModule(super.ctx);

  @override
  List<RouteBase> build() => [
        GoRoute(
          path: '/{{name.snakeCase()}}',
          builder: (context, state) {
            return BlocProvider(
              create: (_) => GetIt.instance<{{name.pascalCase()}}Cubit>(),
              child: const {{name.pascalCase()}}Page(),
            );
          },
        ),
      ];
}
