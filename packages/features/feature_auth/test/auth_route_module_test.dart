import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_auth/feature_auth.dart';

void main() {
  group('AuthRouteModule', () {
    late RouteContext ctx;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUp(() {
      ctx = RouteContext(
        navigatorKey: navigatorKey,
        isLoggedInChecker: () => false,
      );
    });

    test('build returns list with two routes', () {
      final module = AuthRouteModule(ctx);
      final routes = module.build();
      expect(routes.length, 2);
    });

    test('first route path is /login', () {
      final module = AuthRouteModule(ctx);
      final routes = module.build();
      final loginRoute = routes[0] as GoRoute;
      expect(loginRoute.path, '/login');
    });

    test('second route path is /register', () {
      final module = AuthRouteModule(ctx);
      final routes = module.build();
      final registerRoute = routes[1] as GoRoute;
      expect(registerRoute.path, '/register');
    });
  });
}
