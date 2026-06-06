# routing

GoRouter setup with RouteModule pattern.

## Architecture

```dart
// Create a route module
class MyRouteModule extends RouteModule {
  const MyRouteModule(super.ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/my-page',
        pageBuilder: (context, state) {
          final page = MyPage();
          return MaterialPage(child: wrap(page)); // ctx.routeWrapper 自动包一层
        },
      ),
    ];
  }
}

// Register via RouteModuleRegistry
RouteModuleRegistry.instance.register('my_feature',
    (ctx) => const MyRouteModule(ctx));

// Build in app.dart
routes: [
  ...RouteModuleRegistry.instance.get('my_feature', ctx),
],
```

## RouteModule.wrap

`wrap(Widget page)` 是 RouteModule 提供的统一模板,等价于:
```dart
final wrapper = ctx.routeWrapper;
if (wrapper == null) return page;
return wrapper(page);
```
所有 RouteModule 用 `wrap(page)` 替代手写 if/?? 模板。

## Directory Structure

```
routing/
├── lib/
│   ├── routing.dart                # 导出入口
│   ├── src/
│   │   ├── routes/
│   │   │   ├── route_module.dart           # RouteModule 基类 + wrap 模板
│   │   │   ├── route_context.dart          # RouteContext (navigatorKey, isLoggedInChecker, routeWrapper)
│   │   │   ├── route_module_registry.dart  # RouteModuleRegistry 单例
│   │   │   ├── feature_registry.dart       # FeatureRegistry (DI side)
│   │   │   └── app_routes.dart
│   │   ├── guards/
│   │   │   ├── auth_guard.dart             # AuthGuard.check (try-catch 兜底 + debugPrint)
│   │   │   └── public_routes.dart
│   │   ├── route_observer.dart
│   │   └── mixins/                     # 生命周期 mixins
│   │       ├── lifecycle_mixin.dart
│   │       ├── app_lifecycle_mixin.dart
│   │       └── full_lifecycle_mixin.dart
├── test/
│   ├── guards/
│   │   ├── auth_guard_path_test.dart
│   │   ├── auth_guard_error_test.dart       # P1-2 异常兜底
│   │   └── auth_guard_observability_test.dart # P3-7 debugPrint
│   ├── mixins/
│   │   ├── lifecycle_mixin_test.dart
│   │   ├── app_lifecycle_mixin_test.dart
│   │   └── full_lifecycle_mixin_test.dart
│   └── route_module_wrap_test.dart          # P2-5 wrap 模板
└── pubspec.yaml
```

## Auth Guard

路由守卫在 `src/guards/` 中：

```dart
// AuthGuard.check() 检查路由是否需要登录
// location 可含 query / fragment, 内部会先归一化
static String? check(String location, bool Function() isLoggedInChecker)
```

白名单路由在 `src/guards/public_routes.dart`：
```dart
const publicRoutes = {'/', '/home', '/login', '/register'};
```

未登录用户访问非白名单路由 → 重定向到 `/login?redirect=<原路径>`。

**路径归一化**: `AuthGuard.check` 会先剥掉 `?query` 和 `#fragment` 再做白名单匹配。
`/home?from=push` / `/home#section` 这种合法 query 串不再被误踢到 /login。
严格按 `Set.contains` 匹配: `/home/list` 不被 `/home` 覆盖（除非显式列入白名单）。

**异常兜底 (P1-2)**: `isLoggedInChecker` 抛异常时(启动期 AuthManager 未就位等),按"未登录"处理跳到 `/login`,避免白屏。

**可观测性 (P3-7)**: debug 模式下 `debugPrint` 记录每次路径检查的决定路径,线上可通过 Sentry 日志快速定位。

**GoRouter 刷新 (P1-3)**: `app.dart` 通过 `GoRouterRefreshStream` 监听 `AuthCubit.stream`,登出后自动 re-run redirect 跳到 `/login`。

启用控制：`RouteContext.enableAuthGuard`，debug/staging 默认启用，prod 可通过 `--dart-define=ENABLE_AUTH_GUARD=false` 关闭。

测试：
```bash
fvm flutter test test/guards/auth_guard_path_test.dart
```

详细指南：[docs/auth-route-guard.md](../../../docs/auth-route-guard.md)

## Mixins

### LifecycleMixin

页面生命周期 mixin（RouteAware），监听路由事件。

```dart
import 'package:routing/routing.dart';

class _EditPageState extends State<EditPage> with LifecycleMixin<EditPage> {
  @override
  void onPageEnter() {
    context.read<EditCubit>().loadData();  // 进入页面加载
  }
  
  @override
  void onPageLeave() {
    context.read<EditCubit>().saveData();  // 离开页面保存
  }
  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(title: '编辑', body: ...);
  }
}
```

回调：
- `onPageEnter()` — 进入页面（didPush）
- `onPageLeave()` — 离开页面（didPop）
- `onPageCovered()` — 被下一个页面覆盖（didPushNext）
- `onPageRevealed()` — 下一个页面 pop，重新显示（didPopNext）

---

### AppLifecycleMixin

App 级生命周期 mixin（WidgetsBindingObserver），监听前后台切换。

```dart
import 'package:routing/routing.dart';

class _VideoPlayerPageState extends State<VideoPlayerPage> 
    with AppLifecycleMixin<VideoPlayerPage> {
  
  @override
  void onAppPaused() {
    _controller.pause();  // App 后台暂停播放
  }
  
  @override
  void onAppResumed() {
    _controller.play();   // App 前台恢复播放
  }
}
```

---

### FullLifecycleMixin

完整生命周期 mixin（组合版）。

```dart
import 'package:routing/routing.dart';

class _VideoPageState extends State<VideoPage> with FullLifecycleMixin<VideoPage> {
  @override
  void onPageEnter() { _controller.play(); }
  @override
  void onPageLeave() { _controller.pause(); }
  @override
  void onAppPaused() { _controller.pause(); }
  @override
  void onAppResumed() { _controller.play(); }
}
```

适用：视频播放器、计时器、实时数据等需要完整监听的页面。
