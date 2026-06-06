import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/src/http/http_constant.dart';
import 'package:api/src/refresh/refresh_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('shouldRenewToken (L661-671)', () {
    test('code == reTokenCode 返回 true', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: '{"code": ${HttpConstant.reTokenCode}, "data": null}',
        statusCode: 200,
      );
      expect(shouldRenewToken(response), isTrue);
    });

    test('其他 code 返回 false', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: '{"code": 0, "data": null}',
        statusCode: 200,
      );
      expect(shouldRenewToken(response), isFalse);
    });

    test('非 JSON / null data 返回 false', () {
      final r1 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: null,
        statusCode: 200,
      );
      final r2 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: 'plain text',
        statusCode: 200,
      );
      expect(shouldRenewToken(r1), isFalse);
      expect(shouldRenewToken(r2), isFalse);
    });
  });

  group('retryRequest 14-field Options rebuild (L634-649)', () {
    late Dio dio;
    late RequestOptions original;

    setUpAll(() {
      registerFallbackValue(RequestOptions(path: '/'));
      registerFallbackValue(Options());
    });

    setUp(() {
      dio = _MockDio();
      original = RequestOptions(
        path: '/api/data',
        method: 'POST',
        headers: {'X-Custom': 'value'},
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        extra: {'userId': 42},
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        validateStatus: (status) => status != null && status < 500,
        receiveDataWhenStatusError: true,
        followRedirects: false,
        maxRedirects: 3,
        requestEncoder: (request, options) async => request,
        responseDecoder: (response, options) => response,
        listFormat: ListFormat.multi,
        data: {'key': 'value'},
      );
    });

    test('14 字段 Options 保留', () async {
      final result = Response<dynamic>(
        requestOptions: original,
        data: '{"ok": true}',
        statusCode: 200,
      );
      when(() => dio.request<dynamic>(any(), any())).thenAnswer((_) async => result);

      await retryRequest(dio, original, token: 'new-token');

      final captured = verify(() => dio.request<dynamic>(captureAny(), captureAny())).captured;
      final options = captured[1] as Options;
      expect(options.method, equals('POST'));
      expect(options.headers, containsPair('X-Custom', 'value'));
      expect(options.sendTimeout, equals(const Duration(seconds: 30)));
      expect(options.receiveTimeout, equals(const Duration(seconds: 30)));
      expect(options.extra, containsPair('userId', 42));
      expect(options.responseType, equals(ResponseType.json));
      expect(options.contentType, equals(Headers.jsonContentType));
      expect(options.receiveDataWhenStatusError, isTrue);
      expect(options.followRedirects, isFalse);
      expect(options.maxRedirects, equals(3));
      expect(options.listFormat, equals(ListFormat.multi));
      expect(options.headers['token'], equals('new-token'));
    });
  });
}
