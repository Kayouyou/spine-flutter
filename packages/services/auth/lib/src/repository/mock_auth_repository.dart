import 'package:domain/domain.dart';

/// ⚠️ SCAFFOLD MODE: Mock 实现，仅用于脚手架演示和测试。
///
/// 真实项目应替换为:
/// 1. 在 setupAuth 中使用 UserRepositoryImpl（见同目录 user_repository_impl.dart）
/// 2. 或通过环境变量切换 mock/real:
///    sl.registerLazySingleton<AuthRepository>(() {
///      if (kDebugMode) return MockAuthRepository();
///      return AuthRepositoryImpl(sl<UserApi>());
///    });
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
