import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';

import 'locator.dart';
import '../auth/manager.dart';
import '../sync/manager.dart';
import '../utils/logger.dart';

/// 依赖注入配置
///
/// 职责：注册所有应用依赖
void setupDependencies() {
  // 核心服务
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

  // 业务服务
  sl.registerSingleton<AuthManager>(AuthManager());
  sl.registerSingleton<DataSyncManager>(DataSyncManager());
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