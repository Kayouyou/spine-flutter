import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:api/src/dio/cache_interceptor.dart';

/// 记录 next/resolve/reject 的轻量 fake（请求方向）
class _FakeReqHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  bool rejectCalled = false;
  RequestOptions? nextOptions;
  Response? resolved;
  DioException? rejected;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
    nextOptions = requestOptions;
  }

  @override
  void resolve(Response response, [bool failIfNotResolved = true]) {
    resolveCalled = true;
    resolved = response;
  }

  @override
  void reject(DioException error, [bool failIfNotResolved = true]) {
    rejectCalled = true;
    rejected = error;
  }
}

/// 记录 next 的响应/错误 fake
class _FakeRespHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;
  Response? nextResponse;
  @override
  void next(Response response) {
    nextCalled = true;
    nextResponse = response;
  }
}

class _FakeErrHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  DioException? nextError;
  Response? resolved;
  @override
  void next(DioException error) {
    nextCalled = true;
    nextError = error;
  }

  @override
  void resolve(Response response, [bool failIfNotResolved = true]) {
    resolveCalled = true;
    resolved = response;
  }
}

RequestOptions _get({Map<String, dynamic> extra = const {}}) => RequestOptions(
      path: '/resource',
      method: 'GET',
      queryParameters: const {'id': '1'},
      extra: extra,
    );

void main() {
  group('CacheInterceptor', () {
    test('默认（无 extra）：完全透明，next 放行', () {
      final c = CacheInterceptor();
      final h = _FakeReqHandler();
      c.onRequest(_get(), h);
      expect(h.nextCalled, isTrue);
      expect(h.resolveCalled, isFalse);
    });

    test('非 GET：强制 none，next 放行', () {
      final c = CacheInterceptor();
      final h = _FakeReqHandler();
      final opts = RequestOptions(path: '/x', method: 'POST');
      c.onRequest(opts, h);
      expect(h.nextCalled, isTrue);
    });

    test('cacheOnly 未命中：直接 reject', () {
      final c = CacheInterceptor();
      final h = _FakeReqHandler();
      c.onRequest(_get(extra: {'cacheStrategy': CacheStrategy.cacheOnly}), h);
      expect(h.rejectCalled, isTrue);
      expect(h.nextCalled, isFalse);
    });

    test('cacheFirst 命中：直接 resolve 缓存数据', () {
      final store = MemoryCacheStore();
      final c = CacheInterceptor(store: store);
      // 预置缓存
      store.set('GET//resource?id=1', {'name': 'cached'}, const Duration(minutes: 5));
      final h = _FakeReqHandler();
      c.onRequest(_get(extra: {'cacheStrategy': CacheStrategy.cacheFirst}), h);
      expect(h.resolveCalled, isTrue);
      expect(h.resolved!.data, {'name': 'cached'});
    });

    test('networkFirst 响应后写入缓存', () {
      final store = MemoryCacheStore();
      final c = CacheInterceptor(store: store);
      final h = _FakeRespHandler();
      final resp = Response(
        requestOptions: _get(extra: {'cacheStrategy': CacheStrategy.networkFirst}),
        data: {'name': 'fresh'},
        statusCode: 200,
      );
      c.onResponse(resp, h);
      expect(h.nextCalled, isTrue);
      expect(store.get('GET//resource?id=1'), {'name': 'fresh'});
    });

    test('networkFirst 网络失败且有缓存：回退缓存 resolve', () {
      final store = MemoryCacheStore();
      store.set('GET//resource?id=1', {'name': 'cached'}, const Duration(minutes: 5));
      final c = CacheInterceptor(store: store);
      final h = _FakeErrHandler();
      final err = DioException(
        requestOptions: _get(extra: {'cacheStrategy': CacheStrategy.networkFirst}),
        type: DioExceptionType.connectionError,
      );
      c.onError(err, h);
      expect(h.resolveCalled, isTrue);
      expect(h.resolved!.data, {'name': 'cached'});
    });

    test('networkFirst 网络失败且无缓存：继续 next(error)', () {
      final c = CacheInterceptor();
      final h = _FakeErrHandler();
      final err = DioException(
        requestOptions: _get(extra: {'cacheStrategy': CacheStrategy.networkFirst}),
        type: DioExceptionType.connectionError,
      );
      c.onError(err, h);
      expect(h.nextCalled, isTrue);
      expect(h.resolveCalled, isFalse);
    });
  });
}
