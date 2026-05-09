import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_home/feature_home.dart';

void main() {
  group('HomeRouteModule', () {
    late RouteContext ctx;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUp(() {
      ctx = RouteContext(
        navigatorKey: navigatorKey,
      );
    });

    test('build returns list with one route for /home', () {
      final module = HomeRouteModule(ctx);
      final routes = module.build();
      expect(routes.length, 1);
    });

    test('route path is /home', () {
      final module = HomeRouteModule(ctx);
      final routes = module.build();
      final route = routes.first as GoRoute;
      expect(route.path, '/home');
    });
  });
}
