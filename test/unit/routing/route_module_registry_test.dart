import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:feature_home/feature_home.dart';
import 'package:routing/routing.dart';

void main() {
  late RouteContext ctx;

  setUp(() {
    ctx = RouteContext(
      navigatorKey: GlobalKey<NavigatorState>(),
      enableAuthGuard: false,
      isLoggedInChecker: () => false,
    );
    RouteModuleRegistry.instance.clear();
    // Barrel imports already triggered register(), so we just re-register
    // since clear() wiped them
    RouteModuleRegistry.instance.register(
      'feature_home',
      (c) => HomeRouteModule(c),
    );
    RouteModuleRegistry.instance.register(
      'feature_detail',
      (c) => DetailRouteModule(c),
    );
    RouteModuleRegistry.instance.register(
      'feature_auth',
      (c) => AuthRouteModule(c),
    );
  });

  tearDown(() {
    RouteModuleRegistry.instance.clear();
  });

  group('RouteModuleRegistry explicit registration', () {
    test('get returns routes for feature_home', () {
      final routes = RouteModuleRegistry.instance.get('feature_home', ctx);
      expect(routes, isNotEmpty);
    });

    test('get returns routes for feature_auth', () {
      final routes = RouteModuleRegistry.instance.get('feature_auth', ctx);
      expect(routes, isNotEmpty);
    });

    test('get returns routes for feature_detail', () {
      final routes = RouteModuleRegistry.instance.get('feature_detail', ctx);
      expect(routes, isNotEmpty);
    });

    test('buildAll returns routes from all registered features', () {
      final allRoutes = RouteModuleRegistry.instance.buildAll(ctx);
      expect(allRoutes.length, greaterThanOrEqualTo(3));
    });

    test('get throws on unregistered feature', () {
      expect(
        () => RouteModuleRegistry.instance.get('fake_feature', ctx),
        throwsA(isA<StateError>()),
      );
    });

    test('buildAll is idempotent', () {
      final first = RouteModuleRegistry.instance.buildAll(ctx);
      final second = RouteModuleRegistry.instance.buildAll(ctx);
      expect(first.length, second.length);
    });
  });
}
