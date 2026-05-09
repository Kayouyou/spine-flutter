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
    
    // 获取登录结果（返回Result类型）
    final result = await _repository.login(state.username, state.password);
    // 穷尽匹配处理结果
    result.when(
      success: (success) => emit(state.copyWith(
        status: success ? LoginStatus.success : LoginStatus.error,
        errorMessage: success ? null : '用户名或密码错误',
      )),
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      )),
    );
  }

  Future<void> register() async {
    emit(state.copyWith(status: LoginStatus.loading));
    
    // 获取注册结果（返回Result类型）
    final result = await _repository.register(state.username, state.password);
    // 穷尽匹配处理结果
    result.when(
      success: (success) => emit(state.copyWith(
        status: success ? LoginStatus.success : LoginStatus.error,
        errorMessage: success ? null : '注册失败',
      )),
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      )),
    );
  }

  void reset() {
    emit(const LoginState());
  }
}