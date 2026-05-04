import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, error }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? errorMessage;
  final String username;
  final String password;

  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.username = '',
    this.password = '',
  });

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    String? username,
    String? password,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, username, password];
}