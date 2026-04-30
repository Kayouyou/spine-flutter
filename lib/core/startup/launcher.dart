import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'initializer.dart';
import 'profiler.dart';
import '../auth/manager.dart';
import '../sync/manager.dart';
import '../di/setup.dart';

/// App启动器
///
/// 职责：管理App完整启动流程
/// 流程：初始化Flutter binding → 配置系统UI → 依赖注入 → SDK初始化 → 启动App
/// 使用：main.dart中调用 `AppLauncher.launch(const MyApp())`
class AppLauncher {
  AppLauncher._();

  /// 启动App
  static Future<void> launch(Widget app) async {
    // 1. 初始化Flutter binding（必须在最前面）
    WidgetsFlutterBinding.ensureInitialized();
    StartupProfiler.start();
    StartupProfiler.mark('Flutter binding初始化');

    // 2. 配置依赖注入（需要binding：LocaleCubit/NetworkCubit使用平台通道）
    setupDependencies();
    StartupProfiler.mark('依赖注入完成');

    // 3. 配置屏幕方向（仅支持竖屏）
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    StartupProfiler.mark('屏幕方向配置');

    // 4. 初始化第三方SDK（异步，不阻塞）
    final sdkInitializer = SDKInitializer();
    sdkInitializer.initPlugins().then((_) {
      StartupProfiler.mark('SDK初始化完成');
    });

    // 5. 检查认证状态
    final authManager = AuthManager();
    await authManager.handleLogin();
    StartupProfiler.mark('认证检查完成');

    // 6. 数据同步（登录成功后）
    final syncManager = DataSyncManager();
    syncManager.sync();
    StartupProfiler.mark('数据同步启动');

    // 7. 运行App
    runApp(app);
    StartupProfiler.report();
  }
}