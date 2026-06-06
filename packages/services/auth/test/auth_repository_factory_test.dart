import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/di/setup.dart';
import 'package:auth/src/manager.dart';
import 'package:auth/src/repository/mock_auth_repository.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:key_value_storage/key_value_storage.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<LoginResult, DomainException>> login(String a, String b) async =>
      throw UnimplementedError();
  @override
  Future<Result<LoginResult, DomainException>> register(String a, String b) async =>
      throw UnimplementedError();
  @override
  Future<Result<void, DomainException>> logout() async => throw UnimplementedError();
}

void main() {
  late GetIt sl;

  setUp(() {
    sl = GetIt.instance;
    if (sl.isRegistered<AuthCubit>()) sl.unregister<AuthCubit>();
    if (sl.isRegistered<AuthRepository>()) sl.unregister<AuthRepository>();
    if (sl.isRegistered<UserRepository>()) sl.unregister<UserRepository>();
    if (sl.isRegistered<TokenStorage>()) sl.unregister<TokenStorage>();
    if (sl.isRegistered<AuthManager>()) sl.unregister<AuthManager>();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('useMock: true registers MockAuthRepository', () {
    setupAuth(sl, useMock: true);
    expect(sl<AuthRepository>(), isA<MockAuthRepository>());
  });

  test('useMock: false with no prior registration throws', () {
    expect(
      () => setupAuth(sl, useMock: false),
      throwsA(anyOf(isA<AssertionError>(), isA<StateError>())),
      reason: 'release 模式无真实现必须 fail-fast，强制调用方先注册。'
          'debug 模式先 assert (AssertionError), release 模式靠 StateError 兜底',
    );
  });

  test('useMock: false with prior real registration succeeds', () {
    sl.registerSingleton<AuthRepository>(_FakeAuthRepository());
    setupAuth(sl, useMock: false);
    expect(sl<AuthRepository>(), isA<_FakeAuthRepository>());
  });
}
