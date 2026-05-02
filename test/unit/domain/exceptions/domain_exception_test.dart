import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainException', () {
    test('NetworkException 存储 statusCode', () {
      final e = NetworkException('超时', statusCode: 503);
      expect(e.message, '超时');
      expect(e.statusCode, 503);
    });

    test('UnauthorizedException 有固定消息', () {
      const e = UnauthorizedException();
      expect(e.message, '认证已过期');
    });

    test('NotFoundException 有固定消息', () {
      const e = NotFoundException();
      expect(e.message, '请求的资源不存在');
    });

    test('ValidationException 存储 fieldErrors', () {
      final e = ValidationException('无效', fieldErrors: {'email': '格式错误'});
      expect(e.fieldErrors, {'email': '格式错误'});
    });

    test('所有异常都是 DomainException 的子类型', () {
      expect(const UnauthorizedException(), isA<DomainException>());
      expect(NetworkException(''), isA<DomainException>());
      expect(const NotFoundException(), isA<DomainException>());
      expect(ValidationException(''), isA<DomainException>());
    });
  });
}
