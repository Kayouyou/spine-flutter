import 'package:flutter/foundation.dart';
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
///
/// [useMock] 默认走 [kDebugMode]。release 构建必须显式传 `useMock: false`
/// 并在调用前 `sl.registerSingleton<AuthRepository>(RestAuthRepository(...))`，
/// 否则会抛 [StateError]（assert 在 release 模式被剥离，靠 runtime 兜底）。
void setupAuth(GetIt sl, {bool useMock = kDebugMode}) {
  sl.registerLazySingleton<UserRepository>(() {
    final userApi = UserApi(sl<Dio>());
    return UserRepositoryImpl(userApi);
  });

  if (useMock) {
    sl.registerFactory<AuthRepository>(MockAuthRepository.new);
  } else {
    assert(
      sl.isRegistered<AuthRepository>(),
      'release 模式必须提前 sl.registerSingleton<AuthRepository>(真实现)，'
      '否则 AuthCubit 启动期会抛 TypeError',
    );
    if (!sl.isRegistered<AuthRepository>()) {
      throw StateError(
        'setupAuth(useMock: false) 但 AuthRepository 未注册。'
        '请在 setupAuth 之前 sl.registerSingleton<AuthRepository>(真实现)。',
      );
    }
  }

  sl.registerLazySingleton<AuthCubit>(() => AuthCubit());

  sl.registerLazySingleton<AuthManager>(
    () => AuthManager(
      userRepository: sl<UserRepository>(),
      tokenStorage: sl<TokenStorage>(),
      authCubit: sl<AuthCubit>(),
    ),
  );
}
