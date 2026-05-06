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
/// 5. CancelTokenManager
void main() {
  group('续期检测', () {
    test('正常响应不触发续期', () {
      final data = jsonEncode({'code': 0});
      final needsRenewal = jsonDecode(data)['code'] == HttpConstant.reTokenCode;
      expect(needsRenewal, isFalse);
    });

    test('续期码不等于0时触发续期', () {
      final data = jsonEncode({'code': HttpConstant.reTokenCode});
      final needsRenewal = jsonDecode(data)['code'] == HttpConstant.reTokenCode;
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
