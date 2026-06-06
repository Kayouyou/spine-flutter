import 'package:flutter/foundation.dart';
import 'public_routes.dart';

class AuthGuard {
  /// 检查路由是否需要登录
  ///
  /// [location] - 请求的路径（可能含 query string / fragment）
  /// [isLoggedInChecker] - 登录状态检查回调
  ///
  /// 路径会先剥掉 `?...` 和 `#...` 再做白名单匹配，避免
  /// `/home?from=push` 这种合法 query 串被误踢到 /login。
  /// 严格按 set.contains: `/home/list` 不被 `/home` 覆盖（除非显式列入）。
  ///
  /// 异常兜底 (P1-2): 若 [isLoggedInChecker] 抛异常（启动期 AuthManager 未就位等），
  /// 一律按"未登录"处理 — 跳到 /login 避免白屏。
  ///
  /// 可观测性 (P3-7): 在 debug 模式下打印每次检查的决定路径，
  /// 线上 redirect 失败时通过 Sentry 抓到日志能快速定位。
  static String? check(String location, bool Function() isLoggedInChecker) {
    final path = location.split('?').first.split('#').first;
    bool isLoggedIn;
    try {
      isLoggedIn = isLoggedInChecker();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthGuard] isLoggedInChecker threw: $e\n$st');
      }
      isLoggedIn = false;
    }

    final isPublic = publicRoutes.contains(path);
    if (kDebugMode) {
      debugPrint(
        '🛡️ [AuthGuard] path=$path isLoggedIn=$isLoggedIn isPublic=$isPublic → '
        '${isLoggedIn || isPublic ? "allow" : "redirect /login"}',
      );
    }

    if (!isLoggedIn && !isPublic) {
      return '/login?redirect=$location';
    }
    return null;
  }
}
