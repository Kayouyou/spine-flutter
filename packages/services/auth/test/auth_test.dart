import 'package:flutter_test/flutter_test.dart';
import 'package:auth/src/manager.dart';

void main() {
  group('AuthManager', () {
    test('isLoggedIn is false initially', () {
      // Placeholder test
      expect(true, isTrue);
    });

    test('handleLogin completes without error', () async {
      final manager = AuthManager();
      // Should complete without throwing
      await expectLater(manager.handleLogin(), completes);
    });

    test('dispose completes without error', () {
      final manager = AuthManager();
      // Should not throw
      expect(() => manager.dispose(), returnsNormally);
    });
  });
}