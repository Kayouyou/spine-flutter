import 'dart:async';
import 'dart:typed_data';

import 'package:api/src/dio/circuit_breaker.dart';
import 'package:api/src/dio/retry_interceptor.dart';
import 'package:api/src/network/network_environment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 纯函数退避计算测试（jitter 关闭时值为精确指数退避）。
void main() {
  group('computeRetryDelay', () {
    test('jitter 关闭：精确等于 baseDelay * 2^(n-1)', () {
      final config = RetryConfig(
        baseDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(seconds: 8),
        enableJitter: false,
      );
      expect(computeRetryDelay(1, config), const Duration(milliseconds: 500));
      expect(computeRetryDelay(2, config), const Duration(milliseconds: 1000));
      expect(computeRetryDelay(3, config), const Duration(milliseconds: 2000));
      expect(computeRetryDelay(4, config), const Duration(milliseconds: 4000));
    });

    test('退避 clamp 到 maxDelay', () {
      final config = RetryConfig(
        baseDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(milliseconds: 1200),
        enableJitter: false,
      );
      // 第4次理论 4000ms，应被 clamp 到 1200ms。
      expect(computeRetryDelay(4, config), const Duration(milliseconds: 1200));
    });

    test('jitter 开启：结果落在 [退避, 退避+baseDelay] 区间内', () {
      final config = RetryConfig(
        baseDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(seconds: 8),
        enableJitter: true,
      );
      final delay = computeRetryDelay(1, config);
      expect(delay.inMilliseconds, greaterThanOrEqualTo(500));
      expect(delay.inMilliseconds, lessThanOrEqualTo(1000));
    });
  });

  group('RetryInterceptor 行为', () {
    test('良网：重试次数达到 normalMaxRetryCount 后停止', () async {
      final harness = _Harness(
        DioExceptionType.connectionError,
        config: RetryConfig(
          normalMaxRetryCount: 2,
          poorNetworkMaxRetryCount: 4,
          baseDelay: const Duration(milliseconds: 1),
          maxDelay: const Duration(milliseconds: 50),
          enableJitter: false,
        ),
      );
      await expectLater(harness.run(), throwsA(isA<DioException>()));
      // 1 次初始 + 2 次重试 = 3 次请求。
      expect(harness.adapter.callCount, 3);
    });

    test('弱网（poor）：使用 poorNetworkMaxRetryCount 作为上限', () async {
      final harness = _Harness(
        DioExceptionType.connectionError,
        config: RetryConfig(
          normalMaxRetryCount: 2,
          poorNetworkMaxRetryCount: 4,
          baseDelay: const Duration(milliseconds: 1),
          maxDelay: const Duration(milliseconds: 50),
          enableJitter: false,
        ),
        networkEnvironment: _FakeNetworkEnvironment(NetworkQuality.poor),
      );
      await expectLater(harness.run(), throwsA(isA<DioException>()));
      // 1 次初始 + 4 次重试 = 5 次请求。
      expect(harness.adapter.callCount, 5);
    });

    test('弱网（slow）：同样使用 poorNetworkMaxRetryCount', () async {
      final harness = _Harness(
        DioExceptionType.receiveTimeout,
        config: RetryConfig(
          normalMaxRetryCount: 2,
          poorNetworkMaxRetryCount: 4,
          baseDelay: const Duration(milliseconds: 1),
          maxDelay: const Duration(milliseconds: 50),
          enableJitter: false,
        ),
        networkEnvironment: _FakeNetworkEnvironment(NetworkQuality.slow),
      );
      await expectLater(harness.run(), throwsA(isA<DioException>()));
      expect(harness.adapter.callCount, 5);
    });

    test('cancel 类型：直接放行，不进入重试', () async {
      final harness = _Harness(
        DioExceptionType.cancel,
        config: RetryConfig(
          baseDelay: const Duration(milliseconds: 1),
          maxDelay: const Duration(milliseconds: 50),
          enableJitter: false,
        ),
      );
      await expectLater(harness.run(), throwsA(isA<DioException>()));
      // 非可重试类型，请求仅 1 次。
      expect(harness.adapter.callCount, 1);
    });

    test('badResponse 类型：直接放行，不进入重试', () async {
      final harness = _Harness(
        DioExceptionType.badResponse,
        config: RetryConfig(
          baseDelay: const Duration(milliseconds: 1),
          maxDelay: const Duration(milliseconds: 50),
          enableJitter: false,
        ),
      );
      await expectLater(harness.run(), throwsA(isA<DioException>()));
      expect(harness.adapter.callCount, 1);
    });

    test('熔断打开：跳过重试直接放行', () async {
      final breaker = CircuitBreaker(failureThreshold: 1);
      breaker.recordFailure();
      expect(breaker.allowRequest, isFalse);

      final harness = _Harness(
        DioExceptionType.connectionError,
        config: RetryConfig(
          baseDelay: const Duration(milliseconds: 1),
          maxDelay: const Duration(milliseconds: 50),
          enableJitter: false,
        ),
        circuitBreaker: breaker,
      );
      await expectLater(harness.run(), throwsA(isA<DioException>()));
      // 熔断打开，跳过重试，请求仅 1 次。
      expect(harness.adapter.callCount, 1);
    });
  });
}

/// 测试夹具：用真实 Dio + 自定义 Adapter（始终抛指定类型 DioException 并计数），
/// 并将 RetryInterceptor 加入其拦截器链，以覆盖「重发重新进入拦截器链」的真实行为。
class _Harness {
  _Harness(
    DioExceptionType failType, {
    RetryConfig? config,
    NetworkEnvironment? networkEnvironment,
    CircuitBreaker? circuitBreaker,
  }) {
    adapter = _FailingAdapter(failType);
    dio = Dio(BaseOptions());
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(
        dio,
        config: config,
        networkEnvironment: networkEnvironment,
        circuitBreaker: circuitBreaker,
      ),
    );
  }

  late final _FailingAdapter adapter;
  late final Dio dio;

  /// 触发一次请求（失败），返回其 Future 供断言。
  Future<Response<dynamic>> run() => dio.fetch(RequestOptions(path: '/test'));
}

/// 手写网络环境实现：返回固定质量。
class _FakeNetworkEnvironment extends NetworkEnvironment {
  _FakeNetworkEnvironment(this._quality);

  final NetworkQuality _quality;

  @override
  NetworkQuality get quality => _quality;

  @override
  Stream<NetworkQuality> get qualityStream => Stream.value(_quality);

  @override
  Future<bool> isConnected() async => _quality != NetworkQuality.disconnected;

  @override
  Stream<bool> get connectionChanges =>
      Stream.value(_quality != NetworkQuality.disconnected);
}

/// 手写 HttpClientAdapter：每次 fetch 都抛指定类型 DioException 并计数。
class _FailingAdapter implements HttpClientAdapter {
  _FailingAdapter(this.failType);

  final DioExceptionType failType;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    throw DioException(
      requestOptions: options,
      type: failType,
      message: 'mock fetch failure: $failType',
    );
  }

  @override
  void close({bool force = false}) {}
}
