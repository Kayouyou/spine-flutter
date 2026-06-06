import 'package:domain/domain.dart';

/// ⚠️ SCAFFOLD MODE: Mock 实现，仅用于脚手架演示和测试。
///
/// 生产构建必须:
/// 1. 在 setupAuth 之前 `sl.registerSingleton<AuthRepository>(RestAuthRepository(...))`
/// 2. 调 `setupAuth(sl, useMock: false)`（kDebugMode 在 release 已经是 false，
///    但显式传 false 更明确）
/// 3. 把本文件移到 `test/` 目录
///
/// 上面的 assert + StateError 会保证 release 启动期没真实现时立即崩溃，
/// 强制你处理。
///
/// 实现 AuthRepository 接口，返回 Result 类型。
class MockAuthRepository implements AuthRepository {
  bool _loggedIn = false;

  @override
  Future<Result<LoginResult, DomainException>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    return Result.success(const LoginResult(
      userId: 'mock-user-1',
      token: 'mock-token-xxx',
    ),);
  }

  @override
  Future<Result<LoginResult, DomainException>> register(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    return Result.success(const LoginResult(
      userId: 'mock-user-1',
      token: 'mock-token-xxx',
      isNewUser: true,
    ),);
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
