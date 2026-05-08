import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:feature_{{name}}/src/cubit/{{name}}_cubit.dart';
import 'package:feature_{{name}}/src/repository/{{name}}_repository.dart';
import 'package:feature_{{name}}/src/repository/{{name}}_repository_impl.dart';

/// 注册 {{name.pascalCase()}} 功能模块的依赖注入
///
/// 职责：在 GetIt 中注册 Repository 和 Cubit
/// 使用：在 app 启动时调用 setupFeature{{name.pascalCase()}}(sl)
void setupFeature{{name.pascalCase()}}(GetIt sl) {
  sl.registerFactory<{{name.pascalCase()}}Repository>(() => {{name.pascalCase()}}RepositoryImpl(sl<Dio>()));
  sl.registerFactory<{{name.pascalCase()}}Cubit>(() => {{name.pascalCase()}}Cubit(sl<{{name.pascalCase()}}Repository>()));
}