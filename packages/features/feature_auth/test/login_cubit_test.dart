import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:domain/domain.dart';
import 'package:auth/auth.dart';
import 'package:feature_auth/src/cubit/login_cubit.dart';
import 'package:feature_auth/src/cubit/login_state.dart';

class MockRepo extends Mock implements AuthRepository {}

class MockAuthManager extends Mock implements AuthManager {}

void main() {
  group('LoginCubit', () {
    late LoginCubit cubit;
    late MockRepo mockRepo;
    late MockAuthManager mockAuthManager;

    setUpAll(() {
      registerFallbackValue(const LoginResult(userId: '1', token: 'token'));
    });

    setUp(() {
      mockRepo = MockRepo();
      mockAuthManager = MockAuthManager();
      cubit = LoginCubit(repository: mockRepo, authManager: mockAuthManager);
    });

    tearDown(() => cubit.close());

    test('initial state', () {
      expect(cubit.state.status, LoginStatus.initial);
    });

    blocTest<LoginCubit, LoginState>(
      'login success',
      build: () {
        when(() => mockRepo.login('user', 'password123'))
            .thenAnswer((_) async => Result.success(const LoginResult(userId: '1', token: 'token')));
        when(() => mockAuthManager.handleLoginSuccess(any())).thenAnswer((_) async {});
        return LoginCubit(repository: mockRepo, authManager: mockAuthManager);
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
            .thenAnswer((_) async => Result.failure(const ValidationException('密码长度不足6位')));
        return LoginCubit(repository: mockRepo, authManager: mockAuthManager);
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
            .thenAnswer((_) async => Result.failure(const ValidationException('用户名不能为空')));
        return LoginCubit(repository: mockRepo, authManager: mockAuthManager);
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
      'register success',
      build: () {
        when(() => mockRepo.register('user', 'password123'))
            .thenAnswer((_) async => Result.success(const LoginResult(userId: '1', token: 'token', isNewUser: true)));
        when(() => mockAuthManager.handleLoginSuccess(any())).thenAnswer((_) async {});
        return LoginCubit(repository: mockRepo, authManager: mockAuthManager);
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
            .thenAnswer((_) async => Result.failure(const ValidationException('密码长度不足6位')));
        return LoginCubit(repository: mockRepo, authManager: mockAuthManager);
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