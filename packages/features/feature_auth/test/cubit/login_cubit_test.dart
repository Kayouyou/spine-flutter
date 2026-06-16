import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:auth/auth.dart';
import 'package:feature_auth/src/cubit/login_cubit.dart';
import 'package:feature_auth/src/cubit/login_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthManager extends Mock implements AuthManager {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockAuthManager mockAuthManager;

  setUpAll(() {
    registerFallbackValue(const LoginResult(token: '', userId: ''));
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockAuthManager = MockAuthManager();
    
    // Stub handleLoginSuccess to return completed future
    when(() => mockAuthManager.handleLoginSuccess(any())).thenAnswer((_) async {});
  });

  group('LoginCubit', () {
    test('initial state is LoginState.initial', () {
      final cubit = LoginCubit(repository: mockAuthRepository, authManager: mockAuthManager);
      expect(cubit.state, const LoginState());
    });

    group('setUsername', () {
      blocTest<LoginCubit, LoginState>(
        'emits state with updated username',
        build: () => LoginCubit(repository: mockAuthRepository, authManager: mockAuthManager),
        act: (cubit) => cubit.setUsername('testuser'),
        expect: () => [
          const LoginState(username: 'testuser'),
        ],
      );
    });

    group('setPassword', () {
      blocTest<LoginCubit, LoginState>(
        'emits state with updated password',
        build: () => LoginCubit(repository: mockAuthRepository, authManager: mockAuthManager),
        act: (cubit) => cubit.setPassword('password123'),
        expect: () => [
          const LoginState(password: 'password123'),
        ],
      );
    });

    group('login', () {
      blocTest<LoginCubit, LoginState>(
        'emits [loading, success] when login succeeds',
        setUp: () {
          when(() => mockAuthRepository.login(any(), any())).thenAnswer(
            (_) async => Success<LoginResult, DomainException>(
              const LoginResult(token: 'test-token', userId: 'user-123'),
            ),
          );
        },
        build: () => LoginCubit(repository: mockAuthRepository, authManager: mockAuthManager),
        seed: () => const LoginState(username: 'testuser', password: 'password123'),
        act: (cubit) async {
          await cubit.login();
        },
        expect: () => [
          const LoginState(status: LoginStatus.loading, username: 'testuser', password: 'password123'),
          const LoginState(status: LoginStatus.success, username: 'testuser', password: 'password123'),
        ],
        verify: (_) {
          verify(
            () => mockAuthManager.handleLoginSuccess(
              any(that: isA<LoginResult>()),
            ),
          ).called(1);
        },
      );

      blocTest<LoginCubit, LoginState>(
        'emits [loading, error] when login fails',
        setUp: () {
          when(() => mockAuthRepository.login(any(), any())).thenAnswer(
            (_) async => Failure<LoginResult, DomainException>(
              const NetworkException('Invalid credentials'),
            ),
          );
        },
        build: () => LoginCubit(repository: mockAuthRepository, authManager: mockAuthManager),
        seed: () => const LoginState(username: 'testuser', password: 'wrongpassword'),
        act: (cubit) async {
          await cubit.login();
        },
        expect: () => [
          const LoginState(status: LoginStatus.loading, username: 'testuser', password: 'wrongpassword'),
          const LoginState(
            status: LoginStatus.error,
            errorMessage: 'Invalid credentials',
            username: 'testuser',
            password: 'wrongpassword',
          ),
        ],
        verify: (_) {
          verifyNever(
            () => mockAuthManager.handleLoginSuccess(any()),
          );
        },
      );
    });

    group('register', () {
      blocTest<LoginCubit, LoginState>(
        'emits [loading, success] when register succeeds',
        setUp: () {
          when(() => mockAuthRepository.register(any(), any())).thenAnswer(
            (_) async => Success<LoginResult, DomainException>(
              const LoginResult(token: 'test-token', userId: 'user-123'),
            ),
          );
        },
        build: () => LoginCubit(repository: mockAuthRepository, authManager: mockAuthManager),
        seed: () => const LoginState(username: 'newuser', password: 'password123'),
        act: (cubit) async {
          await cubit.register();
        },
        expect: () => [
          const LoginState(status: LoginStatus.loading, username: 'newuser', password: 'password123'),
          const LoginState(status: LoginStatus.success, username: 'newuser', password: 'password123'),
        ],
        verify: (_) {
          verify(
            () => mockAuthManager.handleLoginSuccess(
              any(that: isA<LoginResult>()),
            ),
          ).called(1);
        },
      );

      blocTest<LoginCubit, LoginState>(
        'emits [loading, error] when register fails',
        setUp: () {
          when(() => mockAuthRepository.register(any(), any())).thenAnswer(
            (_) async => Failure<LoginResult, DomainException>(
              const NetworkException('Registration failed'),
            ),
          );
        },
        build: () => LoginCubit(repository: mockAuthRepository, authManager: mockAuthManager),
        seed: () => const LoginState(username: 'newuser', password: 'password123'),
        act: (cubit) async {
          await cubit.register();
        },
        expect: () => [
          const LoginState(status: LoginStatus.loading, username: 'newuser', password: 'password123'),
          const LoginState(
            status: LoginStatus.error,
            errorMessage: 'Registration failed',
            username: 'newuser',
            password: 'password123',
          ),
        ],
        verify: (_) {
          verifyNever(
            () => mockAuthManager.handleLoginSuccess(any()),
          );
        },
      );
    });
  });
}
