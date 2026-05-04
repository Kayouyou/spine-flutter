# routing

GoRouter setup with RouteModule pattern.

## Architecture

```dart
// Create a route module
class MyRouteModule extends RouteModule {
  MyRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/my-page',
        builder: (context, state) => MyPage(),
      ),
    ];
  }
}

// Register in router
routes: [...MyRouteModule(ctx).build()],
```

RouteContext bundles dependencies for route modules.
Add your repositories to RouteContext as needed.

## Auth Guard

路由守卫在 `src/guards/` 中：

```dart
// AuthGuard.check() 检查路由是否需要登录
static String? check(String location, AuthManager auth)
```

白名单路由在 `src/guards/public_routes.dart`：
```dart
const publicRoutes = {'/', '/home', '/login', '/register'};
```

未登录用户访问非白名单路由 → 重定向到 `/login?redirect=<原路径>`。

启用控制：`RouteContext.enableAuthGuard`，debug/staging 默认启用，prod 可通过 `--dart-define=ENABLE_AUTH_GUARD=false` 关闭。

测试：
```bash
fvm flutter test test/unit/routing/auth_guard_test.dart
```

详细指南：[docs/auth-route-guard.md](../../../docs/auth-route-guard.md)
