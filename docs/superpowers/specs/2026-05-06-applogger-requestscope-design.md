# AppLogger + RequestScope 最佳实践设计

> 日期: 2026-05-06
> 范围: AppLogger 完整注入 + RequestScope 自动取消 + Tag 传递中间件
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

---

## 2. 架构总览

```
Dio 拦截器链 (从上往下):
  ┌──────────────────────────────┐
  │ AutoCancelInterceptor (新)     │ ← 从 options.extra 取 tag，自动创建 CancelToken
  ├──────────────────────────────┤
  │ TokenRenewalInterceptor (改)   │ ← 日志改为 AppLogger (非 DefaultLogger)
  ├──────────────────────────────┤
  │ 其他拦截器                      │
  └──────────────────────────────┘

Widget 层:
  RequestScope(tag: 'home_page')
    initState → RequestContext.setTag('home_page')
    dispose   → CancelTokenManager.cancelPage('home_page')

Repository 层:
  不需要手动注册 CancelToken ← 拦截器全包
  Dio 调用保持干净
```

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

- 拦截器优先级: `insert(0)` 插入链头
- 从 `options.extra['page_tag']` 读取 tag
- 无 tag → 放行（兼容旧代码/后台请求）
- 有 tag → 创建 `CancelToken` → `CancelTokenManager.register(tag, token)` → 写回 `options.cancelToken`

### 3.3 TokenRenewalInterceptor (修改)

**现有改动**: 将默认 logger 注入 `sl<AppLogger>()`

**文件改动**: `lib/core/di/setup.dart` 增加注入逻辑

### 3.4 RequestScope (修改)

**文件**: `lib/core/widgets/request_scope.dart`

改动:
- `initState` 中调用 `RequestContext.setTag(widget.tag)`
- `dispose` 中调用 `RequestContext.clear()` 再调用 manager

---

## 4. 拦截器链组装

`lib/core/di/setup.dart` 改动:

```dart
// 插入 AutoCancelInterceptor 到链头
dio.interceptors.insert(0, sl<AutoCancelInterceptor>());

// 注入 AppLogger 到 TokenRenewalInterceptor
final interceptor = dio.interceptors
    .whereType<TokenRenewalInterceptor>()
    .first;
interceptor.logger = sl<AppLogger>();
```

---

## 5. Tag 命名规范

| 格式 | 例子 |
|---|---|
| `feature_page` | `home_page`, `detail_page`, `settings_page` |
| `feature_subpage` | `auth_login_page`, `auth_register_page` |

tag 是纯字符串，无强制验证。错误拼写导致请求不被取消（无害失败）。

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
| `lib/core/widgets/request_scope.dart` | 改 | 增加 RequestContext 设置 |
| `lib/core/di/setup.dart` | 改 | 拦截器组装 + AppLogger 注入 |
| `lib/core/widgets/README.md` | 改 | 更新使用示例 |
| `packages/features/feature_home/lib/ui/home_page.dart` | 改 | 示例页面包裹 RequestScope |
| `lib/core/utils/logger.md` | 新建 | AppLogger 使用文档 |

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
|---|---|---|
| tag 拼写错误 | 请求不被取消 | 无害失败，不影响功能 |
| 多页面同时存在 | dispose 清理其他页面 tag | 实际不存在（单页面前台） |
| 拦截器顺序错误 | CancelToken 未绑定 | setup.dart 用 insert(0) 保证位置 |
| 旧代码兼容性 | 无 tag 请求报错 | 无 tag → 放行，零影响 |

---

## 9. 测试策略

- `AutoCancelInterceptor` 单元测试: 有 tag 注册 / 无 tag 放行
- `TokenRenewalInterceptor` 集成测试: logger 输出走 AppLogger
- `RequestScope` Widget 测试: dispose 调用 cancelPage
