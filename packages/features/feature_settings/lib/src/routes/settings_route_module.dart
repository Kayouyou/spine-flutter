import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../ui/settings_page.dart';

class SettingsRouteModule extends RouteModule {
  const SettingsRouteModule(super.ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) {
          return MaterialPage(child: wrap(const SettingsPage()));
        },
      ),
    ];
  }
}
