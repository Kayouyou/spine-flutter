import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:api/src/http/http_constant.dart';
import 'package:api/src/refresh/refresh_api.dart';

void main() {
  group('shouldRenewToken', () {
    test('code == reTokenCode 返回 true', () async {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: '{"code": ${HttpConstant.reTokenCode}, "data": null}',
        statusCode: 200,
      );
      expect(await shouldRenewToken(response), isTrue);
    });

    test('其他 code 返回 false', () async {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: '{"code": 0, "data": null}',
      );
      expect(await shouldRenewToken(response), isFalse);
    });

    test('非 JSON / null data 返回 false', () async {
      final r1 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: null,
      );
      final r2 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: 'plain text',
        statusCode: 200,
      );
      expect(await shouldRenewToken(r1), isFalse);
      expect(await shouldRenewToken(r2), isFalse);
    });
  });
}

