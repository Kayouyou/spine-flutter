// lib/core/startup/launcher.dart

// Dart imports:
import 'dart:async';

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
import '../bootstrap/bootstrap_options.dart';
import '../config/app_config.dart';
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
  /// [app] 是根 Widget（通常为 SpineFlutter）。
  /// [bootstrapOptions] 控制高级能力开关，默认全部关闭。
  static Future<void> launch(Widget app,
      {BootstrapOptions bootstrapOptions = const BootstrapOptions(),}) async {
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

    // 全局错误边界 — 任何可能出错的代码之前安装
    // 错误处理器需在 Sentry 之后 setup, 这样 setup() 抛错也能被 Sentry 捕获
    // (Sentry 提前到阶段 0.5 init, 见下面)

    // ===== 阶段 0.5: Sentry 必须最早初始化（早于任何可能 throw 的代码）=====
    // 极简 IAppConfig 注册, 仅供 Sentry 读 DSN. setupDependencies 内部
    // 检测到已注册会跳过, 避免冲突.
    sl.registerSingleton<IAppConfig>(EnvAppConfig());
    final sentryDsn = sl<IAppConfig>().sentryDsn;
    if (sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 0.1;
        },
      );
      StartupProfiler.mark('Sentry 初始化完成');
    }

    // Sentry 之后立即安装错误边界 + 绑定 Sentry reporter
    AppErrorHandler.instance.setup(
      onError: (error, stack) {
        sl<AppLogger>().error('未处理错误', error);
      },
    );
    AppErrorHandler.instance.setReporter(SentryReporter());
    StartupProfiler.mark('错误处理器 + Sentry reporter 绑定');

    // 依赖注入配置（会跳过 IAppConfig 注册因上面已注册）
    setupDependencies(options: bootstrapOptions);
    StartupProfiler.mark('依赖注入完成');

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
    if (bootstrapOptions.enableDataSync) {
      unawaited(sl<DataSyncManager>().sync());
    }
    StartupProfiler.mark('数据同步启动');

    // ===== 阶段 4: 启动 UI =====
    runApp(app);
    StartupProfiler.report();
  }
}
