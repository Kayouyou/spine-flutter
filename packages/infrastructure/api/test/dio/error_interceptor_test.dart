// packages/infrastructure/api/test/dio/error_interceptor_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:api/src/dio/error_interceptor.dart';

/// ErrorInterceptorHandler 是个具体类(不是 abstract),
/// 用最小 stub 实现它,只重写 next 让测试继续走通。
class _StubHandler extends ErrorInterceptorHandler {
  DioException? lastNextErr;

  @override
  void next(DioException err) {
    lastNextErr = err;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {}

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {}
}

class _Capture {
  final List<Map<String, dynamic>> contexts = [];
  final List<Object> errors = [];
  final List<StackTrace?> stacks = [];

  void call(Object err, StackTrace? stack, {Map<String, dynamic> context = const {}}) {
    errors.add(err);
    stacks.add(stack);
    contexts.add(context);
  }
}

DioException _makeErr({
  required String path,
  required String method,
  required DioExceptionType type,
  int? status,
}) {
  return DioException(
    requestOptions: RequestOptions(path: path, method: method),
    response: status == null
        ? null
        : Response(
            requestOptions: RequestOptions(path: path, method: method),
            statusCode: status,
          ),
    type: type,
  );
}

void main() {
  group('ErrorInterceptor.onError', () {
    test('reports 5xx with method/url/status context', () {
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);

      final err = _makeErr(
        path: '/api/orders',
        method: 'GET',
        type: DioExceptionType.badResponse,
        status: 500,
      );
      interceptor.onError(err, _StubHandler());

      expect(cap.errors, [err]);
      expect(cap.contexts, hasLength(1));
      final ctx = cap.contexts.first;
      expect(ctx['source'], 'dio');
      expect(ctx['method'], 'GET');
      expect(ctx['url'], '/api/orders');
      expect(ctx['status'], 500);
      expect(ctx['type'], 'badResponse');
    });

    test('skips 4xx (no report, but handler.next still called)', () {
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);
      final handler = _StubHandler();

      for (final code in [400, 401, 403, 404, 422]) {
        final err = _makeErr(
          path: '/api/x',
          method: 'POST',
          type: DioExceptionType.badResponse,
          status: code,
        );
        interceptor.onError(err, handler);
        // next 应被调,否则后续拦截器拿不到 error
        expect(handler.lastNextErr, same(err));
      }
      // 4xx 一律不上报
      expect(cap.errors, isEmpty);
    });

    test('reports network errors (no response, e.g. connectionError)', () {
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);

      final err = _makeErr(
        path: '/api/x',
        method: 'GET',
        type: DioExceptionType.connectionError,
      );
      interceptor.onError(err, _StubHandler());

      expect(cap.contexts, hasLength(1));
      final ctx = cap.contexts.first;
      expect(ctx['status'], isNull);
      expect(ctx['type'], 'connectionError');
      expect(ctx['source'], 'dio');
    });

    test('reports 5xx and forwards stack trace', () {
      // dio 5.8+ 的 DioException 构造器会把缺省的 stackTrace 兜底成
      // requestOptions.sourceStackTrace ?? StackTrace.current,
      // 所以 cap.stacks.first 不可能为 null。这里验证拦截器在 5xx
      // 路径不崩溃,并且确实把 stack 透传给了回调。
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);

      final err = DioException(
        requestOptions: RequestOptions(path: '/api/x', method: 'GET'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/x'),
          statusCode: 503,
        ),
        type: DioExceptionType.badResponse,
      );
      interceptor.onError(err, _StubHandler());

      expect(cap.contexts, hasLength(1));
      expect(cap.stacks.first, isA<StackTrace>());
    });
  });
}
