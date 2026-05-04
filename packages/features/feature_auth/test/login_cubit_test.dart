import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:feature_auth/src/cubit/login_cubit.dart';
import 'package:feature_auth/src/cubit/login_state.dart';
import 'package:feature_auth/src/repository/mock_auth_repository.dart';

class MockRepo extends Mock implements MockAuthRepository {}

void main() {
  group('LoginCubit', () {
    late LoginCubit cubit;
    late MockRepo mockRepo;

    setUp(() {
      mockRepo = MockRepo();
      cubit = LoginCubit(mockRepo);
    });

    tearDown(() => cubit.close());

    test('initial state', () {
      expect(cubit.state.status, LoginStatus.initial);
    });

    blocTest<LoginCubit, LoginState>(
      'login success',
      build: () {
        when(() => mockRepo.login('user', 'password123'))
            .thenAnswer((_) async => true);
        return LoginCubit(mockRepo);
      },
      act: (cubit) {
        cubit.setUsername('user');
        cubit.setPassword('password123');
        return cubit.login();
      },
      expect: () => [
        isA<LoginState>().having((s) => s.username, 'username', 'user'),
        isA<LoginState>().having((s) => s.password, 'password', 'password123'),
        isA<LoginState>().having((s) => s.status, 'status', LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.success)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'login with short password fails',
      build: () {
        when(() => mockRepo.login('user', 'short'))
            .thenAnswer((_) async => false);
        return LoginCubit(mockRepo);
      },
      act: (cubit) {
        cubit.setUsername('user');
        cubit.setPassword('short');
        return cubit.login();
      },
      expect: () => [
        isA<LoginState>().having((s) => s.username, 'username', 'user'),
        isA<LoginState>().having((s) => s.password, 'password', 'short'),
        isA<LoginState>().having((s) => s.status, 'status', LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.error),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'login with empty username fails',
      build: () {
        when(() => mockRepo.login('', 'password123'))
            .thenAnswer((_) async => false);
        return LoginCubit(mockRepo);
      },
      act: (cubit) {
        cubit.setUsername('');
        cubit.setPassword('password123');
        return cubit.login();
      },
      expect: () => [
        isA<LoginState>().having((s) => s.username, 'username', ''),
        isA<LoginState>().having((s) => s.password, 'password', 'password123'),
        isA<LoginState>().having((s) => s.status, 'status', LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.error),
      ],
    );
    
    blocTest<LoginCubit, LoginState>(
      'reset returns to initial',
      build: () {
        when(() => mockRepo.login('user', 'password123'))
            .thenAnswer((_) async => true);
        return LoginCubit(mockRepo);
      },
      act: (cubit) async {
        cubit.setUsername('user');
        cubit.setPassword('password123');
        await cubit.login();
        cubit.reset();
      },
      skip: 3,
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.success),
        isA<LoginState>().having((s) => s.status, 'status', LoginStatus.initial),
      ],
    );
    
    blocTest<LoginCubit, LoginState>(
      'register success',
      build: () {
        when(() => mockRepo.register('user', 'password123'))
            .thenAnswer((_) async => true);
        return LoginCubit(mockRepo);
      },
      act: (cubit) {
        cubit.setUsername('user');
        cubit.setPassword('password123');
        return cubit.register();
      },
      expect: () => [
        isA<LoginState>().having((s) => s.username, 'username', 'user'),
        isA<LoginState>().having((s) => s.password, 'password', 'password123'),
        isA<LoginState>().having((s) => s.status, 'status', LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.success),
      ],
    );
    
    blocTest<LoginCubit, LoginState>(
      'register with short password fails',
      build: () {
        when(() => mockRepo.register('user', 'short'))
            .thenAnswer((_) async => false);
        return LoginCubit(mockRepo);
      },
      act: (cubit) {
        cubit.setUsername('user');
        cubit.setPassword('short');
        return cubit.register();
      },
      expect: () => [
        isA<LoginState>().having((s) => s.username, 'username', 'user'),
        isA<LoginState>().having((s) => s.password, 'password', 'short'),
        isA<LoginState>().having((s) => s.status, 'status', LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.error),
      ],
    );
  });
}