// packages/domain/lib/src/models/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// 用户业务模型
///
/// 代表应用中的用户实体，不依赖任何 UI 或数据源。
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? avatar,
    String? email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
