import '../models/login_result.dart';
import '../result.dart';
import '../exceptions/domain_exception.dart';

/// 认证仓储接口
abstract class AuthRepository {
  /// 用户登录
  ///
  /// 返回 Result: Success(LoginResult) 或 Failure(DomainException)
  /// [LoginResult] 携带 userId、token 等认证信息。
  Future<Result<LoginResult, DomainException>> login(String username, String password);

  /// 用户注册
  ///
  /// 返回 Result: Success(LoginResult) 或 Failure(DomainException)
  Future<Result<LoginResult, DomainException>> register(String username, String password);

  /// 用户登出
  ///
  /// 返回 Result: Success(void) 或 Failure(DomainException)
  Future<Result<void, DomainException>> logout();
}
