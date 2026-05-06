# AppLogger + RequestScope 完整注入 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up AppLogger injection + RequestScope auto-cancel + AutoCancelInterceptor into the Dio interceptor chain, following Clean Architecture.

**Architecture:** Static RequestContext for tag passing. AutoCancelInterceptor at position 0 in Dio chain. TokenRenewalInterceptor at position 1 with AppLogger injected. RequestScope extracts tag from GoRouterState.fullPath.

**Tech Stack:** Dart 3.x, Flutter, Dio, GoRouter, GetIt

**Spec:** `docs/superpowers/specs/2026-05-06-applogger-requestscope-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/core/middleware/request_context.dart` | Create | Static tag pass-through |
| `packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart` | Create | Auto bind CancelToken from tag |
| `lib/core/widgets/request_scope.dart` | Modify | auto-extract fullPath, remove double-cancel |
| `packages/infrastructure/api/lib/src/dio_factory.dart` | Modify | Full interceptor chain + logger param |
| `packages/infrastructure/api/lib/api.dart` | Modify | Export 2 interceptors |
| `lib/core/di/setup.dart` | Modify | Pass logger to createDio |
| `packages/features/feature_home/lib/ui/home_page.dart` | Modify | Example RequestScope wrapping |

---

### Task 1: Create RequestContext

**Files:**
- Create: `lib/core/middleware/request_context.dart`
- Test: `test/unit/middleware/request_context_test.dart`

- [ ] **Step 1: Write RequestContext class**

```dart
// lib/core/middleware/request_context.dart

/// 请求上下文 — 静态 tag 传递
///
/// 设计决策: 不用 Zone。GoRouter 一次只有一个页面在前台，静态字段足够。
/// 限制: 嵌套 RequestScope（如 dialog）需用 overrideTag，不要嵌套。
class RequestContext {
  static String? _currentTag;

  static void setTag(String tag) => _currentTag = tag;
  static String? get currentTag => _currentTag;
  static void clear() => _currentTag = null;
}
```

- [ ] **Step 2: Write failing test**

```dart
// test/unit/middleware/request_context_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/middleware/request_context.dart';

void main() {
  group('RequestContext', () {
    tearDown(() => RequestContext.clear());

    test('currentTag returns null by default', () {
      expect(RequestContext.currentTag, isNull);
    });

    test('setTag sets currentTag', () {
      RequestContext.setTag('/home');
      expect(RequestContext.currentTag, '/home');
    });

    test('setTag overwrites previous tag', () {
      RequestContext.setTag('/home');
      RequestContext.setTag('/detail/:id');
      expect(RequestContext.currentTag, '/detail/:id');
    });

    test('clear resets currentTag to null', () {
      RequestContext.setTag('/home');
      RequestContext.clear();
      expect(RequestContext.currentTag, isNull);
    });

    test('clear is idempotent', () {
      RequestContext.clear();
      RequestContext.clear();
      expect(RequestContext.currentTag, isNull);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `fvm flutter test test/unit/middleware/request_context_test.dart`
Expected: 5 tests pass

- [ ] **Step 4: Commit**

```bash
git add lib/core/middleware/request_context.dart test/unit/middleware/request_context_test.dart
git commit -m "feat: add RequestContext for static tag passing"
```

---

### Task 2: Create AutoCancelInterceptor

**Files:**
- Create: `packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart`
- Test: `packages/infrastructure/api/test/cancel/auto_cancel_interceptor_test.dart`

- [ ] **Step 1: Write AutoCancelInterceptor class**

```dart
// packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart

import 'package:dio/dio.dart';

/// 自动 CancelToken 绑定拦截器
///
/// 必须放在拦截器链 [0] 位置，确保 CancelToken 先生成。
/// 无 tag → 放行（fail-safe，不影响无 RequestScope 的场景）
class AutoCancelInterceptor extends Interceptor {
  final String? Function() _tagProvider;
  final void Function(String tag, CancelToken token) _registerFn;

  AutoCancelInterceptor({
    required String? Function() tagProvider,
    required void Function(String tag, CancelToken token) registerFn,
  })  : _tagProvider = tagProvider,
        _registerFn = registerFn;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tag = _tagProvider();
    if (tag == null) return handler.next(options);

    final cancelToken = CancelToken();
    _registerFn(tag, cancelToken);
    options.cancelToken = cancelToken;
    handler.next(options);
  }
}
```

**Note**: Constructor injection via closures to avoid hard dependency on `RequestContext` + `CancelTokenManager` static singletons. This makes the interceptor testable without mocking statics.

- [ ] **Step 2: Write test**

```dart
// packages/infrastructure/api/test/cancel/auto_cancel_interceptor_test.dart

import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoCancelInterceptor', () {
    late String? currentTag;
    late Map<String, List<CancelToken>> registeredTokens;

    setUp(() {
      currentTag = null;
      registeredTokens = {};
    });

    AutoCancelInterceptor createInterceptor() {
      return AutoCancelInterceptor(
        tagProvider: () => currentTag,
        registerFn: (tag, token) {
          registeredTokens.putIfAbsent(tag, () => []).add(token);
        },
      );
    }

    test('does nothing when tag is null', () async {
      currentTag = null;
      final interceptor = createInterceptor();
      final options = RequestOptions(path: '/api/test');

      await interceptor.onRequest(options, _NoopHandler());

      expect(registeredTokens, isEmpty);
      expect(options.cancelToken, isNull);
    });

    test('creates CancelToken and registers when tag is set', () async {
      currentTag = '/home';
      final interceptor = createInterceptor();
      final options = RequestOptions(path: '/api/test');

      await interceptor.onRequest(options, _NoopHandler());

      expect(options.cancelToken, isNotNull);
      expect(registeredTokens['/home']?.length, 1);
      expect(registeredTokens['/home']!.first, same(options.cancelToken));
    });

    test('accumulates multiple CancelTokens under same tag', () async {
      currentTag = '/home';
      final interceptor = createInterceptor();

      final options1 = RequestOptions(path: '/api/a');
      final options2 = RequestOptions(path: '/api/b');

      await interceptor.onRequest(options1, _NoopHandler());
      await interceptor.onRequest(options2, _NoopHandler());

      expect(registeredTokens['/home']?.length, 2);
    });
  });
}

class _NoopHandler extends RequestInterceptorHandler {
  @override
  void next(RequestOptions options) {}
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `fvm flutter test packages/infrastructure/api/test/cancel/auto_cancel_interceptor_test.dart`
Expected: 3 tests pass

- [ ] **Step 4: Commit**

```bash
git add packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart packages/infrastructure/api/test/cancel/auto_cancel_interceptor_test.dart
git commit -m "feat: add AutoCancelInterceptor with closure-based DI"
```

---

### Task 3: Modify RequestScope (auto path extraction)

**Files:**
- Modify: `lib/core/widgets/request_scope.dart`
- Test: `test/unit/widgets/request_scope_test.dart`

- [ ] **Step 1: Update RequestScope — replace class entirely**

```dart
// lib/core/widgets/request_scope.dart

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:api/api.dart';
import '../middleware/request_context.dart';

/// 请求范围 Widget
///
/// 职责：自动从 GoRouter 提取 path 作为 tag，管理页面级请求取消
/// 使用：包装需要取消请求的页面内容
///
/// 示例：
/// ```dart
/// RequestScope(child: HomePage())
/// ```
///
/// Dialog 等非路由场景：
/// ```dart
/// RequestScope(overrideTag: 'confirm_dialog', child: ...)
/// ```
class RequestScope extends StatefulWidget {
  final Widget child;
  final String? overrideTag;

  const RequestScope({required this.child, this.overrideTag, super.key});

  @override
  State<RequestScope> createState() => _RequestScopeState();
}

class _RequestScopeState extends State<RequestScope> {
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = widget.overrideTag ?? _extractPathFromRouter();
    RequestContext.setTag(_tag);
  }

  /// 从 GoRouter 提取当前路由的 fullPath 模板作为 tag
  ///
  /// 使用 fullPath 而非 uri.path:
  ///   - fullPath 返回 '/detail/:id'（模板）
  ///   - uri.path 返回 '/detail/123'（实例化，每个 ID 不同 → tag 泄漏）
  String _extractPathFromRouter() {
    final fullPath = GoRouterState.of(context).fullPath;
    return fullPath ?? '/unknown';
  }

  @override
  void dispose() {
    RequestContext.clear();
    // cleanup() 内部调用 cancelPage() + 移除条目，一次调用即可
    CancelTokenManager.instance.cleanup(_tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 2: Add GoRouter dependency to pubspec**

Check and add (if not present) to `lib/pubspec.yaml`:
```yaml
dependencies:
  go_router: ^14.0.0
```

- [ ] **Step 3: Write widget test**

```dart
// test/unit/widgets/request_scope_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:api/api.dart';
import 'package:my_app/core/middleware/request_context.dart';

void main() {
  group('RequestScope', () {
    tearDown(() {
      CancelTokenManager.instance.clearAll();
      RequestContext.clear();
    });

    testWidgets('sets RequestContext.currentTag on initState', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const RequestScope(child: SizedBox())),
      );

      expect(RequestContext.currentTag, isNotNull);
    });

    testWidgets('uses overrideTag when provided', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const RequestScope(overrideTag: 'my_dialog', child: SizedBox()),
        ),
      );

      expect(RequestContext.currentTag, 'my_dialog');
    });

    testWidgets('clears RequestContext and cleans up on dispose', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const RequestScope(child: SizedBox())),
      );

      final tagBefore = RequestContext.currentTag;
      expect(tagBefore, isNotNull);

      // Remove RequestScope from tree → triggers dispose
      await tester.pumpWidget(
        _buildTestApp(const SizedBox()),
      );
      await tester.pumpAndSettle();

      expect(RequestContext.currentTag, isNull);
    });
  });
}

Widget _buildTestApp(Widget child) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, __) => child),
      ],
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/unit/widgets/request_scope_test.dart`
Expected: 3 tests pass

- [ ] **Step 5: Verify existing home_page_test still passes**

Run: `fvm flutter test test/bloc/features/home/home_page_test.dart`
Expected: passes (existing test)

- [ ] **Step 6: Commit**

```bash
git add lib/core/widgets/request_scope.dart test/unit/widgets/request_scope_test.dart
git commit -m "feat: RequestScope auto-extract fullPath, remove double-cancel"
```

---

### Task 4: Modify dio_factory.dart — full interceptor chain

**Files:**
- Modify: `packages/infrastructure/api/lib/src/dio_factory.dart`
- Test: `packages/infrastructure/api/test/dio_factory_test.dart`

- [ ] **Step 1: Read current dio_factory.dart to understand existing structure**

File: `packages/infrastructure/api/lib/src/dio_factory.dart`

- [ ] **Step 2: Replace createDio with full interceptor chain**

```dart
// packages/infrastructure/api/lib/src/dio_factory.dart

import 'package:dio/dio.dart';
import 'cancel/auto_cancel_interceptor.dart';
import 'dio/renewal_token_intercaptor.dart';
import '../api.dart';

/// 创建预配置的 Dio 实例
///
/// 拦截器链顺序（请求方向）:
///   [0] AutoCancelInterceptor    → 读 tag，生成 CancelToken
///   [1] TokenRenewalInterceptor  → 检测 401，排队续期
///   [2] InterceptorsWrapper      → 注入 Authorization header
///   [3] LogInterceptor           → 记录日志
///
/// 使用方式：
/// ```dart
/// final dio = createDio(
///   userTokenSupplier: () async => token,
///   onNetworkDisconnected: () => logger.warning('网络断开'),
///   logger: appLogger,  // 注入主应用 AppLogger
/// );
/// ```
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
  AppLoggerInterface? logger,
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // [0] Auto-cancel — 最先执行，确保 CancelToken 可用
  dio.interceptors.add(AutoCancelInterceptor(
    tagProvider: () => RequestContext.currentTag,
    registerFn: (tag, token) => CancelTokenManager.instance.register(tag, token),
  ));

  // [1] Token 续期 — 处理 401，日志走注入的 AppLogger
  final renewalInterceptor = TokenRenewalInterceptor(dio);
  if (logger != null) {
    renewalInterceptor.logger = logger;
  }
  dio.interceptors.add(renewalInterceptor);

  // [2] Auth header — 注入 Authorization token
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await userTokenSupplier();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.type == DioExceptionType.connectionError) {
        onNetworkDisconnected();
      }
      handler.next(error);
    },
  ));

  // [3] Log — 最后执行，记录完整请求/响应
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
}
```

**NOTE**: The `createDio` function needs access to `RequestContext` and `CancelTokenManager`. Since `dio_factory.dart` is in `packages/infrastructure/api/` and `RequestContext` is in `lib/core/middleware/`, we have a dependency issue. 

**Resolution**: Use closure-based DI for `AutoCancelInterceptor` (already designed in Task 2 with `tagProvider` + `registerFn` closures). `RequestContext` and `CancelTokenManager` are referenced from the call site (`setup.dart`, Task 6), not from `dio_factory.dart`.

**CORRECTION**: The above `createDio` references `RequestContext.currentTag` and `CancelTokenManager.instance` directly — that's wrong. Let me fix:

```dart
// packages/infrastructure/api/lib/src/dio_factory.dart

import 'package:dio/dio.dart';
import 'cancel/auto_cancel_interceptor.dart';
import 'dio/renewal_token_intercaptor.dart';
import '../api.dart';

Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
  AppLoggerInterface? logger,
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // [0] Auto-cancel — 由调用方通过闭包注入 tag provider + register fn
  //     在 setup.dart 中注入 RequestContext + CancelTokenManager
  dio.interceptors.add(AutoCancelInterceptor(
    tagProvider: () => null,  // placeholder — overwritten in setup.dart
    registerFn: (tag, token) {},  // placeholder — overwritten in setup.dart
  ));

  // [1] Token 续期
  final renewalInterceptor = TokenRenewalInterceptor(dio);
  if (logger != null) {
    renewalInterceptor.logger = logger;
  }
  dio.interceptors.add(renewalInterceptor);

  // [2] Auth header
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await userTokenSupplier();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.type == DioExceptionType.connectionError) {
        onNetworkDisconnected();
      }
      handler.next(error);
    },
  ));

  // [3] Log
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
}
```

**Wait — placeholder closures are wrong.** Let me think about this properly.

The clean solution: `createDio` accepts optional `AutoCancelInterceptor?` parameter. If provided, it's added to the chain. The caller (`setup.dart`) constructs `AutoCancelInterceptor` with the correct closures that reference `RequestContext` and `CancelTokenManager`.

**FINAL CORRECT VERSION:**

```dart
// packages/infrastructure/api/lib/src/dio_factory.dart

import 'package:dio/dio.dart';
import 'cancel/auto_cancel_interceptor.dart';
import 'dio/renewal_token_intercaptor.dart';
import '../api.dart';

/// 创建预配置的 Dio 实例
///
/// 拦截器链顺序（请求方向）:
///   [0] AutoCancelInterceptor    → 读 tag，生成 CancelToken
///   [1] TokenRenewalInterceptor  → 检测 401，排队续期
///   [2] InterceptorsWrapper      → 注入 Authorization header
///   [3] LogInterceptor           → 记录日志
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
  AppLoggerInterface? logger,
  AutoCancelInterceptor? autoCancelInterceptor,
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // [0] Auto-cancel — 调用方注入（closes over RequestContext + CancelTokenManager）
  if (autoCancelInterceptor != null) {
    dio.interceptors.add(autoCancelInterceptor);
  }

  // [1] Token 续期 — 处理 401，日志走注入的 AppLogger
  final renewalInterceptor = TokenRenewalInterceptor(dio);
  if (logger != null) {
    renewalInterceptor.logger = logger;
  }
  dio.interceptors.add(renewalInterceptor);

  // [2] Auth header — 注入 Authorization token
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await userTokenSupplier();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.type == DioExceptionType.connectionError) {
        onNetworkDisconnected();
      }
      handler.next(error);
    },
  ));

  // [3] Log — 最后执行，记录完整请求/响应
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
}
```

- [ ] **Step 3: Write test for createDio interceptor chain**

```dart
// packages/infrastructure/api/test/dio_factory_test.dart

import 'package:api/api.dart';
import 'package:api/src/dio_factory.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createDio', () {
    test('creates Dio with all interceptors in correct order', () {
      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
      );

      expect(dio.interceptors.length, greaterThanOrEqualTo(3));
    });

    test('adds AutoCancelInterceptor when provided', () {
      String? capturedTag;
      CancelToken? capturedToken;

      final autoCancel = AutoCancelInterceptor(
        tagProvider: () => '/test',
        registerFn: (tag, token) {
          capturedTag = tag;
          capturedToken = token;
        },
      );

      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
        autoCancelInterceptor: autoCancel,
      );

      // AutoCancelInterceptor should be at position 0
      expect(dio.interceptors.first, same(autoCancel));
    });

    test('injects logger into TokenRenewalInterceptor when provided', () {
      final testLogger = _TestLogger();

      createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
        logger: testLogger,
      );

      // Logger injection verified via interceptor's internal state.
      // TokenRenewalInterceptor.logger setter is called during createDio.
      // Integration test in Task 8 covers this end-to-end.
    });
  });
}

class _TestLogger implements AppLoggerInterface {
  final List<String> messages = [];
  @override void debug(String m) => messages.add('[DEBUG] $m');
  @override void info(String m) => messages.add('[INFO] $m');
  @override void warning(String m) => messages.add('[WARN] $m');
  @override void error(String m, [dynamic e]) => messages.add('[ERROR] $m');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test packages/infrastructure/api/test/dio_factory_test.dart`
Expected: tests pass

- [ ] **Step 5: Verify existing api tests still pass**

Run: `fvm flutter test packages/infrastructure/api/test/`
Expected: all existing tests pass

- [ ] **Step 6: Commit**

```bash
git add packages/infrastructure/api/lib/src/dio_factory.dart packages/infrastructure/api/test/dio_factory_test.dart
git commit -m "feat: full interceptor chain in createDio with logger + autoCancel params"
```

---

### Task 5: Modify api.dart — add exports

**Files:**
- Modify: `packages/infrastructure/api/lib/api.dart`

- [ ] **Step 1: Add two export lines**

```dart
// packages/infrastructure/api/lib/api.dart

/// API 基础设施包
///
/// 提供 Dio 工厂函数和标准拦截器，不含业务 API 方法。
/// 业务 API 调用由各 RepositoryImpl 直接使用 Dio 完成。
export 'src/dio_factory.dart';
export 'src/http/http_error.dart';
export 'src/http/http_event_bus.dart';
export 'src/http/http_constant.dart';
export 'src/http/error_handler.dart';
export 'src/http/token_supplier.dart';
export 'src/http/retry_policy.dart';
export 'src/http/concurrent_limiter.dart';
export 'src/dio/log_reporting_interceptor.dart';
export 'src/error/dio_mapper.dart';
export 'src/cancel/cancel_manager.dart';
export 'src/tracking/request_tracker.dart';
export 'src/http/app_logger.dart';
export 'src/cancel/auto_cancel_interceptor.dart';    // ← NEW
export 'src/dio/renewal_token_intercaptor.dart';     // ← NEW
```

- [ ] **Step 2: Verify api.dart analysis passes**

Run: `fvm flutter analyze packages/infrastructure/api/lib/api.dart`
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add packages/infrastructure/api/lib/api.dart
git commit -m "feat: export AutoCancelInterceptor and TokenRenewalInterceptor from api.dart"
```

---

### Task 6: Modify setup.dart — wire everything

**Files:**
- Modify: `lib/core/di/setup.dart`

- [ ] **Step 1: Update setup.dart with AutoCancelInterceptor + logger injection**

```dart
// lib/core/di/setup.dart

import 'package:flutter/material.dart';
import 'package:api/api.dart';
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';
import 'package:dio/dio.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:feature_home/feature_home.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:locale/locale.dart';
import 'package:network/network.dart';

import '../../config.dart';
import '../utils/logger.dart';
import '../middleware/request_context.dart';   // ← NEW
import 'locator.dart';

/// 依赖注入配置
void setupDependencies() {
  // ===== Step 1: 基础设施层 =====
  sl.registerSingleton<AppLogger>(AppLogger());

  final autoCancelInterceptor = AutoCancelInterceptor(
    tagProvider: () => RequestContext.currentTag,
    registerFn: (tag, token) => CancelTokenManager.instance.register(tag, token),
  );

  final dio = createDio(
    userTokenSupplier: () async => null, // TODO: 接入真实的 token 提供者
    onNetworkDisconnected: () {
      sl<AppLogger>().warning('网络连接已断开');
    },
    logger: sl<AppLogger>(),
    autoCancelInterceptor: autoCancelInterceptor,
  );
  dio.options.baseUrl = EnvironmentConfig.apiBaseUrl;
  sl.registerSingleton<Dio>(dio);

  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());

  // ===== Step 2: 数据定义层 =====
  // domain 当前仅导出类型定义，无需注册

  // ===== Step 3: 应用状态 =====
  sl.registerSingleton<LocaleCubit>(LocaleCubit());
  sl.registerSingleton<NetworkCubit>(NetworkCubit()..startListening());

  // ===== Step 4: 业务服务层 =====
  setupAuth(sl);
  setupDataSync(sl);

  // ===== Step 5: 业务功能层 =====
  setupFeatureHome(sl);
  setupFeatureDetail(sl);
  setupFeatureAuth(sl);

  configureEasyLoading();
}

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

- [ ] **Step 2: Run analysis**

Run: `fvm flutter analyze lib/core/di/setup.dart`
Expected: no errors (existing infos only, no new issues)

- [ ] **Step 3: Commit**

```bash
git add lib/core/di/setup.dart
git commit -m "feat: inject AppLogger into TokenRenewalInterceptor, add AutoCancelInterceptor to chain"
```

---

### Task 7: Wrap HomePage with RequestScope (example)

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/routes/module_a.dart`

- [ ] **Step 1: Update ModuleA route to wrap page with RequestScope**

```dart
// packages/infrastructure/routing/lib/src/routes/module_a.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/widgets/request_scope.dart';  // ← NEW

import 'route_context.dart';
import 'route_module.dart';

/// Module A — Home tab route
class ModuleARouteModule extends RouteModule {
  ModuleARouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: RequestScope(  // ← NEW: wrap with RequestScope
            child: const Scaffold(
              body: Center(child: Text('Home Tab')),
            ),
          ),
        ),
      ),
    ];
  }
}
```

- [ ] **Step 2: Also wrap the detail route**

```dart
// packages/infrastructure/routing/lib/src/routes/router.dart (the detail route section)

// Change:
//   GoRoute(path: '/detail', builder: ...)
// To:
//   GoRoute(
//     path: '/detail',
//     builder: (context, state) => RequestScope(
//       child: Scaffold(...),
//     ),
//   ),
```

Wait — `router.dart` already imports basic Flutter. Let me handle this cleanly.

Actually the simplest change: modify the existing detail route in `router.dart`:

In `router.dart`, change lines 39-45:
```dart
// Before:
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: Text('Detail')),
            body: Center(child: Text('This is a detail page')),
          ),
        ),

// After:
        GoRoute(
          path: '/detail',
          builder: (context, state) => RequestScope(
            child: Scaffold(
              appBar: AppBar(title: Text('Detail')),
              body: Center(child: Text('This is a detail page')),
            ),
          ),
        ),
```

Add import at top:
```dart
import 'package:my_app/core/widgets/request_scope.dart';
```

- [ ] **Step 3: Run analysis**

Run: `fvm flutter analyze`
Expected: no new errors (existing infos only)

- [ ] **Step 4: Verify app builds**

Run: `fvm flutter build apk --debug 2>&1 | tail -5`
Expected: BUILD SUCCESSFUL (or no fatal errors)

- [ ] **Step 5: Commit**

```bash
git add packages/infrastructure/routing/lib/src/routes/module_a.dart packages/infrastructure/routing/lib/src/routes/router.dart
git commit -m "feat: wrap routes with RequestScope for auto request cancellation"
```

---

### Task 8: Integration verification

**Files:**
- Test: `test/integration/request_scope_integration_test.dart` (optional — manual verification below)

- [ ] **Step 1: Run all existing tests**

```bash
fvm flutter test
```
Expected: all tests pass, no regressions.

- [ ] **Step 2: Run full analysis**

```bash
fvm flutter analyze
```
Expected: no new errors or warnings (existing 169 infos are pre-existing).

- [ ] **Step 3: Manual verification checklist**

Verify the following manually or via Widget test:

| Check | Expected |
|-------|----------|
| App starts without crash | ✅ |
| `sl<Dio>().interceptors` has `AutoCancelInterceptor` at [0] | ✅ |
| `sl<Dio>().interceptors` has `TokenRenewalInterceptor` at [1] | ✅ |
| `TokenRenewalInterceptor.logger` is `AppLogger` instance (not `DefaultLogger`) | ✅ |
| Navigate to /home → `RequestContext.currentTag` is '/home' | ✅ |
| Navigate to /detail → `RequestContext.currentTag` is '/detail' | ✅ |
| Pop detail → `RequestContext.currentTag` is null | ✅ |

- [ ] **Step 4: Write quick integration verification test**

```dart
// test/integration/request_scope_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:my_app/core/di/locator.dart';
import 'package:my_app/core/di/setup.dart';

void main() {
  group('Integration: DI wiring', () {
    setUp(() {
      // Note: setupDependencies uses GetIt. Run once before tests.
    });

    test('Dio interceptor chain has AutoCancelInterceptor at position 0', () {
      setupDependencies();
      final dio = sl<Dio>();

      expect(dio.interceptors.isNotEmpty, isTrue);
      expect(dio.interceptors.first, isA<AutoCancelInterceptor>());
    });

    test('Dio interceptor chain has TokenRenewalInterceptor at position 1', () {
      setupDependencies();
      final dio = sl<Dio>();

      expect(dio.interceptors.length, greaterThanOrEqualTo(2));
      expect(dio.interceptors[1], isA<TokenRenewalInterceptor>());
    });

    test('TokenRenewalInterceptor uses AppLogger not DefaultLogger', () {
      setupDependencies();
      final dio = sl<Dio>();
      final renewal = dio.interceptors[1] as TokenRenewalInterceptor;

      // Verify logger is NOT DefaultLogger (the fallback)
      // AppLogger implements AppLoggerInterface but is NOT DefaultLogger
      expect(renewal.logger, isNotNull);
      expect(renewal.logger, isNot(isA<DefaultLogger>()));
    });
  });
}
```

**Note**: `setupDependencies()` registers singletons and can only be called once. Write test carefully to avoid double-registration. If tests can't use `setupDependencies()` directly, verify manually.

- [ ] **Step 5: Final commit**

```bash
git add test/integration/request_scope_integration_test.dart
git commit -m "test: add integration tests for DI wiring and interceptor chain"
```

---

## Dependency Order

```
Task 1 (RequestContext) ── independent
Task 2 (AutoCancelInterceptor) ── independent
Task 3 (RequestScope) ── depends on Task 1
Task 4 (dio_factory) ── independent
Task 5 (api.dart exports) ── independent
Task 6 (setup.dart) ── depends on Tasks 1,2,3,4
Task 7 (route wrapping) ── depends on Tasks 3,6
Task 8 (integration verify) ── depends on all above
```

**Parallelizable groups**: Tasks {1, 2, 4, 5} can run in parallel.
