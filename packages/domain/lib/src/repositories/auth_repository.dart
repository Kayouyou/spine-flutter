/// 认证仓库接口
abstract class AuthRepository {
  Future<bool> login(String username, String password);
  Future<bool> register(String username, String password);
  Future<void> logout();
}
