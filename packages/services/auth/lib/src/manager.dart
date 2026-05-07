import 'package:flutter/foundation.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'cubit/auth_cubit.dart';

/// 认证管理器
///
/// 职责：管理用户认证状态，检查Token，处理登录登出
/// 使用：通过DI获取 `sl<AuthManager>()`
class AuthManager {
  final UserRepository _userRepository;
  final TokenStorage _tokenStorage;
  final AuthCubit _authCubit;

  AuthManager({
    required UserRepository userRepository,
    required TokenStorage tokenStorage,
    required AuthCubit authCubit,
  })  : _userRepository = userRepository,
        _tokenStorage = tokenStorage,
        _authCubit = authCubit;

  bool get isLoggedIn => _authCubit.isLoggedIn;

  /// 处理登录流程
  ///
  /// 检查本地是否有有效Token，如有则自动登录
  /// 无Token时跳过，等待用户主动登录
  Future<void> handleLogin() async {
    if (kDebugMode) {
      debugPrint('🚀 [AuthManager] handleLogin: 检查Token...');
    }

    final token = await _tokenStorage.getToken();
    if (token == null) {
      if (kDebugMode) {
        debugPrint('📭 [AuthManager] handleLogin: 无Token，等待用户主动登录');
      }
      return;
    }

    try {
      final user = await _userRepository.getCurrentUser();
      await _tokenStorage.setUserId(user.id);
      _authCubit.loggedIn(user.id);
      if (kDebugMode) {
        debugPrint('✅ [AuthManager] handleLogin: Token有效，自动登录成功 - userId=${user.id}');
      }
    } on UnauthorizedException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AuthManager] handleLogin: Token过期 - ${e.message}');
      }
      await clearAuth();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthManager] handleLogin: 验证失败 - $e');
      }
    }
  }

  /// 保存Token（登录成功时调用）
  Future<void> saveToken(String token, String userId) async {
    await _tokenStorage.setToken(token);
    await _tokenStorage.setUserId(userId);
  }

  /// 清除认证信息（登出或Token失效时调用）
  Future<void> clearAuth() async {
    await _tokenStorage.clear();
  }

  /// 处理登出
  Future<void> logout() async {
    if (kDebugMode) {
      debugPrint('🚪 [AuthManager] logout: 清理认证信息...');
    }
    await clearAuth();
    await _authCubit.logout();
  }

  /// 获取保存的用户ID
  Future<String?> getSavedUserId() async {
    return _tokenStorage.getUserId();
  }

  /// 清理资源
  ///
  /// App退出或销毁时调用
  void dispose() {
    if (kDebugMode) {
      debugPrint('🧹 [AuthManager] dispose: 资源清理完成');
    }
  }
}
