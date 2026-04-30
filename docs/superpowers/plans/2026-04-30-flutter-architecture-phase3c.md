# Flutter架构重构 - Phase 3.3: NetworkCubit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现网络状态管理Cubit和UI组件，支持多种提示样式（Banner/Toast/Snackbar/Dialog）

**Architecture:** 使用connectivity_plus监听网络变化，NetworkCubit管理状态，NetworkBanner/NetworkUIHandler组件展示提示。

**Tech Stack:** connectivity_plus, flutter_bloc, easyloading（可选）

---

## 文件结构概览

**创建的新文件：**

```
lib/
  core/
    global/
      network/
        network_cubit.dart       # NetworkCubit
        network_state.dart       # NetworkState
        README.md
    widgets/
      network/
        network_banner.dart      # NetworkBanner
        network_ui_handler.dart  # NetworkUIHandler
        README.md
```

**依赖Phase 1/2完成项：**
- lib/core/di/locator.dart
- lib/core/di/setup.dart
- lib/core/global/locale/（国际化支持）

---

### Task 1: 添加connectivity_plus依赖

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 添加依赖**

在 `pubspec.yaml` 的 dependencies 中添加：

```yaml
dependencies:
  # ...现有依赖...

  # Network Connectivity
  connectivity_plus: ^6.0.0
```

- [ ] **Step 2: 安装依赖**

```bash
flutter pub get
```

Expected: connectivity_plus ^6.0.0 安装成功

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat(phase3.3): 添加connectivity_plus依赖

- connectivity_plus ^6.0.0监听网络状态

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 创建NetworkState

**Files:**
- Create: `lib/core/global/network/network_state.dart`

- [ ] **Step 1: 创建network目录**

```bash
mkdir -p lib/core/global/network
```

- [ ] **Step 2: 创建NetworkState**

```dart
/// 网络状态
///
/// 职责：存储网络连接状态和UI样式配置
enum NetworkStatus {
  /// 已连接
  connected,
  /// 已断开
  disconnected,
}

/// 网络UI提示样式
///
/// 职责：定义网络断开时的提示方式
enum NetworkUIStyle {
  /// Banner横幅（固定顶部）
  banner,
  /// Toast提示（短暂显示）
  toast,
  /// Snackbar提示（底部弹出）
  snackbar,
  /// Dialog对话框（阻塞式）
  dialog,
  /// 无提示
  none,
}

/// 网络状态数据类
///
/// 职责：封装网络状态信息
class NetworkState {
  /// 网络连接状态
  final NetworkStatus status;

  /// 最近断开时间
  ///
  /// 用于计算断开持续时间
  final DateTime? lastDisconnectedAt;

  /// UI提示样式
  ///
  /// 控制网络断开时的提示方式
  final NetworkUIStyle uiStyle;

  NetworkState({
    required this.status,
    this.lastDisconnectedAt,
    this.uiStyle = NetworkUIStyle.banner,
  });

  /// 是否已连接
  bool get isConnected => status == NetworkStatus.connected;

  /// 复制并修改
  NetworkState copyWith({
    NetworkStatus? status,
    DateTime? lastDisconnectedAt,
    NetworkUIStyle? uiStyle,
  }) {
    return NetworkState(
      status: status ?? this.status,
      lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
      uiStyle: uiStyle ?? this.uiStyle,
    );
  }
}
```

写入 `lib/core/global/network/network_state.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/core/global/network/network_state.dart
git commit -m "feat(phase3.3): 创建NetworkState状态类

- NetworkStatus枚举（connected/disconnected）
- NetworkUIStyle枚举（banner/toast/snackbar/dialog/none）
- NetworkState数据类
- 中文注释说明状态和样式用途

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: 创建NetworkCubit

**Files:**
- Create: `lib/core/global/network/network_cubit.dart`

- [ ] **Step 1: 创建NetworkCubit**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_state.dart';

/// 网络状态管理Cubit
///
/// 职责：监听网络连接变化，管理网络状态
/// 使用：
///   - App顶层BlocProvider提供
///   - NetworkBanner/NetworkUIHandler响应状态
///   - checkNow主动检查网络状态
/// 持久化：无，每次App启动重新监听
///
/// 示例：
/// ```dart
/// BlocProvider(
///   create: (context) => NetworkCubit()..startListening(),
///   child: MyApp(),
/// )
/// ```
class NetworkCubit extends Cubit<NetworkState> {
  /// Connectivity实例
  final Connectivity _connectivity;

  /// 网络监听订阅
  StreamSubscription<ConnectivityResult>? _subscription;

  /// 构造函数
  ///
  /// 参数：
  /// - connectivity: Connectivity实例（可选，用于测试Mock）
  NetworkCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(NetworkState(status: NetworkStatus.connected));

  /// 开始监听网络变化
  ///
  /// 在App启动后调用，监听网络连接状态
  /// 网络变化时自动emit新状态
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      emit(NetworkState(
        status: isConnected ? NetworkStatus.connected : NetworkStatus.disconnected,
        lastDisconnectedAt: isConnected ? null : DateTime.now(),
      ));
    });
  }

  /// 设置UI样式
  ///
  /// 动态切换网络断开提示方式
  ///
  /// 参数：
  /// - style: UI样式
  void setUIStyle(NetworkUIStyle style) {
    emit(state.copyWith(uiStyle: style));
  }

  /// 主动检查网络状态
  ///
  /// 点击重试按钮时调用，立即检查网络
  Future<void> checkNow() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = result != ConnectivityResult.none;
      emit(NetworkState(
        status: isConnected ? NetworkStatus.connected : NetworkStatus.disconnected,
      ));
    } catch (e) {
      // 检查失败，默认为断开
      emit(NetworkState(
        status: NetworkStatus.disconnected,
        lastDisconnectedAt: DateTime.now(),
      ));
    }
  }

  /// 获取断开持续时间
  ///
  /// 返回：断开时长，已连接返回null
  Duration? get disconnectedDuration {
    if (state.isConnected || state.lastDisconnectedAt == null) return null;
    return DateTime.now().difference(state.lastDisconnectedAt!);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

写入 `lib/core/global/network/network_cubit.dart`

- [ ] **Step 2: 创建README**

```markdown
# 网络状态管理模块

## 职责
监听网络连接变化，管理网络状态，支持多种UI提示。

## 使用示例

### App顶层提供
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => NetworkCubit()..startListening()),
    BlocProvider(create: (context) => LocaleCubit()),
  ],
  child: MyApp(),
)
```

### UI组件响应
```dart
NetworkBanner(
  child: HomePage(),
)
```

### 主动检查
```dart
context.read<NetworkCubit>().checkNow();
```

## 状态类型
- connected: 网络已连接
- disconnected: 网络已断开

## UI样式
- banner: 横幅固定顶部
- toast: 短暂提示
- snackbar: 底部弹出
- dialog: 阻塞式对话框
- none: 无提示

## 依赖关系
- connectivity_plus: 网络监听
- flutter_bloc: Cubit基类

## 性能警告
网络监听使用Stream，轻量级，无性能影响。
```

写入 `lib/core/global/network/README.md`

- [ ] **Step 3: Commit**

```bash
git add lib/core/global/network/
git commit -m "feat(phase3.3): 创建NetworkCubit网络状态管理

- startListening监听网络变化
- setUIStyle动态切换提示样式
- checkNow主动检查网络
- 中文注释和README说明使用方式

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 创建NetworkBanner

**Files:**
- Create: `lib/core/widgets/network/network_banner.dart`

- [ ] **Step 1: 创建network widgets目录**

```bash
mkdir -p lib/core/widgets/network
```

- [ ] **Step 2: 创建NetworkBanner**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../global/network/network_cubit.dart';
import '../../global/network/network_state.dart';

/// 网络状态Banner
///
/// 职责：网络断开时在顶部显示红色横幅提示
/// 使用：包装App主体内容
/// 特性：
///   - 固定顶部，不遮挡主要内容
///   - 红色背景，醒目提示
///   - 显示图标和文字
///
/// 示例：
/// ```dart
/// NetworkBanner(
///   child: MaterialApp.router(...),
/// )
/// ```
class NetworkBanner extends StatelessWidget {
  /// 子Widget（App主要内容）
  final Widget child;

  const NetworkBanner({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        return Stack(
          children: [
            // 主要内容
            child,
            // 网络断开Banner
            if (!state.isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildBanner(context),
              ),
          ],
        );
      },
    );
  }

  /// 构建Banner
  Widget _buildBanner(BuildContext context) {
    return Material(
      color: Colors.red.shade400,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 网络断开图标
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              // 提示文字
              Text(
                // Phase 2国际化完成后使用：
                // AppLocalizations.of(context).networkError,
                '网络连接已断开',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

写入 `lib/core/widgets/network/network_banner.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/network/network_banner.dart
git commit -m "feat(phase3.3): 创建NetworkBanner横幅提示

- Stack布局，固定顶部
- 网络断开时显示红色Banner
- 图标+文字提示
- 中文注释说明布局设计

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: 创建NetworkUIHandler

**Files:**
- Create: `lib/core/widgets/network/network_ui_handler.dart`

- [ ] **Step 1: 创建NetworkUIHandler**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../global/network/network_cubit.dart';
import '../../global/network/network_state.dart';

/// 网络状态UI处理器
///
/// 职责：根据UI样式显示不同类型的网络断开提示
/// 使用：在App顶层NetworkBanner之后添加
/// 样式：
///   - toast: EasyLoading短暂提示
///   - snackbar: ScaffoldMessenger底部弹出
///   - dialog: showDialog阻塞式对话框
///
/// 示例：
/// ```dart
/// NetworkBanner(
///   child: NetworkUIHandler(
///     child: MaterialApp.router(...),
///   ),
/// )
/// ```
class NetworkUIHandler extends StatelessWidget {
  /// 子Widget
  final Widget? child;

  const NetworkUIHandler({this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      // 仅在状态变化时触发
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        // 已连接，不显示提示
        if (state.isConnected) return;

        // 根据UI样式显示不同提示
        switch (state.uiStyle) {
          case NetworkUIStyle.toast:
            _showToast(context);
            break;
          case NetworkUIStyle.snackbar:
            _showSnackbar(context);
            break;
          case NetworkUIStyle.dialog:
            _showDialog(context);
            break;
          case NetworkUIStyle.banner:
          case NetworkUIStyle.none:
            // Banner由NetworkBanner处理，none不显示
            break;
        }
      },
      child: child ?? const SizedBox.shrink(),
    );
  }

  /// Toast提示
  ///
  /// 使用EasyLoading短暂显示
  void _showToast(BuildContext context) {
    EasyLoading.showToast(
      // Phase 2国际化完成后使用AppLocalizations
      '网络连接已断开',
      duration: const Duration(seconds: 2),
      toastPosition: EasyLoadingToastPosition.top,
    );
  }

  /// Snackbar提示
  ///
  /// 底部弹出，带重试按钮
  void _showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('网络连接已断开'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '重试',
          onPressed: () {
            context.read<NetworkCubit>().checkNow();
          },
        ),
      ),
    );
  }

  /// Dialog对话框
  ///
  /// 阻塞式，用户需点击确认
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('网络连接已断开'),
        content: const Text('请检查网络连接后点击重试'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NetworkCubit>().checkNow();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
```

写入 `lib/core/widgets/network/network_ui_handler.dart`

- [ ] **Step 2: 创建README**

```markdown
# 网络提示组件模块

## 职责
提供网络状态UI提示组件，支持多种样式。

## 组件列表

### NetworkBanner
顶部红色横幅，固定显示。

```dart
NetworkBanner(
  child: MaterialApp.router(...),
)
```

### NetworkUIHandler
根据UIStyle显示不同提示。

```dart
NetworkUIHandler(
  child: Content(),
)
```

## UI样式说明
- banner: NetworkBanner处理，固定顶部
- toast: EasyLoading短暂提示，2秒自动消失
- snackbar: ScaffoldMessenger底部弹出，带重试按钮
- dialog: showDialog阻塞式，需用户确认
- none: 不显示任何提示

## 组合使用
```dart
NetworkBanner(
  child: NetworkUIHandler(
    child: MaterialApp.router(...),
  ),
)
```

## 动态切换样式
```dart
context.read<NetworkCubit>().setUIStyle(NetworkUIStyle.snackbar);
```

## 依赖关系
- flutter_bloc: BlocBuilder/BlocListener
- connectivity_plus: 网络监听（间接）
- flutter_easyloading: Toast提示（可选）

## 性能警告
Stack层叠影响布局性能，建议仅在需要时使用。
```

写入 `lib/core/widgets/network/README.md`

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/network/
git commit -m "feat(phase3.3): 创建NetworkUIHandler多种提示样式

- toast使用EasyLoading
- snackbar带重试按钮
- dialog阻塞式确认
- BlocListener监听状态变化
- 中文注释说明样式切换

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: 在DI中注册NetworkCubit

**Files:**
- Modify: `lib/core/di/setup.dart`

- [ ] **Step 1: 更新DI Setup**

添加NetworkCubit注册：

```dart
// 在setupDependencies函数中添加：

  // ===== 全局状态 =====

  // LocaleCubit（已注册）
  // NetworkCubit（单例）
  sl.registerSingleton<NetworkCubit>(
    NetworkCubit()..startListening()
  );
```

添加导入：
```dart
import '../global/network/network_cubit.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/di/setup.dart
git commit -m "feat(phase3.3): DI注册NetworkCubit

- NetworkCubit单例，启动时自动监听
- 中文注释说明注册位置

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: 在app.dart中集成NetworkBanner

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: 更新app.dart**

添加NetworkBanner包装：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

import 'src/theme/app_theme.dart';
import 'core/di/locator.dart';
import 'core/global/locale/locale_cubit.dart';
import 'core/global/locale/locale_state.dart';
import 'core/global/network/network_cubit.dart';
import 'core/widgets/network/network_banner.dart';
import 'core/widgets/network/network_ui_handler.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<LocaleCubit>()),
        BlocProvider(create: (context) => sl<NetworkCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return NetworkBanner(
            child: NetworkUIHandler(
              child: MaterialApp.router(
                title: '骨架演示',
                theme: appLightTheme,
                darkTheme: appDarkTheme,
                locale: localeState.locale,
                supportedLocales: const [Locale('zh'), Locale('en')],
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
              ),
            ),
          );
        },
      ),
    );
  }
}
```

写入 `lib/app.dart`

- [ ] **Step 2: Commit**

```bash
git add lib/app.dart
git commit -m "feat(phase3.3): 集成NetworkCubit到App

- MultiBlocProvider提供LocaleCubit和NetworkCubit
- NetworkBanner包装显示网络断开提示
- NetworkUIHandler支持多种提示样式
- 中文注释说明全局Provider设计

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: 验证编译

**Files:**
- 无新文件

- [ ] **Step 1: 运行Flutter分析**

```bash
flutter analyze
```

Expected: 无错误

- [ ] **Step 2: 尝试编译**

```bash
flutter build apk --debug
```

Expected: 编译成功

- [ ] **Step 3: 测试网络断开提示**

运行应用后，模拟断开网络（关闭WiFi/移动数据），检查：
1. Banner显示红色横幅
2. Toast/Snackbar/Dialog根据样式显示
3. 重试按钮可点击检查网络

- [ ] **Step 4: Final Commit**

```bash
git add -A
git commit -m "feat(phase3.3): Phase 3.3 NetworkCubit完成

完成内容：
- NetworkState状态类（status/uiStyle）
- NetworkCubit监听网络变化
- NetworkBanner顶部横幅提示
- NetworkUIHandler多种提示样式（toast/snackbar/dialog）
- DI注册NetworkCubit单例
- App集成NetworkBanner和NetworkUIHandler
- 完整中文README和注释

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Spec Coverage Check

| Design要求 | Plan任务覆盖 |
|-----------|-------------|
| NetworkCubit | Task 3 |
| NetworkState | Task 2 |
| NetworkUIStyle | Task 2 |
| NetworkBanner | Task 4 |
| NetworkUIHandler | Task 5 |
| DI注册 | Task 6 |
| App集成 | Task 7 |
| 中文README | Task 3, 5 |

---

Plan complete and saved to `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3c.md`.

继续生成Plan-3d？