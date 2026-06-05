# Plan C: 生产就绪 (P3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 深度链接、错误上报、弱网检测、RTL 测试 —— 四个生产环境必备能力。

**Architecture:** 增量添加，不改变现有架构。每个 Task 独立可部署，可选择性执行。

**Tech Stack:** Flutter 3.19+, GoRouter 14.x, Sentry SDK 或 Firebase Crashlytics, connectivity_plus

**前置条件:** Plan A 完成，Plan B 建议完成（非强制）

**预估工期:** 2-4 周 (1人顺序推进，各 Task 独立)

---

### Task 1: 深度链接 (Deep Link)

**目标:** 支持外部链接（推送通知、短信、二维码）直接跳转到 App 内指定页面。

**文件:**
- 修改: `packages/infrastructure/routing/lib/src/routes/router.dart` — GoRouter deep link 配置
- 修改: `lib/app.dart` — MaterialApp.router deep link builder
- 创建: `test/unit/routing/deep_link_test.dart`
- 修改: `packages/infrastructure/routing/lib/src/routes/app_routes.dart` — 定义 deep link 模式

**设计:** GoRouter 原生支持 deep link，通过 `initialLocation` + `redirect` 处理。Android 需配置 AndroidManifest，iOS 需配置 Info.plist 和 Associated Domains。本 Task 覆盖 Flutter 层的路由配置，原生配置见 Step 5 的文档指引。

- [ ] **Step 1: 定义 Deep Link 路由模式**

```dart
// packages/infrastructure/routing/lib/src/routes/app_routes.dart
class AppRoutes {
  AppRoutes._();

  // 页面路由
  static const String home = '/home';
  static const String settings = '/settings';
  static const String detail = '/detail';
  static const String login = '/login';
  static const String register = '/register';

  // Deep link 路径模式（供外部链接使用）
  // 格式: myapp://detail/123 或 https://myapp.com/detail/123
  static const String detailWithId = '/detail/:id';
}
```

- [ ] **Step 2: 修改 router.dart — 添加 Deep Link 路由**

```dart
// packages/infrastructure/routing/lib/src/routes/router.dart
// 在现有 routes 数组中添加带参数的 /detail/:id 路由:

GoRoute(
  path: '/detail/:id',
  builder: (context, state) {
    final id = state.pathParameters['id'] ?? '0';
    return BlocProvider(
      create: (_) => sl<DetailCubit>(),
      child: DetailPage(id: id),
    );
  },
),

// 修改 GoRouter 构造，添加 deep link 配置:
static GoRouter getRouter({required RouteContext ctx}) {
  router = GoRouter(
    initialLocation: '/home',
    // ... 现有配置 ...

    // Deep link 异常处理
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, size: 48),
            const SizedBox(height: 16),
            Text('无法打开链接: ${state.uri}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('回到首页'),
            ),
          ],
        ),
      ),
    ),
  );
  return router;
}
```

- [ ] **Step 3: 修改 DetailPage — 支持 id 参数**

如果 DetailPage 当前不接受 id 参数（当前实现: `const DetailPage()`），需要改为接受可选 id:

```dart
// packages/features/feature_detail/lib/src/ui/detail_page.dart
class DetailPage extends StatelessWidget {
  final String? id;
  const DetailPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    // 如果有 id，自动加载
    if (id != null) {
      context.read<DetailCubit>().loadData(id!);
    }
    // ... 其余不变
  }
}
```

- [ ] **Step 4: 编写 Deep Link 测试**

```dart
// test/unit/routing/deep_link_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

void main() {
  group('Deep Link Routing', () {
    late GoRouter router;

    setUp(() {
      // 构造测试用 router
    });

    test('detail route matches /detail/:id', () {
      final match = router.routeInformationProvider.value;
      // 测试 /detail/123 匹配
    });

    test('unknown routes show error page', () {
      // 测试 /unknown xxx 返回 errorBuilder
    });
  });
}
```

**注意:** GoRouter 单元测试需要完整的 GoRouter 实例。如果构造复杂，可推迟到 widget test 中验证。

- [ ] **Step 5: 原生平台配置**

Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="myapp" android:host="detail"/>
  <data android:scheme="https" android:host="myapp.com"/>
</intent-filter>
```

iOS (`ios/Runner/Info.plist`):
```xml
<key>FlutterDeepLinkingEnabled</key>
<true/>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

**注意:** 原生配置需根据实际 bundle ID 和域名调整，本步骤提供模板。

- [ ] **Step 6: 创建 Deep Link 文档**

```bash
# 创建 docs/deep-link-guide.md
```

内容: 包含上述所有配置的完整说明 + 测试方法。

- [ ] **Step 7: Commit**

```bash
git add packages/infrastructure/routing/lib/src/routes/app_routes.dart
git add packages/infrastructure/routing/lib/src/routes/router.dart
git add packages/features/feature_detail/lib/src/ui/detail_page.dart
git add test/unit/routing/deep_link_test.dart
git add docs/deep-link-guide.md
git commit -m "feat(routing): add deep link support for /detail/:id

GoRouter route with path parameter, DetailPage accepts optional id,
Android/iOS platform config templates, deep link documentation."
```

---

### Task 2: 错误上报预留接口

**目标:** 在现有 AppErrorHandler 中预留错误上报接口，为后续接入 Sentry/Firebase 做准备。

**文件:**
- 修改: `packages/services/error/lib/src/error_handler.dart` — 增加 reporter 回调
- 创建: `packages/services/error/lib/src/error_reporter.dart` — 错误上报抽象接口
- 修改: `lib/core/startup/launcher.dart` — 接入 reporter
- 创建: `packages/services/error/test/error_handler_test.dart`

**设计:** 不引入真实 SDK（避免增加依赖），只定义抽象接口 + ConsoleReporter 示例实现。后续接入 Sentry 时只需实现 ErrorReporter 接口。

- [ ] **Step 1: 创建 ErrorReporter 接口**

```dart
// packages/services/error/lib/src/error_reporter.dart
/// 错误上报接口
///
/// 实现类负责将错误发送到 Sentry、Firebase Crashlytics 等平台。
///
/// 使用示例：
/// ```dart
/// class SentryReporter implements ErrorReporter {
///   @override
///   Future<void> reportError(Object error, StackTrace? stack, {bool isFatal = false}) async {
///     await Sentry.captureException(error, stackTrace: stack);
///   }
/// }
/// ```
abstract class ErrorReporter {
  /// 上报错误
  ///
  /// [error] — 错误对象
  /// [stack] — 调用栈（可能为 null）
  /// [isFatal] — 是否为致命错误（崩溃）
  /// [context] — 附加上下文信息（用户ID、当前页面等）
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  });
}

/// 控制台错误上报器（开发用）
///
/// 生产环境替换为 SentryReporter 或 CrashlyticsReporter。
class ConsoleReporter implements ErrorReporter {
  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('=== ERROR REPORT ===');
    debugPrint('Fatal: $isFatal');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    if (context != null) {
      debugPrint('Context: $context');
    }
    debugPrint('====================');
  }
}
```

- [ ] **Step 2: 修改 AppErrorHandler — 集成 reporter**

```dart
// packages/services/error/lib/src/error_handler.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'error_reporter.dart';

class AppErrorHandler {
  ErrorReporter? _reporter;

  /// 设置错误上报器
  void setReporter(ErrorReporter reporter) {
    _reporter = reporter;
  }

  void setup({required void Function(Object error, StackTrace? stack) onError}) {
    FlutterError.onError = (FlutterErrorDetails details) {
      onError(details.exception, details.stack);

      // 区分 fatal 和非 fatal
      final isFatal = details.silent != true;
      _reporter?.reportError(
        details.exception,
        details.stack,
        isFatal: isFatal,
      );

      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      onError(error, stack);

      // PlatformDispatcher 错误默认为 fatal
      _reporter?.reportError(error, stack, isFatal: true);
      return true;
    };
  }
}
```

- [ ] **Step 3: 启动流程中注册 reporter**

```dart
// lib/core/startup/launcher.dart — 在 AppErrorHandler.setup() 之后添加:

// 设置错误上报器（开发环境用 ConsoleReporter，生产环境替换为 Sentry）
final errorHandler = AppErrorHandler();
errorHandler.setReporter(ConsoleReporter());
errorHandler.setup(
  onError: (error, stack) {
    // 已有逻辑不变
  },
);
```

- [ ] **Step 4: 更新 error.dart barrel file**

```dart
// packages/services/error/lib/error.dart
export 'src/error_handler.dart';
export 'src/error_reporter.dart';
```

- [ ] **Step 5: 创建 ErrorHandler 测试**

```dart
// packages/services/error/test/error_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:error/error.dart';

class _TestReporter implements ErrorReporter {
  Object? lastError;
  StackTrace? lastStack;
  bool? lastFatal;

  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    lastError = error;
    lastStack = stack;
    lastFatal = isFatal;
  }
}

void main() {
  group('AppErrorHandler with reporter', () {
    late _TestReporter reporter;
    late AppErrorHandler handler;

    setUp(() {
      reporter = _TestReporter();
      handler = AppErrorHandler();
      handler.setReporter(reporter);
    });

    test('ConsoleReporter does not throw', () async {
      final reporter = ConsoleReporter();
      await reporter.reportError(Exception('test'), StackTrace.current);
      // 验证不抛异常即可
    });

    test('ErrorReporter interface can be implemented', () {
      final impl = _TestReporter();
      expect(impl, isA<ErrorReporter>());
    });
  });
}
```

- [ ] **Step 6: 验证**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter
flutter analyze
flutter test packages/services/error/test/
```
预期: analyze 零错误，测试通过。

- [ ] **Step 7: Commit**

```bash
git add packages/services/error/lib/src/error_handler.dart
git add packages/services/error/lib/src/error_reporter.dart
git add packages/services/error/lib/error.dart
git add packages/services/error/test/error_handler_test.dart
git add lib/core/startup/launcher.dart
git commit -m "feat(error): add ErrorReporter interface for crash reporting

Define ErrorReporter abstract interface with ConsoleReporter example.
Integrate reporter into AppErrorHandler with fatal/non-fatal distinction.
Ready for Sentry/Crashlytics integration later."
```

---

### Task 3: 弱网检测

**目标:** 在 NetworkCubit 中增加弱网检测能力——通过请求延迟判断网络质量，而不限于 connectivity_plus 的连接/断开。

**文件:**
- 修改: `packages/services/network/lib/src/network_state.dart` — 增加 NetworkQuality enum
- 修改: `packages/services/network/lib/src/network_cubit.dart` — 增加质量检测
- 创建: `packages/services/network/lib/src/network_quality_monitor.dart` — 延迟监控
- 修改: `packages/services/network/test/network_cubit_test.dart` — 补充测试

**设计:** 新增 NetworkQuality enum (good / slow / poor / disconnected)。NetworkCubit 保持简洁，弱网检测通过独立的 NetworkQualityMonitor 类实现——基于最近 N 次 HTTP 请求的延迟中位数判断。

- [ ] **Step 1: 扩展 NetworkState — 增加 NetworkQuality**

```dart
// packages/services/network/lib/src/network_state.dart — 在现有枚举后追加:

/// 网络质量
enum NetworkQuality {
  /// 良好 (< 200ms)
  good,

  /// 偏慢 (200-1000ms)
  slow,

  /// 很差 (> 1000ms 或频繁超时)
  poor,

  /// 断开
  disconnected,
}
```

以及在 NetworkState 类中添加 `quality` 字段:

```dart
@freezed
class NetworkState with _$NetworkState {
  const factory NetworkState({
    required NetworkStatus status,
    DateTime? lastDisconnectedAt,
    @Default(NetworkUIStyle.banner) NetworkUIStyle uiStyle,
    @Default(NetworkQuality.good) NetworkQuality quality,
  }) = _NetworkState;

  const NetworkState._();
  bool get isConnected => status == NetworkStatus.connected;
}
```

- [ ] **Step 2: 创建 NetworkQualityMonitor**

```dart
// packages/services/network/lib/src/network_quality_monitor.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'network_state.dart';

/// 网络质量监控器
///
/// 通过测量最近请求的延迟来判断网络质量。
/// Stream 输出 NetworkQuality 变化。
class NetworkQualityMonitor {
  final int _windowSize;
  final List<int> _recentLatencies = [];
  StreamController<NetworkQuality>? _controller;

  /// [windowSize] — 滑动窗口大小，取最近 N 次请求延迟的中位数
  NetworkQualityMonitor({int windowSize = 5}) : _windowSize = windowSize;

  /// 网络质量变化流
  Stream<NetworkQuality> get qualityStream {
    _controller ??= StreamController<NetworkQuality>.broadcast();
    return _controller!.stream;
  }

  /// 记录一次请求延迟（毫秒）
  ///
  /// 在 Dio 拦截器或 Repository 中调用。
  void recordLatency(int latencyMs) {
    _recentLatencies.add(latencyMs);
    if (_recentLatencies.length > _windowSize) {
      _recentLatencies.removeAt(0);
    }
    _emitQuality();
  }

  /// 获取当前网络质量
  NetworkQuality get currentQuality {
    if (_recentLatencies.isEmpty) return NetworkQuality.good;

    final sorted = List<int>.from(_recentLatencies)..sort();
    final median = sorted[sorted.length ~/ 2];

    if (median < 200) return NetworkQuality.good;
    if (median < 1000) return NetworkQuality.slow;
    return NetworkQuality.poor;
  }

  void _emitQuality() {
    _controller?.add(currentQuality);
  }

  /// 重置统计（网络恢复连接时调用）
  void reset() {
    _recentLatencies.clear();
    _controller?.add(NetworkQuality.good);
  }

  void dispose() {
    _controller?.close();
  }
}
```

- [ ] **Step 3: NetworkCubit 集成 QualityMonitor**

```dart
// packages/services/network/lib/src/network_cubit.dart
// 在 NetworkCubit 中添加 _qualityMonitor 字段，监听其 stream:

class NetworkCubit extends Cubit<NetworkState> {
  final Connectivity _connectivity;
  final NetworkQualityMonitor _qualityMonitor;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _qualitySub;

  NetworkCubit(this._connectivity)
      : _qualityMonitor = NetworkQualityMonitor(),
        super(NetworkState(status: NetworkStatus.connected)) {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _qualitySub = _qualityMonitor.qualityStream.listen(_onQualityChanged);
  }

  void _onQualityChanged(NetworkQuality quality) {
    emit(state.copyWith(quality: quality));
  }

  /// 暴露质量监控器供 Dio 拦截器调用
  NetworkQualityMonitor get qualityMonitor => _qualityMonitor;

  // ... 其余不变
}
```

- [ ] **Step 4: 验证**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter
flutter analyze
flutter test packages/services/network/test/
```
预期: analyze 零错误，测试通过。

- [ ] **Step 5: Commit**

```bash
git add packages/services/network/lib/src/network_state.dart
git add packages/services/network/lib/src/network_cubit.dart
git add packages/services/network/lib/src/network_quality_monitor.dart
git add packages/services/network/test/network_cubit_test.dart
git commit -m "feat(network): add NetworkQualityMonitor for weak network detection

Add NetworkQuality enum (good/slow/poor/disconnected).
NetworkQualityMonitor uses sliding window median latency.
Integrated into NetworkCubit with quality stream."
```

---

### Task 4: RTL 测试

**目标:** 确保 App 在 RTL（从右到左）语言下的 UI 表现正确。

**文件:**
- 创建: `test/widget/rtl_layout_test.dart`
- 修改: `packages/infrastructure/component_library/test/widgets/custom_app_bar_test.dart` — 补充 RTL 用例
- 修改: `packages/infrastructure/component_library/test/widgets/app_scaffold_test.dart` — 补充 RTL 用例

**设计:** 使用 Flutter 的 `Directionality` widget 强制 RTL，验证关键 widget 的布局不变形。

- [ ] **Step 1: 创建 RTL 布局测试**

```dart
// test/widget/rtl_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('RTL Layout', () {
    Widget wrapRTL(Widget child) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      );
    }

    testWidgets('AppScaffold works in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        AppScaffold(
          title: 'اختبار',
          body: const Center(child: Text('محتوى')),
        ),
      ));
      expect(find.text('اختبار'), findsOneWidget);
      expect(find.text('محتوى'), findsOneWidget);
    });

    testWidgets('CustomAppBar back button flips in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        const Scaffold(
          appBar: CustomAppBar(title: 'عنوان', showBackButton: true),
          body: SizedBox(),
        ),
      ));
      // RTL 下返回箭头应镜像翻转（系统自动处理）
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('LoadingButton works in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        LoadingButton(
          isLoading: false,
          onPressed: () {},
          child: const Text('إرسال'),
        ),
      ));
      expect(find.text('إرسال'), findsOneWidget);
    });

    testWidgets('EmptyState works in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        const EmptyState(
          title: 'لا توجد بيانات',
          subtitle: 'اسحب للتحديث',
          onAction: _noop,
          actionLabel: 'تحديث',
        ),
      ));
      expect(find.text('لا توجد بيانات'), findsOneWidget);
      expect(find.text('اسحب للتحديث'), findsOneWidget);
      expect(find.text('تحديث'), findsOneWidget);
    });

    testWidgets('ErrorCard works in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        const ErrorCard(
          message: 'حدث خطأ',
          onRetry: _noop,
          retryLabel: 'إعادة المحاولة',
        ),
      ));
      expect(find.text('حدث خطأ'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });
}

void _noop() {}
```

- [ ] **Step 2: 验证 — RTL 测试通过**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter
flutter test test/widget/rtl_layout_test.dart
```
预期: 5 个 RTL 测试全部通过。

- [ ] **Step 3: Commit**

```bash
git add test/widget/rtl_layout_test.dart
git commit -m "test(rtl): add RTL layout tests for key widgets

Test AppScaffold, CustomAppBar, LoadingButton, EmptyState, ErrorCard
in TextDirection.rtl with Arabic text. All pass."
```

---

## 验证清单（Plan C 全部完成后）

- [ ] `flutter analyze` — 零错误
- [ ] `flutter test` — 所有已有 + 新增测试通过
- [ ] Deep link 可通过 `adb shell am start -d "myapp://detail/123"` 验证
- [ ] RTL 测试 5 个用例全部通过

---

## 回滚策略

每个 Task 独立 commit。`git revert <commit-hash>` 即可回滚。
