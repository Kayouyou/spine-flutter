import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:api/src/dio/request_queue.dart';

/// 轻量 fake：记录 resolve/reject 调用结果
class FakeRequestInterceptorHandler extends RequestInterceptorHandler {
  Response? resolved;
  DioException? rejected;
  int resolveCount = 0;
  int rejectCount = 0;

  @override
  void next(RequestOptions requestOptions) {
    // 测试中未使用
  }

  @override
  void resolve(Response response, [bool failIfNotResolved = true]) {
    resolved = response;
    resolveCount++;
  }

  @override
  void reject(DioException error, [bool failIfNotResolved = true]) {
    rejected = error;
    rejectCount++;
  }
}

RequestOptions _opts(String path) => RequestOptions(path: path);

void main() {
  group('RequestQueue 入队与淘汰', () {
    test('超过 maxSize 时丢弃最旧请求', () async {
      final maxSize = 3;
      final paths = ['/a', '/b', '/c', '/d'];
      final handlers = <FakeRequestInterceptorHandler>[];

      final queue = RequestQueue(maxSize: maxSize);
      for (final p in paths) {
        final h = FakeRequestInterceptorHandler();
        handlers.add(h);
        queue.enqueue(QueuedRequest(options: _opts(p), handler: h));
      }

      // 长度被限制在 maxSize 内
      expect(queue.length, maxSize);
      expect(queue.isEmpty, isFalse);

      // 最早入队的 /a（handlers[0]）被淘汰，flush 后应未被 resolve
      await queue.flush(
        (options) async => Response(requestOptions: options, data: 'ok'),
      );

      expect(handlers[0].resolveCount, 0); // /a 已丢弃
      expect(handlers[1].resolveCount, 1); // /b
      expect(handlers[2].resolveCount, 1); // /c
      expect(handlers[3].resolveCount, 1); // /d
      expect(queue.isEmpty, isTrue);
    });
  });

  group('RequestQueue flush', () {
    test('按入队顺序重发并各自 resolve，最终队列清空', () async {
      final queue = RequestQueue(maxSize: 10);
      final order = <String>[];
      final handlers = <FakeRequestInterceptorHandler>[];

      for (final p in ['/1', '/2', '/3']) {
        final h = FakeRequestInterceptorHandler();
        handlers.add(h);
        queue.enqueue(QueuedRequest(options: _opts(p), handler: h));
      }

      // 假 fetch：记录调用顺序，返回固定 Response
      final fetch = (RequestOptions options) async {
        order.add(options.path);
        return Response(requestOptions: options, data: 'resp-${options.path}');
      };

      await queue.flush(fetch);

      expect(order, ['/1', '/2', '/3']); // 顺序重发
      for (final h in handlers) {
        expect(h.resolveCount, 1);
        expect(h.rejected, isNull);
      }
      expect(queue.isEmpty, isTrue);
    });

    test('flush 中 fetch 失败应调用 reject 且 failIfNotResolved=false', () async {
      final queue = RequestQueue(maxSize: 10);
      final h = FakeRequestInterceptorHandler();
      queue.enqueue(QueuedRequest(options: _opts('/fail'), handler: h));

      final fetch = (RequestOptions options) async =>
          throw DioException(requestOptions: options, error: 'boom');

      await queue.flush(fetch);

      expect(h.rejectCount, 1);
      expect(h.rejected?.error, 'boom');
      expect(queue.isEmpty, isTrue);
    });

    test('空队列 flush 直接返回不抛异常', () async {
      final queue = RequestQueue();
      await queue.flush((options) async => Response(requestOptions: options));
      expect(queue.isEmpty, isTrue);
    });
  });

  group('RequestQueue clear', () {
    test('clear(reason) 使每个 handler reject 并清空队列', () async {
      final queue = RequestQueue(maxSize: 10);
      final handlers = <FakeRequestInterceptorHandler>[];
      for (final p in ['/x', '/y']) {
        final h = FakeRequestInterceptorHandler();
        handlers.add(h);
        queue.enqueue(QueuedRequest(options: _opts(p), handler: h));
      }

      queue.clear('网络不可恢复');

      for (final h in handlers) {
        expect(h.rejectCount, 1);
        expect(h.rejected?.error, '网络不可恢复');
      }
      expect(queue.isEmpty, isTrue);
    });
  });
}
