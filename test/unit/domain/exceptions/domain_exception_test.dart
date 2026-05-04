import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

void main() {
  group('DomainException', () {
    test('NetworkException carries message and statusCode', () {
      const ex = NetworkException('Failed', statusCode: 500);
      expect(ex.message, 'Failed');
      expect(ex.statusCode, 500);
    });

    test('UnauthorizedException has default message', () {
      const ex = UnauthorizedException();
      expect(ex.message, '认证已过期');
    });

    test('NotFoundException has default message', () {
      const ex = NotFoundException();
      expect(ex.message, '请求的资源不存在');
    });

    test('ValidationException carries field errors', () {
      const ex = ValidationException('Invalid', fieldErrors: {'email': '格式错误'});
      expect(ex.fieldErrors['email'], '格式错误');
    });

    test('sealed class allows exhaustive matching', () {
      final exceptions = <DomainException>[
        const NetworkException('net'),
        const UnauthorizedException(),
        const NotFoundException(),
        const ValidationException('val'),
      ];

      for (final ex in exceptions) {
        final result = switch (ex) {
          NetworkException() => 'network',
          UnauthorizedException() => 'unauthorized',
          NotFoundException() => 'notfound',
          ValidationException() => 'validation',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}