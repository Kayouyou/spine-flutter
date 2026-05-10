import 'public_routes.dart';

class AuthGuard {
  /// 检查路由是否需要登录
  ///
  /// [location] - 请求的路径
  /// [isLoggedInChecker] - 登录状态检查回调
  static String? check(String location, bool Function() isLoggedInChecker) {
    if (!isLoggedInChecker() && !publicRoutes.contains(location)) {
      return '/login?redirect=$location';
    }
    return null;
  }
}