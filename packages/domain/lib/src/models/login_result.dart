import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_result.freezed.dart';
part 'login_result.g.dart';

/// 登录结果模型
///
/// 携带认证成功后返回的用户标识和令牌信息。
/// 替代 [AuthRepository] 中原有的裸 `bool` 返回，让调用方直接获取 userId 和 token。
@freezed
class LoginResult with _$LoginResult {
  const factory LoginResult({
    required String userId,
    required String token,
    @Default(false) bool isNewUser,
  }) = _LoginResult;

  factory LoginResult.fromJson(Map<String, dynamic> json) =>
      _$LoginResultFromJson(json);
}
