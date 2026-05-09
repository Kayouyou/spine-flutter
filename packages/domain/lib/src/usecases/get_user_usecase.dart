// packages/domain/lib/src/usecases/get_user_usecase.dart
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../exceptions/domain_exception.dart';
import '../result.dart';

/// 获取当前用户信息的用例
///
/// 示例 UseCase，展示如何在 domain 层编排 Repository 调用。
/// 返回 Result 类型，调用方通过 when() 处理成功/失败。
///
/// 使用方式：
/// ```dart
/// final useCase = sl<GetUserUseCase>();
/// final result = await useCase.execute();
/// result.when(
///   success: (user) => print(user.name),
///   failure: (error) => showError(error),
/// );
/// ```
///
/// 注册方式：Factory（无状态，每次创建）
class GetUserUseCase {
  final UserRepository _userRepository;

  const GetUserUseCase(this._userRepository);

  /// 获取当前用户
  ///
  /// 返回 Result: Success(User) 或 Failure(DomainException)
  Future<Result<User, DomainException>> execute() async {
    return _userRepository.getCurrentUser();
  }
}
