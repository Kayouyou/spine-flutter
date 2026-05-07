import 'package:domain/domain.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return username.isNotEmpty && password.length >= 6;
  }

  @override
  Future<bool> register(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return username.isNotEmpty && password.length >= 6;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}