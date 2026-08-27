import 'package:alice/alice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'cancel/auto_cancel_interceptor.dart';
import 'dio/circuit_breaker.dart';
import 'dio/error_interceptor.dart';
import 'dio/header_interceptor.dart';
import 'dio/latency_monitor_interceptor.dart';
import 'dio/network_status_interceptor.dart';
import 'dio/renewal_token_interceptor.dart';
import 'dio/request_queue.dart';
import 'dio/response_envelope_interceptor.dart';
import 'dio/retry_interceptor.dart';
import 'dio/cache_interceptor.dart';
import 'endpoints/api_endpoints.dart';
import 'http/api_config.dart';
import 'http/app_logger.dart';
import 'network/network_environment.dart';

/// 创建预配置的 Dio 实例
///
/// 拦截器链顺序（请求方向）:
///   [0] AutoCancelInterceptor      → 读 pageTag，生成 CancelToken
///   [1] CacheInterceptor           → 通用 GET 缓存（默认 none 透明；extra 显式开启）
///   [2] NetworkStatusInterceptor   → 断网入队/暂停，恢复后重发（P0 弱网）
///   [3] TokenRenewalInterceptor    → 检测 code=1000102，排队续期
///   [4] InterceptorsWrapper        → 注入 token header + 网络断开 callback
///   [5] HeaderInterceptor          → 请求签名（sha1），必须在 Auth 之后（token 已注入）
///   [6] ErrorInterceptor           → 5xx/网络错误上报(传入 onDioError 回调)
///   [7] RetryInterceptor           → 网络错误指数退避重试 + 熔断联动（P0 弱网）
///   [8] LatencyMonitorInterceptor  → 记录请求延迟（用于网络质量监控）
///   [9] LogInterceptor             → 记录日志（仅 Debug）
///   [10] AliceInterceptor          → HTTP Inspector（仅 Debug）
///   [11] ResponseEnvelopeInterceptor → 统一信封解包 + 业务码→BusinessException（仅对 {code,data} 结构生效；裸 payload 原样放行）
///
/// 动态超时：当注入 [networkEnvironment] 后，订阅其 [NetworkEnvironment.qualityStream]，
/// 按网络质量自动调整 connect/receive 超时（good 10s / slow 15s·20s / poor 30s·40s），
/// 提升弱网下成功率，断网时由 [NetworkStatusInterceptor] 入队不依赖超时。
///
/// 使用方式：
/// ```dart
/// final dio = createDio(
///   userTokenSupplier: () async => token,
///   onNetworkDisconnected: () => logger.warning('网络断开'),
///   onDioError: (err, stack) => AppErrorHandler.instance.reportError(
///     err, stack, isFatal: true, context: {'source': 'dio', ...},
///   ),
///   onLatencyRecord: (latencyMs) => networkCubit.recordLatency(latencyMs),
///   logger: appLogger,
///   autoCancelInterceptor: myInterceptor,
///   tokenStorage: sl<TokenStorage>(),
///   alice: sl<Alice>(),
///   networkEnvironment: InfraNetworkEnvironment(networkCubit), // R3 桥接注入
/// );
/// ```
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
  void Function(
    Object error,
    StackTrace? stack, {
    Map<String, dynamic> context,
  })? onDioError,
  void Function(int latencyMs)? onLatencyRecord,
  AppLoggerInterface? logger,
  AutoCancelInterceptor? autoCancelInterceptor,
  TokenStorage? tokenStorage,
  ApiConfig? apiConfig,
  Duration? connectTimeout,
  Duration? receiveTimeout,
  Alice? alice,
  // 网络环境抽象（R3 合规）：由 services/network 桥接注入。
  // 提供后启用「动态超时 + 断网入队/重发 + 弱网重试上限」等弱网优化能力。
  NetworkEnvironment? networkEnvironment,
  // 弱网熔断实例；不传则由工厂创建默认实例并与 RetryInterceptor 共享。
  CircuitBreaker? circuitBreaker,
  // 弱网重试配置；不传则用 RetryConfig() 默认值。
  RetryConfig? retryConfig,
  // 离线队列容量；不传默认 100。
  int? requestQueueMaxSize,
  // 统一业务信封（解包 data['data'] + 业务码→BusinessException）；默认开启。
  // 仅对 {code,message,data} 结构生效，裸 payload 原样放行，不破坏既有 Retrofit 解析。
  bool enableEnvelope = true,
}) {
  // 注入 ApiConfig 到 ApiBase (供 Retrofit / 业务代码读 baseUrl)
  if (apiConfig != null) {
    ApiBase.injectConfig(apiConfig);
  }

  final dio = Dio(BaseOptions(
    connectTimeout: connectTimeout ?? const Duration(seconds: 10),
    receiveTimeout: receiveTimeout ?? const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ),);

  // 请求签名拦截器：复用注入的 logger，必须在 Auth 之后（token header 已注入）。
  final headerInterceptor = HeaderInterceptor()..logger = logger;

  // [0] Auto-cancel — 调用方注入（closes over RequestContext + CancelTokenManager）
  if (autoCancelInterceptor != null) {
    dio.interceptors.add(autoCancelInterceptor);
  }

  // [1] Cache — 通用 GET 缓存（默认 none 透明；通过 extra['cacheStrategy'] 显式开启）。
  // 放在 AutoCancel 之后、NetworkStatus 之前：cacheFirst 可在断网前直接命中缓存短路。
  dio.interceptors.add(CacheInterceptor(logger: logger),);

  // [2] NetworkStatus — 断网入队/暂停，恢复后重发（P0 弱网）。
  // 仅在注入了 networkEnvironment 时启用；缺失则退化为「离线直接失败」（与原行为一致）。
  RequestQueue? requestQueue;
  if (networkEnvironment != null) {
    requestQueue = RequestQueue(maxSize: requestQueueMaxSize ?? 100);
    dio.interceptors.add(NetworkStatusInterceptor(
      dio,
      networkEnvironment: networkEnvironment,
      requestQueue: requestQueue,
      logger: logger,
    ),);
  }

  // [3] Token 续期 — 处理 code=1000102，日志走注入的 AppLogger
  // 同时传入 apiConfig, 续期 URL 从 ApiConfig.host 读取 (替代原硬编码)
  final renewalInterceptor = TokenRenewalInterceptor(
    dio,
    tokenStorage: tokenStorage,
    apiConfig: apiConfig,
  );
  if (logger != null) {
    renewalInterceptor.logger = logger;
  }
  dio.interceptors.add(renewalInterceptor);

  // [4] Auth header — 注入 token header（供后续签名拦截器使用）。
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
  ),);

  // [5] Header（签名）— 请求 sha1 签名，复用注入的 logger。
  // 必须放在 Auth 之后，确保 token header 已注入参与签名（与刷新请求一致）。
  dio.interceptors.add(headerInterceptor);

  // [6] Error — 5xx/网络错误上报(4xx 业务期望错误不上报)
  if (onDioError != null) {
    dio.interceptors.add(ErrorInterceptor(onError: onDioError));
  }

  // [6] Retry — 网络错误指数退避重试 + 熔断联动（P0 弱网）。
  // 放在 Error 之后：每次重试尝试仍会走 Error 上报（与原上报行为一致，不屏蔽中间失败）。
  final sharedCircuitBreaker = circuitBreaker ?? CircuitBreaker();
  dio.interceptors.add(RetryInterceptor(
    dio,
    config: retryConfig ?? RetryConfig(),
    networkEnvironment: networkEnvironment,
    circuitBreaker: sharedCircuitBreaker,
    logger: logger,
  ),);

  // [7] Latency Monitor — 记录请求延迟（用于网络质量监控）
  if (onLatencyRecord != null) {
    dio.interceptors.add(LatencyMonitorInterceptor(onLatencyRecord: onLatencyRecord));
  }

  // [8] Log — 最后执行，记录完整请求/响应（仅 Debug 模式）
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  // [9] Alice — HTTP Inspector（仅 Debug 模式，可选）
  if (kDebugMode && alice != null) {
    dio.interceptors.add(alice.getDioInterceptor());
  }

  // [10] ResponseEnvelope — 统一信封解包 + 业务码→BusinessException（P1）。
  // 放在链尾：响应方向上最先执行，解包后的干净 payload 优先于日志/监控被记录。
  // 仅对 {code,message,data} 结构生效，裸 payload 原样放行（不破坏既有 Retrofit 解析）。
  if (enableEnvelope) {
    dio.interceptors.add(ResponseEnvelopeInterceptor(
      enabled: enableEnvelope,
      logger: logger,
    ),);
  }

  // 动态超时：订阅网络质量流，弱网下放宽超时以提升成功率。
  // Dio 为 App 级单例，订阅生命周期与应用一致，无需额外释放。
  if (networkEnvironment != null) {
    networkEnvironment.qualityStream.listen((quality) {
      _applyDynamicTimeout(dio, quality);
    },);
  }

  return dio;
}

/// 按网络质量调整 connect/receive 超时。
void _applyDynamicTimeout(Dio dio, NetworkQuality quality) {
  switch (quality) {
    case NetworkQuality.good:
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
    case NetworkQuality.slow:
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 20);
    case NetworkQuality.poor:
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 40);
    case NetworkQuality.disconnected:
      // 断网时请求由 NetworkStatusInterceptor 入队，不依赖超时，保持当前值即可。
      break;
  }
}
