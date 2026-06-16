import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:auth/src/manager.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockTokenStorage extends Mock implements TokenStorage {}
class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late AuthManager manager;
  late MockUserRepository mockUserRepo;
  late MockTokenStorage mockTokenStorage;
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockTokenStorage = MockTokenStorage();
    mockAuthCubit = MockAuthCubit();
    
    // Stub async methods to return completed futures
    when(() => mockTokenStorage.setToken(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.setUserId(any())).thenAnswer((_) async {});
    when(() => mockAuthCubit.setAuthState(any())).thenAnswer((_) async {});
    
    manager = AuthManager(
      userRepository: mockUserRepo,
      tokenStorage: mockTokenStorage,
      authCubit: mockAuthCubit,
    );
  });

  group('AuthManager.handleLoginSuccess', () {
    setUpAll(() {
      registerFallbackValue(AuthState());
    });

    test('saves token to TokenStorage', () async {
      final loginResult = const LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verify(() => mockTokenStorage.setToken('token-abc')).called(1);
    });

    test('saves userId to TokenStorage', () async {
      final loginResult = const LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verify(() => mockTokenStorage.setUserId('user-123')).called(1);
    });

    test('updates AuthCubit state to loggedIn', () async {
      final loginResult = const LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verify(() => mockAuthCubit.setAuthState(
        any(that: isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.loggedIn)
          .having((s) => s.userId, 'userId', 'user-123')),
      )).called(1);
    });

    test('calls saveToken and setUserId in correct order', () async {
      final loginResult = const LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verifyInOrder([
        () => mockTokenStorage.setToken('token-abc'),
        () => mockTokenStorage.setUserId('user-123'),
        () => mockAuthCubit.setAuthState(any()),
      ]);
    });
  });
}
