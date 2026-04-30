import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';

import 'locator.dart';
import '../auth/manager.dart';
import '../sync/manager.dart';
import '../utils/logger.dart';
import '../global/locale/locale_cubit.dart';
import '../../features/home/repository/home_repository.dart';
import '../../features/home/repository/home_repository_impl.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/detail/repository/detail_repository.dart';
import '../../features/detail/repository/detail_repository_impl.dart';
import '../../features/detail/cubit/detail_cubit.dart';

/// 依赖注入配置
///
/// 职责：注册所有应用依赖
void setupDependencies() {
  // ===== 核心服务 =====

  sl.registerSingleton<AppLogger>(AppLogger());

  sl.registerSingleton<Api>(
    Api(
      userTokenSupplier: () async => null,
      networkDisconnectedCallback: () {
        sl<AppLogger>().warning('网络连接已断开');
      },
    ),
  );

  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());

  // ===== BoxService =====
  // 注意：BoxService需要泛型类型，这里注册示例
  // sl.registerFactory<BoxService<User>>(() => BoxService<User>('user_box'));

  // ===== 业务服务 =====

  sl.registerSingleton<AuthManager>(AuthManager());
  sl.registerSingleton<DataSyncManager>(DataSyncManager());

  // ===== 全局状态 =====

  // LocaleCubit（单例）
  sl.registerSingleton<LocaleCubit>(
    LocaleCubit(sl<KeyValueStorage>())
  );

  // ===== Repository =====

  // HomeRepository（Factory）
  sl.registerFactory<HomeRepository>(() =>
    HomeRepositoryImpl(sl<Api>())
  );

  // DetailRepository（Factory）
  sl.registerFactory<DetailRepository>(() =>
    DetailRepositoryImpl(sl<Api>())
  );

  // ===== Cubit =====

  // HomeCubit（Factory）
  sl.registerFactory<HomeCubit>(() =>
    HomeCubit(sl<HomeRepository>())
  );

  // DetailCubit（Factory）
  sl.registerFactory<DetailCubit>(() =>
    DetailCubit(sl<DetailRepository>())
  );
}

/// 配置EasyLoading
void configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 30.0
    ..radius = 8.0
    ..backgroundColor = Colors.black87
    ..textColor = Colors.white
    ..indicatorColor = Colors.white
    ..maskType = EasyLoadingMaskType.black
    ..maskColor = Colors.transparent;
}