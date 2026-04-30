import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

import 'src/theme/app_theme.dart';
import 'core/di/locator.dart';
import 'core/global/locale/locale_cubit.dart';
import 'core/global/locale/locale_state.dart';
import 'core/global/network/network_cubit.dart';
import 'core/widgets/network/network_banner.dart';

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
    final ctx = RouteContext(navigatorKey: _navigatorKey);
    _router = AppRouter.getRouter(ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    // 全局BlocProvider包装，提供LocaleCubit和NetworkCubit
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<LocaleCubit>()),
        BlocProvider(create: (context) => sl<NetworkCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp.router(
            title: '骨架演示',
            theme: appLightTheme,
            darkTheme: appDarkTheme,
            // 语言配置
            locale: localeState.locale,
            supportedLocales: const [
              Locale('zh'), // 中文
              Locale('en'), // 英文
            ],
            // 国际化配置
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
        },
      ),
    );
  }
}