import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

import 'src/theme/app_theme.dart';

/// 主应用Widget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final ctx = RouteContext(navigatorKey: _navigatorKey);
    _router = AppRouter.getRouter(ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '骨架演示',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      routerConfig: _router,
      builder: (context, child) {
        final easyLoadingBuilder = EasyLoading.init();
        return easyLoadingBuilder(
          context,
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}