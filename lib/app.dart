// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:alice/alice.dart';
import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:locale/locale.dart';
import 'package:network/network.dart';
import 'package:routing/routing.dart';

// Project imports:
import 'core/bootstrap/bootstrap_options.dart';
import 'core/di/locator.dart';
import 'core/widgets/debug/debug_tools_wrapper.dart';
import 'core/widgets/network/network_banner.dart';
import 'core/widgets/request_scope.dart';
import 'core/widgets/upgrade/upgrade_wrapper.dart';
import 'src/theme/app_theme.dart';

/// 主应用Widget
///
/// 职责：配置全局Provider、主题、路由、国际化
/// Provider：
///   - LocaleCubit：语言管理
///   - NetworkCubit：网络状态管理
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
    // 构建路由
    final config = sl<IAppConfig>();
    final ctx = RouteContext(
      navigatorKey: _navigatorKey,
      enableAuthGuard: config.enableAuthGuard,
      // 登录状态检查回调 — 从 DI 容器中获取 AuthManager
      isLoggedInChecker: () => sl<AuthManager>().isLoggedIn,
      // routeWrapper：在每个路由页面外层包裹 RequestScope，实现页面退出时自动取消请求
      routeWrapper: (child) => RequestScope(child: child),
    );
    // Alice HTTP Inspector — 创建时传入 navigatorKey，确保 showInspector 可用
    final options = sl<BootstrapOptions>();
    if (kDebugMode && options.enableDebugTools && !sl.isRegistered<Alice>()) {
      final alice = Alice(
        showInspectorOnShake: true,
        navigatorKey: _navigatorKey,
      );
      sl.registerSingleton<Alice>(alice);

      // Add Alice interceptor to existing Dio singleton
      final dio = sl<Dio>();
      dio.interceptors.add(alice.getDioInterceptor());
    }

    _router = _buildRouter(ctx);
  }

  /// 使用 RouteModules 构建 GoRouter
  ///
  /// Wave 2: 直接在 app.dart 组装路由，不再依赖 routing 包的 router.dart
  GoRouter _buildRouter(RouteContext ctx) {
    return GoRouter(
      navigatorKey: _navigatorKey,
      initialLocation: '/home',
      observers: [AppRouteObserver.instance],
      redirect: ctx.enableAuthGuard && ctx.isLoggedInChecker != null
          ? (context, state) {
              final location = state.matchedLocation;
              return AuthGuard.check(location, ctx.isLoggedInChecker!);
            }
          : null,
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
              routes: RouteModuleRegistry.instance.get('feature_home', ctx),
            ),
            StatefulShellBranch(
              routes: RouteModuleRegistry.instance.get('feature_auth', ctx),
            ),
          ],
        ),
        // 其他非 tab 路由通过注册中心构建
        ...RouteModuleRegistry.instance.get('feature_detail', ctx),
      ],
      errorBuilder: (context, state) => const Scaffold(
        body: Center(child: Text('Page not found')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = sl<BootstrapOptions>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<LocaleCubit>()),
        BlocProvider(create: (context) => sl<NetworkCubit>()),
        BlocProvider(create: (context) => sl<AuthCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          Widget app = MaterialApp.router(
            title: '骨架演示',
            theme: appLightTheme,
            darkTheme: appDarkTheme,
            locale: localeState.locale,
            supportedLocales: const [
              Locale('zh'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) {
              final easyLoadingBuilder = EasyLoading.init();
              return easyLoadingBuilder(
                context,
                NetworkBanner(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: child ?? const SizedBox(),
                  ),
                ),
              );
            },
          );
          if (options.enableDebugTools) {
            app = DebugToolsWrapper(child: app);
          }
          if (options.enableUpgradePrompt) {
            app = UpgradeWrapper(child: app);
          }
          return app;
        },
      ),
    );
  }
}

/// Main Shell with bottom navigation
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
