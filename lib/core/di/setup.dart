import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart';

import 'locator.dart';
import '../utils/logger.dart';
import '../global/locale/locale_cubit.dart';
import '../global/network/network_cubit.dart';

/// 依赖注入配置
///
/// 职责：注册所有应用依赖
void setupDependencies() {
  // ===== Step 1: 基础设施层 =====
  sl.registerSingleton<AppLogger>(AppLogger());

  sl.registerSingleton<Api>(
    Api(
      userTokenSupplier: () async => null,
      networkDisconnectedCallback: () {
        sl<AppLogger>().warning('网络连接已断开');
      },
    ),
  );

  // 注入Logger到Api（Token续期拦截器使用）
  sl<Api>().setLogger(sl<AppLogger>());

  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());

  // ===== Step 2: 数据定义层 =====
  // domain 当前仅导出类型定义，无需注册

  // ===== Step 3: 应用状态 =====
  sl.registerSingleton<LocaleCubit>(LocaleCubit(sl<KeyValueStorage>()));
  sl.registerSingleton<NetworkCubit>(NetworkCubit()..startListening());

  // ===== Step 4: 业务服务层 =====
  setupAuth(sl);
  setupDataSync(sl);

  // ===== Step 5: 业务功能层 =====
  setupFeatureHome(sl);
  setupFeatureDetail(sl);

  configureEasyLoading();
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