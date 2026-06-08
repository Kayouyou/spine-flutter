# 错误处理业务层串联 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Sentry 能真正接住业务层的运行时错误,而不是只收 Flutter 框架的同步 throw。

**Architecture:**
- 在 `AppErrorHandler` 暴露一个 `reportError(...)` 公共入口,所有调用方走它,内含 LRU 去重(16 项 × 1 秒窗)。
- `AppBlocObserver.onError` 与 `Dio` 错误拦截器都调 `AppErrorHandler.instance.reportError(...)`,并附带 `source: 'bloc' | 'dio'` 的 context,便于 Sentry 归因。
- 为遵守 **R3(infrastructure 不得依赖 services)**,Dio 拦截器不直接引用 `AppErrorHandler`,改用 `createDio(..., onDioError: callback)` 函数式注入,call-site(在 `lib/core/di/setup.dart`)负责把 callback 接到 `AppErrorHandler.instance.reportError`。

**Tech Stack:** Flutter 3.38 / Dart 3 / flutter_bloc 9 / dio 5 / sentry_flutter 8 / bloc_test / flutter_test。

---

## 0. 前提约束(不可违反)

| 约束 | 内容 | 出处 |
|---|---|---|
| **R3** | `infrastructure/api` **不得** `import` 任何 `services/...` 包 | `scripts/check_deps.sh:18-25` |
| **R10** | 全部 commit 走 Conventional Commits | `AGENTS.md §R10` |
| **业务范围** | 仅做 T1 的 2 条改动 + 1 个 LRU 去重,不做 T2/T3 | 用户 2026-06-08 决策 |
| **4xx 过滤** | Dio 错误里 4xx (400/401/403/404/422) **不**上报,5xx + 网络错误上报 | 用户 2026-06-08 决策 |

**R3 修正要点(已确认)**:
- `AppBlocObserver` 在 `lib/core/bloc/`,**可** import `package:error/error.dart`(`lib/core/startup/launcher.dart:13` 已 import 同样包)。
- `ErrorInterceptor` 在 `infrastructure/api`,**必须**通过 callback 注入。具体地,`createDio(...)` 加可选参数 `onDioError`,call-site(在 `lib/core/di/setup.dart:76`)传入 `(err, stack) => AppErrorHandler.instance.reportError(...)`。
- `lib/core/di/setup.dart` 在 app shell(根 `lib/`),依赖 services 合法。

---

## 1. 文件清单(8 个)

| 操作 | 路径 | 职责 |
|---|---|---|
| Modify | `packages/services/error/lib/src/error_handler.dart` | 加 LRU 集 + public `reportError` |
| Modify | `packages/services/error/test/error_handler_test.dart` | 扩展 4 个测试覆盖 `reportError` |
| Modify | `lib/core/bloc/app_bloc_observer.dart` | `onError` 改调 `AppErrorHandler.instance.reportError` |
| Create | `lib/core/bloc/app_bloc_observer_test.dart` | 验证 onError 上报 + context |
| Create | `packages/infrastructure/api/lib/src/dio/error_interceptor.dart` | Dio 错误拦截器 + 4xx 过滤 |
| Modify | `packages/infrastructure/api/lib/src/dio_factory.dart` | 加 `onDioError` 参数,注册 `ErrorInterceptor` |
| Modify | `packages/infrastructure/api/lib/api.dart` | export `error_interceptor.dart` |
| Create | `packages/infrastructure/api/test/dio/error_interceptor_test.dart` | 验证 5xx 上报 / 4xx 跳过 / 网络错 |
| Modify | `packages/infrastructure/api/test/dio_factory_test.dart` | 验证 `ErrorInterceptor` 在链中 |
| Modify | `lib/core/di/setup.dart` | `createDio` 调用传 `onDioError` 接到 `AppErrorHandler` |

---

## 2. 任务列表(7 个 Task,TDD 顺序)

### Task 1: 扩展 `error_handler_test.dart` — 写失败测试

**Files:**
- Modify: `packages/services/error/test/error_handler_test.dart`(已有 30 行)
- Modify(下个 task): `packages/services/error/lib/src/error_handler.dart`

- [ ] **Step 1.1: 把现有 `_TestReporter` 升级为可同时记录 `callCount`**

打开 `packages/services/error/test/error_handler_test.dart`,把 `_TestReporter` 改成:

```dart
class _TestReporter implements ErrorReporter {
  int callCount = 0;
  Object? lastError;
  StackTrace? lastStack;
  bool? lastFatal;
  Map<String, dynamic>? lastContext;

  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    callCount++;
    lastError = error;
    lastStack = stack;
    lastFatal = isFatal;
    lastContext = context;
  }
}
```

- [ ] **Step 1.2: 在文件末尾追加 4 个新测试**

紧接在 `test('ErrorReporter interface can be implemented', ...)` 之后追加:

```dart
group('AppErrorHandler.reportError', () {
  late AppErrorHandler handler;
  late _TestReporter reporter;

  setUp(() {
    // 用一个新的 handler 实例避免污染全局单例
    // 通过 package:error 暴露的 instance,测试中用 setReporter 覆盖前先清掉
    handler = AppErrorHandler.instance;
    reporter = _TestReporter();
    handler.setReporter(reporter);
  });

  tearDown(() {
    // 把 reporter 清空避免影响其他测试
    handler.setReporter(_NullReporter());
  });

  test('forwards error / stack / isFatal / context to reporter', () {
    final stack = StackTrace.current;
    handler.reportError(
      Exception('boom'),
      stack,
      isFatal: true,
      context: {'k': 'v'},
    );
    expect(reporter.callCount, 1);
    expect(reporter.lastError, isA<Exception>());
    expect(reporter.lastStack, same(stack));
    expect(reporter.lastFatal, isTrue);
    expect(reporter.lastContext, {'k': 'v'});
  });

  test('de-duplicates same hash within 1 second', () {
    final err = Exception('dup');
    final stack = StackTrace.current;
    handler.reportError(err, stack);
    handler.reportError(err, stack);
    handler.reportError(err, stack);
    expect(reporter.callCount, 1);
  });

  test('forwards same error after 1 second window', () async {
    final err = Exception('tick');
    handler.reportError(err, StackTrace.current);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    handler.reportError(err, StackTrace.current);
    expect(reporter.callCount, 2);
  });

  test('forwards different errors immediately', () {
    handler.reportError(Exception('a'), StackTrace.current);
    handler.reportError(Exception('b'), StackTrace.current);
    expect(reporter.callCount, 2);
  });
});

class _NullReporter implements ErrorReporter {
  @override
  Future<void> reportError(Object error, StackTrace? stack,
          {bool isFatal = false, Map<String, dynamic>? context}) async {}
}
```

> **注意**:`AppErrorHandler._reporter` 是 nullable 字段,但没有公开清空方法。我们用 `setReporter(_NullReporter())` 兜底,避免后续测试拿到旧 reporter。
> **同 hash 判定**:`error.runtimeType == error.runtimeType && error.toString() == error.toString() && stack == stack`。三个 Exception('dup') 的 `toString()` 完全相同(都是 `Exception: dup`),`runtimeType` 也相同,栈用同一个引用 → 视为同 hash。Task 2 实现时用 `Object.hash` + 1 秒窗做 dedup。

- [ ] **Step 1.3: 跑测试,确认 4 个新测试全部失败**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/services/error
flutter test test/error_handler_test.dart
```

预期:原有 2 个测试过,新增 4 个测试**全失败**(因为 `AppErrorHandler` 还没有 `reportError` 方法)。失败信息形如 `The method 'reportError' isn't defined for the type 'AppErrorHandler'`。

- [ ] **Step 1.4: 提交(测试已挂,作为基线)**

```bash
cd /Users/yeyangyang/Desktop/my_app
git add packages/services/error/test/error_handler_test.dart
git commit -m "test(error): cover AppErrorHandler.reportError LRU dedup"
```

---

### Task 2: 实现 `AppErrorHandler.reportError` + LRU 集

**Files:**
- Modify: `packages/services/error/lib/src/error_handler.dart`(62 行,改 ~25 行)

- [ ] **Step 2.1: 编辑 `error_handler.dart`,加 LRU 字段和 `reportError` 方法**

完整替换文件 `packages/services/error/lib/src/error_handler.dart` 为:

```dart
// packages/services/error/lib/src/error_handler.dart
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'error_reporter.dart';

/// 全局错误边界处理器
///
/// 安装后，所有 Flutter 框架和平台级别的未捕获错误
/// 都会通过 [onError] 回调被统一处理。
///
/// 业务代码可调用 [reportError] 上报自定义错误，
/// 内部使用 LRU 集(16 项 × 1 秒)对重复上报做去重。
///
/// 使用方式：
/// ```dart
/// AppErrorHandler.instance.setup(
///   onError: (error, stack) {
///     logger.error('未处理错误', error, stack);
///   },
/// );
///
/// // 注册 SentryReporter（DSN 不为空时）
/// if (EnvironmentConfig.sentryDsn.isNotEmpty) {
///   AppErrorHandler.instance.setReporter(SentryReporter());
/// }
///
/// // 业务层上报
/// AppErrorHandler.instance.reportError(
///   err,
///   stack,
///   isFatal: true,
///   context: {'source': 'dio', 'method': 'GET', 'url': '/api/x'},
/// );
/// ```
class AppErrorHandler {
  /// 单例实例
  static final instance = AppErrorHandler._();

  ErrorReporter? _reporter;

  /// LRU 去重表：hash -> 最后上报时间
  /// LinkedHashMap 默认按插入顺序迭代,evict 第一个 key 即最旧
  final LinkedHashMap<int, DateTime> _recentReports = LinkedHashMap();

  /// LRU 容量
  static const int _lruCapacity = 16;

  /// 去重时间窗
  static const Duration _dedupWindow = Duration(seconds: 1);

  /// 私有构造函数（单例模式）
  AppErrorHandler._();

  // ignore: use_setters_to_change_properties
  void setReporter(ErrorReporter reporter) {
    _reporter = reporter;
  }

  /// 安装全局错误处理器
  ///
  /// 应在 [runApp] 之前调用。
  /// [onError] 接收错误对象和调用栈。
  void setup({required void Function(Object error, StackTrace? stack) onError}) {
    FlutterError.onError = (FlutterErrorDetails details) {
      onError(details.exception, details.stack);
      _reporter?.reportError(
        details.exception,
        details.stack,
        isFatal: details.silent != true,
      );
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      onError(error, stack);
      _reporter?.reportError(error, stack, isFatal: true);
      return true;
    };
  }

  /// 上报一个错误到当前 [reporter]。
  ///
  /// 调用方应传入 [context] 标注错误来源(如 `{'source': 'dio'}`)。
  /// 内部用 (runtimeType, toString, stack) 算 hash,
  /// 在 [_dedupWindow] 内同一 hash 只会上报一次,避免 retry / 循环上报刷屏。
  void reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) {
    final hash = Object.hash(
      error.runtimeType,
      error.toString(),
      stack?.toString() ?? '',
    );
    final now = DateTime.now();
    final last = _recentReports[hash];
    if (last != null && now.difference(last) < _dedupWindow) {
      return;
    }
    _recentReports[hash] = now;
    if (_recentReports.length > _lruCapacity) {
      _recentReports.remove(_recentReports.keys.first);
    }
    // fire-and-forget：与 FlutterError.onError 内部行为保持一致
    // ignore: discarded_futures
    _reporter?.reportError(error, stack, isFatal: isFatal, context: context);
  }
}
```

> **`discarded_futures` 注释**:与现有 `_reporter?.reportError(...)` 在 `setup()` 里的用法一致(行 45、58 都是 fire-and-forget),保持 codebase 风格。
> **`noSuchMethod` / `intentional`**:无,纯新增字段和方法。

- [ ] **Step 2.2: 跑测试,确认 4 个新测试全过 + 原有 2 个测试不挂**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/services/error
flutter test test/error_handler_test.dart
```

预期:`+6 tests, all passed` (2 旧 + 4 新)。

- [ ] **Step 2.3: 跑 R3 守门(防止新 import 误伤)**

```bash
cd /Users/yeyangyang/Desktop/my_app
./scripts/check_deps.sh
```

预期:`✅ [R3] Infrastructure packages have no services dependencies`。

- [ ] **Step 2.4: 跑该包分析**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/services/error
flutter analyze --no-fatal-infos --no-fatal-warnings
```

预期:`No issues found!`。

- [ ] **Step 2.5: 提交**

```bash
cd /Users/yeyangyang/Desktop/my_app
git add packages/services/error/lib/src/error_handler.dart
git commit -m "feat(error): expose reportError with LRU dedup"
```

---

### Task 3: 写 `error_interceptor_test.dart` 失败测试

**Files:**
- Create: `packages/infrastructure/api/test/dio/error_interceptor_test.dart`
- Modify(下个 task): `packages/infrastructure/api/lib/src/dio/error_interceptor.dart`

- [ ] **Step 3.1: 创建测试目录与文件**

`packages/infrastructure/api/test/dio/` 已存在(`auto_cancel_interceptor_test.dart` 在同目录)。直接创建 `error_interceptor_test.dart`:

```dart
// packages/infrastructure/api/test/dio/error_interceptor_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:api/src/dio/error_interceptor.dart';

/// ErrorInterceptorHandler 是个具体类(不是 abstract),
/// 用最小 stub 实现它,只重写 next 让测试继续走通。
class _StubHandler extends ErrorInterceptorHandler {
  DioException? lastNextErr;

  @override
  void next(DioException err) {
    lastNextErr = err;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {}

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {}
}

class _Capture {
  final List<Map<String, dynamic>> contexts = [];
  final List<Object> errors = [];
  final List<StackTrace?> stacks = [];

  void call(Object err, StackTrace? stack, {Map<String, dynamic> context = const {}}) {
    errors.add(err);
    stacks.add(stack);
    contexts.add(context);
  }
}

DioException _makeErr({
  required String path,
  required String method,
  required DioExceptionType type,
  int? status,
}) {
  return DioException(
    requestOptions: RequestOptions(path: path, method: method),
    response: status == null
        ? null
        : Response(
            requestOptions: RequestOptions(path: path, method: method),
            statusCode: status,
          ),
    type: type,
  );
}

void main() {
  group('ErrorInterceptor.onError', () {
    test('reports 5xx with method/url/status context', () {
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);

      final err = _makeErr(
        path: '/api/orders',
        method: 'GET',
        type: DioExceptionType.badResponse,
        status: 500,
      );
      interceptor.onError(err, _StubHandler());

      expect(cap.errors, [err]);
      expect(cap.contexts, hasLength(1));
      final ctx = cap.contexts.first;
      expect(ctx['source'], 'dio');
      expect(ctx['method'], 'GET');
      expect(ctx['url'], '/api/orders');
      expect(ctx['status'], 500);
      expect(ctx['type'], 'badResponse');
    });

    test('skips 4xx (no report, but handler.next still called)', () {
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);
      final handler = _StubHandler();

      for (final code in [400, 401, 403, 404, 422]) {
        final err = _makeErr(
          path: '/api/x',
          method: 'POST',
          type: DioExceptionType.badResponse,
          status: code,
        );
        interceptor.onError(err, handler);
        // next 应被调,否则后续拦截器拿不到 error
        expect(handler.lastNextErr, same(err));
      }
      // 4xx 一律不上报
      expect(cap.errors, isEmpty);
    });

    test('reports network errors (no response, e.g. connectionError)', () {
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);

      final err = _makeErr(
        path: '/api/x',
        method: 'GET',
        type: DioExceptionType.connectionError,
      );
      interceptor.onError(err, _StubHandler());

      expect(cap.contexts, hasLength(1));
      final ctx = cap.contexts.first;
      expect(ctx['status'], isNull);
      expect(ctx['type'], 'connectionError');
      expect(ctx['source'], 'dio');
    });

    test('reports 5xx even when stackTrace is null', () {
      final cap = _Capture();
      final interceptor = ErrorInterceptor(onError: cap.call);

      final err = DioException(
        requestOptions: RequestOptions(path: '/api/x', method: 'GET'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/x'),
          statusCode: 503,
        ),
        type: DioExceptionType.badResponse,
        // stackTrace 默认 null
      );
      interceptor.onError(err, _StubHandler());

      expect(cap.contexts, hasLength(1));
      expect(cap.stacks.first, isNull);
    });
  });
}
```

- [ ] **Step 3.2: 跑测试,确认全部失败(模块还没实现)**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/infrastructure/api
flutter test test/dio/error_interceptor_test.dart
```

预期:失败,信息 `Target of URI doesn't exist: 'package:api/src/dio/error_interceptor.dart'`。

- [ ] **Step 3.3: 提交测试基线**

```bash
cd /Users/yeyangyang/Desktop/my_app
git add packages/infrastructure/api/test/dio/error_interceptor_test.dart
git commit -m "test(api): cover ErrorInterceptor 5xx/4xx/network filter"
```

---

### Task 4: 实现 `ErrorInterceptor` + 在 `dio_factory` 注册

**Files:**
- Create: `packages/infrastructure/api/lib/src/dio/error_interceptor.dart`
- Modify: `packages/infrastructure/api/lib/src/dio_factory.dart`(90 行,改 ~15 行)
- Modify: `packages/infrastructure/api/lib/api.dart`(加 1 行 export)

- [ ] **Step 4.1: 创建 `ErrorInterceptor`**

写入 `packages/infrastructure/api/lib/src/dio/error_interceptor.dart`:

```dart
// packages/infrastructure/api/lib/src/dio/error_interceptor.dart
import 'package:dio/dio.dart';

/// Dio 错误拦截器
///
/// 把 Dio 异常上报给上层(典型为 [AppErrorHandler.instance.reportError])。
/// 过滤规则：
///   - 4xx (400/401/403/404/422) **不上报**(业务期望错误,刷屏无意义)
///   - 5xx + 网络错误(connectionError / timeout / unknown / ...) **上报**
///
/// 使用 callback 注入是为了遵守 R3 规则：
/// infrastructure 包不依赖 services,所以这里不知道 AppErrorHandler 存在。
/// call-site(如 lib/core/di/setup.dart)负责把 onError 接到 AppErrorHandler。
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({required this.onError});

  /// 上报回调。签名与 AppErrorHandler.reportError 一致。
  final void Function(
    Object error,
    StackTrace? stack, {
    Map<String, dynamic> context,
  }) onError;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final is4xx = status != null && status >= 400 && status < 500;

    if (!is4xx) {
      onError(
        err,
        err.stackTrace,
        context: {
          'source': 'dio',
          'method': err.requestOptions.method,
          'url': err.requestOptions.uri.toString(),
          'status': status,
          'type': err.type.name,
        },
      );
    }

    // 必须继续 next,否则链路断在 ErrorInterceptor,后续拦截器(包括 LogInterceptor)看不到这个错误
    handler.next(err);
  }
}
```

- [ ] **Step 4.2: 跑 `error_interceptor_test.dart`,确认 4 个测试全过**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/infrastructure/api
flutter test test/dio/error_interceptor_test.dart
```

预期:`+4 tests, all passed`。

- [ ] **Step 4.3: 改 `dio_factory.dart`**

打开 `packages/infrastructure/api/lib/src/dio_factory.dart`,做 3 处修改:

**(a)** 在 import 区第 5 行下方加一行:

```dart
import 'dio/error_interceptor.dart';
```

**(b)** 顶部 docstring 改成(更新拦截器链描述):

```dart
/// 创建预配置的 Dio 实例
///
/// 拦截器链顺序（请求方向）:
///   [0] AutoCancelInterceptor    → 读 tag，生成 CancelToken
///   [1] TokenRenewalInterceptor  → 检测 code=1000102，排队续期
///   [2] InterceptorsWrapper    → 注入 Authorization header + 网络断开 callback
///   [3] ErrorInterceptor        → 5xx/网络错误上报(传入 onDioError 回调)
///   [4] LogInterceptor          → 记录日志（仅 Debug）
///   [5] AliceInterceptor        → HTTP Inspector（仅 Debug）
///
/// 使用方式：
/// ```dart
/// final dio = createDio(
///   userTokenSupplier: () async => token,
///   onNetworkDisconnected: () => logger.warning('网络断开'),
///   onDioError: (err, stack) => AppErrorHandler.instance.reportError(
///     err, stack, isFatal: true, context: {'source': 'dio', ...},
///   ),
///   logger: appLogger,
///   autoCancelInterceptor: myInterceptor,
///   tokenStorage: sl<TokenStorage>(),
///   alice: sl<Alice>(),
/// );
/// ```
```

**(c)** 在 `Dio createDio({...})` 签名里加 `onDioError` 参数:

```dart
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
  void Function(
    Object error,
    StackTrace? stack, {
    Map<String, dynamic> context,
  })? onDioError,
  AppLoggerInterface? logger,
  AutoCancelInterceptor? autoCancelInterceptor,
  TokenStorage? tokenStorage,
  Duration? connectTimeout,
  Duration? receiveTimeout,
  Alice? alice,
}) {
```

**(d)** 在 `dio.interceptors.add(InterceptorsWrapper(...))` 之后(也就是 LogInterceptor 之前)插入:

```dart
  // [3] Error — 5xx/网络错误上报(4xx 业务期望错误不上报)
  if (onDioError != null) {
    dio.interceptors.add(ErrorInterceptor(onError: onDioError));
  }
```

- [ ] **Step 4.4: 在 `api.dart` 加 export**

打开 `packages/infrastructure/api/lib/api.dart`,在 `// Phase 3d新增：日志接口` 之前加一行:

```dart
export 'src/dio/error_interceptor.dart';  // Phase x: Dio 错误拦截器(上报到 AppErrorHandler)
```

- [ ] **Step 4.5: 跑 `dio_factory_test.dart` 验证旧测试不挂**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/infrastructure/api
flutter test test/dio_factory_test.dart
```

预期:`+3 tests, all passed` (原有 3 个测试应该不挂,因为我用的是 `if (onDioError != null)` 守护,默认调用不传 → 不加 ErrorInterceptor → interceptor count 不变)。

- [ ] **Step 4.6: 跑 R3 守门**

```bash
cd /Users/yeyangyang/Desktop/my_app
./scripts/check_deps.sh
```

预期:`✅ [R3] Infrastructure packages have no services dependencies` — 即使加了 `ErrorInterceptor`,它不 import services,R3 不触发。

- [ ] **Step 4.7: 跑该包分析**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/infrastructure/api
flutter analyze --no-fatal-infos --no-fatal-warnings
```

预期:`No issues found!`。

- [ ] **Step 4.8: 提交**

```bash
cd /Users/yeyangyang/Desktop/my_app
git add packages/infrastructure/api/lib/src/dio/error_interceptor.dart \
        packages/infrastructure/api/lib/src/dio_factory.dart \
        packages/infrastructure/api/lib/api.dart
git commit -m "feat(api): add ErrorInterceptor with 4xx filter and callback injection"
```

---

### Task 5: 更新 `dio_factory_test.dart` + 验证 ErrorInterceptor 注入路径

**Files:**
- Modify: `packages/infrastructure/api/test/dio_factory_test.dart`

- [ ] **Step 5.1: 在 `dio_factory_test.dart` 末尾追加 2 个测试**

打开文件,在 `test('has TokenRenewalInterceptor in chain', ...)` 之后、`});` 之前追加:

```dart
    test('adds ErrorInterceptor when onDioError is provided', () {
      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
        onDioError: (_, __, {context = const {}}) {},
      );

      // ErrorInterceptor 必须在 TokenRenewal 之后、Log 之前(因 Log 是 [4])
      final errorIdx = dio.interceptors.indexWhere((i) => i is ErrorInterceptor);
      expect(errorIdx, greaterThan(0),
          reason: 'ErrorInterceptor should be in the chain');
    });

    test('omits ErrorInterceptor when onDioError is null', () {
      final dio = createDio(
        userTokenSupplier: () async => null,
        onNetworkDisconnected: () {},
      );

      final hasError =
          dio.interceptors.any((i) => i is ErrorInterceptor);
      expect(hasError, isFalse,
          reason: 'No callback → no ErrorInterceptor (R3 friendly)');
    });
```

需要加 import,在文件顶部 `import 'package:api/api.dart';` 之后追加:

```dart
import 'package:api/src/dio/error_interceptor.dart';
```

(`api.dart` 已经有 `export 'src/dio/error_interceptor.dart';` 在 Task 4.4 加的,所以 `import 'package:api/api.dart';` 本身就够了。Plan 里我保留 `import 'src/dio/error_interceptor.dart';` 因为它是 internal src,直接 import 更明确。)

- [ ] **Step 5.2: 跑全包测试**

```bash
cd /Users/yeyangyang/Desktop/my_app/packages/infrastructure/api
flutter test
```

预期:`+10 tests, all passed` (3 旧 dio_factory + 2 新 dio_factory + 4 error_interceptor + 1 token_renewal + 1 auto_cancel + refresh_api + refresh_queue)。

> 如果 token_renewal / auto_cancel / refresh_api / refresh_queue 任何测试挂,说明 `ErrorInterceptor` 的默认 nil 路径影响了别处。先单独跑失败的那个 test 排查,不要回退 ErrorInterceptor。

- [ ] **Step 5.3: 提交**

```bash
cd /Users/yeyangyang/Desktop/my_app
git add packages/infrastructure/api/test/dio_factory_test.dart
git commit -m "test(api): verify ErrorInterceptor is wired when onDioError provided"
```

---

### Task 6: 写 `app_bloc_observer_test.dart` 失败测试

**Files:**
- Create: `lib/core/bloc/app_bloc_observer_test.dart`
- Modify(下个 task): `lib/core/bloc/app_bloc_observer.dart`

- [ ] **Step 6.1: 创建测试文件**

`lib/` 根目前**没有** `test/` 目录(`ls lib/test/` 失败)。先建目录再写文件。

写入 `lib/core/bloc/app_bloc_observer_test.dart`:

```dart
// lib/core/bloc/app_bloc_observer_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:error/error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'app_bloc_observer.dart';

class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);
  void bang() => throw StateError('boom from cubit');
}

class _NullReporter implements ErrorReporter {
  final List<Object> errors = [];
  final List<StackTrace?> stacks = [];
  final List<Map<String, dynamic>?> contexts = [];

  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    errors.add(error);
    stacks.add(stack);
    contexts.add(context);
  }
}

void main() {
  group('AppBlocObserver.onError', () {
    late _NullReporter reporter;

    setUp(() {
      reporter = _NullReporter();
      AppErrorHandler.instance.setReporter(reporter);
    });

    test('forwards cubit error with bloc/source context', () {
      final observer = AppBlocObserver();
      final cubit = _TestCubit();
      final stack = StackTrace.current;

      observer.onError(cubit, StateError('boom from cubit'), stack);

      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first, isA<StateError>());
      expect(reporter.stacks.first, same(stack));
      expect(reporter.contexts.first, {
        'source': 'bloc',
        'bloc': '_TestCubit',
      });
    });
  });
}
```

- [ ] **Step 6.2: 跑测试,确认失败(observer 还没接)**

```bash
cd /Users/yeyangyang/Desktop/my_app
flutter test lib/core/bloc/app_bloc_observer_test.dart
```

预期:失败,信息形如 `Expected: hasLength(1) / Actual: 0` —— 因为 `AppBlocObserver.onError` 当前只 `debugPrint` 不调 `AppErrorHandler.instance.reportError`,所以 `reporter.errors` 始终是空,length 断言挂。

- [ ] **Step 6.3: 提交测试基线**

```bash
cd /Users/yeyangyang/Desktop/my_app
git add lib/core/bloc/app_bloc_observer_test.dart
git commit -m "test(app): cover AppBlocObserver.onError reporting to AppErrorHandler"
```

---

### Task 7: 实现 `AppBlocObserver.onError` + 接入 `setup.dart`

**Files:**
- Modify: `lib/core/bloc/app_bloc_observer.dart`(27 行,改 5 行)
- Modify: `lib/core/di/setup.dart`(124 行,改 ~15 行)

- [ ] **Step 7.1: 改 `app_bloc_observer.dart`**

完整替换文件 `lib/core/bloc/app_bloc_observer.dart` 为:

```dart
import 'package:error/error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 全局 Bloc 观察者
///
/// 职责：打印状态变化日志，捕获异常并上报到 AppErrorHandler
/// 使用：main.dart 启动前注册
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('[BlocObserver] onCreate: ${bloc.runtimeType}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('[BlocObserver] ${bloc.runtimeType}: ${transition.currentState} → ${transition.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('[BlocObserver] ${bloc.runtimeType} ERROR: $error');
    debugPrint(stackTrace.toString());
    AppErrorHandler.instance.reportError(
      error,
      stackTrace,
      isFatal: true,
      context: {
        'source': 'bloc',
        'bloc': bloc.runtimeType.toString(),
      },
    );
  }
}
```

- [ ] **Step 7.2: 跑 `app_bloc_observer_test.dart`,确认通过**

```bash
cd /Users/yeyangyang/Desktop/my_app
flutter test lib/core/bloc/app_bloc_observer_test.dart
```

预期:`+1 test, passed`。

- [ ] **Step 7.3: 改 `lib/core/di/setup.dart` 的 `createDio` 调用**

打开 `lib/core/di/setup.dart`,做 2 处修改:

**(a)** 在 import 区(`import 'package:dio/dio.dart';` 之后)加:

```dart
import 'package:error/error.dart';
```

**(b)** 在 `final dio = createDio(` 调用块(行 76-86),把 `onDioError` 参数加进去,完整替换为:

```dart
  final dio = createDio(
    userTokenSupplier: () => sl<TokenStorage>().getToken(),
    onNetworkDisconnected: () {
      sl<AppLogger>().warning('网络连接已断开');
    },
    onDioError: (err, stack) {
      AppErrorHandler.instance.reportError(
        err,
        stack,
        isFatal: true,
        context: {
          'source': 'dio',
          'method': (err as DioException).requestOptions.method,
          'url': err.requestOptions.uri.toString(),
          'status': err.response?.statusCode,
          'type': err.type.name,
        },
      );
    },
    logger: sl<AppLogger>(),
    autoCancelInterceptor: autoCancelInterceptor,
    tokenStorage: sl<TokenStorage>(),
    connectTimeout: Duration(seconds: config.networkTimeout),
    receiveTimeout: Duration(seconds: config.networkTimeout),
  );
```

> 类型说明:`createDio` 的 `onDioError` 签名是 `(Object error, StackTrace? stack, {Map<String, dynamic> context}) => void`,而 `DioException` 才是带 `requestOptions` 的具体类型,所以这里用 `as DioException` cast。`DioException` 已在 `import 'package:dio/dio.dart';` 暴露。

- [ ] **Step 7.4: 跑 R3 守门**

```bash
cd /Users/yeyangyang/Desktop/my_app
./scripts/check_deps.sh
```

预期:`✅ [R1] ✅ [R3] ✅ [R4] all pass`。**这里关键是 setup.dart 在 `lib/`,import services/error 合法,不会被 R3 拦**。

- [ ] **Step 7.5: 跑 lib/ 静态分析**

```bash
cd /Users/yeyangyang/Desktop/my_app
flutter analyze --no-fatal-infos --no-fatal-warnings
```

预期:`No issues found!`(只看 error,info/warning 忽略)。

- [ ] **Step 7.6: 跑 lib/ 受影响包测试**

```bash
cd /Users/yeyangyang/Desktop/my_app
melos test:affected
```

预期:所有受影响的包(至少 services/error、infrastructure/api、lib)的测试全过。

- [ ] **Step 7.7: 提交**

```bash
cd /Users/yeyangyang/Desktop/my_app
git add lib/core/bloc/app_bloc_observer.dart \
        lib/core/di/setup.dart
git commit -m "feat(app): route bloc and dio errors through AppErrorHandler"
```

---

## 3. 收尾验证(在最后一个 commit 之后跑一次)

- [ ] **Step 8.1: 全仓 melos validate**

```bash
cd /Users/yeyangyang/Desktop/my_app
melos validate
```

预期输出(`AGENTS.md §6.6.6`):
```
▸ Step 1: 依赖方向检查...
✅ [R1/R3/R4] all pass
▸ Step 2: 翻译一致性...
✅ (无 ARB 改动,跳过)
▸ Step 3: 静态分析 (仅拦 error)...
✅ No issues found!
▸ Step 4: 全量测试...
✅ all tests passed
✅ 全部通过 — 项目健康
```

- [ ] **Step 8.2: 人工 review diff 一遍**

```bash
cd /Users/yeyangyang/Desktop/my_app
git log --oneline -8        # 看 7 个 commit 的标题
git diff origin/main --stat # 看变更范围
git diff origin/main -- packages/services/error/lib/src/error_handler.dart \
                        lib/core/bloc/app_bloc_observer.dart \
                        packages/infrastructure/api/lib/src/dio/error_interceptor.dart \
                        packages/infrastructure/api/lib/src/dio_factory.dart \
                        lib/core/di/setup.dart
```

检查清单:
- 每个文件改动是否都对应 R3/spec 目标(没有"顺手 refactor")
- commit message 是否都符合 Conventional Commits
- 没有意外 commit `.env` / 密钥 / 临时文件

- [ ] **Step 8.3: 不主动 push / PR**

按 AGENTS.md §R10 + 8.3,本任务**不**自动 push / PR。用户明确要求时再 `git push -u origin <branch>`。

---

## 4. 不在本 plan 范围(留给后续 spec)

| # | 主题 | 备注 |
|---|---|---|
| 1 | Sentry options 补全(release/environment/beforeSend/attachStacktrace/sendDefaultPii) | 当前 `lib/core/startup/launcher.dart:75-80` 只设了 dsn+tracesSampleRate |
| 2 | DSN 空时降级到 ConsoleReporter | 当前 `launcher.dart:90` 无条件注册 SentryReporter,DSN 空时 Sentry SDK 内部静默 |
| 3 | `setReporter` 加守卫(防并发覆盖) | 当前可被覆盖多次,无锁 |
| 4 | `runZonedGuarded` 包整个 `runApp`(防止 PlatformDispatcher 漏接 zone error) | 当前 0 处使用,但 `PlatformDispatcher.onError` 已在 `error_handler.dart:56` 覆盖,优先级更低 |
| 5 | silent catch 加显式标记(replace `catch (_) {}` with `// silently ignored because <reason>`) | 全仓 91 处 try/catch 里有大量 `catch (_) {}`,需逐处判断 |
| 6 | Repository 层主动 `reportError`(目前只到 `AppBlocObserver.onError` + Dio 拦截器) | 业务 catch 后还应可选上报(分 `isFatal` 标志) |
| 7 | `error_handler.setup()` 现有行为补单测 | 当前 0 个 setup() 行为测试,本次 TDD 集中在 `reportError` |

每个主题开个独立 change:`openspec new change` → 设计 → plan → 实现。

---

## 5. Self-Review 记录(写完 plan 自查)

- **Spec 覆盖**:✅ AppErrorHandler LRU + 公共方法 / AppBlocObserver 改调 / ErrorInterceptor 4xx 过滤 / R3 合规 / 3 个测试文件
- **Placeholder 扫描**:无 "TBD/TODO/实现后/适当处理" 等占位
- **类型一致**:`reportError(Object error, StackTrace? stack, {bool isFatal, Map<String, dynamic>? context})` 在 `error_handler.dart`、`error_interceptor.dart`、`app_bloc_observer.dart` 三处签名一致;`onDioError` 在 `dio_factory.dart` 和 `setup.dart` 一致
- **R3 合规**:`infrastructure/api` 全程不 import services,只有 `lib/core/di/setup.dart`(app shell)调 `AppErrorHandler.instance.reportError`
- **依赖倒置**:`ErrorInterceptor` 不依赖 `AppErrorHandler` 类,只依赖一个 function signature,符合"infrastructure 不知道 service"原则

---

**Plan 完成,文件位于 `docs/superpowers/plans/2026-06-08-error-handler-business-layer.md`(7 个 Task + 3 步收尾 + 7 项遗留)。**

下一步执行方式二选一:
1. **Subagent-Driven**(推荐):每个 Task 派一个新 subagent 跑,Task 之间可审查,迭代快
2. **Inline Execution**:在当前会话里直接跑,有 checkpoint 可以暂停 review

请告诉我用哪种。
