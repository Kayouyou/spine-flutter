import 'package:domain/domain.dart';

class MockAuthRepository implements AuthRepository {
  bool _loggedIn = false;

  @override
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    return _loggedIn;
  }

  @override
  Future<bool> register(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    return _loggedIn;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = false;
  }

  // Helper method (not part of domain interface)
  Future<bool> isLoggedIn() async => _loggedIn;
}
