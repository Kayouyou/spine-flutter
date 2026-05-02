import 'package:flutter/foundation.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';

/// 认证管理器
///
/// 职责：管理用户认证状态，检查Token，处理登录登出
/// 使用：通过DI获取 `sl<AuthManager>()`
class AuthManager {
  final UserRepository _userRepository;
  final KeyValueStorage _keyValueStorage;

  AuthManager({
    required UserRepository userRepository,
    required KeyValueStorage keyValueStorage,
  })  : _userRepository = userRepository,
        _keyValueStorage = keyValueStorage;

  /// 处理登录流程
  ///
  /// 检查本地是否有有效Token，如有则自动登录
  /// 无Token时跳过，等待用户主动登录
  Future<void> handleLogin() async {
    // TODO: 实现Token检查逻辑
    if (kDebugMode) {
      debugPrint('🚀 [AuthManager] handleLogin: 检查Token...');
    }
    // TODO: 从 _keyValueStorage 读取本地Token
    // TODO: 通过 _userRepository.getCurrentUser() 验证Token是否有效
    if (kDebugMode) {
      debugPrint('✅ [AuthManager] handleLogin: 无Token，跳过登录');
    }
  }

  /// 清理资源
  ///
  /// App退出或登出时调用
  void dispose() {
    // TODO: 清理认证相关资源
  }
}