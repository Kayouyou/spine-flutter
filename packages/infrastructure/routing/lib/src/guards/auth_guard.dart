import 'package:go_router/go_router.dart';
import 'public_routes.dart';
import 'package:auth/auth.dart';

class AuthGuard {
  static String? check(String location, AuthManager auth) {
    if (!auth.isLoggedIn && !publicRoutes.contains(location)) {
      return '/login?redirect=$location';
    }
    return null;
  }
}