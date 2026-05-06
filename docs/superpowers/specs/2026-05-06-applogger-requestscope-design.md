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
  │ AutoCancelInterceptor (新)     │ ← 从 options.extra['page_tag'] 读 tag
  ├──────────────────────────────┤ 或退 RequestContext.currentTag → 自动注册
  │ TokenRenewalInterceptor (改)   │ ← 日志改为 AppLogger (非 DefaultLogger)
  ├──────────────────────────────┤
  │ 其他拦截器                      │
  └──────────────────────────────┘

路由层:
  GoRoute.metadata = {'page_tag': 'home_page'}  ← 唯一定义点

Widget 层:
  RequestScope(tag: 'home_page')  ← initState 设置 RequestContext
    initState → RequestContext.setTag('home_page')
    dispose   → CancelTokenManager.cancelPage('home_page')
               + RequestContext.clear()

Repository 层:
  不需要手动注册 CancelToken ← 拦截器全包
  Dio 调用保持干净

兜底场景 (dialog/bottomSheet):
  RequestScope(tag: 'confirm_dialog', child: ...)
  → 设置 RequestContext → 拦截器读取
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

### 3.5 路由层 GoRoute pageBuilder 集成

`packages/infrastructure/routing/` 的 GoRoute 定义增加 `metadata: {'page_tag': 'xxx'}`，确保路由系统与 tag 单一数据源。

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

## 5. Tag 传递策略（混合方案）

### 5.1 Tag 常量管理

**文件**: `lib/core/constants/page_tags.dart`

```dart
class PageTags {
  // pages
  static const homePage = 'home_page';
  static const detailPage = 'detail_page';
  static const settingsPage = 'settings_page';
  // subpages
  static const authLoginPage = 'auth_login_page';
  static const authRegisterPage = 'auth_register_page';
  // dialogs/sheets
  static const confirmDialog = 'confirm_dialog';
  static const feedbackSheet = 'feedback_sheet';
}
```

**优势**: IDE 自动补全，编译期防拼错，集中管理避免重复。

### 5.2 主路径：GoRouter meta 自动提取

页面路由定义时携带 `page_tag` metadata：

```dart
// packages/infrastructure/routing/lib/src/routes/module_x.dart
GoRoute(
  path: '/home',
  name: 'home',
  pageBuilder: (context, state) => {
    metadata: {'page_tag': PageTags.homePage},  // ← 常量引用，IDE 补全
    child: RequestScope(
      tag: PageTags.homePage,                   // ← 同一常量
      child: BlocProvider(
        create: (_) => HomeCubit()..loadData(),
        child: const HomePage(),
      ),
    ),
  },
)
```

**AutoCancelInterceptor 读取来源**: 
- 优先从 Dio `options.extra['page_tag']` 读取（拦截器层面）
- 若未传，则从 `RequestContext.currentTag` 回退（RequestScope 设置的静态字段）

### 5.3 兜底路径：RequestScope 手动包裹

场景：`showDialog`、`showModalBottomSheet`、非 GoRouter 子页面

```dart
RequestScope(
  tag: PageTags.confirmDialog,
  child: SomeDialogContent(),
)
```

`RequestScope.initState()` → `RequestContext.setTag(widget.tag)`，拦截器读到静态字段。

### 5.4 原则

| 问题 | 答案 |
|---|---|
| Repository 需要手动注册 CancelToken 吗？ | **不需要**。拦截器全包 |
| 每个页面都要指定 tag 吗？ | **是**，通过 GoRouter route metadata + RequestScope |
| 忘记设 tag 会怎样？ | 请求正常发出，不被自动取消（fail-safe，不崩溃） |
| 后台请求（无页面）？ | 不调用拦截器或传空 tag → 不受影响 |

### 5.5 Tag 命名规范

| 格式 | 常量命名 | 值 |
|---|---|---|
| `feature_page` | `PageTags.homePage` | `'home_page'` |
| `feature_subpage` | `PageTags.authLoginPage` | `'auth_login_page'` |
| `dialog_component` | `PageTags.confirmDialog` | `'confirm_dialog'` |

常量集中管理，新增页面需在 `page_tags.dart` 添加条目。

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
| `packages/infrastructure/routing/` | 改 | GoRoute 增加 metadata.page_tag |

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

- `AutoCancelInterceptor` 单元测试: 有 tag 注册 / 无 tag 放行 / RequestContext 回退
- `TokenRenewalInterceptor` 集成测试: logger 输出走 AppLogger
- `RequestScope` Widget 测试: dispose 调用 cancelPage + RequestContext.clear()

---

## 10. FAQ

### Q: 每个页面都要手动指定 tag 吗？
A: 是。tag 通过 `PageTags` 常量统一管理，新增页面需在 `lib/core/constants/page_tags.dart` 添加条目。GoRouter `metadata` 和 `RequestScope` 都引用同一常量，确保一致性。

### Q: Repository 需要改吗？
A: 不需要。Repository 保持 `await dio.get('/path')` 干净写法，拦截器自动绑定 CancelToken。

### Q: 忘记设 tag 后果？
A: 请求照常在，只是页面退出时不会被自动取消。fail-safe 设计，不会崩溃。

### Q: 后台任务（推送、定时同步）需要 tag 吗？
A: 不需要。无 tag 的请求不受 AutoCancelInterceptor 影响。
