import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthState());

  Future<void> login(String username, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final success = await _repository.login(username, password);
      if (success) {
        emit(state.copyWith(status: AuthStatus.loggedIn, userId: 'mock-user-1'));
      } else {
        emit(state.copyWith(status: AuthStatus.error, errorMessage: '登录失败'));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _repository.logout();
    emit(const AuthState());
  }

  bool get isLoggedIn => state.status == AuthStatus.loggedIn;

  void loggedIn(String userId) {
    emit(state.copyWith(status: AuthStatus.loggedIn, userId: userId));
  }
}
