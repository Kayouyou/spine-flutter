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
import 'package:routing/routing.dart';

// Project imports:
import 'package:domain/domain.dart';
import '../bootstrap/bootstrap_options.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import '../middleware/request_context.dart'; // 请求上下文（用于自动取消标记）
import 'locator.dart';

/// 依赖注入配置
///
/// 职责：注册所有应用依赖
void setupDependencies({BootstrapOptions options = const BootstrapOptions()}) {
  sl.registerSingleton<BootstrapOptions>(options);
  // ===== 1. injectable 初始化（自动注册 @injectable 类）=====
  // 注意：这需要在任何手动注册之前调用
  // 需要先运行 build_runner 生成 injectable.config.dart 才能启用
  // getIt.init();

  // ===== 0. 应用配置（必须在其他依赖之前注册）=====
  sl.registerSingleton<IAppConfig>(EnvAppConfig());

  // ===== Step 1: 基础设施层 =====
  sl.registerSingleton<AppLogger>(AppLogger());

  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());

  sl.registerSingleton<TokenStorage>(
    TokenStorage(sl<KeyValueStorage>()),
  );

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

  // ===== Step 2: Dio（依赖 TokenStorage） =====
  final autoCancelInterceptor = AutoCancelInterceptor(
    tagProvider: () => RequestContext.currentTag,
    registerFn: (tag, token) =>
        CancelTokenManager.instance.register(tag, token),
  );

  final config = sl<IAppConfig>();
  final dio = createDio(
    userTokenSupplier: () => sl<TokenStorage>().getToken(),
    onNetworkDisconnected: () {
      sl<AppLogger>().warning('网络连接已断开');
    },
    logger: sl<AppLogger>(),
    autoCancelInterceptor: autoCancelInterceptor,
    tokenStorage: sl<TokenStorage>(),
    connectTimeout: Duration(seconds: config.networkTimeout),
    receiveTimeout: Duration(seconds: config.networkTimeout),
  );
  dio.options.baseUrl = config.apiBaseUrl;
  sl.registerSingleton<Dio>(dio);

  // ===== Step 3: 业务服务层（依赖 Dio 和 TokenStorage） =====
  setupAuth(sl);
  if (options.enableDataSync) {
    setupDataSync(sl);
  }

  // ===== Step 4: 应用状态 =====
  sl.registerSingleton<LocaleCubit>(LocaleCubit());
  sl.registerSingleton<NetworkCubit>(NetworkCubit()..startListening());

  // ===== Step 5: 业务功能层 =====
  // 显式注册后 runAll 统一执行。
  // 新增 feature 时只需在此处加一行 register + 一行 import。
  FeatureRegistry.instance.register('feature_home', setupFeatureHome);
  FeatureRegistry.instance.register('feature_detail', setupFeatureDetail);
  FeatureRegistry.instance.register('feature_auth', setupFeatureAuth);
  FeatureRegistry.instance.runAll(sl);

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
