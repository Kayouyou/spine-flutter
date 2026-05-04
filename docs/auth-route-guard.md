# Auth Route Guard

## 概述

路由守卫保护需要登录的路由，未登录用户访问时自动重定向到登录页。

## 启用控制

| 环境 | 默认启用 |
|------|----------|
| debug | ✓ |
| staging | ✓ |
| prod | 可配置（`--dart-define=ENABLE_AUTH_GUARD=false`） |

## 白名单路由

```dart
const publicRoutes = {'/', '/home', '/login', '/register'};
```

无需登录即可访问。

## Redirect 处理

访问 `/profile` 未登录 → `/login?redirect=/profile`

登录成功后自动跳转回原路径。

## 自定义白名单

编辑 `packages/infrastructure/routing/lib/src/guards/public_routes.dart`。

## 测试

```bash
fvm flutter test test/unit/routing/auth_guard_test.dart
```
