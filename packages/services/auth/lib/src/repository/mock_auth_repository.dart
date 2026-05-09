import 'package:domain/domain.dart';

/// Mock 认证仓储实现（用于测试和脚手架）
///
/// 实现 AuthRepository 接口，返回 Result 类型。
class MockAuthRepository implements AuthRepository {
  bool _loggedIn = false;

  @override
  Future<Result<bool, DomainException>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    return Result.success(_loggedIn);
  }

  @override
  Future<Result<bool, DomainException>> register(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    return Result.success(_loggedIn);
  }

  @override
  Future<Result<void, DomainException>> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = false;
    return Result.success(null);
  }

  /// 检查是否已登录（非接口方法）
  Future<bool> isLoggedIn() async => _loggedIn;
}
