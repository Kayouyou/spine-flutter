import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_result.freezed.dart';
part 'session_result.g.dart';

@freezed
class SessionResult with _$SessionResult {
  const factory SessionResult({
    required bool success,
    String? message,
  }) = _SessionResult;

  factory SessionResult.fromJson(Map<String, dynamic> json) => _$SessionResultFromJson(json);
}
