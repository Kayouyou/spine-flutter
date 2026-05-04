import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/manager.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockKeyValueStorage extends Mock implements KeyValueStorage {}

class _MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late _MockUserRepository mockUserRepository;
  late _MockKeyValueStorage mockKeyValueStorage;
  late _MockAuthCubit mockAuthCubit;

  setUp(() {
    mockUserRepository = _MockUserRepository();
    mockKeyValueStorage = _MockKeyValueStorage();
    mockAuthCubit = _MockAuthCubit();
  });

  group('AuthManager', () {
    test('isLoggedIn is false initially', () {
      when(() => mockAuthCubit.isLoggedIn).thenReturn(false);
      final manager = AuthManager(
        userRepository: mockUserRepository,
        keyValueStorage: mockKeyValueStorage,
        authCubit: mockAuthCubit,
      );
      expect(manager.isLoggedIn, false);
    });

    test('handleLogin completes without error', () async {
      final manager = AuthManager(
        userRepository: mockUserRepository,
        keyValueStorage: mockKeyValueStorage,
        authCubit: mockAuthCubit,
      );
      await expectLater(manager.handleLogin(), completes);
    });

    test('dispose completes without error', () {
      final manager = AuthManager(
        userRepository: mockUserRepository,
        keyValueStorage: mockKeyValueStorage,
        authCubit: mockAuthCubit,
      );
      expect(() => manager.dispose(), returnsNormally);
    });
  });
}