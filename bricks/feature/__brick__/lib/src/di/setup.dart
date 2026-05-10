import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:routing/routing.dart';
import 'package:feature_{{name}}/src/cubit/{{name}}_cubit.dart';
import 'package:feature_{{name}}/src/repository/{{name}}_repository_impl.dart';
import 'package:feature_{{name}}/src/routes/{{name}}_route_module.dart';

/// 注册 {{name.pascalCase()}} 功能模块的依赖
void setupFeature{{name.pascalCase()}}(GetIt sl) {
  sl.registerFactory<{{name.pascalCase()}}Repository>(() => {{name.pascalCase()}}RepositoryImpl(sl<Dio>()));
  sl.registerFactory<{{name.pascalCase()}}Cubit>(() => {{name.pascalCase()}}Cubit(sl<{{name.pascalCase()}}Repository>()));

  RouteModuleRegistry.instance.register('feature_{{name}}', (ctx) => {{name.pascalCase()}}RouteModule(ctx));
}