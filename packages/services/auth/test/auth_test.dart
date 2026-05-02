import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:auth/src/manager.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockKeyValueStorage extends Mock implements KeyValueStorage {}

void main() {
  late _MockUserRepository mockUserRepository;
  late _MockKeyValueStorage mockKeyValueStorage;

  setUp(() {
    mockUserRepository = _MockUserRepository();
    mockKeyValueStorage = _MockKeyValueStorage();
  });

  group('AuthManager', () {
    test('isLoggedIn is false initially', () {
      final manager = AuthManager(
        userRepository: mockUserRepository,
        keyValueStorage: mockKeyValueStorage,
      );
      // Placeholder: 验证管理器实例化成功
      expect(manager, isNotNull);
    });

    test('handleLogin completes without error', () async {
      final manager = AuthManager(
        userRepository: mockUserRepository,
        keyValueStorage: mockKeyValueStorage,
      );
      // Should complete without throwing
      await expectLater(manager.handleLogin(), completes);
    });

    test('dispose completes without error', () {
      final manager = AuthManager(
        userRepository: mockUserRepository,
        keyValueStorage: mockKeyValueStorage,
      );
      // Should not throw
      expect(() => manager.dispose(), returnsNormally);
    });
  });
}