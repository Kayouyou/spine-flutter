// lib/core/startup/launcher.dart

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';
import 'package:error/error.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Project imports:
import 'package:domain/domain.dart';
import '../di/locator.dart';
import '../di/setup.dart';
import '../utils/logger.dart';
import 'initializer.dart';
import 'profiler.dart';

// Bloc imports:
import '../bloc/app_bloc_observer.dart';

/// 应用启动编排器
///
/// 按阶段顺序执行启动流程：
/// 1. 核心初始化（binding、错误处理、DI、屏幕方向）
/// 2. SDK 初始化（阻塞等待）
/// 3. 业务初始化（认证检查、数据同步）
/// 4. 启动 UI
class AppLauncher {
  AppLauncher._();

  /// 启动应用
  ///
  /// [app] 是根 Widget（通常为 MyApp）。
  static Future<void> launch(Widget app) async {
    // ===== 阶段 1: 核心初始化 =====
    WidgetsFlutterBinding.ensureInitialized();
    StartupProfiler.start();
    StartupProfiler.mark('Flutter binding 初始化');

    // ===== 阶段 1.5: Bloc 扩展初始化 =====
    // HydratedBloc 存储（必须在任何 Cubit 创建前）
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(
        (await getApplicationDocumentsDirectory()).path,
      ),
    );
    StartupProfiler.mark('HydratedStorage 初始化');

    // BlocObserver 注册（全局日志）
    Bloc.observer = AppBlocObserver();
    StartupProfiler.mark('BlocObserver 注册');

    // 全局错误边界 — 在任何可能出错的代码之前安装
    AppErrorHandler.instance.setup(
      onError: (error, stack) {
        sl<AppLogger>().error('未处理错误', error);
      },
    );
    StartupProfiler.mark('错误处理器安装');

    // 依赖注入配置
    setupDependencies();
    StartupProfiler.mark('依赖注入完成');

    // ===== Sentry 初始化（依赖 IAppConfig 配置）=====
    final config = sl<IAppConfig>();
    if (config.sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = config.sentryDsn;
          options.tracesSampleRate = 0.1;
        },
      );
      AppErrorHandler.instance.setReporter(SentryReporter());
    }
    StartupProfiler.mark('Sentry 初始化完成');

    // 屏幕方向
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    StartupProfiler.mark('屏幕方向配置');

    // ===== 阶段 2: SDK 初始化（阻塞，必须完成后才能进阶段 3）=====
    final sdkInitializer = SDKInitializer();
    await sdkInitializer.initPlugins();
    StartupProfiler.mark('SDK 初始化完成');

    // ===== 阶段 3: 业务初始化 =====
    // 认证检查 — 通过 DI 获取 AuthManager
    await sl<AuthManager>().handleLogin();
    StartupProfiler.mark('认证检查完成');

    // 数据同步 — 触发后不等待（后台执行）
    sl<DataSyncManager>().sync();
    StartupProfiler.mark('数据同步启动');

    // ===== 阶段 4: 启动 UI =====
    runApp(app);
    StartupProfiler.report();
  }
}
