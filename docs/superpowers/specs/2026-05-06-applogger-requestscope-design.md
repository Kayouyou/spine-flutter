# AppLogger + RequestScope 最佳实践设计

> 日期: 2026-05-06
> 范围: AppLogger 完整注入 + RequestScope 自动取消 + Path-as-Tag 自动提取
> 架构: Clean Architecture + Feature-First Flutter 骨架

---

## 1. 问题陈述

### 1.1 AppLogger 缺失注入
- `TokenRenewalInterceptor` 使用 `DefaultLogger`（`debugPrint`）而非主 app 的 `AppLogger`
- 拦截器内有数十处 `_logger.xxx()` 调用，全部走默认回退
- 架构支持 setter 注入，但 `setup.dart` 未执行

### 1.2 RequestScope 零使用
- `lib/core/widgets/request_scope.dart` 已定义，但无任何页面包裹
- `CancelTokenManager.register()` 仅在测试中调用，生产代码为零
- Repository 层无法自动绑定 tag 到请求

### 1.3 目标
- 拦截器链自动为请求绑定 CancelToken，Repository 无需手动注册
- `RequestScope` 包裹页面，dispose 时自动取消该页面所有未完成请求
- `AppLogger` 全局注入，拦截器日志走统一日志系统
- Path 自动作为 tag，零手动维护

---

## 2. 架构总览

```
路由层:
  GoRoute(path: '/home')  ← path 本身就是 tag，无需额外定义

Widget 层:
  RequestScope(child: HomePage())
    initState → 自动从 GoRouter 提取 path → 'home' 作为 tag
    dispose  → CancelTokenManager.cancelPage('home')

Dio 拦截器链:
  AutoCancelInterceptor → 读 RequestContext.currentTag → 创建 CancelToken 注册

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
从 GoRouter 提取 path → 'home'
    ↓
RequestContext.setTag('home')
```

### 发起请求

```
Repository: dio.get('/api/data')
    ↓
AutoCancelInterceptor.onRequest()
    ↓
tag = RequestContext.currentTag → 'home'
    ↓
创建 CancelToken → 注册到 CancelTokenManager
    ↓
Manager._tokens['home'] = [CancelToken#1, #2, ...]  ← 同一页面多次请求累积
```

### 页面退出

```
Pop 页面 → RequestScope.dispose()
    ↓
CancelTokenManager.cancelPage('home')
    ↓
遍历 'home' 下所有 CancelToken → 每个调用 .cancel()
    ↓
Dio 请求收到取消信号 → 中断 → DioError(type: cancel)
    ↓
cleanup('home') → 移除条目
    ↓
RequestContext.clear()
```

**关键**: 同一页面多次请求 → 同一 tag 下多 CancelToken → 退出时批量取消。

---

## 3. 组件设计

### 3.1 RequestContext (新建)

**文件**: `lib/core/middleware/request_context.dart`

```dart
class RequestContext {
  static String? _currentTag;

  static void setTag(String tag) => _currentTag = tag;
  static String? get currentTag => _currentTag;
  static void clear() => _currentTag = null;
}
```

**决策**: 不用 Zone。GoRouter 一次只有一个页面在前台，静态字段足够。

### 3.2 AutoCancelInterceptor (新建)

**文件**: `packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart`

```dart
class AutoCancelInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tag = RequestContext.currentTag;
    if (tag == null) {
      return handler.next(options);  // 无 tag → 放行
    }

    final cancelToken = CancelToken();
    CancelTokenManager.instance.register(tag, cancelToken);
    options.cancelToken = cancelToken;
    handler.next(options);
  }
}
```

**逻辑**: 拦截器链头插入，从 RequestContext 读 tag，自动创建并注册 CancelToken。

### 3.3 TokenRenewalInterceptor (修改)

**改动**: 将默认 logger 注入 `sl<AppLogger>()`

**文件**: `lib/core/di/setup.dart` 增加注入逻辑

### 3.4 RequestScope (修改)

**文件**: `lib/core/widgets/request_scope.dart`

```dart
class RequestScope extends StatefulWidget {
  final Widget child;
  final String? overrideTag;  // dialog 兜底场景

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

  String _extractPathFromRouter() {
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    return path.replaceFirst('/', '');  // '/home' → 'home'
  }

  @override
  void dispose() {
    CancelTokenManager.instance.cancelPage(_tag);
    CancelTokenManager.instance.cleanup(_tag);
    RequestContext.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

---

## 4. 拦截器链组装

`lib/core/di/setup.dart` 改动:

```dart
// 插入 AutoCancelInterceptor 到链头
dio.interceptors.insert(0, AutoCancelInterceptor());

// 注入 AppLogger 到 TokenRenewalInterceptor
final interceptor = dio.interceptors
    .whereType<TokenRenewalInterceptor>()
    .first;
interceptor.logger = sl<AppLogger>();
```

---

## 5. Path-as-Tag 优势

| 维度 | Path 自动提取 | 手动定义 PageTags |
|---|---|---|
| 单一数据源 | ✅ path 即 tag | ❌ 双重维护 |
| 唯一性保证 | ✅ GoRouter 内置 | ❌ 需断言检测 |
| 维护成本 | ✅ 只改路由定义 | ❌ 加页面改两处 |
| 侵入性 | ✅ 零额外定义 | ❌ 需定义常量表 |

### 动态路由处理

```dart
GoRoute(path: '/detail/:id')
```

- path 模板 `'detail/:id'` 作为 tag
- `/detail/123` 和 `/detail/456` 共享同一 tag
- 任一退出 → 全部取消（同一功能，符合预期）

---

## 6. AppLogger 使用规范

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

## 7. 改动文件清单

| 文件 | 操作 | 说明 |
|---|---|---|
| `lib/core/middleware/request_context.dart` | 新建 | 静态 tag 上下文 |
| `packages/infrastructure/api/lib/src/cancel/auto_cancel_interceptor.dart` | 新建 | 自动 CancelToken 绑定 |
| `packages/infrastructure/api/lib/api.dart` | 改 | 导出 AutoCancelInterceptor |
| `lib/core/widgets/request_scope.dart` | 改 | 自动提取 path + overrideTag 兜底 |
| `lib/core/di/setup.dart` | 改 | 拦截器组装 + AppLogger 注入 |
| `lib/core/widgets/README.md` | 改 | 更新使用示例 |
| `packages/features/feature_home/lib/ui/home_page.dart` | 改 | 示例页面包裹 RequestScope |

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
|---|---|---|
| path 提取失败 | tag 为空 | 无 tag → 放行，请求不取消（fail-safe） |
| 多页面同时存在 | dispose 清理其他页面 tag | 实际不存在（单页面前台） |
| 拦截器顺序错误 | CancelToken 未绑定 | setup.dart 用 insert(0) 保证位置 |
| 旧代码兼容性 | 无 tag 请求报错 | 无 tag → 放行，零影响 |

---

## 9. 测试策略

- `AutoCancelInterceptor` 单元测试: 有 tag 注册 / 无 tag 放行
- `TokenRenewalInterceptor` 集成测试: logger 输出走 AppLogger
- `RequestScope` Widget 测试: dispose 调用 cancelPage + RequestContext.clear()
- Path 提取测试: `/home` → `'home'`，`/detail/:id` → `'detail/:id'`

---

## 10. FAQ

### Q: 每个页面都要手动指定 tag 吗？
A: **否**。RequestScope 自动从 GoRouter 提取 path 作为 tag。dialog 等非路由场景用 `overrideTag` 参数。

### Q: Repository 需要改吗？
A: **不需要**。Repository 保持 `await dio.get('/path')` 干净写法，拦截器自动绑定 CancelToken。

### Q: 忘记包 RequestScope 会怎样？
A: 请求照常发出，tag 为空 → 不注册 CancelToken → 页面退出时不取消。fail-safe，不崩溃。

### Q: 后台任务（推送、定时同步）需要 tag 吗？
A: **不需要**。无 tag 的请求不受 AutoCancelInterceptor 影响。

### Q: 动态路由 `/detail/:id` 怎么处理？
A: path 模板 `'detail/:id'` 作为 tag，所有详情页共享。任一退出 → 全部取消（同一功能，合理行为）。