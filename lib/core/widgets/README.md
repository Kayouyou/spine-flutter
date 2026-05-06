# 通用组件模块

## 职责
提供跨Feature共享的通用UI组件。

## 组件列表

### RequestScope
请求范围管理Widget，自动从GoRouter提取路由path作为tag，页面退出时自动取消未完成请求。

```dart
RequestScope(
  child: DetailContent(),   // tag 自动从 GoRouterState.fullPath 提取
)
```

Dialog等非路由场景使用 overrideTag：
```dart
RequestScope(
  overrideTag: 'confirm_dialog',
  child: AlertDialog(...),
)
```

### NetworkBanner（Phase 3.3）
网络状态提示Banner。

## 使用示例
```dart
// 在路由页面顶层自动包裹（通过 routeWrapper）
// app.dart 中：
routeWrapper: (child) => RequestScope(child: child),

// 页面内无需手动添加，tag 自动从 GoRouterState.fullPath 提取
```

## 实现原理
```
页面进入 → RequestScope.initState()
         → GoRouterState.of(context).fullPath → '/home' 作为 tag
         → RequestContext.setTag('/home')

发起请求 → AutoCancelInterceptor.onRequest()
         → 读 RequestContext.currentTag
         → 创建 CancelToken → 注册到 CancelTokenManager

页面退出 → RequestScope.dispose()
         → RequestContext.clear()
         → CancelTokenManager.cleanup(tag) → 取消所有未完成请求
```

## 依赖关系
- api: CancelTokenManager, AutoCancelInterceptor
- go_router: GoRouterState.fullPath
- core/middleware: RequestContext

## 性能警告
- RequestScope仅管理请求取消，不影响UI渲染性能
- 避免过度嵌套Stack层叠
- StatefulShellRoute（Tab）切换不触发 dispose，请求继续（符合预期）
