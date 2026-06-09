# Auth Route Guard

## 概述

路由守卫保护需要登录的路由，未登录用户访问时自动重定向到登录页。

## 启用控制

| 环境 | 默认启用 |
|------|----------|
| debug | ✓ |
| staging | ✓ |
| prod | 可配置（`--dart-define=ENABLE_AUTH_GUARD=false`） |

在 `lib/core/config/app_config.dart` 中：
```dart
bool get enableAuthGuard => EnvironmentConfig.enableAuthGuard;
```

## 白名单路由

```dart
// packages/infrastructure/routing/lib/src/guards/public_routes.dart
const publicRoutes = {'/', '/home', '/login', '/register'};
const publicRoutePrefixes = <String>{};
```

无需登录即可访问。

## 前缀匹配

默认使用精确匹配（`Set.contains`）。如果需要某个路径前缀下的所有子路由都公开：

```dart
const publicRoutePrefixes = <String>{'/public/'};
```

`/public/abc`、`/public/xyz/123` 都会放行。默认空集合，不影响现有行为。

## Redirect 处理

访问 `/profile` 未登录 → `/login?redirect=/profile`

登录成功后自动跳转回原路径。query 和 fragment 也会保留：
- `/settings?tab=security` → `/login?redirect=/settings?tab=security`
- `/home#section` → 正常放行（白名单内）

## 异常兜底

如果 `isLoggedInChecker` 抛异常（启动期 AuthManager 未就绪等）：
- 白名单路径 → 正常放行
- 非白名单路径 → 按未登录处理，跳 `/login`

不会白屏，不会崩溃。

## 可观测性

Debug 模式下打印每次检查的决定路径：
```
🛡️ [AuthGuard] path=/profile isLoggedIn=false isPublic=false → redirect /login
🛡️ [AuthGuard] path=/home isLoggedIn=false isPublic=true → allow
```

## 路由组装

在 `lib/app.dart` 中：
```dart
GoRouter(
  refreshListenable: GoRouterRefreshStream(sl<AuthCubit>().stream),
  redirect: (context, state) {
    return AuthGuard.check(state.matchedLocation, () => sl<AuthManager>().isLoggedIn);
  },
);
```

`refreshListenable` 监听 AuthCubit 状态变化，登出时自动触发路由刷新。

## 自定义守卫

如需其他守卫（如权限检查），在 `RouteModule.build()` 中给路由加 `redirect`：

```dart
GoRoute(
  path: '/admin',
  builder: (_, __) => AdminPage(),
  redirect: (context, state) {
    if (!sl<AuthManager>().isAdmin) return '/home';
    return null;
  },
);
```

## 测试

```bash
# 路径匹配测试
fvm flutter test packages/infrastructure/routing/test/guards/auth_guard_path_test.dart

# 异常兜底测试
fvm flutter test packages/infrastructure/routing/test/auth_guard_error_test.dart

# 可观测性测试
fvm flutter test packages/infrastructure/routing/test/auth_guard_observability_test.dart
```
