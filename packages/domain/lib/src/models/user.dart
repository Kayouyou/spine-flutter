// packages/domain/lib/src/models/user.dart
import 'package:equatable/equatable.dart';

/// 用户业务模型
///
/// 代表应用中的用户实体，不依赖任何 UI 或数据源。
class User extends Equatable {
  /// 唯一标识
  final String id;

  /// 显示名称
  final String name;

  /// 头像 URL（可空）
  final String? avatar;

  /// 邮箱地址（可空）
  final String? email;

  const User({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
  });

  /// 从 JSON 创建
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'email': email,
  };

  @override
  List<Object?> get props => [id, name, avatar, email];
}
