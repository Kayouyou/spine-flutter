import '../models/login_result.dart';
import '../repositories/auth_repository.dart';
import '../exceptions/domain_exception.dart';
import '../result.dart';

/// 用户登录用例
///
/// 编排 [AuthRepository.login]，将登录逻辑收拢到 domain 层。
/// 调用方通过 `when()` 处理成功/失败。
class LoginUseCase {
  final AuthRepository _authRepository;

  const LoginUseCase(this._authRepository);

  /// 执行登录
  Future<Result<LoginResult, DomainException>> execute({
    required String username,
    required String password,
  }) async {
    return _authRepository.login(username, password);
  }
}
