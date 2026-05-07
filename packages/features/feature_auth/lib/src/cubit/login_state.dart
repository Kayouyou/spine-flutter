import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    @Default(LoginStatus.initial) LoginStatus status,
    String? errorMessage,
    @Default('') String username,
    @Default('') String password,
  }) = _LoginState;
}

enum LoginStatus { initial, loading, success, error }