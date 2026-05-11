import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import '../repository/user_repository_impl.dart';
import '../cubit/auth_cubit.dart';
import '../repository/mock_auth_repository.dart';
import '../manager.dart';

/// 注册 auth 服务的所有依赖
void setupAuth(GetIt sl) {
  sl.registerLazySingleton<UserRepository>(() {
    final userApi = UserApi(sl<Dio>());
    return UserRepositoryImpl(userApi);
  });

  sl.registerFactory<AuthRepository>(() => MockAuthRepository()); // ⚠️ SCAFFOLD MODE — 见 mock_auth_repository.dart 注释

  sl.registerSingleton<AuthCubit>(AuthCubit(sl<AuthRepository>()));

  sl.registerLazySingleton<AuthManager>(
    () => AuthManager(
      userRepository: sl<UserRepository>(),
      tokenStorage: sl<TokenStorage>(),
      authCubit: sl<AuthCubit>(),
    ),
  );
}
