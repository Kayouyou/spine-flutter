import 'package:test/test.dart';
import '../lib/domain.dart';

/// ErrorCode枚举测试
///
/// TDD: 先写测试，再实现
void main() {
  group('ErrorCode', () {
    test('包含所有业务错误类型', () {
      // 验证ErrorCode枚举存在并包含所有预期值
      expect(ErrorCode.values.length, greaterThan(5));

      // 验证关键错误类型存在
      expect(ErrorCode.values.any((e) => e.name == 'networkError'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'unauthorized'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'tokenExpired'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'serverError'), isTrue);
      expect(ErrorCode.values.any((e) => e.name == 'unknown'), isTrue);
    });

    test('networkError枚举值可访问', () {
      // 验证可以获取特定ErrorCode
      final error = ErrorCode.networkError;
      expect(error.name, equals('networkError'));
    });
  });

  group('DomainException', () {
    test('携带ErrorCode', () {
      // 创建DomainException，携带ErrorCode
      final exception = DomainException(
        ErrorCode.networkError,
        httpCode: 503,
      );

      expect(exception.errorCode, equals(ErrorCode.networkError));
      expect(exception.httpCode, equals(503));
    });

    test('携带原始响应数据', () {
      final rawData = {'error': 'timeout', 'details': 'connection failed'};
      final exception = DomainException(
        ErrorCode.networkError,
        httpCode: 503,
        rawData: rawData,
      );

      expect(exception.rawData, equals(rawData));
    });

    test('toString包含errorCode和httpCode', () {
      final exception = DomainException(
        ErrorCode.unauthorized,
        httpCode: 401,
      );

      final str = exception.toString();
      expect(str, contains('DomainException'));
      expect(str, contains('unauthorized'));
      expect(str, contains('401'));
    });

    test('无httpCode时toString仍正常', () {
      final exception = DomainException(ErrorCode.unknown);

      final str = exception.toString();
      expect(str, contains('DomainException'));
      expect(str, contains('unknown'));
    });
  });
}