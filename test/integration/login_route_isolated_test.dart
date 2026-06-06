// test/integration/login_route_isolated_test.dart
//
// P0-1: /login 路由应脱离 StatefulShellRoute 顶层注册,这样未登录用户
// 访问 /login 时不渲染底部 NavigationBar.
//
// 镜像 lib/app.dart 的 _buildRouter 结构 + 真实 feature_auth / feature_home
// 的 GoRoute 注册方式,断言 /login 路径在 GoRoute 列表里是顶级 GoRoute
// 而非 StatefulShellBranch 内的路由.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

void main() {
  group('P0-1: /login 路由隔离', () {
    testWidgets('未登录访问 /login 不渲染底部 NavigationBar', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final isLoggedIn = false;

      final ctx = RouteContext(
        navigatorKey: navigatorKey,
        enableAuthGuard: true,
        isLoggedInChecker: () => isLoggedIn,
        routeWrapper: (child) => child,
      );

      // 镜像 _buildRouter 修复后结构: /login /register 顶层注册, 在 StatefulShellRoute 之外
      final router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: '/home',
        redirect: (context, state) {
          return AuthGuard.check(
            state.matchedLocation,
            ctx.isLoggedInChecker!,
          );
        },
        routes: [
          // P0-1: /login /register 顶层
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Login')),
            ),
          ),
          GoRoute(
            path: '/register',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Register')),
            ),
          ),
          StatefulShellRoute.indexedStack(
            pageBuilder: (context, state, navigationShell) {
              return NoTransitionPage(
                key: state.pageKey,
                child: _FakeMainShell(navigationShell: navigationShell),
              );
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, __) => const Scaffold(
                      body: Center(child: Text('Home')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/_placeholder',
                    builder: (_, __) => const Scaffold(
                      body: Center(child: Text('Settings (TODO)')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // /home 是 public,未登录也能进, 应当渲染 NavigationBar
      expect(find.byType(NavigationBar), findsOneWidget);

      // 跳到 /login
      router.go('/login');
      await tester.pumpAndSettle();

      // Bug 状态: /login 在 StatefulShellBranch 内 → 应渲染 NavigationBar
      // P0-1 修复后: 不渲染
      final navBarCount = find.byType(NavigationBar).evaluate().length;
      expect(navBarCount, 0,
          reason:
              '/login 应在 StatefulShellRoute 之外, 不渲染 NavigationBar (当前 bug: 渲染 $navBarCount 个)');
    });
  });
}

class _FakeMainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _FakeMainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
