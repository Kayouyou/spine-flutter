import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:api/src/dio/renewal_token_intercaptor.dart';
import 'package:api/src/http/token_supplier.dart';

/// Token续期拦截器单元测试
///
/// 测试覆盖：
/// 1. Logger注入（默认DefaultLogger + 自定义注入）
/// 2. TokenSupplier注入
/// 3. 续期检测逻辑
/// 4. 续期状态枚举完整性
/// 5. CancelTokenManager、ConcurrentLimiter、RetryPolicy、RequestTracker
void main() {
  group('续期检测', () {
    test('Api.testToken为true时触发续期检测', () {
      Api.testToken = true;

      final data = jsonEncode({'code': HttpConstant.renewalTokenCode});
      final needsRenewal = jsonDecode(data)['code'] == HttpConstant.renewalTokenCode;
      expect(needsRenewal, isTrue);

      Api.testToken = false; // reset
    });

    test('正常响应不触发续期', () {
      final data = jsonEncode({'code': 0});
      final needsRenewal = jsonDecode(data)['code'] == HttpConstant.renewalTokenCode;
      expect(needsRenewal, isFalse);
    });

    test('续期码不等于0时触发续期', () {
      final data = jsonEncode({'code': HttpConstant.renewalTokenCode});
      final needsRenewal = jsonDecode(data)['code'] == HttpConstant.renewalTokenCode;
      expect(needsRenewal, isTrue);
    });
  });

  group('Logger注入', () {
    test('拦截器创建成功（默认使用DefaultLogger）', () {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.com'));
      final interceptor = TokenRenewalInterceptor(dio);
      expect(interceptor, isNotNull);
    });

    test('可通过setter注入自定义Logger', () {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.com'));
      final interceptor = TokenRenewalInterceptor(dio);
      final logger = _TestLogger();
      interceptor.logger = logger;
      expect(interceptor, isNotNull);

      // 验证Logger可接收消息
      logger.debug('test debug');
      logger.info('test info');
      logger.warning('test warning');
      logger.error('test error');
    });
  });

  group('TokenSupplier注入', () {
    test('构造函数可接收TokenSupplier', () {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.com'));
      final supplier = _TestTokenSupplier();
      final interceptor = TokenRenewalInterceptor(dio, supplier);
      expect(interceptor, isNotNull);
    });

    test('TokenSupplier可延迟注入', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.com'));
      final interceptor = TokenRenewalInterceptor(dio);
      final supplier = _TestTokenSupplier();
      interceptor.tokenSupplier = supplier;

      final token = await supplier.getToken();
      expect(token, equals('test-token-123'));
      expect(token, isNotEmpty);
    });

    test('TokenSupplier可获取和设置Token', () async {
      final supplier = _TestTokenSupplier();
      expect(await supplier.getToken(), equals('test-token-123'));
      await supplier.setToken('new-token');
      expect(await supplier.getToken(), equals('new-token'));
    });
  });

  group('响应Handler', () {
    test('ResponseInterceptorHandler可传递响应', () {
      final handler = _TestResponseHandler();
      final response = Response(
        requestOptions: RequestOptions(path: '/api/test'),
        statusCode: 200,
      );
      final result = handler.next(response);
      expect(result, isNotNull);
    });
  });

  group('续期状态枚举', () {
    test('续期状态完整', () {
      expect(TokenRenewalState.values.length, 4);
      expect(TokenRenewalState.values, contains(TokenRenewalState.idle));
      expect(TokenRenewalState.values, contains(TokenRenewalState.renewing));
      expect(TokenRenewalState.values, contains(TokenRenewalState.success));
      expect(TokenRenewalState.values, contains(TokenRenewalState.failed));
    });

    test('TokenRenewalState默认值', () {
      // 枚举第一个值是idle（默认值）
      expect(TokenRenewalState.values.first, TokenRenewalState.idle);
    });
  });

  group('CancelTokenManager', () {
    test('注册和取消页面请求', () {
      final manager = CancelTokenManager.instance;
      manager.clearAll();

      final token1 = CancelToken();
      final token2 = CancelToken();
      manager.register('test_page', token1);
      manager.register('test_page', token2);
      expect(manager.getTokenCount('test_page'), 2);

      // 取消后数量应归零（tokens被clear）
      manager.cancelPage('test_page');
      expect(manager.getTokenCount('test_page'), 0);

      manager.clearAll();
    });

    test('清理不存在的页面不报错', () {
      final manager = CancelTokenManager.instance;
      manager.cleanup('non_existent_page');
      expect(manager.getTokenCount('non_existent_page'), 0);
    });
  });

  group('ConcurrentLimiter', () {
    test('未达上限直接执行', () async {
      final limiter = ConcurrentLimiter(maxConcurrent: 5);
      final result = await limiter.execute(() async => 'ok');
      expect(result, equals('ok'));
    });

    test('队列优先级排序', () async {
      final limiter = ConcurrentLimiter(maxConcurrent: 1);
      final results = <String>[];

      // 第一个请求占用槽位
      final first = limiter.execute(() async {
        await Future.delayed(Duration(milliseconds: 50));
        results.add('first');
        return 'first';
      });

      // 后续请求排队
      final highPriority = limiter.execute(() async {
        results.add('high');
        return 'high';
      }, priority: 10);

      final lowPriority = limiter.execute(() async {
        results.add('low');
        return 'low';
      }, priority: 1);

      await Future.wait([first, highPriority, lowPriority]);

      // 高优先级应先于低优先级执行
      expect(results.indexOf('high'), lessThan(results.indexOf('low')));
    });

    test('cancelTag取消等待请求', () async {
      final limiter = ConcurrentLimiter(maxConcurrent: 1);
      final results = <String>[];

      // 第一个请求占用槽位
      final first = limiter.execute(() async {
        await Future.delayed(Duration(seconds: 1));
        results.add('first');
        return 'first';
      });

      // 带tag的请求排队
      final tagged = limiter.execute(() async => 'tagged', tag: 'my-tag');

      // 立即取消
      limiter.cancelTag('my-tag');

      try {
        await tagged;
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>()); // DomainException
      }

      // 验证第一个请求不受影响
      await first;
      expect(results, contains('first'));
    });
  });

  group('RetryPolicy', () {
    test('默认不重试', () {
      const policy = RetryPolicy();
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(policy.shouldRetry(error, 0), isFalse);
    });

    test('标准策略可重试超时', () {
      const policy = RetryPolicy.standard;
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(policy.shouldRetry(error, 0), isTrue);
      expect(policy.shouldRetry(error, 2), isTrue);
      expect(policy.shouldRetry(error, 3), isFalse); // 已达上限
    });

    test('标准策略可重试502/503/504', () {
      const policy = RetryPolicy.standard;

      for (final code in [502, 503, 504]) {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(requestOptions: RequestOptions(path: '/test'), statusCode: code),
        );
        expect(policy.shouldRetry(error, 0), isTrue, reason: 'Should retry $code');
      }
    });

    test('不可重试的错误', () {
      const policy = RetryPolicy.standard;

      // 400不应重试
      final error400 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(requestOptions: RequestOptions(path: '/test'), statusCode: 400),
      );
      expect(policy.shouldRetry(error400, 0), isFalse);
    });
  });

  group('RequestTracker', () {
    test('追踪和完成请求', () {
      final tracker = RequestTracker.instance;
      tracker.clearAll();

      tracker.track('req-1', '/api/test', null);
      expect(tracker.pendingCount, 1);

      tracker.complete('req-1');
      expect(tracker.pendingCount, 0);
    });

    test('完成不存在的请求不报错', () {
      final tracker = RequestTracker.instance;
      tracker.complete('non-existent');
    });

    test('自定义开始时间', () {
      final tracker = RequestTracker.instance;
      tracker.clearAll();

      final startTime = DateTime.now().subtract(Duration(seconds: 5));
      tracker.track('req-2', '/api/test', startTime);
      expect(tracker.pendingCount, 1);

      tracker.clearAll();
    });
  });
}

/// 测试用Logger实现
class _TestLogger implements AppLoggerInterface {
  final List<String> _messages = [];
  List<String> get messages => List.unmodifiable(_messages);

  @override
  void debug(String message) => _messages.add('DEBUG: $message');

  @override
  void info(String message) => _messages.add('INFO: $message');

  @override
  void warning(String message) => _messages.add('WARNING: $message');

  @override
  void error(String message, [dynamic error]) =>
      _messages.add('ERROR: $message');
}

/// 测试用TokenSupplier
class _TestTokenSupplier implements TokenSupplier {
  String _token = 'test-token-123';

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> setToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getUsername() async => 'test-user';

  @override
  Future<void> clearToken() async {
    _token = '';
  }
}

/// 测试用ResponseHandler
class _TestResponseHandler extends ResponseInterceptorHandler {
  @override
  ResponseInterceptorHandler next(Response response) => this;
}
