import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:feature_auth/feature_auth.dart';
import 'route_context.dart';
import 'route_module.dart';

/// Module B — Settings tab route
class ModuleBRouteModule extends RouteModule {
  ModuleBRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) {
          // 构建页面内容，并用 routeWrapper 包裹以支持 RequestScope 等功能
          Widget page = Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _InfoTile(label: 'Framework', value: 'Flutter'),
                _InfoTile(label: 'Architecture', value: 'Clean Architecture + Feature-First'),
                _InfoTile(label: 'State', value: 'flutter_bloc (Cubit)'),
                _InfoTile(label: 'HTTP', value: 'Dio'),
                _InfoTile(label: 'Storage', value: 'Hive + SharedPreferences'),
                _InfoTile(label: 'DI', value: 'GetIt'),
              ],
            ),
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          Widget page = LoginPage(
            redirect: state.uri.queryParameters['redirect'],
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          Widget page = RegisterPage(
            redirect: state.uri.queryParameters['redirect'],
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
    ];
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(value),
        ],
      ),
    );
  }
}
