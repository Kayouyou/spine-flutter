import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../api/auth_api.dart';
import '../repository/auth_repository_impl.dart';

/// 注册 Auth API 模块
void setupApiAuth(GetIt sl, String baseUrl) {
  sl.registerFactory<AuthApi>(
    () => AuthApi(sl<Dio>(), baseUrl: baseUrl),
  );

  sl.registerFactory<AuthRepositoryImpl>(
    () => AuthRepositoryImpl(sl<AuthApi>()),
  );
}
