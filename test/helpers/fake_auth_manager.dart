// test/helpers/fake_auth_manager.dart
import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';

/// Test-only AuthManager that controls `isLoggedIn` deterministically.
///
/// Extends the real AuthManager (so it satisfies the `sl<AuthManager>()`
/// registration) and overrides only the `isLoggedIn` getter to return
/// whatever the test sets via [setLoggedIn].
class FakeAuthManager extends AuthManager {
  bool _loggedIn;

  FakeAuthManager({required bool isLoggedIn})
      : _loggedIn = isLoggedIn,
        super(
          userRepository: _NoopUserRepository(),
          tokenStorage: _NoopTokenStorage(),
          authCubit: _NoopAuthCubit(),
        );

  @override
  bool get isLoggedIn => _loggedIn;

  void setLoggedIn(bool v) => _loggedIn = v;
}

class _NoopUserRepository implements UserRepository {
  @override
  Future<Result<User, DomainException>> getCurrentUser() async =>
      Failure<User, DomainException>(UnauthorizedException());

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('NoopUserRepository.${invocation.memberName}');
}

class _NoopTokenStorage implements TokenStorage {
  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> setToken(String token) async {}

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> clear() async {}

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('NoopTokenStorage.${invocation.memberName}');
}

class _NoopAuthCubit extends AuthCubit {
  _NoopAuthCubit() : super(_NoopAuthRepository());

  @override
  bool get isLoggedIn => false;
}

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<Result<LoginResult, DomainException>> login(
          String username, String password) async =>
      Failure<LoginResult, DomainException>(UnauthorizedException());

  @override
  Future<Result<LoginResult, DomainException>> register(
          String username, String password) async =>
      Failure<LoginResult, DomainException>(UnauthorizedException());

  @override
  Future<Result<void, DomainException>> logout() async =>
      Success<void, DomainException>(null);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('NoopAuthRepository.${invocation.memberName}');
}
