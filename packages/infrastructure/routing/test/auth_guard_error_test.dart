// packages/infrastructure/routing/test/auth_guard_error_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

void main() {
  group('AuthGuard.check 异常处理 (P1-2)', () {
    test('非白名单路径 isLoggedInChecker 抛异常时, 走 /login 兜底', () {
      // /profile 不在 publicRoutes 里 → 异常时按未登录处理 → 跳 /login
      final result = AuthGuard.check(
        '/profile',
        () => throw Exception('AuthManager not ready'),
      );
      expect(result, '/login?redirect=/profile');
    });

    test('白名单路径在异常时仍放行', () {
      final result = AuthGuard.check(
        '/login',
        () => throw Exception('boom'),
      );
      expect(result, isNull);
    });

    test('异常时非白名单路径的 query/fragment 也被保留到 redirect', () {
      final result = AuthGuard.check(
        '/profile?from=push',
        () => throw Exception('boom'),
      );
      expect(result, '/login?redirect=/profile?from=push');
    });
  });
}
