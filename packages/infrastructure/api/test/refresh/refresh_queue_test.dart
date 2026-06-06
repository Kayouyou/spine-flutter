import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:api/src/refresh/refresh_queue.dart';

void main() {
  group('PendingRequest 4-field construction + equality', () {
    test('requestOptions + completer + handler + originalResponse 4 字段全必填', () {
      final opts = RequestOptions(path: '/a', method: 'GET');
      final completer = Completer<Response>();
      final handler = ResponseInterceptorHandler();
      final originalResponse = Response<dynamic>(
        requestOptions: opts,
        data: 'orig',
        statusCode: 401,
      );

      final r = PendingRequest(
        requestOptions: opts,
        completer: completer,
        handler: handler,
        originalResponse: originalResponse,
      );

      expect(r.requestOptions, same(opts));
      expect(r.completer, same(completer));
      expect(r.handler, same(handler));
      expect(r.originalResponse, same(originalResponse));
      expect(r.timestamp, isA<DateTime>());
    });

    test('相同 path+method+queryParameters.toString()+data.toString() 视为相等', () {
      final opts1 = RequestOptions(
        path: '/a',
        method: 'GET',
        queryParameters: {'k': 'v'},
        data: 'body',
      );
      final opts2 = RequestOptions(
        path: '/a',
        method: 'GET',
        queryParameters: {'k': 'v'},
        data: 'body',
      );
      final h1 = ResponseInterceptorHandler();
      final h2 = ResponseInterceptorHandler();
      final r1 = PendingRequest(
        requestOptions: opts1,
        completer: Completer<Response>(),
        handler: h1,
        originalResponse: Response<dynamic>(requestOptions: opts1),
      );
      final r2 = PendingRequest(
        requestOptions: opts2,
        completer: Completer<Response>(),
        handler: h2,
        originalResponse: Response<dynamic>(requestOptions: opts2),
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('path 不同则不等', () {
      final opts1 = RequestOptions(path: '/a', method: 'GET');
      final opts2 = RequestOptions(path: '/b', method: 'GET');
      final r1 = PendingRequest(
        requestOptions: opts1,
        completer: Completer<Response>(),
        handler: ResponseInterceptorHandler(),
        originalResponse: Response<dynamic>(requestOptions: opts1),
      );
      final r2 = PendingRequest(
        requestOptions: opts2,
        completer: Completer<Response>(),
        handler: ResponseInterceptorHandler(),
        originalResponse: Response<dynamic>(requestOptions: opts2),
      );

      expect(r1, isNot(equals(r2)));
    });
  });
}
