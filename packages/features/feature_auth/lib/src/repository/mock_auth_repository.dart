import 'package:domain/domain.dart';

class MockAuthRepository implements AuthRepository {
  bool _loggedIn = false;

  @override
  Future<Result<bool, DomainException>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _loggedIn = username.isNotEmpty && password.length >= 6;
    return Result.success(_loggedIn);
  }

  @override
  Future<Result<bool, DomainException>> register(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _loggedIn = username.isNotEmpty && password.length >= 6;
    return Result.success(_loggedIn);
  }

  @override
  Future<Result<void, DomainException>> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.success(null);
  }
}