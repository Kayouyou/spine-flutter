import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_state.dart';
import '../repository/mock_auth_repository.dart';

class LoginCubit extends Cubit<LoginState> {
  final MockAuthRepository _repository;

  LoginCubit(this._repository) : super(const LoginState());

  void setUsername(String value) {
    emit(state.copyWith(username: value));
  }

  void setPassword(String value) {
    emit(state.copyWith(password: value));
  }

  Future<void> login() async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final success = await _repository.login(state.username, state.password);
      emit(state.copyWith(
        status: success ? LoginStatus.success : LoginStatus.error,
        errorMessage: success ? null : '用户名或密码错误',
      ),);
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> register() async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final success = await _repository.register(state.username, state.password);
      emit(state.copyWith(
        status: success ? LoginStatus.success : LoginStatus.error,
        errorMessage: success ? null : '注册失败',
      ),);
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.error, errorMessage: e.toString()));
    }
  }

  void reset() {
    emit(const LoginState());
  }
}