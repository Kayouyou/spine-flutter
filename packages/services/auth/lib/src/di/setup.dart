import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import '../repository/auth_repository_impl.dart';
import '../cubit/auth_cubit.dart';
import '../repository/mock_auth_repository.dart';
import '../manager.dart';

/// 注册 auth 服务的所有依赖
void setupAuth(GetIt sl) {
  // Repository — 组合注入 Dio
  sl.registerLazySingleton<UserRepository>(
    () => AuthRepositoryImpl(sl<Dio>()),
  );

  // MockAuthRepository — 用于 AuthCubit 的 mock 仓库
  sl.registerFactory<MockAuthRepository>(() => MockAuthRepository());

  // AuthCubit — 认证状态管理
  sl.registerSingleton<AuthCubit>(AuthCubit(sl<MockAuthRepository>()));

  // AuthManager — 注入 Repository、存储 和 AuthCubit
  sl.registerLazySingleton<AuthManager>(
    () => AuthManager(
      userRepository: sl<UserRepository>(),
      keyValueStorage: sl<KeyValueStorage>(),
      authCubit: sl<AuthCubit>(),
    ),
  );
}
