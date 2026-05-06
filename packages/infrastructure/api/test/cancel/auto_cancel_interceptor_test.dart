import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoCancelInterceptor', () {
    late String? currentTag;
    late Map<String, List<CancelToken>> registeredTokens;

    setUp(() {
      currentTag = null;
      registeredTokens = {};
    });

    AutoCancelInterceptor createInterceptor() {
      return AutoCancelInterceptor(
        tagProvider: () => currentTag,
        registerFn: (tag, token) {
          registeredTokens.putIfAbsent(tag, () => []).add(token);
        },
      );
    }

    test('does nothing when tag is null', () {
      currentTag = null;
      final interceptor = createInterceptor();
      final options = RequestOptions(path: '/api/test');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(registeredTokens, isEmpty);
      expect(options.cancelToken, isNull);
    });

    test('creates CancelToken and registers when tag is set', () {
      currentTag = '/home';
      final interceptor = createInterceptor();
      final options = RequestOptions(path: '/api/test');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.cancelToken, isNotNull);
      expect(registeredTokens['/home']?.length, 1);
      expect(registeredTokens['/home']!.first, same(options.cancelToken));
    });

    test('accumulates multiple CancelTokens under same tag', () {
      currentTag = '/home';
      final interceptor = createInterceptor();

      final options1 = RequestOptions(path: '/api/a');
      final options2 = RequestOptions(path: '/api/b');

      interceptor.onRequest(options1, RequestInterceptorHandler());
      interceptor.onRequest(options2, RequestInterceptorHandler());

      expect(registeredTokens['/home']?.length, 2);
    });
  });
}
