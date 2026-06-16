import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  bool get isLoggedIn => state.status == AuthStatus.loggedIn;

  /// 外部唯一写入入口：仅 AuthManager 可调
  ///
  /// 旧的 loggedIn(userId) public mutator 已删除 — 它允许任意模块
  /// 直接 emit, 制造 AuthCubit 与 AuthManager 双真相源.
  /// 所有状态变化必须经 AuthManager 流过来.
  void setAuthState(AuthState newState) => emit(newState);
}
