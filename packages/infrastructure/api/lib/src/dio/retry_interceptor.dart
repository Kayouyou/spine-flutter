import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../http/app_logger.dart';
import '../network/network_environment.dart';
import 'circuit_breaker.dart';

/// 重试次数在 [RequestOptions.extra] 中使用的键，用于防止无限循环。
const String _retryCountKey = 'retry_count';

/// 重试配置
///
/// 与 Gitee 参考实现思路一致（指数退避 + 抖动），但字段改为 Duration 形式，
/// 并区分良网/弱网两套重试上限，便于按 [NetworkEnvironment] 质量动态切换。
class RetryConfig {
  /// 良网（good/disconnected）最大重试次数，默认 2。
  final int normalMaxRetryCount;

  /// 弱网（poor/slow）最大重试次数，默认 4。
  final int poorNetworkMaxRetryCount;

  /// 指数退避基础延迟，默认 500ms。
  final Duration baseDelay;

  /// 延迟上限（退避与抖动之和不会超过此值），默认 8s。
  final Duration maxDelay;

  /// 是否启用随机抖动，默认 true。
  final bool enableJitter;

  /// 可重试的错误类型集合。
  /// 默认仅含连接/超时类错误，**不含 cancel 与 badResponse**。
  final List<DioExceptionType> retryableTypes;

  RetryConfig({
    this.normalMaxRetryCount = 2,
    this.poorNetworkMaxRetryCount = 4,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 8),
    this.enableJitter = true,
    List<DioExceptionType>? retryableTypes,
  }) : retryableTypes = retryableTypes ??
            const [
              DioExceptionType.connectionTimeout,
              DioExceptionType.sendTimeout,
              DioExceptionType.receiveTimeout,
              DioExceptionType.connectionError,
            ];
}

/// 计算第 [attempt] 次重试的延迟（纯函数，便于测试）。
///
/// 规则：
/// 1. 指数退避：`baseDelay * 2^(attempt-1)`。
/// 2. 退避先 clamp 到 [RetryConfig.maxDelay]。
/// 3. 若启用抖动，叠加 `[0, baseDelay]` 的随机量（使用 [Random]）。
/// 4. 最终值再 clamp 到 [RetryConfig.maxDelay]。
///
/// 示例（baseDelay=500ms, maxDelay=8s, jitter 关闭）：
///   第1次 = 500ms，第2次 = 1000ms，第3次 = 2000ms。
Duration computeRetryDelay(int attempt, RetryConfig config) {
  final int baseMs = config.baseDelay.inMilliseconds;
  final int maxMs = config.maxDelay.inMilliseconds;

  // 1. 指数退避
  int backoffMs = baseMs * (1 << (attempt - 1));
  // 2. 退避 clamp 到上限
  if (backoffMs > maxMs) backoffMs = maxMs;

  // 3. 随机抖动：0 ~ baseDelay
  int jitterMs = 0;
  if (config.enableJitter) {
    jitterMs = _random.nextInt(baseMs + 1);
  }

  // 4. 总计再 clamp 到上限
  int total = backoffMs + jitterMs;
  if (total > maxMs) total = maxMs;
  return Duration(milliseconds: total);
}

/// 模块级随机源（jitter 用）。
final Random _random = Random();

/// 重试拦截器
///
/// 优化原则：指数退避 + 随机抖动 + 重试上限 + 熔断保护。
/// - 仅对 [RetryConfig.retryableTypes] 内的错误类型重试（cancel/badResponse 直接放行）。
/// - 按 [NetworkEnvironment] 质量切换良网/弱网重试上限。
/// - 熔断打开（[CircuitBreaker.allowRequest] 为 false）时跳过重试。
/// - 通过 [dio].fetch 重发会重新进入拦截器链（含本拦截器），
///   并以 [RequestOptions.extra]['retry_count'] 记录已尝试次数防死循环。
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    RetryConfig? config,
    NetworkEnvironment? networkEnvironment,
    CircuitBreaker? circuitBreaker,
    AppLoggerInterface? logger,
  })  : _config = config ?? RetryConfig(),
        _networkEnvironment = networkEnvironment,
        _circuitBreaker = circuitBreaker {
    if (logger != null) _logger = logger;
  }

  /// 用于重发请求的 Dio 实例（由外部注入，通常即持有本拦截器的同一实例）。
  final Dio _dio;

  final RetryConfig _config;
  final NetworkEnvironment? _networkEnvironment;
  final CircuitBreaker? _circuitBreaker;

  /// 日志输出实例，默认使用 [DefaultLogger]。
  AppLoggerInterface _logger = DefaultLogger();

  /// 设置日志输出实例（支持延迟注入，打破依赖循环）。
  set logger(AppLoggerInterface logger) => _logger = logger;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // a. 非可重试类型：直接放行，不重试。
    if (!_config.retryableTypes.contains(err.type)) {
      _logger.debug('[Retry] 非可重试错误类型 ${err.type}，跳过重试');
      handler.next(err);
      return;
    }

    // b. 熔断打开：跳过重试直接放行。
    //    注意：此处不调用 recordFailure，否则会刷新熔断冷却时间（_lastFailureTime），
    //    导致熔断器永远无法按时进入半开态恢复。
    if (_circuitBreaker != null && !_circuitBreaker!.allowRequest) {
      _logger.warning('[Retry] 熔断器打开，跳过重试: ${err.requestOptions.path}');
      handler.next(err);
      return;
    }

    // 读取已尝试次数（extra 中记录，重发时随 requestOptions 跨拦截器链传递）。
    final int attempt = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    // 按网络质量选择重试上限。
    final int maxRetry = _resolveMaxRetry();
    final String qualityLabel = _qualityLabel();

    // c. 已达上限：本次为最终失败且无重试，记录失败并放行。
    if (attempt >= maxRetry) {
      _logger.warning(
        '[Retry] 已达重试上限 $maxRetry（$qualityLabel），放弃重试: '
        '${err.requestOptions.path}',
      );
      _circuitBreaker?.recordFailure();
      handler.next(err);
      return;
    }

    // d. 进入重试流程：自增尝试次数，计算延迟后重发。
    final int nextAttempt = attempt + 1;
    err.requestOptions.extra[_retryCountKey] = nextAttempt;

    final Duration delay = computeRetryDelay(nextAttempt, _config);
    _logger.warning(
      '[Retry] 第 $nextAttempt/$maxRetry 次重试（$qualityLabel），'
      '延迟 ${delay.inMilliseconds}ms: ${err.requestOptions.path}',
    );

    await Future.delayed(delay);

    try {
      // 重发：重新进入完整拦截器链（含本拦截器）。
      // 若重发仍失败，Dio 会在链中再次调用本拦截器的 onError，
      // 并按 extra['retry_count'] 自动决定是否继续重试（防死循环）。
      final Response<dynamic> response = await _dio.fetch(err.requestOptions);
      _circuitBreaker?.recordSuccess();
      handler.resolve(response);
    } on DioException catch (e) {
      // 重发再次失败：链内已自动重入并穷尽重试，
      // 此处只需把“最终失败”交还给「本层」handler（必须调用一次）。
      // 注意：不可 unawaited(onError(e, handler)) 手动递归，
      // 否则本层 handler 未被调用，Dio 会报 "handler should be called"。
      handler.next(e);
    } catch (e) {
      // 非 DioException（极少见）：视为最终失败。
      _circuitBreaker?.recordFailure();
      handler.next(err);
    }
  }

  /// 根据网络质量选择重试上限：poor/slow 用弱网值，其余用良网值。
  int _resolveMaxRetry() {
    final NetworkQuality? quality = _networkEnvironment?.quality;
    if (quality == NetworkQuality.poor || quality == NetworkQuality.slow) {
      return _config.poorNetworkMaxRetryCount;
    }
    return _config.normalMaxRetryCount;
  }

  /// 网络质量描述（仅用于日志）。
  String _qualityLabel() {
    final NetworkQuality? quality = _networkEnvironment?.quality;
    if (quality == NetworkQuality.poor || quality == NetworkQuality.slow) {
      return '弱网';
    }
    return '良网';
  }
}
