import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

void main() {
  group('AuthGuard.check', () {
    test('exact public path passes for unauthenticated user', () {
      expect(AuthGuard.check('/login', () => false), isNull);
      expect(AuthGuard.check('/home', () => false), isNull);
      expect(AuthGuard.check('/', () => false), isNull);
      expect(AuthGuard.check('/register', () => false), isNull);
    });

    test('public path with query string still passes', () {
      // 关键 bug 修复: /home?from=push 不应被踢到 /login
      expect(AuthGuard.check('/home?from=push', () => false), isNull);
      expect(AuthGuard.check('/login?redirect=/settings', () => false), isNull);
      expect(AuthGuard.check('/?ref=email', () => false), isNull);
    });

    test('public path with fragment still passes', () {
      expect(AuthGuard.check('/home#section', () => false), isNull);
      expect(AuthGuard.check('/home?from=push#section', () => false), isNull);
    });

    test('protected path without query redirects to /login', () {
      expect(AuthGuard.check('/settings', () => false), '/login?redirect=/settings');
    });

    test('protected path with query redirects to /login (preserves original location)', () {
      final result = AuthGuard.check('/settings?tab=profile', () => false);
      expect(result, '/login?redirect=/settings?tab=profile');
    });

    test('nested public path is NOT auto-allowed (strict set match)', () {
      // /home 在白名单, /home/list 不在 — 严格 Set.contains
      expect(AuthGuard.check('/home/list', () => false),
          '/login?redirect=/home/list');
    });

    test('authenticated user on protected path passes', () {
      expect(AuthGuard.check('/settings', () => true), isNull);
      expect(AuthGuard.check('/settings?tab=profile', () => true), isNull);
    });
  });
}
