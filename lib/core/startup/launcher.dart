// lib/core/startup/launcher.dart

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
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
import '../../config.dart';
import '../bootstrap/bootstrap_options.dart';
import '../config/app_config.dart';
import '../di/locator.dart';
import '../di/setup.dart';
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
          options.release = 'spine_flutter@${EnvironmentConfig.appVersion}+${EnvironmentConfig.buildNumber}';
          options.environment = EnvironmentConfig.current.name;
        },
      );
      StartupProfiler.mark('Sentry 初始化完成');
    }

    // Sentry 之后立即安装错误边界 + 绑定 Sentry reporter
    //
    // 关键: onError 闭包不能依赖 sl (此时 setupDependencies 还没跑).
    // 启动期任何抛错 (例如下面的 _assertRequiredEnvFields) 都会经
    // PlatformDispatcher.instance.onError 走到这里, 如果闭包调
    // sl<AppLogger>() 会再抛 'AppLogger not registered', 形成 panic 链.
    // 真正上报走 reporter (已就绪), 日志留给 setupDependencies 之后的
    // 错误 — 启动期错误已经走 Sentry/ConsoleReporter, 不缺日志.
    AppErrorHandler.instance.setup(
      onError: (error, stack) {
        // 启动期 error 上报完全依赖 reporter, 不写 logger.
        // reporter 在 setup() 之后已就绪 (Sentry/Console), 单例
        // 自身, 不通过 sl.
      },
    );
    AppErrorHandler.instance.setReporter(
      kDebugMode ? ConsoleReporter() : SentryReporter(),
    );
    StartupProfiler.mark('错误处理器 + Sentry reporter 绑定');

    // ===== 阶段 0.7: 环境配置 fail-fast 校验 =====
    // AGENTS.md R5: 必需 env 字段缺失时启动崩溃.
    // 之前 HttpConstant.Http_Host / AliyunOSSConstant.BucketName 硬编码,
    // 即使 .env 缺失也能跑 (掩盖错误). 现在改为 fail-fast.
    // (L-1 修复引入)
    _assertRequiredEnvFields();

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

  /// 校验所有必需的环境变量已在启动时注入.
  ///
  /// 行为 (8.15 修订):
  /// - dev/staging: 仅触发 getter 警告 (占位符 / 空), 不抛错 — IDE 启动场景可跑
  /// - prod: 立即抛 [StateError], fail-fast
  ///
  /// 各 getter 内部已分流 (isProd 路径必填, dev 路径警告).
  /// 本方法**调用 getter** 触发校验, 然后汇总 prod 必填结果.
  ///
  /// 调用时机: Sentry 初始化之后, setupDependencies 之前.
  /// 这样错误能被 Sentry 捕获上报.
  static void _assertRequiredEnvFields() {
    final missing = <String>[];

    // dev/staging: getter 已警告占位符, 这里只需汇总 prod 必填.
    // 调用 getter 触发警告打印 (仅一次, 见 EnvironmentConfig._warned)
    final host = EnvironmentConfig.apiHost;
    final accessKey = EnvironmentConfig.apiAccessKeyId;
    final bucket = EnvironmentConfig.ossBucket;
    final endpoint = EnvironmentConfig.ossEndpoint;
    final ossKey = EnvironmentConfig.ossAccessKey;

    // isProd 已经在 getter 内抛 StateError, 这里再次汇总提示.
    if (EnvironmentConfig.isProd) {
      if (host.contains('placeholder')) missing.add('API_HOST');
      if (accessKey.isEmpty) missing.add('API_ACCESS_KEY_ID');
      if (bucket.contains('placeholder')) missing.add('OSS_BUCKET');
      if (endpoint.isEmpty) missing.add('OSS_ENDPOINT');
      if (ossKey.isEmpty) missing.add('OSS_ACCESS_KEY');
    }

    if (missing.isNotEmpty) {
      throw StateError(
        'EnvironmentConfig 启动校验失败, 缺失字段:\n'
        '  ${missing.join(', ')}\n'
        '请通过 --dart-define-from-file=env/.env.{dev,staging,prod} 注入, '
        '或在 CI / 部署平台设置.\n'
        '详见 AGENTS.md R5 + SCAFFOLD_REVIEW_RETROSPECTIVE.md L-1.',
      );
    }
    StartupProfiler.mark('环境配置校验通过');
  }
}
