import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request.freezed.dart';
part 'login_request.g.dart';

/// LoginRequest 数据模型
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String id,
    required String name,
    @Default('') String description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = __LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}
