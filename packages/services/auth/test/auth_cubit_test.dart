import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';

void main() {
  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'initial state is AuthStatus.initial',
      build: () => AuthCubit(),
      verify: (cubit) {
        expect(cubit.state.status, AuthStatus.initial);
        expect(cubit.state.userId, isNull);
        expect(cubit.state.errorMessage, isNull);
        expect(cubit.isLoggedIn, false);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'setAuthState updates state correctly',
      build: () => AuthCubit(),
      act: (cubit) => cubit.setAuthState(
        const AuthState(status: AuthStatus.loggedIn, userId: 'test-user'),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loggedIn, userId: 'test-user'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'isLoggedIn getter returns true when loggedIn',
      build: () => AuthCubit(),
      act: (cubit) => cubit.setAuthState(
        const AuthState(status: AuthStatus.loggedIn, userId: 'test-user'),
      ),
      verify: (cubit) {
        expect(cubit.isLoggedIn, true);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'isLoggedIn getter returns false when initial',
      build: () => AuthCubit(),
      verify: (cubit) {
        expect(cubit.isLoggedIn, false);
      },
    );
  });
}
