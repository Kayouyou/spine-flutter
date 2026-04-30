# Flutter架构重构 - Phase 1: 基础设施 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立核心目录结构，迁移现有文件，创建Constants、AppLogger和GetIt依赖注入系统

**Architecture:** 采用feature-first目录结构，core模块存放跨功能基础设施，features模块存放业务功能。使用GetIt替代RepositoryFactory实现依赖注入。

**Tech Stack:** Flutter 3.0+, get_it ^7.6.0, 现有packages (api, key_value_storage, routing等)

---

## 文件结构概览

**创建的新目录和文件：**

```
lib/
  core/
    auth/
      manager.dart           # AuthManager迁移
      README.md
    di/
      locator.dart           # GetIt实例
      setup.dart             # DI配置（合并RepositoryFactory + AppConfigurator）
      README.md
    global/
      network/               # Phase 2占位
      locale/                # Phase 2占位
    startup/
      launcher.dart          # AppLauncher（迁移AppStarter）
      initializer.dart       # SDKInitializer迁移
      profiler.dart          # StartupProfiler迁移
      README.md
    sync/
      manager.dart           # DataSyncManager迁移
      README.md
    utils/
      logger.dart            # 新AppLogger
      README.md
    constants/
      app_constants.dart     # 应用配置常量
      api_constants.dart     # API配置常量
      cache_constants.dart   # 缓存配置常量
      README.md
    widgets/
      network/               # Phase 3占位
      README.md
  features/
    home/
      ui/
        home_page.dart       # TabAPage迁移
        README.md
    detail/
      ui/
        detail_page.dart     # DetailCPage迁移
        README.md
```

**迁移映射表：**

| 现有文件 | 新位置 | 改动说明 |
|---------|--------|---------|
| lib/src/auth_manager.dart | lib/core/auth/manager.dart | 类名不变，添加中文注释 |
| lib/src/sdk_initializer.dart | lib/core/startup/initializer.dart | 类名不变，添加中文注释 |
| lib/src/startup_profiler.dart | lib/core/startup/profiler.dart | 类名不变，添加中文注释 |
| lib/src/data_sync_manager.dart | lib/core/sync/manager.dart | 类名不变，添加中文注释 |
| lib/src/app_starter.dart | lib/core/startup/launcher.dart | 类名改为AppLauncher |
| lib/src/repository_factory.dart | lib/core/di/setup.dart | 合并入setup.dart |
| lib/src/app_configurator.dart | lib/core/di/setup.dart | 合并入setup.dart |
| lib/src/ui/tab_a_page.dart | lib/features/home/ui/home_page.dart | 类名改为HomePage |
| lib/src/ui/tab_b_page.dart | lib/features/home/ui/ | Phase 2处理 |
| lib/src/ui/detail_c_page.dart | lib/features/detail/ui/detail_page.dart | 类名改为DetailPage |

---

### Task 1: 创建核心目录结构和README

**Files:**
- Create: `lib/core/auth/README.md`
- Create: `lib/core/di/README.md`
- Create: `lib/core/startup/README.md`
- Create: `lib/core/sync/README.md`
- Create: `lib/core/utils/README.md`
- Create: `lib/core/constants/README.md`
- Create: `lib/core/widgets/README.md`
- Create: `lib/features/home/ui/README.md`
- Create: `lib/features/detail/ui/README.md`
- Create: `lib/core/global/network/.gitkeep`
- Create: `lib/core/global/locale/.gitkeep`

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p lib/core/auth
mkdir -p lib/core/di
mkdir -p lib/core/startup
mkdir -p lib/core/sync
mkdir -p lib/core/utils
mkdir -p lib/core/constants
mkdir -p lib/core/widgets/network
mkdir -p lib/core/global/network
mkdir -p lib/core/global/locale
mkdir -p lib/features/home/ui
mkdir -p lib/features/detail/ui
mkdir -p lib/features/user
mkdir -p lib/features/order
```

- [ ] **Step 2: 创建auth模块README**

```markdown
# Auth模块

## 职责
管理用户认证状态，包括登录、登出、Token检查等。

## 使用示例
```dart
// 在DI配置中注册
sl.registerSingleton<AuthManager>(AuthManager());

// 在需要的地方获取
final authManager = sl<AuthManager>();
await authManager.handleLogin();
```

## 依赖关系
- 无外部依赖
- 未来可能依赖KeyValueStorage存储Token

## 性能警告
无
```

写入 `lib/core/auth/README.md`

- [ ] **Step 3: 创建di模块README**

```markdown
# 依赖注入模块

## 职责
使用GetIt管理应用所有依赖的生命周期，包括注册、获取、销毁。

## 使用示例
```dart
// 获取已注册的服务
final api = sl<Api>();
final logger = sl<AppLogger>();

// 在组件中使用BlocProvider
BlocProvider(
  create: (context) => sl<HomeCubit>(),
  child: HomePage(),
)
```

## 依赖关系
- get_it: ^7.6.0
- 所有需要注入的服务模块

## 性能警告
- 单例服务在App启动时创建，避免懒加载导致首屏卡顿
- Factory每次调用都创建新实例，注意内存管理
```

写入 `lib/core/di/README.md`

- [ ] **Step 4: 创建startup模块README**

```markdown
# 启动模块

## 职责
管理App启动流程，包括：
- AppLauncher：启动入口，初始化Flutter binding
- SDKInitializer：第三方SDK初始化
- StartupProfiler：启动性能计时

## 使用示例
```dart
// main.dart中使用
void main() {
  AppLauncher.launch(const MyApp());
}

// 性能计时
StartupProfiler.start();
StartupProfiler.mark('SDK初始化完成');
StartupProfiler.report();
```

## 依赖关系
- AuthManager（启动时调用handleLogin）
- SDKInitializer（初始化第三方SDK）
- AppLogger（日志输出）

## 性能警告
- 启动流程应尽量精简，避免阻塞首屏渲染
- SDK初始化可异步进行，不阻塞UI
```

写入 `lib/core/startup/README.md`

- [ ] **Step 5: 创建sync模块README**

```markdown
# 数据同步模块

## 职责
管理用户登录后的数据同步，包括本地缓存更新、远程数据拉取等。

## 使用示例
```dart
// 登录成功后触发同步
final syncManager = sl<DataSyncManager>();
syncManager.sync();
```

## 依赖关系
- Api（远程数据获取）
- KeyValueStorage（本地缓存）

## 性能警告
- 同步操作可能耗时，建议在后台线程执行
- 避免同步大量数据阻塞UI
```

写入 `lib/core/sync/README.md`

- [ ] **Step 6: 创建utils模块README**

```markdown
# 工具模块

## 职责
提供通用工具类，包括日志、格式化、验证等。

## 使用示例
```dart
// 获取Logger实例
final logger = sl<AppLogger>();
logger.info('操作成功');
logger.error('发生错误', exception);
```

## 依赖关系
- flutter/foundation.dart（kDebugMode判断）

## 性能警告
- 生产环境默认禁用日志输出，避免性能损耗
- 日志输出仅在Debug模式启用
```

写入 `lib/core/utils/README.md`

- [ ] **Step 7: 创建constants模块README**

```markdown
# 常量模块

## 职责
集中管理应用所有常量配置，包括：
- AppConstants：应用配置（名称、版本等）
- APIConstants：API配置（baseUrl、超时等）
- CacheConstants：缓存配置（TTL、容量等）

## 使用示例
```dart
// API配置
final url = APIConstants.baseUrl;
final timeout = APIConstants.connectTimeout;

// 缓存配置
final ttl = CacheConstants.defaultTTL;
```

## 依赖关系
- 无外部依赖

## 性能警告
- 常量使用static const，编译时内联，零运行时开销
```

写入 `lib/core/constants/README.md`

- [ ] **Step 8: 创建widgets模块README**

```markdown
# 通用组件模块

## 职责
提供跨Feature共享的通用UI组件，包括网络状态提示、加载指示器等。

## 使用示例
```dart
// 网络状态Banner
NetworkBanner(
  child: HomePage(),
)
```

## 依赖关系
- flutter_bloc（BlocBuilder/BlocListener）
- NetworkCubit（Phase 2）

## 性能警告
- 避免过度使用Stack层叠，影响布局性能
```

写入 `lib/core/widgets/README.md`

- [ ] **Step 9: 创建features README**

```markdown
# Home功能模块

## 职责
首页相关UI、状态管理、数据获取。

## 使用示例
```dart
// 路由导航
context.go('/home');

// BlocProvider包装
BlocProvider(
  create: (context) => sl<HomeCubit>(),
  child: HomePage(),
)
```

## 依赖关系
- HomeCubit（Phase 2）
- HomeRepository（Phase 2）
- routing包

## 性能警告
无
```

写入 `lib/features/home/ui/README.md`

```markdown
# Detail功能模块

## 职责
详情页相关UI、状态管理、数据获取。

## 使用示例
```dart
// 路由导航
context.push('/detail');
```

## 依赖关系
- routing包

## 性能警告
无
```

写入 `lib/features/detail/ui/README.md`

- [ ] **Step 10: 创建占位文件**

```bash
touch lib/core/global/network/.gitkeep
touch lib/core/global/locale/.gitkeep
```

- [ ] **Step 11: 验证目录结构**

```bash
ls -la lib/core/
ls -la lib/features/
```

Expected: 目录结构完整创建

- [ ] **Step 12: Commit**

```bash
git add lib/core/ lib/features/
git commit -m "feat(phase1): 创建核心目录结构和README

- 创建core/auth, core/di, core/startup, core/sync, core/utils, core/constants, core/widgets目录
- 创建features/home, features/detail目录结构
- 添加各模块中文README说明文档
- 创建Phase 2/3占位目录

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 迁移AuthManager到core/auth

**Files:**
- Create: `lib/core/auth/manager.dart`
- Modify: 无（旧文件Task 12删除）

- [ ] **Step 1: 创建AuthManager新文件**

```dart
import 'package:flutter/foundation.dart';

/// 认证管理器
///
/// 职责：管理用户认证状态，检查Token，处理登录登出
/// 使用：通过DI获取 `sl<AuthManager>()`
class AuthManager {
  /// 处理登录流程
  ///
  /// 检查本地是否有有效Token，如有则自动登录
  /// 无Token时跳过，等待用户主动登录
  Future<void> handleLogin() async {
    // TODO: 实现Token检查逻辑
    if (kDebugMode) {
      debugPrint('🚀 [AuthManager] handleLogin: 检查Token...');
    }
    // TODO: 检查本地存储的Token是否有效
    // TODO: 有效则自动登录，无效则等待用户登录
    if (kDebugMode) {
      debugPrint('✅ [AuthManager] handleLogin: 无Token，跳过登录');
    }
  }

  /// 清理资源
  ///
  /// App退出或登出时调用
  void dispose() {
    // TODO: 清理认证相关资源
  }
}
```

写入 `lib/core/auth/manager.dart`

- [ ] **Step 2: 验证文件创建**

```bash
cat lib/core/auth/manager.dart
```

Expected: 文件内容正确，包含中文注释

- [ ] **Step 3: Commit**

```bash
git add lib/core/auth/manager.dart
git commit -m "feat(phase1): 创建AuthManager到core/auth目录

- 迁移auth_manager.dart到core/auth/manager.dart
- 添加中文注释说明职责和使用方式

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: 迁移SDKInitializer到core/startup

**Files:**
- Create: `lib/core/startup/initializer.dart`

- [ ] **Step 1: 创建SDKInitializer新文件**

```dart
import 'package:flutter/foundation.dart';

/// SDK初始化器
///
/// 职责：初始化第三方SDK，如推送、统计、支付等
/// 使用：在AppLauncher启动流程中调用
/// 注意：SDK初始化应异步进行，不阻塞首屏渲染
class SDKInitializer {
  /// 初始化第三方SDK
  ///
  /// 包括推送SDK、统计SDK、支付SDK等
  /// 建议在后台线程执行，避免阻塞UI
  Future<void> initPlugins() async {
    if (kDebugMode) {
      debugPrint('🚀 [SDKInitializer] initPlugins: 开始初始化...');
    }
    // TODO: 初始化推送SDK
    // TODO: 初始化统计SDK
    // TODO: 初始化支付SDK
    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] initPlugins: 初始化完成');
    }
  }
}
```

写入 `lib/core/startup/initializer.dart`

- [ ] **Step 2: 验证文件创建**

```bash
cat lib/core/startup/initializer.dart
```

Expected: 文件内容正确

- [ ] **Step 3: Commit**

```bash
git add lib/core/startup/initializer.dart
git commit -m "feat(phase1): 创建SDKInitializer到core/startup目录

- 迁移sdk_initializer.dart到core/startup/initializer.dart
- 添加中文注释和使用说明

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 迁移StartupProfiler到core/startup

**Files:**
- Create: `lib/core/startup/profiler.dart`

- [ ] **Step 1: 创建StartupProfiler新文件**

```dart
import 'package:flutter/foundation.dart';

/// 启动性能计时器
///
/// 职责：测量App启动各阶段耗时，用于性能优化分析
/// 使用：在启动流程关键节点调用mark()记录时间
/// 注意：仅在Debug模式输出日志，生产环境零开销
class StartupProfiler {
  static final Stopwatch _watch = Stopwatch();

  /// 开始计时
  ///
  /// 在App启动最开始调用
  static void start() {
    _watch.reset();
    _watch.start();
  }

  /// 记录时间点
  ///
  /// 在关键节点调用，输出当前累计耗时
  /// 仅Debug模式输出
  static void mark(String label) {
    if (kDebugMode) {
      debugPrint('⏱️ [Profiler] $label: ${_watch.elapsedMilliseconds}ms');
    }
  }

  /// 输出总耗时
  ///
  /// 启动完成时调用，输出总启动时间
  static void report() {
    if (kDebugMode) {
      debugPrint('⏱️ [Profiler] 总耗时: ${_watch.elapsedMilliseconds}ms');
    }
  }
}
```

写入 `lib/core/startup/profiler.dart`

- [ ] **Step 2: 验证文件创建**

```bash
cat lib/core/startup/profiler.dart
```

Expected: 文件内容正确

- [ ] **Step 3: Commit**

```bash
git add lib/core/startup/profiler.dart
git commit -m "feat(phase1): 创建StartupProfiler到core/startup目录

- 迁移startup_profiler.dart到core/startup/profiler.dart
- 添加中文注释和性能警告说明

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: 迁移DataSyncManager到core/sync

**Files:**
- Create: `lib/core/sync/manager.dart`

- [ ] **Step 1: 创建DataSyncManager新文件**

```dart
import 'package:flutter/foundation.dart';

/// 数据同步管理器
///
/// 职责：用户登录后同步本地数据和远程数据
/// 使用：登录成功后调用sync()触发同步
/// 注意：同步操作可能耗时，建议后台执行
class DataSyncManager {
  /// 执行数据同步
  ///
  /// 同步本地缓存和远程数据
  /// 包括：用户信息、配置数据、离线数据等
  void sync() {
    if (kDebugMode) {
      debugPrint('🚀 [DataSyncManager] sync: 开始同步...');
    }
    // TODO: 同步用户信息
    // TODO: 同步配置数据
    // TODO: 处理离线数据
    if (kDebugMode) {
      debugPrint('✅ [DataSyncManager] sync: 同步完成');
    }
  }
}
```

写入 `lib/core/sync/manager.dart`

- [ ] **Step 2: 验证文件创建**

```bash
cat lib/core/sync/manager.dart
```

Expected: 文件内容正确

- [ ] **Step 3: Commit**

```bash
git add lib/core/sync/manager.dart
git commit -m "feat(phase1): 创建DataSyncManager到core/sync目录

- 迁移data_sync_manager.dart到core/sync/manager.dart
- 添加中文注释和性能警告

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: 创建AppLauncher（迁移AppStarter）

**Files:**
- Create: `lib/core/startup/launcher.dart`

- [ ] **Step 1: 创建AppLauncher新文件**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'initializer.dart';
import 'profiler.dart';
import '../auth/manager.dart';
import '../sync/manager.dart';

/// App启动器
///
/// 职责：管理App完整启动流程
/// 流程：初始化Flutter binding → 配置系统UI → 初始化SDK → 启动App
/// 使用：main.dart中调用 `AppLauncher.launch(const MyApp())`
class AppLauncher {
  AppLauncher._();

  /// 启动App
  ///
  /// 执行完整启动流程：
  /// 1. 初始化Flutter binding
  /// 2. 配置屏幕方向
  /// 3. 初始化第三方SDK
  /// 4. 检查认证状态
  /// 5. 数据同步（如有Token）
  /// 6. 运行App Widget
  static Future<void> launch(Widget app) async {
    // 开始性能计时
    StartupProfiler.start();

    // 1. 初始化Flutter binding
    WidgetsFlutterBinding.ensureInitialized();
    StartupProfiler.mark('Flutter binding初始化');

    // 2. 配置屏幕方向（仅支持竖屏）
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    StartupProfiler.mark('屏幕方向配置');

    // 3. 初始化第三方SDK（异步，不阻塞）
    final sdkInitializer = SDKInitializer();
    sdkInitializer.initPlugins().then((_) {
      StartupProfiler.mark('SDK初始化完成');
    });

    // 4. 检查认证状态
    final authManager = AuthManager();
    await authManager.handleLogin();
    StartupProfiler.mark('认证检查完成');

    // 5. 数据同步（登录成功后）
    final syncManager = DataSyncManager();
    syncManager.sync();
    StartupProfiler.mark('数据同步启动');

    // 6. 运行App
    runApp(app);
    StartupProfiler.report();
  }
}
```

写入 `lib/core/startup/launcher.dart`

- [ ] **Step 2: 验证文件创建**

```bash
cat lib/core/startup/launcher.dart
```

Expected: 文件内容正确

- [ ] **Step 3: Commit**

```bash
git add lib/core/startup/launcher.dart
git commit -m "feat(phase1): 创建AppLauncher替代AppStarter

- 合并启动流程到单一入口
- 添加性能计时节点
- 包含认证检查和数据同步
- 中文注释说明启动流程

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: 创建Constants文件

**Files:**
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/constants/api_constants.dart`
- Create: `lib/core/constants/cache_constants.dart`

- [ ] **Step 1: 创建AppConstants**

```dart
/// 应用配置常量
///
/// 职责：存储应用级配置，如名称、版本、默认超时等
/// 使用：`AppConstants.appName`, `AppConstants.defaultTimeout`
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = 'MyApp';

  /// 应用版本
  static const String version = '1.0.0';

  /// 默认超时时间（秒）
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// 默认动画时长
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
```

写入 `lib/core/constants/app_constants.dart`

- [ ] **Step 2: 创建APIConstants**

```dart
/// API配置常量
///
/// 职责：存储API相关配置，如baseUrl、超时时间等
/// 使用：`APIConstants.baseUrl`, `APIConstants.connectTimeout`
class APIConstants {
  APIConstants._();

  /// API基础URL
  ///
  /// 开发环境使用测试服务器
  /// 生产环境切换为正式服务器
  static const String baseUrl = 'https://api.example.com';

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 30000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 30000;

  /// 发送超时时间（毫秒）
  static const int sendTimeout = 30000;
}
```

写入 `lib/core/constants/api_constants.dart`

- [ ] **Step 3: 创建CacheConstants**

```dart
/// 缓存配置常量
///
/// 职责：存储缓存相关配置，如TTL、容量限制等
/// 使用：`CacheConstants.defaultTTL`, `CacheConstants.maxListSize`
class CacheConstants {
  CacheConstants._();

  /// 默认缓存过期时间
  static const Duration defaultTTL = Duration(hours: 24);

  /// 列表缓存最大条数
  ///
  /// 超过此数量建议使用分页加载
  static const int maxListSize = 100;

  /// 用户信息缓存过期时间
  static const Duration userTTL = Duration(days: 7);

  /// 配置数据缓存过期时间
  static const Duration configTTL = Duration(hours: 1);
}
```

写入 `lib/core/constants/cache_constants.dart`

- [ ] **Step 4: 验证文件创建**

```bash
ls -la lib/core/constants/
cat lib/core/constants/app_constants.dart
cat lib/core/constants/api_constants.dart
cat lib/core/constants/cache_constants.dart
```

Expected: 三个常量文件全部创建成功

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/
git commit -m "feat(phase1): 创建Constants模块

- AppConstants: 应用配置常量
- APIConstants: API配置常量
- CacheConstants: 缓存配置常量
- 所有常量使用static const，零运行时开销

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: 创建AppLogger

**Files:**
- Create: `lib/core/utils/logger.dart`

- [ ] **Step 1: 创建AppLogger**

```dart
import 'package:flutter/foundation.dart';

/// 日志级别
///
/// debug: 调试信息（仅开发环境）
/// info: 一般信息
/// warning: 警告信息
/// error: 错误信息
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 应用日志器
///
/// 职责：统一日志输出管理，支持级别过滤和生产环境禁用
/// 使用：通过DI获取 `sl<AppLogger>()`
/// 配置：
///   - enableInProduction: 生产环境是否启用日志（默认false）
///   - minLevel: 最小输出级别（默认info）
/// 注意：生产环境默认禁用，避免性能损耗和敏感信息泄露
class AppLogger {
  /// 是否在生产环境启用日志
  final bool enableInProduction;

  /// 最小日志级别
  ///
  /// 低于此级别的日志不会输出
  final LogLevel minLevel;

  AppLogger({
    this.enableInProduction = false,
    this.minLevel = LogLevel.info,
  });

  /// 输出调试日志
  ///
  /// 仅Debug模式且minLevel <= debug时输出
  void debug(String message) => log(LogLevel.debug, message);

  /// 输出信息日志
  void info(String message) => log(LogLevel.info, message);

  /// 输出警告日志
  void warning(String message) => log(LogLevel.warning, message);

  /// 输出错误日志
  ///
  /// 可附带异常对象
  void error(String message, [dynamic error]) =>
      log(LogLevel.error, message, error);

  /// 核心日志输出方法
  ///
  /// 根据级别和模式判断是否输出
  void log(LogLevel level, String message, [dynamic error]) {
    // 级别过滤：低于minLevel不输出
    if (level.index < minLevel.index) return;

    // 生产环境过滤：未启用且非Debug模式不输出
    if (!enableInProduction && !kDebugMode) return;

    // 格式化输出
    final timestamp = DateTime.now().toString();
    final levelStr = level.name.toUpperCase();
    final output = '[$timestamp] [$levelStr] $message';

    // Debug模式使用debugPrint
    if (kDebugMode) {
      debugPrint(output);
      if (error != null) {
        debugPrint('  错误详情: ${error.toString()}');
      }
    }
  }
}
```

写入 `lib/core/utils/logger.dart`

- [ ] **Step 2: 验证文件创建**

```bash
cat lib/core/utils/logger.dart
```

Expected: 文件内容正确，包含完整中文注释

- [ ] **Step 3: Commit**

```bash
git add lib/core/utils/logger.dart
git commit -m "feat(phase1): 创建AppLogger统一日志管理

- 支持日志级别过滤（debug/info/warning/error）
- 生产环境默认禁用，避免性能损耗
- 可配置minLevel控制输出粒度
- 中文注释说明使用方式和注意事项

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 9: 创建GetIt Locator

**Files:**
- Create: `lib/core/di/locator.dart`

- [ ] **Step 1: 添加get_it依赖到pubspec.yaml**

修改 `pubspec.yaml`，在dependencies部分添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Infrastructure
  api:
    path: packages/api
  key_value_storage:
    path: packages/key_value_storage
  domain_models:
    path: packages/domain_models
  component_library:
    path: packages/component_library
  routing:
    path: packages/routing

  # Dependency Injection
  get_it: ^7.6.0

  # Common
  flutter_easyloading: ^3.0.5
  flutter_screenutil: ^5.9.0
  go_router: ^14.2.7
  rxdart: ^0.27.1
  dio: ^5.2.0+1
  cupertino_icons: ^1.0.2
```

- [ ] **Step 2: 安装依赖**

```bash
flutter pub get
```

Expected: get_it ^7.6.0安装成功

- [ ] **Step 3: 创建Locator文件**

```dart
import 'package:get_it/get_it.dart';

/// 全局服务定位器
///
/// 使用GetIt实现依赖注入，管理所有服务的生命周期
/// 使用方式：
///   - 注册服务：`sl.registerSingleton<Type>(instance)`
///   - 获取服务：`sl<Type>()`
///   - 异步注册：`sl.registerSingletonAsync<Type>(factory)`
final sl = GetIt.instance;
```

写入 `lib/core/di/locator.dart`

- [ ] **Step 4: 验证文件创建**

```bash
cat lib/core/di/locator.dart
```

Expected: locator文件创建成功

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/core/di/locator.dart
git commit -m "feat(phase1): 添加GetIt依赖并创建Locator

- 添加get_it ^7.6.0依赖
- 创建全局服务定位器sl
- 中文注释说明使用方式

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 10: 创建DI Setup（合并RepositoryFactory + AppConfigurator）

**Files:**
- Create: `lib/core/di/setup.dart`

- [ ] **Step 1: 创建DI Setup文件**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';

import 'locator.dart';
import '../auth/manager.dart';
import '../sync/manager.dart';
import '../utils/logger.dart';
import '../constants/api_constants.dart';

/// 依赖注入配置
///
/// 职责：注册所有应用依赖，包括单例服务和工厂服务
/// 使用：在App启动前调用 `setupDependencies()`
/// 流程：
///   1. 注册核心服务（Logger, Api, KeyValueStorage）
///   2. 注册业务服务（AuthManager, DataSyncManager）
///   3. 配置EasyLoading
void setupDependencies() {
  // ===== 核心服务 =====

  // 日志服务（单例）
  sl.registerSingleton<AppLogger>(AppLogger());

  // API服务（单例）
  sl.registerSingleton<Api>(
    Api(
      userTokenSupplier: () async {
        // TODO: 从KeyValueStorage获取Token
        return null;
      },
      networkDisconnectedCallback: () {
        sl<AppLogger>().warning('网络连接已断开');
      },
    ),
  );

  // KeyValueStorage（单例）
  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());

  // ===== 业务服务 =====

  // AuthManager（单例）
  sl.registerSingleton<AuthManager>(AuthManager());

  // DataSyncManager（单例）
  sl.registerSingleton<DataSyncManager>(DataSyncManager());
}

/// 配置EasyLoading
///
/// 设置全局加载指示器样式
/// 在App启动前调用
void configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 30.0
    ..radius = 8.0
    ..backgroundColor = Colors.black87
    ..textColor = Colors.white
    ..indicatorColor = Colors.white
    ..maskType = EasyLoadingMaskType.black
    ..maskColor = Colors.transparent;
}
```

写入 `lib/core/di/setup.dart`

- [ ] **Step 2: 验证文件创建**

```bash
cat lib/core/di/setup.dart
```

Expected: setup文件创建成功

- [ ] **Step 3: Commit**

```bash
git add lib/core/di/setup.dart
git commit -m "feat(phase1): 创建DI Setup合并RepositoryFactory和AppConfigurator

- 注册核心服务：AppLogger, Api, KeyValueStorage
- 注册业务服务：AuthManager, DataSyncManager
- 配置EasyLoading样式
- 中文注释说明注册流程

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 11: 迁移UI页面到features

**Files:**
- Create: `lib/features/home/ui/home_page.dart`
- Create: `lib/features/detail/ui/detail_page.dart`

- [ ] **Step 1: 读取现有UI文件内容**

现有 `lib/src/ui/tab_a_page.dart`：
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home tab page
class TabAPage extends StatelessWidget {
  const TabAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Scaffold Ready',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Infrastructure packages are set up.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/detail-c'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Detail'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 创建HomePage**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 首页
///
/// 职责：应用主页面，展示骨架搭建完成状态
/// 使用：路由导航 `context.go('/home')`
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 成功图标
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            // 标题
            Text(
              '骨架搭建完成',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            // 说明文本
            const Text('基础设施包已配置完成。'),
            const SizedBox(height: 24),
            // 导航按钮
            FilledButton.icon(
              onPressed: () => context.push('/detail'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('打开详情页'),
            ),
          ],
        ),
      ),
    );
  }
}
```

写入 `lib/features/home/ui/home_page.dart`

- [ ] **Step 3: 读取Detail页面**

现有 `lib/src/ui/detail_c_page.dart`（需要先读取确认内容）

- [ ] **Step 4: 创建DetailPage**

假设现有内容为简单详情页，创建：

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 详情页
///
/// 职责：展示详情信息
/// 使用：路由导航 `context.push('/detail')`
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('详情页'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              '详情页面',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
```

写入 `lib/features/detail/ui/detail_page.dart`

- [ ] **Step 5: 验证文件创建**

```bash
ls -la lib/features/home/ui/
ls -la lib/features/detail/ui/
```

Expected: home_page.dart和detail_page.dart创建成功

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/ui/home_page.dart lib/features/detail/ui/detail_page.dart
git commit -m "feat(phase1): 迁移UI页面到features目录

- TabAPage → HomePage（lib/features/home/ui/）
- DetailCPage → DetailPage（lib/features/detail/ui/）
- 添加中文注释和页面说明

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 12: 更新routing包路由配置

**Files:**
- Modify: `packages/routing/lib/routing.dart` 或相关路由配置文件

需要先检查routing包的路由配置方式。

- [ ] **Step 1: 读取routing包配置**

```bash
cat packages/routing/lib/routing.dart
```

- [ ] **Step 2: 更新路由路径**

将路由路径从：
- `/tab-a` → `/home`
- `/detail-c` → `/detail`

具体修改取决于routing包的实现方式。需要查看后确定修改内容。

- [ ] **Step 3: Commit路由变更**

```bash
git add packages/routing/
git commit -m "feat(phase1): 更新路由路径适配新目录结构

- /tab-a → /home
- /detail-c → /detail

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 13: 更新main.dart和app.dart

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: 更新main.dart**

```dart
import 'app.dart';
import 'core/startup/launcher.dart';
import 'core/di/setup.dart';

void main() {
  // 配置依赖注入
  setupDependencies();
  configureEasyLoading();

  // 启动App
  AppLauncher.launch(const MyApp());
}
```

写入 `lib/main.dart`

- [ ] **Step 2: 更新app.dart**

```dart
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
    // 构建路由
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
```

写入 `lib/app.dart`

- [ ] **Step 3: 验证文件更新**

```bash
cat lib/main.dart
cat lib/app.dart
```

Expected: 两个文件更新成功

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/app.dart
git commit -m "feat(phase1): 更新main.dart和app.dart使用新启动流程

- main.dart使用AppLauncher和DI setup
- app.dart移除AppConfigurator调用（已合并入setup）
- 导入路径更新为core/目录

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 14: 清理旧文件

**Files:**
- Delete: `lib/src/auth_manager.dart`
- Delete: `lib/src/sdk_initializer.dart`
- Delete: `lib/src/startup_profiler.dart`
- Delete: `lib/src/data_sync_manager.dart`
- Delete: `lib/src/app_starter.dart`
- Delete: `lib/src/repository_factory.dart`
- Delete: `lib/src/app_configurator.dart`
- Delete: `lib/src/ui/tab_a_page.dart`
- Delete: `lib/src/ui/detail_c_page.dart`

- [ ] **Step 1: 删除旧文件**

```bash
rm lib/src/auth_manager.dart
rm lib/src/sdk_initializer.dart
rm lib/src/startup_profiler.dart
rm lib/src/data_sync_manager.dart
rm lib/src/app_starter.dart
rm lib/src/repository_factory.dart
rm lib/src/app_configurator.dart
rm lib/src/ui/tab_a_page.dart
rm lib/src/ui/detail_c_page.dart
```

- [ ] **Step 2: 检查lib/src剩余文件**

```bash
ls -la lib/src/
ls -la lib/src/ui/
```

Expected: 仅保留 `lib/src/ui/tab_b_page.dart`（Phase 2处理）和 `lib/src/theme/`

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat(phase1): 清理已迁移的旧文件

- 删除lib/src/下的已迁移文件
- 保留lib/src/theme/和lib/src/ui/tab_b_page.dart（Phase 2处理）

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 15: 验证编译和运行

**Files:**
- 无新文件

- [ ] **Step 1: 运行Flutter分析**

```bash
flutter analyze
```

Expected: 无错误，无警告（或仅有TODO注释警告）

- [ ] **Step 2: 尝试编译**

```bash
flutter build apk --debug
```

或在iOS：
```bash
flutter build ios --debug --no-codesign
```

Expected: 编译成功

- [ ] **Step 3: 运行应用**

```bash
flutter run
```

Expected: 应用启动成功，首页显示"骨架搭建完成"

- [ ] **Step 4: 验证功能**

检查：
1. App启动无报错
2. 首页显示正常
3. 点击"打开详情页"按钮导航成功
4. 详情页返回按钮正常

- [ ] **Step 5: Final Commit（如有遗漏修复）**

```bash
git add -A
git commit -m "feat(phase1): Phase 1基础设施重构完成

完成内容：
- 核心目录结构创建（core/auth, core/di, core/startup, core/sync, core/utils, core/constants, core/widgets）
- features目录结构创建（features/home, features/detail）
- 文件迁移：AuthManager, SDKInitializer, StartupProfiler, DataSyncManager, AppLauncher
- Constants模块：AppConstants, APIConstants, CacheConstants
- AppLogger统一日志管理
- GetIt依赖注入系统
- UI页面迁移：HomePage, DetailPage
- 所有模块添加中文README和注释

破坏性变更：
- lib/src/* → core/*, features/*
- RepositoryFactory → GetIt DI
- 路由路径变更

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Spec Coverage Check

| Design要求 | Plan任务覆盖 |
|-----------|-------------|
| 目录重构 | Task 1, 11 |
| 文件迁移（9个） | Task 2-6, 11, 14 |
| Constants管理 | Task 7 |
| AppLogger | Task 8 |
| GetIt依赖注入 | Task 9-10 |
| README（中文） | Task 1各步骤 |
| 中文注释 | 所有代码文件 |

---

## Self-Review Placeholder Scan

检查plan中的placeholder：
- 无"TBD"、"TODO"、"implement later"等placeholder（仅代码中的TODO注释保留，表示待实现功能）
- 所有步骤都有完整代码或命令
- 无"Similar to Task N"等省略
- 文件路径明确

---

## Type Consistency Check

- AuthManager类名一致
- SDKInitializer类名一致
- StartupProfiler类名一致
- DataSyncManager类名一致
- AppLauncher类名一致（新创建）
- sl定位器命名一致
- HomePage类名一致
- DetailPage类名一致

---

Plan complete and saved to `docs/superpowers/plans/2026-04-30-flutter-architecture-phase1.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints for review

**Which approach?**