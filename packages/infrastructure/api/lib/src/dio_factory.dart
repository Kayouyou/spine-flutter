import 'package:alice/alice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'cancel/auto_cancel_interceptor.dart';
import 'dio/renewal_token_intercaptor.dart';
import 'http/app_logger.dart';

/// 创建预配置的 Dio 实例
///
/// 拦截器链顺序（请求方向）:
///   [0] AutoCancelInterceptor    → 读 tag，生成 CancelToken
///   [1] TokenRenewalInterceptor  → 检测 code=1000102，排队续期
///   [2] InterceptorsWrapper    → 注入 Authorization header
///   [3] LogInterceptor          → 记录日志（仅 Debug）
///   [4] AliceInterceptor        → HTTP Inspector（仅 Debug）
///
/// 使用方式：
/// ```dart
/// final dio = createDio(
///   userTokenSupplier: () async => token,
///   onNetworkDisconnected: () => logger.warning('网络断开'),
///   logger: appLogger,                        // 注入主应用 AppLogger
///   autoCancelInterceptor: myInterceptor,      // 从外部注入 AutoCancelInterceptor
///   tokenStorage: sl<TokenStorage>(),          // 用于 Token 续期成功后写入 Hive
///   alice: sl<Alice>(),                        // Alice HTTP Inspector（可选，仅 Debug）
/// );
/// ```
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
  AppLoggerInterface? logger,
  AutoCancelInterceptor? autoCancelInterceptor,
  TokenStorage? tokenStorage,
  Duration? connectTimeout,
  Duration? receiveTimeout,
  Alice? alice,
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: connectTimeout ?? const Duration(seconds: 10),
    receiveTimeout: receiveTimeout ?? const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // [0] Auto-cancel — 调用方注入（closes over RequestContext + CancelTokenManager）
  if (autoCancelInterceptor != null) {
    dio.interceptors.add(autoCancelInterceptor);
  }

  // [1] Token 续期 — 处理 code=1000102，日志走注入的 AppLogger
  final renewalInterceptor = TokenRenewalInterceptor(dio, tokenStorage);
  if (logger != null) {
    renewalInterceptor.logger = logger;
  }
  dio.interceptors.add(renewalInterceptor);

  // [2] Auth header — 注入 Authorization token
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await userTokenSupplier();
      if (token != null) {
        options.headers['token'] = token;
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.type == DioExceptionType.connectionError) {
        onNetworkDisconnected();
      }
      handler.next(error);
    },
  ));

  // [3] Log — 最后执行，记录完整请求/响应（仅 Debug 模式）
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  // [4] Alice — HTTP Inspector（仅 Debug 模式，可选）
  if (kDebugMode && alice != null) {
    dio.interceptors.add(alice.getDioInterceptor());
  }

  return dio;
}
