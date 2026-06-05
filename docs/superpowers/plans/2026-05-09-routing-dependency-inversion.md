# Routing Dependency Inversion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the `routing` package's reverse dependencies on feature packages — each feature implements its own `RouteModule`, the assembly layer wires them into GoRouter.

**Architecture:** `routing` provides `RouteModule` abstract + `RouteContext` with generic callbacks only. Each `feature_*` creates its own `RouteModule` subclass. `app.dart` collects all modules and assembles GoRouter. `AuthGuard` uses `bool Function()` instead of `AuthManager`.

**Tech Stack:** Dart 3+, Flutter, GoRouter 14, flutter_bloc 9, Melos, GetIt DI

**Undo Plan:** All of Wave 1 is additive only — no old code removed. If Wave 1 commits cause issues, simply delete the new `*_route_module.dart` files and their barrel exports. Wave 2 (atomic transition) can be reverted by rolling back the single commit.

---
---

## Wave 1: Create Feature RouteModules (Additive — No Breaking Changes)

New RouteModule implementations added inside feature packages. Only ADD files and barrel exports. App continues compiling with old routing intact.

---

### Task 1: Write Failing Test — HomeRouteModule

**Files:**
- Create: `packages/features/feature_home/test/home_route_module_test.dart`

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_home/feature_home.dart';

void main() {
  group('HomeRouteModule', () {
    late RouteContext ctx;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUp(() {
      ctx = RouteContext(
        navigatorKey: navigatorKey,
        isLoggedInChecker: () => true,
      );
    });

    test('build returns list with one route for /home', () {
      final module = HomeRouteModule(ctx);
      final routes = module.build();
      expect(routes.length, 1);
    });

    test('route path is /home', () {
      final module = HomeRouteModule(ctx);
      final routes = module.build();
      final route = routes.first as GoRoute;
      expect(route.path, '/home');
    });

    test('pageBuilder creates NoTransitionPage', () {
      final module = HomeRouteModule(ctx);
      final routes = module.build();
      final route = routes.first as GoRoute;
      final page = route.pageBuilder(
        navigatorKey.currentContext!,
        GoRouterState.of(navigatorKey.currentContext!),
      );
      expect(page, isA<NoTransitionPage<void>>());
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd packages/features/feature_home && fvm flutter test test/home_route_module_test.dart
```
Expected: FAIL — `HomeRouteModule` not found.

- [ ] **Step 3: Commit**

```bash
git add packages/features/feature_home/test/home_route_module_test.dart
git commit -m "test(feature_home): add failing test for HomeRouteModule"
```

---

### Task 2: Implement HomeRouteModule

**Files:**
- Create: `packages/features/feature_home/lib/src/routes/home_route_module.dart`
- Modify: `packages/features/feature_home/lib/feature_home.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p packages/features/feature_home/lib/src/routes
```

- [ ] **Step 2: Write route module**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/home_cubit.dart';
import '../ui/home_page.dart';

/// Home route module — registers /home route
///
/// Uses GetIt to resolve HomeCubit (registered as Factory in setupFeatureHome).
/// Applies routeWrapper (RequestScope) if provided by RouteContext.
class HomeRouteModule extends RouteModule {
  HomeRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          Widget page = BlocProvider(
            create: (_) => GetIt.instance<HomeCubit>(),
            child: const HomePage(),
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
    ];
  }
}
```

- [ ] **Step 3: Export from barrel**

Add to end of `packages/features/feature_home/lib/feature_home.dart`:

```dart
export 'src/routes/home_route_module.dart';
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd packages/features/feature_home && fvm flutter test test/home_route_module_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/features/feature_home/lib/src/routes/ \
        packages/features/feature_home/lib/feature_home.dart
git commit -m "feat(feature_home): create HomeRouteModule"
```

---

### Task 3: Write Failing Test — AuthRouteModule

**Files:**
- Create: `packages/features/feature_auth/test/auth_route_module_test.dart`

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_auth/feature_auth.dart';

void main() {
  group('AuthRouteModule', () {
    late RouteContext ctx;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUp(() {
      ctx = RouteContext(
        navigatorKey: navigatorKey,
        isLoggedInChecker: () => false,
      );
    });

    test('build returns list with two routes', () {
      final module = AuthRouteModule(ctx);
      final routes = module.build();
      expect(routes.length, 2);
    });

    test('first route path is /login', () {
      final module = AuthRouteModule(ctx);
      final routes = module.build();
      final loginRoute = routes[0] as GoRoute;
      expect(loginRoute.path, '/login');
    });

    test('second route path is /register', () {
      final module = AuthRouteModule(ctx);
      final routes = module.build();
      final registerRoute = routes[1] as GoRoute;
      expect(registerRoute.path, '/register');
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd packages/features/feature_auth && fvm flutter test test/auth_route_module_test.dart
```
Expected: FAIL — `AuthRouteModule` not found.

- [ ] **Step 3: Commit**

```bash
git add packages/features/feature_auth/test/auth_route_module_test.dart
git commit -m "test(feature_auth): add failing test for AuthRouteModule"
```

---

### Task 4: Implement AuthRouteModule

**Files:**
- Create: `packages/features/feature_auth/lib/src/routes/auth_route_module.dart`
- Modify: `packages/features/feature_auth/lib/feature_auth.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p packages/features/feature_auth/lib/src/routes
```

- [ ] **Step 2: Write route module**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../ui/login_page.dart';
import '../ui/register_page.dart';

/// Auth route module — registers /login and /register routes
///
/// Both routes support ?redirect=<path> for post-login redirect.
/// Applies routeWrapper (RequestScope) if provided by RouteContext.
class AuthRouteModule extends RouteModule {
  AuthRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          Widget page = LoginPage(
            redirect: state.uri.queryParameters['redirect'],
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          Widget page = RegisterPage(
            redirect: state.uri.queryParameters['redirect'],
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: page,
          );
        },
      ),
    ];
  }
}
```

- [ ] **Step 3: Export from barrel**

Add to end of `packages/features/feature_auth/lib/feature_auth.dart`:

```dart
export 'src/routes/auth_route_module.dart';
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd packages/features/feature_auth && fvm flutter test test/auth_route_module_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/features/feature_auth/lib/src/routes/ \
        packages/features/feature_auth/lib/feature_auth.dart
git commit -m "feat(feature_auth): create AuthRouteModule"
```

---

### Task 5: Write Failing Test — DetailRouteModule

**Files:**
- Create: `packages/features/feature_detail/test/detail_route_module_test.dart`

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import 'package:feature_detail/feature_detail.dart';

void main() {
  group('DetailRouteModule', () {
    late RouteContext ctx;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUp(() {
      ctx = RouteContext(
        navigatorKey: navigatorKey,
        isLoggedInChecker: () => true,
      );
    });

    test('build returns list with two routes', () {
      final module = DetailRouteModule(ctx);
      final routes = module.build();
      expect(routes.length, 2);
    });

    test('first route path is /detail', () {
      final module = DetailRouteModule(ctx);
      final routes = module.build();
      final detailRoute = routes[0] as GoRoute;
      expect(detailRoute.path, '/detail');
    });

    test('second route path is /detail/:id', () {
      final module = DetailRouteModule(ctx);
      final routes = module.build();
      final detailWithIdRoute = routes[1] as GoRoute;
      expect(detailWithIdRoute.path, '/detail/:id');
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd packages/features/feature_detail && fvm flutter test test/detail_route_module_test.dart
```
Expected: FAIL — `DetailRouteModule` not found.

- [ ] **Step 3: Commit**

```bash
git add packages/features/feature_detail/test/detail_route_module_test.dart
git commit -m "test(feature_detail): add failing test for DetailRouteModule"
```

---

### Task 6: Implement DetailRouteModule

**Files:**
- Create: `packages/features/feature_detail/lib/src/routes/detail_route_module.dart`
- Modify: `packages/features/feature_detail/lib/feature_detail.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p packages/features/feature_detail/lib/src/routes
```

- [ ] **Step 2: Write route module**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/detail_cubit.dart';
import '../ui/detail_page.dart';

/// Detail route module — registers /detail and /detail/:id routes
///
/// Uses GetIt to resolve DetailCubit (registered as Factory in setupFeatureDetail).
class DetailRouteModule extends RouteModule {
  DetailRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/detail',
        builder: (context, state) => BlocProvider(
          create: (_) => GetIt.instance<DetailCubit>(),
          child: const DetailPage(),
        ),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return BlocProvider(
            create: (_) => GetIt.instance<DetailCubit>(),
            child: DetailPage(id: id),
          );
        },
      ),
    ];
  }
}
```

- [ ] **Step 3: Export from barrel**

Add to end of `packages/features/feature_detail/lib/feature_detail.dart`:

```dart
export 'src/routes/detail_route_module.dart';
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd packages/features/feature_detail && fvm flutter test test/detail_route_module_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/features/feature_detail/lib/src/routes/ \
        packages/features/feature_detail/lib/feature_detail.dart
git commit -m "feat(feature_detail): create DetailRouteModule"
```

---

## Wave 2: Atomic Transition — Switch from Old Routing to New

All changes in this wave committed together — intermediate state won't compile. The new RouteModules from Wave 1 already exist.

---

### Task 7: Atomic Switch — RouteContext, AuthGuard, Pubspec, app.dart, Delete Old Files, Update Barrels

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/routes/route_context.dart` (simplify)
- Modify: `packages/infrastructure/routing/lib/src/guards/auth_guard.dart` (callback)
- Modify: `packages/infrastructure/routing/pubspec.yaml` (remove deps)
- Modify: `lib/app.dart` (new assembly)
- Modify: `packages/infrastructure/routing/lib/src/routes/routes.dart` (update barrel)
- Modify: `packages/infrastructure/routing/lib/routing.dart` (update barrel)
- Modify: `packages/infrastructure/routing/lib/src/routes/app_router.dart` (update barrel)
- Delete: `packages/infrastructure/routing/lib/src/routes/module_a.dart`
- Delete: `packages/infrastructure/routing/lib/src/routes/module_b.dart`
- Delete: `packages/infrastructure/routing/lib/src/routes/router.dart`

- [ ] **Step 1: Simplify RouteContext**

Replace file `packages/infrastructure/routing/lib/src/routes/route_context.dart`:

```dart
import 'package:flutter/material.dart';

/// 路由上下文 — 封装每个页面构建时需要的通用依赖
///
/// 只提供基础设施级别的能力（navigator key、认证检查器、页面包装器）。
/// 业务依赖由各 feature 的 RouteModule 自行通过 DI 获取。
class RouteContext {
  final GlobalKey<NavigatorState> navigatorKey;

  /// 认证状态检查器（由 app 层注入 AuthManager.isLoggedIn）
  final bool Function()? isLoggedInChecker;

  final bool enableAuthGuard;

  /// 由 app 层提供的页面包装器，用于在每个路由页面上层包裹通用组件
  ///
  /// 典型用途：包装 RequestScope 实现页面级请求自动取消
  final Widget Function(Widget child)? routeWrapper;

  const RouteContext({
    required this.navigatorKey,
    this.isLoggedInChecker,
    this.enableAuthGuard = true,
    this.routeWrapper,
  });
}
```

- [ ] **Step 2: Simplify AuthGuard**

Replace file `packages/infrastructure/routing/lib/src/guards/auth_guard.dart`:

```dart
import 'public_routes.dart';

class AuthGuard {
  /// 检查路由是否需要登录
  ///
  /// [isLoggedInChecker] — 由 RouteContext 注入的认证状态回调
  /// [location] — 当前路由路径
  ///
  /// 返回 null 表示放行；返回重定向路径表示需要登录
  static String? check(String location, bool Function() isLoggedInChecker) {
    if (!isLoggedInChecker() && !publicRoutes.contains(location)) {
      return '/login?redirect=$location';
    }
    return null;
  }
}
```

- [ ] **Step 3: Clean pubspec**

Replace `dependencies:` block (lines 8-20) in `packages/infrastructure/routing/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.0
  go_router: ^14.2.7
```

- [ ] **Step 4: Rewrite app.dart**

Replace `_SpineFlutterState.initState()` (lines 39-62) in `lib/app.dart`:

```dart
  late final GoRouter _router;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // 构建路由上下文（仅基础设施级能力，无业务依赖）
    final config = sl<IAppConfig>();
    final ctx = RouteContext(
      navigatorKey: _navigatorKey,
      isLoggedInChecker: () => sl<AuthManager>().isLoggedIn,
      enableAuthGuard: config.enableAuthGuard,
      routeWrapper: (child) => RequestScope(child: child),
    );

    // 收集各 Feature 路由模块，在组装层统一注册
    _router = GoRouter(
      initialLocation: '/home',
      observers: [AppRouteObserver.instance],
      redirect: ctx.enableAuthGuard && ctx.isLoggedInChecker != null
          ? (context, state) {
              final location = state.matchedLocation;
              return AuthGuard.check(location, ctx.isLoggedInChecker!);
            }
          : null,
      routes: [
        StatefulShellRoute.indexedStack(
          pageBuilder: (context, state, navigationShell) {
            return NoTransitionPage(
              key: state.pageKey,
              child: Scaffold(
                body: navigationShell,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [...HomeRouteModule(ctx).build()],
            ),
            StatefulShellBranch(
              routes: [...AuthRouteModule(ctx).build()],
            ),
          ],
        ),
        ...DetailRouteModule(ctx).build(),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found')),
      ),
    );

    // Alice HTTP Inspector 设置 navigator key（仅 Debug 模式）
    if (kDebugMode && sl.isRegistered<Alice>()) {
      sl<Alice>().setNavigatorKey(_navigatorKey);
    }
  }
```

- [ ] **Step 5: Delete old router files**

```bash
rm packages/infrastructure/routing/lib/src/routes/module_a.dart
rm packages/infrastructure/routing/lib/src/routes/module_b.dart
rm packages/infrastructure/routing/lib/src/routes/router.dart
```

- [ ] **Step 6: Update routes.dart barrel**

Replace file `packages/infrastructure/routing/lib/src/routes/routes.dart`:

```dart
export 'route_module.dart';
export 'route_context.dart';
export 'app_routes.dart';
```

- [ ] **Step 7: Update routing.dart barrel**

Replace file `packages/infrastructure/routing/lib/routing.dart`:

```dart
export 'src/routes/route_module.dart';
export 'src/routes/route_context.dart';
export 'src/routes/app_routes.dart';
export 'src/guards/auth_guard.dart';
export 'src/guards/public_routes.dart';
export 'src/route_observer.dart';
export 'src/mixins/app_lifecycle_mixin.dart';
export 'src/mixins/lifecycle_mixin.dart';
export 'src/mixins/full_lifecycle_mixin.dart';
```

- [ ] **Step 8: Update app_router.dart**

Replace file `packages/infrastructure/routing/lib/src/routes/app_router.dart`:

```dart
/// ═══════════════════════════════════════════════════════════
/// 模块: 路由入口（向后兼容）
/// 文件: app_router.dart
/// 说明: 路由组装逻辑已迁移至 spine_flutter/lib/app.dart
///       RouteModule 实现已迁移至各 feature 包
/// ═══════════════════════════════════════════════════════════

export 'route_context.dart';
export 'route_module.dart';
```

- [ ] **Step 9: Run melos bootstrap**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && melos bootstrap
```
Expected: SUCCESS.

- [ ] **Step 10: Run melos validate**

```bash
melos run validate
```
Expected: all 4 steps pass (deps → l10n → analyze → test).

- [ ] **Step 11: Verify no feature imports in routing**

```bash
grep -r "feature_" packages/infrastructure/routing/lib/ --include="*.dart" || echo "Clean"
```
Expected: "Clean — no feature imports in routing"

- [ ] **Step 12: Verify routing pubspec is clean**

```bash
grep "feature_\|auth:" packages/infrastructure/routing/pubspec.yaml || echo "Clean"
```
Expected: "Clean — no feature deps"

- [ ] **Step 13: Commit the atomic transition**

```bash
git add packages/infrastructure/routing/lib/src/routes/route_context.dart \
        packages/infrastructure/routing/lib/src/guards/auth_guard.dart \
        packages/infrastructure/routing/pubspec.yaml \
        lib/app.dart \
        packages/infrastructure/routing/lib/src/routes/routes.dart \
        packages/infrastructure/routing/lib/routing.dart \
        packages/infrastructure/routing/lib/src/routes/app_router.dart \
        packages/infrastructure/routing/lib/src/routes/module_a.dart \
        packages/infrastructure/routing/lib/src/routes/module_b.dart \
        packages/infrastructure/routing/lib/src/routes/router.dart \
        pubspec.lock
git commit -m "refactor(routing): dependency inversion — remove feature reverse dependencies

- RouteContext simplified: isLoggedInChecker callback replaces AuthManager
- AuthGuard uses bool Function() instead of importing AuthManager
- routing/pubspec.yaml: removed auth, feature_home, feature_auth, feature_detail
- app.dart: direct GoRouter assembly with feature RouteModules
- Deleted: module_a.dart, module_b.dart, router.dart (migrated to features)"
```

---

## Wave 3: Cleanup

---

### Task 8: Delete feature_test_mason Package

**Files:**
- Delete: `packages/features/feature_test_mason/` (entire directory)

- [ ] **Step 1: Delete directory**

```bash
rm -rf packages/features/feature_test_mason
```

- [ ] **Step 2: Clean and rebuild**

```bash
melos clean && melos bootstrap
```
Expected: SUCCESS.

- [ ] **Step 3: Verify no remaining references**

```bash
grep -r "feature_test_mason" . --include="*.yaml" --include="*.dart" 2>/dev/null || echo "Clean"
```
Expected: "Clean — no references"

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: delete unused feature_test_mason package"
```

---

### Task 9: Final Verification

- [ ] **Step 1: Run standard validation**

```bash
melos run validate
```
Expected: all 4 steps pass (deps → l10n → analyze → test).

- [ ] **Step 2: Verify dependency direction**

```bash
./scripts/check_deps.sh
```
Expected: SUCCESS.

- [ ] **Step 3: Commit final verification**

```bash
git add -A
git commit -m "verify: final melos validate — routing dependency inversion complete"
```

---

## Verification Checklist

After all tasks complete:

- [ ] `packages/infrastructure/routing/pubspec.yaml` has NO `feature_*` or `auth` dependencies
- [ ] `packages/infrastructure/routing/lib/` has NO imports from `feature_*` packages
- [ ] `feature_home`, `feature_auth`, `feature_detail` each have `*_route_module.dart` in `lib/src/routes/`
- [ ] All 3 feature barrel files export their respective route module
- [ ] `lib/app.dart` collects all 3 RouteModules and assembles GoRouter in `initState()`
- [ ] `AuthGuard.check()` uses `bool Function()`, NOT `AuthManager` type
- [ ] `RouteContext` has NO imports from `feature_*` or `auth`
- [ ] `feature_test_mason/` deleted
- [ ] `melos run validate` passes (deps + l10n + analyze + test)
- [ ] All new route module tests pass (3 modules × 3 tests = 9 tests)
- [ ] All existing tests from before the refactoring still pass
