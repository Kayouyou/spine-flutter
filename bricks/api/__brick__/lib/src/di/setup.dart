import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../api/{{name}}_api.dart';
import '../repository/{{name}}_repository_impl.dart';

/// 注册 {{name.pascalCase()}} API 模块
void setupApi{{name.pascalCase()}}(GetIt sl, String baseUrl) {
  sl.registerFactory<{{name.pascalCase()}}Api>(
    () => {{name.pascalCase()}}Api(sl<Dio>(), baseUrl: baseUrl),
  );

  sl.registerFactory<{{name.pascalCase()}}RepositoryImpl>(
    () => {{name.pascalCase()}}RepositoryImpl(sl<{{name.pascalCase()}}Api>()),
  );
}
