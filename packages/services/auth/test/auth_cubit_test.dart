import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  group('AuthCubit', () {
    late MockAuthRepo mockRepo;

    setUp(() {
      mockRepo = MockAuthRepo();
    });

    blocTest<AuthCubit, AuthState>(
      'initial state is AuthStatus.initial',
      build: () => AuthCubit(mockRepo),
      verify: (cubit) {
        expect(cubit.state.status, AuthStatus.initial);
        expect(cubit.state.userId, isNull);
        expect(cubit.state.errorMessage, isNull);
        expect(cubit.isLoggedIn, false);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'login success emits [loading, loggedIn]',
      build: () => AuthCubit(mockRepo),
      setUp: () {
        when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => Result.success(LoginResult(userId: 'test-user', token: 'test-token')));
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.loggedIn, userId: 'test-user'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login failure emits [loading, error]',
      build: () => AuthCubit(mockRepo),
      setUp: () {
        when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => Result.failure(NetworkException('登录失败')));
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.error, errorMessage: '登录失败'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login exception emits [loading, error] with exception message',
      build: () => AuthCubit(mockRepo),
      setUp: () {
        when(() => mockRepo.login('user', 'pass'))
            .thenAnswer((_) async => Result.failure(NetworkException('network error')));
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.error, errorMessage: 'network error'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout emits [loading, initial] after login',
      build: () => AuthCubit(mockRepo),
      setUp: () {
        when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => Result.success(LoginResult(userId: 'test-user', token: 'test-token')));
        when(() => mockRepo.logout()).thenAnswer((_) async => Result.success(null));
      },
      act: (cubit) async {
        await cubit.login('user', 'pass');
        await cubit.logout();
      },
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.loggedIn, userId: 'test-user'),
        const AuthState(status: AuthStatus.loading, userId: 'test-user'),
        const AuthState(status: AuthStatus.initial),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'isLoggedIn getter returns true when loggedIn',
      build: () => AuthCubit(mockRepo),
      setUp: () {
        when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => Result.success(LoginResult(userId: 'test-user', token: 'test-token')));
      },
      act: (cubit) => cubit.login('user', 'pass'),
      verify: (cubit) {
        expect(cubit.isLoggedIn, true);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'isLoggedIn getter returns false when initial',
      build: () => AuthCubit(mockRepo),
      verify: (cubit) {
        expect(cubit.isLoggedIn, false);
      },
    );
  });
}
