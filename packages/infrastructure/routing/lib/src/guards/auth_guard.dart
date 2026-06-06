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
  static String? check(String location, bool Function() isLoggedInChecker) {
    final path = location.split('?').first.split('#').first;
    if (!isLoggedInChecker() && !publicRoutes.contains(path)) {
      return '/login?redirect=$location';
    }
    return null;
  }
}