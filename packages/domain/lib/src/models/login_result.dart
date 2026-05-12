import 'package:equatable/equatable.dart';

/// 登录结果模型
///
/// 携带认证成功后返回的用户标识和令牌信息。
/// 替代 [AuthRepository] 中原有的裸 `bool` 返回，让调用方直接获取 userId 和 token。
class LoginResult extends Equatable {
  /// 用户唯一标识
  final String userId;

  /// 认证令牌
  final String token;

  /// 是否为新注册用户（用于引导流程等场景）
  final bool isNewUser;

  const LoginResult({
    required this.userId,
    required this.token,
    this.isNewUser = false,
  });

  @override
  List<Object?> get props => [userId, token, isNewUser];
}
