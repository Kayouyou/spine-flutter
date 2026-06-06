// packages/infrastructure/routing/test/route_module_wrap_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

class _FakeModule extends RouteModule {
  _FakeModule(super.ctx);
  @override
  List<RouteBase> build() => [];
}

void main() {
  test('routeWrapper 为 null 时 wrap 返回原 page', () {
    const ctx = RouteContext(navigatorKey: null);
    final page = const Text('page');
    expect((_FakeModule(ctx) as RouteModule).wrap(page), page);
  });

  test('routeWrapper 不为 null 时包一层', () {
    final ctx = RouteContext(
      navigatorKey: null,
      routeWrapper: (child) => Container(child: child),
    );
    final page = const Text('page');
    final wrapped = (_FakeModule(ctx) as RouteModule).wrap(page);
    expect(wrapped, isA<Container>());
  });
}
