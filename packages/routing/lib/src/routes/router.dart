import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_context.dart';
import 'module_a.dart';
import 'module_b.dart';

/// App Router — GoRouter factory
class AppRouter {
  static late GoRouter router;

  static GoRouter getRouter({required RouteContext ctx}) {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          pageBuilder: (context, state, navigationShell) {
            return NoTransitionPage(
              key: state.pageKey,
              child: _MainShell(navigationShell: navigationShell),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [...ModuleARouteModule(ctx).build()],
            ),
            StatefulShellBranch(
              routes: [...ModuleBRouteModule(ctx).build()],
            ),
          ],
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: Text('Detail')),
            body: Center(child: Text('This is a detail page')),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found')),
      ),
    );
    return router;
  }
}

class _MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
