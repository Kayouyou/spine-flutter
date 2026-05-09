import '../result.dart';
import '../exceptions/domain_exception.dart';

/// 认证仓储接口
abstract class AuthRepository {
  /// 用户登录
  ///
  /// 返回 Result: Success(bool) 或 Failure(DomainException)
  Future<Result<bool, DomainException>> login(String username, String password);

  /// 用户注册
  ///
  /// 返回 Result: Success(bool) 或 Failure(DomainException)
  Future<Result<bool, DomainException>> register(String username, String password);

  /// 用户登出
  ///
  /// 返回 Result: Success(void) 或 Failure(DomainException)
  Future<Result<void, DomainException>> logout();
}
