import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_detail/feature_detail.dart';

void main() {
  group('DetailRouteModule', () {
    late RouteContext ctx;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUp(() {
      ctx = RouteContext(
        navigatorKey: navigatorKey,
      );
    });

    test('build returns list with two routes', () {
      final module = DetailRouteModule(
        ctx,
        createCubit: () => throw UnimplementedError('not used'),
      );
      final routes = module.build();
      expect(routes.length, 2);
    });

    test('first route path is /detail', () {
      final module = DetailRouteModule(
        ctx,
        createCubit: () => throw UnimplementedError('not used'),
      );
      final routes = module.build();
      final detailRoute = routes[0] as GoRoute;
      expect(detailRoute.path, '/detail');
    });

    test('second route path is /detail/:id', () {
      final module = DetailRouteModule(
        ctx,
        createCubit: () => throw UnimplementedError('not used'),
      );
      final routes = module.build();
      final detailWithIdRoute = routes[1] as GoRoute;
      expect(detailWithIdRoute.path, '/detail/:id');
    });
  });
}
