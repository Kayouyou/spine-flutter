// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:api/api.dart';
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';
import 'package:dio/dio.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:feature_home/feature_home.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:locale/locale.dart';
import 'package:network/network.dart';

// Project imports:
import '../../config.dart';
import '../utils/logger.dart';
import '../middleware/request_context.dart'; // 请求上下文（用于自动取消标记）
import 'locator.dart';

/// 依赖注入配置
///
/// 职责：注册所有应用依赖
void setupDependencies() {
  // ===== Step 1: 基础设施层 =====
  sl.registerSingleton<AppLogger>(AppLogger());

  // 构造 AutoCancelInterceptor（注入 RequestContext + CancelTokenManager）
  final autoCancelInterceptor = AutoCancelInterceptor(
    tagProvider: () => RequestContext.currentTag,
    registerFn: (tag, token) => CancelTokenManager.instance.register(tag, token),
  );

  final dio = createDio(
    userTokenSupplier: () async => null, // TODO: 接入真实的 token 提供者
    onNetworkDisconnected: () {
      sl<AppLogger>().warning('网络连接已断开');
    },
    logger: sl<AppLogger>(),
    autoCancelInterceptor: autoCancelInterceptor,
  );
  dio.options.baseUrl = EnvironmentConfig.apiBaseUrl;
  sl.registerSingleton<Dio>(dio);

  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());

  // ===== Step 2: 数据定义层 =====
  // domain 当前仅导出类型定义，无需注册

  // ===== Step 3: 应用状态 =====
  sl.registerSingleton<LocaleCubit>(LocaleCubit());
  sl.registerSingleton<NetworkCubit>(NetworkCubit()..startListening());

  // 链路图解
  // lib/core/di/setup.dart
  // │
  // │ ① import 'package:auth/auth.dart';
  // ↓
  // pubspec.yaml 映射
  // │ auth: path: packages/services/auth
  // ↓
  // packages/services/auth/lib/auth.dart  ← barrel 文件
  // │ export 'src/di/setup.dart';       ← 把 setup 函数导出
  // ↓
  // packages/services/auth/lib/src/di/setup.dart
  // │ void setupAuth(GetIt sl) {
  // │   sl.registerSingleton<AuthManager>(...);
  // │ }
  // 三步骤
  // 每个模块负责组装自己的依赖，主应用只需调用一次 setupXxx(sl)

  // ===== Step 4: 业务服务层 =====
  setupAuth(sl);
  setupDataSync(sl);

  // ===== Step 5: 业务功能层 =====
  setupFeatureHome(sl);
  setupFeatureDetail(sl);
  setupFeatureAuth(sl);

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
