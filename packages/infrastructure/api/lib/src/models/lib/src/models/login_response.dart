import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

/// LoginResponse 数据模型
@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String id,
    required String name,
    @Default('') String description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = __LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}
