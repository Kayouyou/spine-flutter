import 'package:flutter/foundation.dart';

/// Auth Manager — authentication skeleton
class AuthManager {
  Future<void> handleLogin() async {
    debugPrint('🚀 [AuthManager] handleLogin: checking token...');
    // TODO: Implement token check and auto-login
    debugPrint('✅ [AuthManager] handleLogin: no token, login skipped');
  }

  void dispose() {}
}
