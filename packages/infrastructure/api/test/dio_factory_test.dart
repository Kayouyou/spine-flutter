// packages/infrastructure/api/test/dio_factory_test.dart

import 'package:api/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createDio', () {
    test('creates Dio with all interceptors', () {
      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
      );

      // 默认链：TokenRenewalInterceptor + InterceptorsWrapper + LogInterceptor
      // （外加 Dio 内置的 ImplyContentTypeInterceptor）
      expect(dio.interceptors.length, greaterThanOrEqualTo(3));
    });

    test('adds AutoCancelInterceptor when provided', () {
      final autoCancel = AutoCancelInterceptor(
        tagProvider: () => '/test',
        registerFn: (tag, token) {},
      );

      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
        autoCancelInterceptor: autoCancel,
      );

      // AutoCancelInterceptor 应在链中（Dio 内置拦截器之后）
      expect(dio.interceptors.contains(autoCancel), isTrue);

      // AutoCancelInterceptor 应排在 TokenRenewalInterceptor 之前
      final autoIndex =
          dio.interceptors.indexWhere((i) => identical(i, autoCancel));
      final renewalIndex =
          dio.interceptors.indexWhere((i) => i is TokenRenewalInterceptor);
      expect(autoIndex, lessThan(renewalIndex));
    });

    test('has TokenRenewalInterceptor in chain', () {
      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
      );

      // TokenRenewalInterceptor 应在链中
      final hasRenewal =
          dio.interceptors.any((i) => i is TokenRenewalInterceptor);
      expect(hasRenewal, isTrue);
    });

    test('adds ErrorInterceptor when onDioError is provided', () {
      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
        onDioError: (_, __, {context = const {}}) {},
      );

      // ErrorInterceptor 在链中(不要求具体位置,位置由 dio_factory docstring 约束)
      final errorIdx = dio.interceptors.indexWhere((i) => i is ErrorInterceptor);
      expect(errorIdx, greaterThan(0),
          reason: 'ErrorInterceptor should be in the chain');
    });

    test('omits ErrorInterceptor when onDioError is null', () {
      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
      );

      final hasError =
          dio.interceptors.any((i) => i is ErrorInterceptor);
      expect(hasError, isFalse,
          reason: 'No callback → no ErrorInterceptor (R3 friendly)');
    });
  });
}
