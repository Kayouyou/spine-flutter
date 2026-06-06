import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthState());

  Future<void> login(String username, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    // 获取登录结果（返回Result类型）
    final result = await _repository.login(username, password);
    // 穷尽匹配处理结果
    result.when(
      success: (loginResult) {
        emit(state.copyWith(
          status: AuthStatus.loggedIn,
          userId: loginResult.userId,
        ),);
      },
      failure: (error) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: error.message,
      ),),
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _repository.logout();
    emit(const AuthState());
  }

  bool get isLoggedIn => state.status == AuthStatus.loggedIn;

  /// 外部唯一写入入口：仅 AuthManager 可调
  ///
  /// 旧的 loggedIn(userId) public mutator 已删除 — 它允许任意模块
  /// 直接 emit, 制造 AuthCubit 与 AuthManager 双真相源.
  /// 所有状态变化必须经 AuthManager 流过来.
  void setAuthState(AuthState newState) => emit(newState);
}
