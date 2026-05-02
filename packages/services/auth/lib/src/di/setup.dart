import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import '../repository/auth_repository_impl.dart';
import '../manager.dart';

/// 注册 auth 服务的所有依赖
void setupAuth(GetIt sl) {
  // Repository — 组合注入 Dio
  sl.registerLazySingleton<UserRepository>(
    () => AuthRepositoryImpl(sl<Dio>()),
  );

  // AuthManager — 注入 Repository 和存储
  sl.registerLazySingleton<AuthManager>(
    () => AuthManager(
      userRepository: sl<UserRepository>(),
      keyValueStorage: sl<KeyValueStorage>(),
    ),
  );
}