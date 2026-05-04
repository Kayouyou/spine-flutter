import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routing/src/guards/auth_guard.dart';
import 'package:routing/src/guards/public_routes.dart';
import 'package:auth/auth.dart';

class MockAuthManager extends Mock implements AuthManager {}

void main() {
  group('AuthGuard', () {
    late MockAuthManager mockAuth;

    setUp(() {
      mockAuth = MockAuthManager();
    });

    test('whitelist routes return null', () {
      when(() => mockAuth.isLoggedIn).thenReturn(false);
      for (final route in publicRoutes) {
        expect(AuthGuard.check(route, mockAuth), null);
      }
    });

    test('logged in user no redirect', () {
      when(() => mockAuth.isLoggedIn).thenReturn(true);
      expect(AuthGuard.check('/profile', mockAuth), null);
    });

    test('not logged in non-whitelist redirect to login', () {
      when(() => mockAuth.isLoggedIn).thenReturn(false);
      final result = AuthGuard.check('/profile', mockAuth);
      expect(result, '/login?redirect=/profile');
    });

    test('redirect preserves original path', () {
      when(() => mockAuth.isLoggedIn).thenReturn(false);
      final result = AuthGuard.check('/settings/theme', mockAuth);
      expect(result, contains('/login?redirect=/settings/theme'));
    });
  });
}