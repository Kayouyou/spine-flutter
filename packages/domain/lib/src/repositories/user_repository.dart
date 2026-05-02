// packages/domain/lib/src/repositories/user_repository.dart
import '../models/user.dart';

/// 用户数据访问契约
///
/// 实现在 services/ 或 features/ 层，通过 DI 注入。
/// domain 只定义接口，不关心实现细节（网络、缓存等）。
abstract class UserRepository {
  /// 获取当前登录用户
  ///
  /// 抛出 [UnauthorizedException] 若令牌过期。
  /// 抛出 [NetworkException] 若网络失败。
  Future<User> getCurrentUser();

  /// 更新用户资料
  ///
  /// 抛出 [ValidationException] 若字段校验失败。
  /// 抛出 [NetworkException] 若网络失败。
  Future<void> updateProfile(ProfileData data);
}

/// 资料更新数据传输对象
class ProfileData {
  final String? name;
  final String? avatar;
  final String? email;

  const ProfileData({this.name, this.avatar, this.email});
}
