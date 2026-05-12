import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;

  LoginCubit(this._repository) : super(const LoginState());

  void setUsername(String value) {
    emit(state.copyWith(username: value));
  }

  void setPassword(String value) {
    emit(state.copyWith(password: value));
  }

  Future<void> login() async {
    emit(state.copyWith(status: LoginStatus.loading));

    final result = await _repository.login(state.username, state.password);
    result.when(
      success: (_) => emit(state.copyWith(
        status: LoginStatus.success,
        errorMessage: null,
      ),),
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      ),),
    );
  }

  Future<void> register() async {
    emit(state.copyWith(status: LoginStatus.loading));

    final result = await _repository.register(state.username, state.password);
    result.when(
      success: (_) => emit(state.copyWith(
        status: LoginStatus.success,
        errorMessage: null,
      ),),
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      ),),
    );
  }

  void reset() {
    emit(const LoginState());
  }
}