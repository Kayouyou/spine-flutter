import 'package:test/test.dart';
import 'package:domain/domain.dart';

/// ErrorCode枚举测试
void main() {
  group('ErrorCode', () {
    test('包含所有业务错误类型', () {
      expect(ErrorCode.values.length, greaterThan(5));
      expect(ErrorCode.values.any((e) => e.name == 'networkError'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'unauthorized'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'tokenExpired'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'serverError'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'unknown'), isTrue);
    });

    test('networkError枚举值可访问', () {
      const error = ErrorCode.networkError;
      expect(error.name, equals('networkError'));
    });
  });

  group('DomainException sealed 体系', () {
    test('NetworkException 携带状态码和消息', () {
      const e = NetworkException('服务不可用', statusCode: 503);
      expect(e.message, equals('服务不可用'));
      expect(e.statusCode, equals(503));
      expect(e.toString(), contains('NetworkException'));
      expect(e.toString(), contains('服务不可用'));
    });

    test('UnauthorizedException', () {
      const e = UnauthorizedException();
      expect(e.message, equals('认证已过期'));
      expect(e.toString(), contains('UnauthorizedException'));
    });

    test('NotFoundException', () {
      const e = NotFoundException();
      expect(e.message, equals('请求的资源不存在'));
      expect(e.toString(), contains('NotFoundException'));
    });

    test('ValidationException 携带字段错误信息', () {
      const e = ValidationException(
        '输入校验失败',
        fieldErrors: {'email': '邮箱格式不正确'},
      );
      expect(e.message, equals('输入校验失败'));
      expect(e.fieldErrors, containsPair('email', '邮箱格式不正确'));
      expect(e.toString(), contains('ValidationException'));
    });

    test('所有异常子类均实现 Exception', () {
      expect(const NetworkException('x'), isA<Exception>());
      expect(const UnauthorizedException(), isA<Exception>());
      expect(const NotFoundException(), isA<Exception>());
      expect(const ValidationException('x'), isA<Exception>());
      expect(const ConflictException(), isA<Exception>());
      expect(const RateLimitedException(), isA<Exception>());
    });

    test('sealed class 穷尽性模式匹配', () {
      // 验证 sealed 特性：switch 需要穷尽所有分支
      String describe(DomainException e) => switch (e) {
            NetworkException _ => 'network',
            UnauthorizedException _ => 'auth',
            NotFoundException _ => 'not found',
            ValidationException _ => 'validation',
            ConflictException _ => 'conflict',
            RateLimitedException _ => 'rate limited',
          };

      expect(describe(const NetworkException('x')), equals('network'));
      expect(describe(const UnauthorizedException()), equals('auth'));
      expect(describe(const NotFoundException()), equals('not found'));
      expect(describe(const ValidationException('x')), equals('validation'));
      expect(describe(const ConflictException()), equals('conflict'));
      expect(describe(const RateLimitedException()), equals('rate limited'));
    });
  });
}
