import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';
import 'package:auth/src/repository/mock_auth_repository.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  group('AuthCubit', () {
    late AuthCubit cubit;
    late MockAuthRepo mockRepo;

    setUp(() {
      mockRepo = MockAuthRepo();
      cubit = AuthCubit(mockRepo);
    });

    tearDown(() => cubit.close());

    test('initial state is AuthStatus.initial', () {
      expect(cubit.state.status, AuthStatus.initial);
    });

    test('login success changes state to loggedIn', () async {
      when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => true);
      await cubit.login('user', 'pass');
      expect(cubit.state.status, AuthStatus.loggedIn);
      expect(cubit.isLoggedIn, true);
    });

    test('login failure changes state to error', () async {
      when(() => mockRepo.login('', '')).thenAnswer((_) async => false);
      await cubit.login('', '');
      expect(cubit.state.status, AuthStatus.error);
    });

    test('logout resets state', () async {
      when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => true);
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      await cubit.login('user', 'pass');
      await cubit.logout();
      expect(cubit.state.status, AuthStatus.initial);
      expect(cubit.isLoggedIn, false);
    });
  });
}
