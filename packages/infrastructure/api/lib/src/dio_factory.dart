import 'package:dio/dio.dart';

/// 创建预配置的 Dio 实例
///
/// 包含标准的请求拦截器（认证令牌注入、网络断开检测）。
/// 使用方式：
/// ```dart
/// final dio = createDio(
///   userTokenSupplier: () async => token,
///   onNetworkDisconnected: () => logger.warning('网络断开'),
/// );
/// ```
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // 认证拦截器 — 自动附加 Bearer 令牌
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await userTokenSupplier();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
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

  // 日志拦截器（调试模式）
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
}
