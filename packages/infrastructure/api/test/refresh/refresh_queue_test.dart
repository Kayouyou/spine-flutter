import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:api/src/refresh/refresh_queue.dart';

void main() {
  group('PendingRequest 3-field construction + equality', () {
    test('requestOptions + completer + originalResponse 3 字段全必填', () {
      final opts = RequestOptions(path: '/a', method: 'GET');
      final completer = Completer<Response>();
      final originalResponse = Response<dynamic>(
        requestOptions: opts,
        data: 'orig',
        statusCode: 401,
      );

      final r = PendingRequest(
        requestOptions: opts,
        completer: completer,
        originalResponse: originalResponse,
      );

      expect(r.requestOptions, same(opts));
      expect(r.completer, same(completer));
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
      final r1 = PendingRequest(
        requestOptions: opts1,
        completer: Completer<Response>(),
        originalResponse: Response<dynamic>(requestOptions: opts1),
      );
      final r2 = PendingRequest(
        requestOptions: opts2,
        completer: Completer<Response>(),
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
        originalResponse: Response<dynamic>(requestOptions: opts1),
      );
      final r2 = PendingRequest(
        requestOptions: opts2,
        completer: Completer<Response>(),
        originalResponse: Response<dynamic>(requestOptions: opts2),
      );

      expect(r1, isNot(equals(r2)));
    });
  });

  group('RefreshQueue.add + drain', () {
    test('add 去重: 相同请求只入队 1 次', () {
      final q = RefreshQueue();
      final opts = RequestOptions(path: '/a', method: 'GET');
      q.add(PendingRequest(
        requestOptions: opts,
        completer: Completer<Response>(),
        originalResponse: Response<dynamic>(requestOptions: opts),
      ));
      q.add(PendingRequest(
        requestOptions: RequestOptions(path: '/a', method: 'GET'),
        completer: Completer<Response>(),
        originalResponse: Response<dynamic>(requestOptions: opts),
      ));

      expect(q.size, equals(1));
    });

    test('drain batchSize=5, fireAndForget=false, N=12 分 3 批', () async {
      final q = RefreshQueue();
      for (var i = 0; i < 12; i++) {
        final opts = RequestOptions(path: '/p$i', method: 'GET');
        q.add(PendingRequest(
          requestOptions: opts,
          completer: Completer<Response>(),
          originalResponse: Response<dynamic>(requestOptions: opts),
          timestamp: DateTime.now().add(Duration(milliseconds: i)),
        ));
      }

      final timestamps = <DateTime>[];
      await q.drain<void>(
        (p) async => timestamps.add(DateTime.now()),
        batchSize: 5,
        fireAndForget: false,
      );

      expect(timestamps.length, equals(12));
      final gap1 = timestamps[5].difference(timestamps[4]);
      final gap2 = timestamps[10].difference(timestamps[9]);
      expect(gap1.inMilliseconds, greaterThanOrEqualTo(45));
      expect(gap2.inMilliseconds, greaterThanOrEqualTo(45));
    });

    test('drain fireAndForget=true: caller Future 在 processor 完成前 resolve', () async {
      final q = RefreshQueue();
      for (var i = 0; i < 3; i++) {
        final opts = RequestOptions(path: '/p$i', method: 'GET');
        q.add(PendingRequest(
          requestOptions: opts,
          completer: Completer<Response>(),
          originalResponse: Response<dynamic>(requestOptions: opts),
        ));
      }

      final processorStarted = Completer<void>();
      var processorCompleted = false;

      final drainFuture = q.drain<void>(
        (p) async {
          processorStarted.complete();
          await Future.delayed(const Duration(milliseconds: 200));
          processorCompleted = true;
        },
        batchSize: 5,
        fireAndForget: true,
      );

      await drainFuture;
      expect(processorCompleted, isFalse);
      await processorStarted.future;
    });
  });
}
