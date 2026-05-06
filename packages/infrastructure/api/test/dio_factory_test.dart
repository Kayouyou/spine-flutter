// packages/infrastructure/api/test/dio_factory_test.dart

import 'package:api/api.dart';
import 'package:dio/dio.dart';
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
  });
}
