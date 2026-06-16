import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'package:auth/auth.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;
  final AuthManager _authManager;

  LoginCubit({
    required AuthRepository repository,
    required AuthManager authManager,
  })  : _authRepository = repository,
        _authManager = authManager,
        super(const LoginState());

  void setUsername(String username) => emit(state.copyWith(username: username));

  void setPassword(String password) => emit(state.copyWith(password: password));

  Future<void> login() async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _authRepository.login(state.username, state.password);
    result.when(
      success: (loginResult) async {
        await _authManager.handleLoginSuccess(loginResult);
        emit(state.copyWith(status: LoginStatus.success));
      },
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      )),
    );
  }

  Future<void> register() async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _authRepository.register(state.username, state.password);
    result.when(
      success: (loginResult) async {
        await _authManager.handleLoginSuccess(loginResult);
        emit(state.copyWith(status: LoginStatus.success));
      },
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      )),
    );
  }

  void reset() => emit(const LoginState());
}
