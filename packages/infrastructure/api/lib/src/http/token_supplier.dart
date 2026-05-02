/// Abstract token supplier — breaks circular dependency with user_repository.
/// user_repository implements this interface instead of api importing user_repository.
abstract class TokenSupplier {
  /// 获取当前用户Token
  Future<String?> getToken();

  /// 设置用户Token
  Future<void> setToken(String token);

  /// 获取用户名
  Future<String?> getUsername();

  /// 清除Token（退出登录时调用）
  Future<void> clearToken();
}