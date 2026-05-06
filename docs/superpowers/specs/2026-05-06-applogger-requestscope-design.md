# AppLogger + RequestScope 最佳实践设计

> 日期: 2026-05-06 | 版本: v2 (brainstorming 修订)
> 范围: AppLogger 完整注入 + RequestScope 自动取消 + Path-as-Tag 自动提取
> 架构: Clean Architecture + Feature-First Flutter 骨架

---

## 1. 问题陈述

### 1.1 AppLogger 缺失注入
- `TokenRenewalInterceptor` 使用 `DefaultLogger`（`debugPrint`）而非主 app 的 `AppLogger`
- 拦截器内有数十处 `_logger.xxx()` 调用，全部走默认回退
- 架构支持 setter 注入，但 `setup.dart` 未执行
- **根因**: `TokenRenewalInterceptor` 未加入 Dio 拦截器链（`dio_factory.dart` 只添加了 `InterceptorsWrapper` + `LogInterceptor`）

### 1.2 RequestScope 零使用
- `lib/core/widgets/request_scope.dart` 已定义，但无任何页面包裹
- `CancelTokenManager.register()` 仅在测试中调用，生产代码为零
- Repository 层无法自动绑定 tag 到请求

### 1.3 目标
- 拦截器链自动为请求绑定 CancelToken，Repository 无需手动注册
- `RequestScope` 包裹页面，dispose 时自动取消该页面所有未完成请求
- `AppLogger` 全局注入，拦截器日志走统一日志系统
- Path 自动作为 tag，零手动维护
- **StatefulShellRoute（Tab）**: 页面切换不触发 dispose，请求继续（符合预期）

---

## 2. 架构总览

```
路由层:
  GoRoute(path: '/detail/:id')  ← fullPath 模板作为 tag

Widget 层:
  RequestScope(child: HomePage())
    initState → 从 GoRouterState.fullPath 提取 → '/detail/:id' 作为 tag
    dispose  → RequestContext.clear() → CancelTokenManager.cleanup('home')

Dio 拦截器链 (顺序关键):
  [0] AutoCancelInterceptor → 读 RequestContext.currentTag → 创建 CancelToken 注册
  [1] TokenRenewalInterceptor → 401 自动续期，日志走注入的 AppLogger
  [2] InterceptorsWrapper → 注入 Authorization header
  [3] LogInterceptor → 调试日志

Repository 层:
  await dio.get('/api') ← 干净，拦截器自动绑定 CancelToken

兜底场景 (dialog):
  RequestScope(overrideTag: 'confirm_dialog', child: ...)
```

---

## 2.1 Token 取消流程（完整生命周期）

### 页面进入

```
Push GoRoute('/home')
    ↓
RequestScope.initState()
    ↓
GoRouterState.of(context).fullPath → '/home'
    ↓
RequestContext.setTag('/home')
```

### 发起请求

```
Repository: dio.get('/api/data')
    ↓
AutoCancelInterceptor.onRequest()
    ↓
tag = RequestContext.currentTag → '/home'
    ↓
创建 CancelToken → 注册到 CancelTokenManager
    ↓
Manager._tokens['/home'] = [CancelToken#1, #2, ...]  ← 同一页面多次请求累积
```

### 页面退出

```
Pop 页面 → RequestScope.dispose()
    ↓
RequestContext.clear()
    ↓
CancelTokenManager.cleanup('/home')
    ↓  内部: cancelPage('/home') → 遍历所有 CancelToken → 每个调用 .cancel()
    ↓       移除 _tokens['/home'] 条目
Dio 请求收到取消信号 → 中断 → DioException(type: cancel)
```

---

## 3. 组件设计

### 3.1 RequestContext (新建)

**文件**: `lib/core/middleware/request_context.dart`

```dart
/// 请求上下文 — 静态 tag 传递
///
/// 设计决策: 不用 Zone。GoRouter 一次只有一个页面在前台，静态字段足够。
/// 限制: 嵌套 RequestScope（如 dialog 覆盖页面）需要用 overrideTag，不要嵌套。
class RequestContext {
  static String? _currentTag;

  static void setTag(String tag) => _currentTag = tag;
  static String? get currentTag => _currentTag;
  static void clear() => _currentTag = null;
}
```

### 3.2 AutoCancelInterceptor (新建)

**文件**: `packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart`

```dart
/// 自动 CancelToken 绑定拦截器
///
/// 必须放在拦截器链 [0] 位置，确保 CancelToken 先生成。
/// 无 tag → 放行（fail-safe，不影响无 RequestScope 的场景）
class AutoCancelInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tag = RequestContext.currentTag;
    if (tag == null) return handler.next(options);

    final cancelToken = CancelToken();
    CancelTokenManager.instance.register(tag, cancelToken);
    options.cancelToken = cancelToken;
    handler.next(options);
  }
}
```

### 3.3 RequestScope (修改)

**文件**: `lib/core/widgets/request_scope.dart`

**关键改动**:
1. tag 参数改为可选 — 从 GoRouter 自动提取（`overrideTag` 用于 dialog 兜底）
2. Path 提取使用 `GoRouterState.fullPath`（模板），非 `uri.path`（实例化路径）
3. dispose 只调用 `cleanup()` — 避免 double-cancel（`cleanup` 内部已调用 `cancelPage`）

```dart
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

**对比原设计**:

| 问题 | 原 spec | 修复后 |
|------|---------|--------|
| Path 来源 | `uri.path` → 实例化路径 | `fullPath` → 路由模板 |
| `/detail/:id` 行为 | 每个 ID 不同 tag → 泄漏 | 共享 tag → 正确 |
| dispose | cancelPage + cleanup（double） | cleanup only |
| 参数 | `required this.tag` | `this.overrideTag?` 可选 |

### 3.4 TokenRenewalInterceptor

**无需修改源码**。已有 `set logger(AppLoggerInterface)` setter，通过 `createDio()` 工厂注入。

---

## 4. 拦截器链组装（dio_factory.dart 修改）

**决策**: 所有拦截器在 `createDio()` 中组装，不在 `setup.dart` 中后续修改。

**文件**: `packages/infrastructure/api/lib/src/dio_factory.dart`

```dart
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
  AppLoggerInterface? logger,  // ← 新增: 注入主应用 AppLogger
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // [0] Auto-cancel — 最先执行，确保 CancelToken 可用
  dio.interceptors.add(AutoCancelInterceptor());

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

**拦截器执行顺序（请求方向）**:
```
[0] AutoCancelInterceptor    → 读 tag，生成 CancelToken
[1] TokenRenewalInterceptor  → 检测 401，排队续期
[2] InterceptorsWrapper      → 注入 Authorization header
[3] LogInterceptor           → 记录日志
```

---

## 5. DI 注册（setup.dart 修改）

**文件**: `lib/core/di/setup.dart`

```dart
void setupDependencies() {
  sl.registerSingleton<AppLogger>(AppLogger());

  final dio = createDio(
    userTokenSupplier: () async => null,  // TODO: 接入真实的 token 提供者
    onNetworkDisconnected: () {
      sl<AppLogger>().warning('网络连接已断开');
    },
    logger: sl<AppLogger>(),  // ← 注入 AppLogger
  );
  dio.options.baseUrl = EnvironmentConfig.apiBaseUrl;
  sl.registerSingleton<Dio>(dio);

  // ... 其余不变
}
```

---

## 6. api.dart 导出补充

**文件**: `packages/infrastructure/api/lib/api.dart`

新增两行导出:

```dart
export 'src/cancel/auto_cancel_interceptor.dart';  // ← 新增
export 'src/dio/renewal_token_intercaptor.dart';     // ← 新增（原缺失）
```

---

## 7. Path-as-Tag 优势

| 维度 | Path 自动提取 (fullPath) | 手动定义 PageTags |
|---|---|---|
| 单一数据源 | ✅ path 即 tag | ❌ 双重维护 |
| 唯一性保证 | ✅ GoRouter 内置 | ❌ 需断言检测 |
| 维护成本 | ✅ 只改路由定义 | ❌ 加页面改两处 |
| 侵入性 | ✅ 零额外定义 | ❌ 需定义常量表 |

### 动态路由处理

```dart
GoRoute(path: '/detail/:id')
```

- `GoRouterState.fullPath` 返回 `'/detail/:id'`（模板）
- `/detail/123` 和 `/detail/456` 共享同一 tag
- 任一退出 → 全部取消（同一功能，符合预期）

---

## 8. AppLogger 使用规范

| 场景 | 方法 |
|---|---|
| 启动失败/崩溃 | `sl<AppLogger>().error()` |
| 网络/降级 | `sl<AppLogger>().warning()` |
| 性能/诊断 | `sl<AppLogger>().debug()` |
| 正常流程追踪 | `sl<AppLogger>().info()` |

环境适配:
- 开发: `minLevel = debug`
- 生产: `enableInProduction = false`, `minLevel = warning`

---

## 9. 改动文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/core/middleware/request_context.dart` | 新建 | 静态 tag 上下文 |
| `packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart` | 新建 | 自动 CancelToken 绑定 |
| `lib/core/widgets/request_scope.dart` | 改 | 自动提取 fullPath + overrideTag + 单次 cleanup |
| `packages/infrastructure/api/lib/src/dio_factory.dart` | 改 | 完整拦截器链 + logger 参数 |
| `packages/infrastructure/api/lib/api.dart` | 改 | 导出 AutoCancelInterceptor + TokenRenewalInterceptor |
| `lib/core/di/setup.dart` | 改 | 传递 logger 给 createDio |
| `packages/features/feature_home/lib/ui/home_page.dart` | 改 | 示例页面包裹 RequestScope |

---

## 10. 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| GoRouterState 不可用（非路由场景） | `fullPath` 返回 null | 兜底 `'/unknown'`；overrideTag 覆盖 |
| 嵌套 RequestScope | 内层覆盖外层 tag | `overrideTag` 机制 + 文档约定 |
| 拦截器顺序错误 | CancelToken 未绑定 | `createDio()` 内置顺序，不可外部修改 |
| StatefulShellRoute 不 dispose | Tab 切换不取消请求 | 符合预期 — 用户可能切回，请求继续 |
| 旧代码兼容性 | 无 tag 请求报错 | 无 tag → 放行，零影响 |
| `cleanup()` 幂等性 | 重复调用 | 安全 — Map.remove 幂等 |

---

## 11. 测试策略

- `AutoCancelInterceptor` 单元测试: 有 tag 注册 / 无 tag 放行 / CancelToken 正确绑定到 options
- `RequestContext` 单元测试: setTag / currentTag / clear 基本操作
- `RequestScope` Widget 测试: dispose 调用 cleanup + RequestContext.clear()
- `fullPath` 提取测试: `/home` → `'/home'`，`/detail/:id` → `'/detail/:id'`
- `createDio()` 集成测试: 拦截器链顺序正确，logger 注入生效
- `TokenRenewalInterceptor` 已有测试保持通过

---

## 12. FAQ

### Q: 每个页面都要手动指定 tag 吗？
A: **否**。RequestScope 自动从 GoRouterState.fullPath 提取。dialog 等非路由场景用 `overrideTag`。

### Q: Repository 需要改吗？
A: **不需要**。Repository 保持 `await dio.get('/path')` 干净写法。

### Q: 忘记包 RequestScope 会怎样？
A: 请求照常发出，tag 为空 → 不注册 CancelToken。fail-safe。

### Q: 动态路由 `/detail/:id` 怎么处理？
A: `fullPath` 返回模板 `'/detail/:id'`，所有详情页共享同一 tag。符合预期。

### Q: Tab 切换时请求会取消吗？
A: **否**。StatefulShellRoute 的 Tab 切换不触发 dispose。请求继续（用户可能切回）。

### Q: 后台任务（推送、定时同步）需要 tag 吗？
A: **不需要**。无 tag 的请求不受 AutoCancelInterceptor 影响。

### Q: TokenRenewalInterceptor 需要修改吗？
A: **不需要**。已有完整的 setter 注入机制，通过 `createDio(logger: ...)` 即可注入。

---

## 修订记录

| 版本 | 日期 | 变更 |
|------|------|------|
| v1 | 2026-05-06 | 初版 |
| v2 | 2026-05-06 | brainstorming 修订: 修复 fullPath、double-cancel、拦截器链组装、api.dart 导出、Tab 生命周期说明 |
