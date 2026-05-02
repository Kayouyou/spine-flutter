// packages/domain/lib/src/usecases/get_user_usecase.dart
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../exceptions/domain_exception.dart';

/// 获取当前用户信息的用例
///
/// 示例 UseCase，展示如何在 domain 层编排 Repository 调用。
/// 真实项目中，复杂业务逻辑（多 Repository 协调、缓存策略等）放在 UseCase 中。
///
/// 使用方式：
/// ```dart
/// final useCase = sl<GetUserUseCase>();
/// final user = await useCase.execute();
/// ```
///
/// 注册方式：Factory（无状态，每次创建）
class GetUserUseCase {
  final UserRepository _userRepository;

  const GetUserUseCase(this._userRepository);

  /// 获取当前用户
  ///
  /// 如果用户未登录（[UnauthorizedException]），调用方应引导登录。
  Future<User> execute() async {
    return _userRepository.getCurrentUser();
  }
}
