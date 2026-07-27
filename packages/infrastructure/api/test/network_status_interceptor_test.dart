import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:api/src/dio/network_status_interceptor.dart';
import 'package:api/src/network/network_environment.dart';
import 'package:api/src/dio/request_queue.dart';

/// NetworkStatusInterceptor 单元测试（仅编写，不在沙箱执行）
///
/// 覆盖：
/// 1. 离线时 onRequest 不调用 next（请求被暂停/入队）
/// 2. 离线且 extra['enqueueOnOffline'] == false 时 handler.reject 被调用
/// 3. 在线时 handler.next 被调用
/// 4. connectionChanges 发出 true 且队列非空时，flush 被触发且 fetch 回调调用一次
void main() {
  group('NetworkStatusInterceptor', () {
    test('离线：请求入队且不调用 next', () async {
      final env = FakeNetworkEnvironment(initialConnected: false);
      final queue = FakeRequestQueue();
      final dio = Dio();
      final interceptor = NetworkStatusInterceptor(
        dio,
        networkEnvironment: env,
        requestQueue: queue,
      );

      final handler = FakeRequestHandler();
      final options = RequestOptions(path: '/offline');
      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isFalse);
      expect(queue.enqueueCount, equals(1));
      expect(handler.rejectCalled, isFalse);
      interceptor.dispose();
    });

    test('离线且 enqueueOnOffline==false：直接 reject，不入队', () async {
      final env = FakeNetworkEnvironment(initialConnected: false);
      final queue = FakeRequestQueue();
      final dio = Dio();
      final interceptor = NetworkStatusInterceptor(
        dio,
        networkEnvironment: env,
        requestQueue: queue,
      );

      final handler = FakeRequestHandler();
      final options = RequestOptions(path: '/critical');
      options.extra['enqueueOnOffline'] = false;
      await interceptor.onRequest(options, handler);

      expect(handler.rejectCalled, isTrue);
      expect(queue.enqueueCount, equals(0));
      expect(handler.nextCalled, isFalse);
      interceptor.dispose();
    });

    test('在线：调用 handler.next', () async {
      final env = FakeNetworkEnvironment(initialConnected: true);
      final queue = FakeRequestQueue();
      final dio = Dio();
      final interceptor = NetworkStatusInterceptor(
        dio,
        networkEnvironment: env,
        requestQueue: queue,
      );

      final handler = FakeRequestHandler();
      final options = RequestOptions(path: '/online');
      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(queue.enqueueCount, equals(0));
      interceptor.dispose();
    });

    test('网络恢复且队列非空：flush 被触发，fetch 回调调用一次', () async {
      final env = FakeNetworkEnvironment(initialConnected: false);
      final queue = FakeRequestQueue();
      final adapter = _MockHttpClientAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final interceptor = NetworkStatusInterceptor(
        dio,
        networkEnvironment: env,
        requestQueue: queue,
      );

      // 先离线入队一个请求
      final handler = FakeRequestHandler();
      await interceptor.onRequest(RequestOptions(path: '/offline'), handler);
      expect(queue.enqueueCount, equals(1));

      // 恢复连接
      env.emitConnection(true);
      // 等待异步监听回调执行 flush 与 dio.fetch 完成
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(queue.flushCount, equals(1));
      expect(queue.fetchInvoked, isTrue);
      expect(adapter.fetchCount, equals(1));
      interceptor.dispose();
    });
  });
}

/// 可手动控制连通性的 NetworkEnvironment fake
class FakeNetworkEnvironment implements NetworkEnvironment {
  FakeNetworkEnvironment({this.initialConnected = true});

  bool initialConnected;
  final _connectionController = StreamController<bool>.broadcast();

  void emitConnection(bool connected) => _connectionController.add(connected);

  @override
  Future<bool> isConnected() async => initialConnected;

  @override
  Stream<bool> get connectionChanges => _connectionController.stream;

  @override
  NetworkQuality get quality =>
      initialConnected ? NetworkQuality.good : NetworkQuality.disconnected;

  @override
  Stream<NetworkQuality> get qualityStream => const Stream.empty();
}

/// 记录 enqueue / flush 行为的 RequestQueue fake
class FakeRequestQueue extends RequestQueue {
  int enqueueCount = 0;
  int flushCount = 0;
  bool fetchInvoked = false;

  @override
  void enqueue(QueuedRequest request) {
    enqueueCount++;
    super.enqueue(request);
  }

  @override
  Future<void> flush(Future<Response<dynamic>> Function(RequestOptions) fetch) async {
    flushCount++;
    fetchInvoked = true;
    await fetch(RequestOptions(path: '/offline'));
  }
}

/// 记录 fetch 调用次数的 HttpClientAdapter mock（Dio 仅有工厂构造器，不能继承）
class _MockHttpClientAdapter implements HttpClientAdapter {
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    fetchCount++;
    return Future<ResponseBody>.value(
      ResponseBody.fromString('{}', 200),
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 记录 next / reject 调用状态的请求处理器 fake
class FakeRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  bool rejectCalled = false;
  RequestOptions? capturedOptions;
  DioException? capturedError;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
    capturedOptions = requestOptions;
  }

  @override
  void reject(DioException error, [bool failIfNotResolved = true]) {
    rejectCalled = true;
    capturedError = error;
  }
}
