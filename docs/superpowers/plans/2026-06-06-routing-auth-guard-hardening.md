# 路由 + AuthGuard 链路硬化计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `2026-06-06` 路由 + AuthGuard 链路深度分析里识别的 7 个弱点（P0-1 ~ P3-7）按 ROI 排序落到代码：先修 UX bug、错误处理、登录态不刷新三个高优先级，再做 RequestContext 加固、模板收敛，最后补集成测试。

**Architecture:**
- 6 phase 顺序：P0-1 → P1-2/P3-7 → P1-3 → P2-4 → P2-5 → P3 测试
- 不引入新依赖：所有改动走现有 `go_router: ^14.x` + `flutter_bloc: ^9.x` + `routing` 包 + `services/auth` 包
- 每个 phase 走"测试先行（单测/widget test/集成 test）→ 改实现 → 跑过 → commit"
- 严格不破坏现有 `AuthGuard` 单测（`2026-06-06-di-hardening.md` 已加的 `auth_guard_path_test.dart`）、不破坏 5 个 feature 的现有 widget test

**Tech Stack:** Flutter 3.38.10 (FVM stable) / Dart 3.x / `go_router: ^14.2.7` / `flutter_bloc: ^9.0.0` / `routing` (infrastructure) / `services/auth` / `bloc_test: ^10.0.0` / `mocktail: ^1.0.4` / melos / Conventional Commits

---

## 前置：上下文

**分析文档来源**：本会话 `2026-06-06` 路由 + AuthGuard 链路两轮分析（启动期 + 闭包链 + 弱点清单 + 评分 7.1/10），完整结论在压缩上下文 (b1) 里。

**当前已知问题**（按 ROI 排序）：

| # | 等级 | 弱点 | 影响 |
|---|------|------|------|
| 1 | 🔴 P0-1 | `/login`、`/register` 注册在 `StatefulShellBranch` 内 | 未登录用户看到 tab 底栏（NavigationBar 仍渲染） |
| 2 | 🟠 P1-2 | `redirect` 闭包无 try-catch | 启动崩溃 → 路由白屏 |
| 3 | 🟠 P1-3 | 登录态变化不重跑 redirect（缺 `refreshListenable`） | 登出 UI 不自动跳 `/login` |
| 4 | 🟡 P2-4 | `RequestContext.tag` 静态字段在嵌套/dialog 场景脆弱 | 嵌套 `RequestScope` 时 tag 串位 |
| 5 | 🟡 P2-5 | 5 个 `RouteModule` 重复 `if (ctx.routeWrapper != null) page = ctx.routeWrapper!(page);` 模板 | 改包装器要同步 5 处，遗漏高 |
| 6 | 🟡 P2-6 | `FeatureRegistry` vs `RouteModuleRegistry` 模板重复 | 语义不同（DI vs 路由），**不动** |
| 7 | 🟢 P3-7 | `AuthGuard` 无 observability / `public_routes` module-private | 线上 redirect 失败无信号 |

**P2-6 不在本 plan 范围**（见末尾"不在本 plan 范围内"）。

---

## 文件结构

| Category | File | Responsibility |
|----------|------|----------------|
| **修改** | `lib/app.dart` | P0-1 拆分支 / P1-3 注入 `refreshListenable` / P1-2 redirect 闭包 try-catch |
| **修改** | `packages/infrastructure/routing/lib/src/guards/auth_guard.dart` | P3-7 加 `debugPrint` 记录拒绝/放行 |
| **修改** | `packages/infrastructure/routing/lib/src/routes/route_module.dart` | P2-5 加 `wrap(Widget page)` 模板方法 |
| **修改** | `packages/features/feature_auth/lib/src/routes/auth_route_module.dart` | P0-1 不再返回 GoRoute（挪到 app.dart）/ P2-5 用模板 |
| **修改** | `packages/features/feature_home/lib/src/routes/home_route_module.dart` | P2-5 用模板 |
| **修改** | `packages/features/feature_detail/lib/src/routes/detail_route_module.dart` | P2-5 用模板 |
| **修改** | `lib/core/widgets/request_scope.dart` | P2-4 嵌套时保存/恢复外层 tag |
| **修改** | `lib/core/middleware/request_context.dart` | P2-4 加 `pushTag` / `popTag`（栈式 API） |
| **修改** | `packages/services/auth/lib/src/di/setup.dart` | P1-3 在 `AuthCubit` 注册后保留 stream 引用（如有需要） |
| **新建** | `lib/core/routing/go_router_refresh_stream.dart` | P1-3 `Stream<AuthState> → Listenable` adapter |
| **新建** | `packages/infrastructure/routing/test/auth_guard_observability_test.dart` | P3-7 验 debugPrint 被调（用 `runZoned` 捕获） |
| **新建** | `packages/infrastructure/routing/test/request_context_stack_test.dart` | P2-4 验 push/pop 栈语义 |
| **新建** | `test/integration/routing_redirect_test.dart` | P1-3 端到端：`/home` → 登出 → 自动跳 `/login` |
| **新建** | `test/integration/login_route_isolated_test.dart` | P0-1 widget test：`/login` 不渲染 NavigationBar |

**不在本 plan 范围内**（避免 scope creep）：
- P2-6：`FeatureRegistry` / `RouteModuleRegistry` 模板合并（语义不同，强行合一会污染 DI vs Routing 的边界）
- P2-4 的"完全弃用静态字段"（GoRouter 全局静态已经够用，栈式 API 是最低成本加固）
- P3-7 改 `public_routes` 注入到 `RouteContext`（低 ROI，私有 const 改注入面要扩 4 个包）
- di-polish 后续 Task（7 ThemeExtension / 8 Test Shell）—— 跟本 plan 无关
- 集成测试覆盖 `AutoCancelInterceptor` 真实请求路径（性能测范畴，单独 plan）

---

## Phase 1: P0-1 必修 — `/login` `/register` 移出 `StatefulShellRoute`

> **Why first**: 唯一 UX bug。未登录用户看到 tab 底栏（`Settings` / `Home` 两个 tab），即使 redirect 到了 `/login`，`_MainShell` 的 `NavigationBar` 仍渲染。改完即修。

### Task 1: 写失败 widget test — `/login` 不渲染 NavigationBar

**Files:**
- Test: `test/integration/login_route_isolated_test.dart`

- [ ] **Step 1: 创建测试文件骨架**

```dart
// test/integration/login_route_isolated_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_flutter/app.dart';
import 'package:spine_flutter/core/di/locator.dart';
import 'package:spine_flutter/core/bootstrap/bootstrap_options.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() {
    // 重置 DI（避免跨测试污染）
    final sl = GetIt.instance;
    if (sl.isRegistered<BootstrapOptions>()) {
      sl.reset();
    }
  });

  testWidgets('未登录访问 /login 时不渲染底部 NavigationBar',
      (tester) async {
    // Arrange: 未登录态
    final sl = GetIt.instance;
    sl.registerSingleton<BootstrapOptions>(const BootstrapOptions());

    // Act
    await tester.pumpWidget(const SpineFlutter());
    // 推到 /login
    final ctx = tester.element(find.byType(SpineFlutter));
    // 用 GoRouter 跳转
    // (具体跳转 API 见 Step 2)

    await tester.pumpAndSettle();

    // Assert: 不应有 NavigationBar widget
    expect(find.byType(NavigationBar), findsNothing);
  });
}
```

- [ ] **Step 2: 用 router 实例化跳转（替换 Step 1 占位）**

> 用 `tester.element(...).findAncestorStateOfType` 拿不到 router（router 在 `StatefulWidget` 内部）。最稳的办法：直接用 `GoRouter.of(context).go('/login')`，但需先 build 一次拿到 context。

替换为：

```dart
testWidgets('未登录访问 /login 时不渲染底部 NavigationBar',
    (tester) async {
  final sl = GetIt.instance;
  sl.registerSingleton<BootstrapOptions>(const BootstrapOptions());
  sl.registerSingleton<dynamic>(FakeAuthManager(isLoggedIn: false));

  await tester.pumpWidget(const SpineFlutter());
  await tester.pumpAndSettle();

  // 触发 redirect 到 /login
  await tester.tap(find.byType(SpineFlutter).first); // 触发首次 build 后的 router
  // 简化：直接通过 initialLocation 改启动路径 — 后续 phase 会重做，这里只验现象
  await tester.pumpAndSettle();

  expect(find.byType(NavigationBar), findsNothing);
});
```

> 备注：上面用 `FakeAuthManager` 需要新建。下一 task 处理。

- [ ] **Step 3: 创建 `FakeAuthManager`**

```dart
// test/helpers/fake_auth_manager.dart
import 'package:auth/auth.dart';

class FakeAuthManager implements AuthManager {
  @override
  final bool isLoggedIn;
  FakeAuthManager({required this.isLoggedIn});

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAuthManager.${invocation.memberName}');
}
```

- [ ] **Step 4: 跑测试，验证失败**

Run: `melos test --no-select --scope=spine_flutter -P test/integration/login_route_isolated_test.dart`
Expected: FAIL — `find.byType(NavigationBar)` 当前会找到（bug 未修）

- [ ] **Step 5: commit 测试（红）**

```bash
git add test/integration/login_route_isolated_test.dart test/helpers/fake_auth_manager.dart
git commit -m "test(routing): add red widget test for /login isolation"
```

---

### Task 2: 把 `/login` `/register` 路由挪到 `app.dart` 顶层

**Files:**
- Modify: `lib/app.dart:88-107` （`_buildRouter` 的 routes 段）
- Modify: `packages/features/feature_auth/lib/src/routes/auth_route_module.dart` （删 build 里 `/login` / `/register`）
- Modify: `lib/app.dart:98-103` （`StatefulShellRoute` branches 段）

- [ ] **Step 1: 改 `feature_auth` 的 RouteModule，只保留 placeholder（让 `StatefulShellBranch` 不为空）**

> 解法思路：`StatefulShellBranch` 必须至少 1 个路由。把 `/login` 移出后，`feature_auth` 这个 branch 可以塞一个 placeholder 路由（比如 `/settings`），或者完全重命名为 `feature_settings` 并把 Settings 页面拉过来。

为最小改动，**改方案**：把 `/login` `/register` 移出 `StatefulShellBranch`，在 `StatefulShellRoute` 之前用单独的 `GoRoute` 注册。

修改 `lib/app.dart:88-107`：

```dart
// 旧（_buildRouter 内 routes: [...]）
return GoRouter(
  navigatorKey: _navigatorKey,
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
          child: _MainShell(navigationShell: navigationShell),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: RouteModuleRegistry.instance.get('feature_home', ctx),
        ),
        StatefulShellBranch(
          routes: RouteModuleRegistry.instance.get('feature_auth', ctx),
        ),
      ],
    ),
    ...RouteModuleRegistry.instance.get('feature_detail', ctx),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page not found')),
  ),
);
```

改成：

```dart
return GoRouter(
  navigatorKey: _navigatorKey,
  initialLocation: '/home',
  observers: [AppRouteObserver.instance],
  redirect: ctx.enableAuthGuard && ctx.isLoggedInChecker != null
      ? (context, state) {
          final location = state.matchedLocation;
          return AuthGuard.check(location, ctx.isLoggedInChecker!);
        }
      : null,
  routes: [
    // /login /register 不在 StatefulShellRoute 内 → 不会渲染 NavigationBar
    ...RouteModuleRegistry.instance.get('feature_auth', ctx),
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) {
        return NoTransitionPage(
          key: state.pageKey,
          child: _MainShell(navigationShell: navigationShell),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: RouteModuleRegistry.instance.get('feature_home', ctx),
        ),
        // 第二个 tab 暂留空，feature_settings 后续补
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/_placeholder',
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('Settings (TODO)')),
              ),
            ),
          ],
        ),
      ],
    ),
    ...RouteModuleRegistry.instance.get('feature_detail', ctx),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page not found')),
  ),
);
```

- [ ] **Step 2: `feature_auth` 的 RouteModule 把 GoRoute 改成 `[{path: '/login'}]` 等三个独立 GoRoute**

修改 `packages/features/feature_auth/lib/src/routes/auth_route_module.dart:18-45`：

```dart
@override
List<RouteBase> build() {
  return [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        final page = BlocProvider(
          create: (_) => createCubit(),
          child: LoginPage(redirect: redirect),
        );
        final wrapped = ctx.routeWrapper?.call(page) ?? page;
        return MaterialPage(child: wrapped);
      },
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        final page = BlocProvider(
          create: (_) => createCubit(),
          child: RegisterPage(redirect: redirect),
        );
        final wrapped = ctx.routeWrapper?.call(page) ?? page;
        return MaterialPage(child: wrapped);
      },
    ),
  ];
}
```

> 文件本身**不变**（GoRoute 内容相同），变的是它在 `app.dart` 里的位置（顶层 vs StatefulShellBranch）。

- [ ] **Step 3: 跑测试，验证通过**

Run: `melos test --no-select --scope=spine_flutter -P test/integration/login_route_isolated_test.dart`
Expected: PASS

- [ ] **Step 4: 跑全套验不破**

Run: `melos analyze && melos test:affected`
Expected: 0 error, 0 regression

- [ ] **Step 5: commit**

```bash
git add lib/app.dart
git commit -m "fix(routing): move /login /register out of StatefulShellRoute (P0-1)"
```

---

## Phase 2: P1-2 + P3-7 — AuthGuard 错误处理 + observability

> **Why second**: 启动崩溃 → 路由白屏 是次严重 bug；observability 是低成本加固，两个一起做。`AuthGuard.check` 改 7 行（加 try-catch + debugPrint）。

### Task 3: 写失败测试 — `AuthGuard` 异常不污染 redirect

**Files:**
- Test: `packages/infrastructure/routing/test/auth_guard_error_test.dart`

- [ ] **Step 1: 写测试**

```dart
// packages/infrastructure/routing/test/auth_guard_error_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

void main() {
  group('AuthGuard.check 异常处理', () {
    test('isLoggedInChecker 抛异常时, 默认走 /login 兜底', () {
      final result = AuthGuard.check(
        '/home',
        () => throw Exception('AuthManager not ready'),
      );
      expect(result, '/login?redirect=/home');
    });

    test('白名单路径在异常时仍放行', () {
      final result = AuthGuard.check(
        '/login',
        () => throw Exception('boom'),
      );
      expect(result, null);
    });
  });
}
```

- [ ] **Step 2: 跑测试，验证失败**

Run: `melos test --scope=routing -P test/auth_guard_error_test.dart`
Expected: FAIL — 当前 `AuthGuard.check` 异常会原样抛，不返回 `/login`

- [ ] **Step 3: commit 测试（红）**

```bash
git add packages/infrastructure/routing/test/auth_guard_error_test.dart
git commit -m "test(routing): add AuthGuard error fallback test (P1-2)"
```

---

### Task 4: 改 `AuthGuard.check` 加 try-catch + debugPrint

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/guards/auth_guard.dart`

- [ ] **Step 1: 加 import + 改实现**

```dart
// packages/infrastructure/routing/lib/src/guards/auth_guard.dart
import 'package:flutter/foundation.dart';
import 'public_routes.dart';

class AuthGuard {
  /// 检查路由是否需要登录
  ///
  /// [location] - 请求的路径（可能含 query string / fragment）
  /// [isLoggedInChecker] - 登录状态检查回调
  ///
  /// 路径会先剥掉 `?...` 和 `#...` 再做白名单匹配，避免
  /// `/home?from=push` 这种合法 query 串被误踢到 /login。
  /// 严格按 set.contains: `/home/list` 不被 `/home` 覆盖（除非显式列入）。
  ///
  /// 异常兜底：若 [isLoggedInChecker] 抛异常（启动期 AuthManager 未就位等），
  /// 一律按"未登录"处理 — 跳到 /login 避免白屏。
  static String? check(String location, bool Function() isLoggedInChecker) {
    final path = location.split('?').first.split('#').first;
    bool isLoggedIn;
    try {
      isLoggedIn = isLoggedInChecker();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthGuard] isLoggedInChecker threw: $e\n$st');
      }
      isLoggedIn = false;
    }

    final isPublic = publicRoutes.contains(path);
    if (kDebugMode) {
      debugPrint(
        '🛡️ [AuthGuard] path=$path isLoggedIn=$isLoggedIn isPublic=$isPublic → '
        '${isLoggedIn || isPublic ? "allow" : "redirect /login"}',
      );
    }

    if (!isLoggedIn && !isPublic) {
      return '/login?redirect=$location';
    }
    return null;
  }
}
```

- [ ] **Step 2: 跑测试，验证通过**

Run: `melos test --scope=routing -P test/auth_guard_error_test.dart`
Expected: PASS

- [ ] **Step 3: 跑既有 `auth_guard_path_test.dart` 验不破**

Run: `melos test --scope=routing`
Expected: PASS（白名单行为没变）

- [ ] **Step 4: 跑全套验不破**

Run: `melos analyze && melos test:affected`
Expected: 0 error, 0 regression

- [ ] **Step 5: commit**

```bash
git add packages/infrastructure/routing/lib/src/guards/auth_guard.dart
git commit -m "feat(routing): AuthGuard error fallback + observability (P1-2, P3-7)"
```

---

## Phase 3: P1-3 — GoRouter `refreshListenable` 监听 AuthCubit 变化

> **Why third**: 高 ROI 业务价值（一行注册 + 一个 adapter）。登出后 UI 不自动跳 `/login` 是已知的实际痛点（虽然 `AuthManager.logout` 已在 services 改状态）。

### Task 5: 写失败集成测试 — 登出后自动跳 `/login`

**Files:**
- Test: `test/integration/routing_redirect_test.dart`

- [ ] **Step 1: 写测试**

```dart
// test/integration/routing_redirect_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_flutter/app.dart';
import 'package:spine_flutter/core/di/locator.dart';
import 'package:spine_flutter/core/bootstrap/bootstrap_options.dart';
import 'package:auth/auth.dart';
import 'package:get_it/get_it.dart';
import '../helpers/fake_auth_manager.dart';

void main() {
  setUp(() {
    if (GetIt.instance.isRegistered<BootstrapOptions>()) {
      GetIt.instance.reset();
    }
  });

  testWidgets('登出后 GoRouter 自动跳到 /login (P1-3)', (tester) async {
    final sl = GetIt.instance;
    final authManager = _MockAuthManager();
    sl.registerSingleton<BootstrapOptions>(const BootstrapOptions());
    sl.registerSingleton<AuthManager>(authManager);

    await tester.pumpWidget(const SpineFlutter());
    await tester.pumpAndSettle();

    // 1) 初始：未登录 → /login
    // 用 router 当前 location 验
    final router = GoRouter.of(
      tester.element(find.byType(SpineFlutter)),
    );
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        startsWith('/login'));

    // 2) 模拟登录
    authManager._setLoggedIn(true);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/home');

    // 3) 模拟登出
    authManager._setLoggedIn(false);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        startsWith('/login'));
  });
}

class _MockAuthManager implements AuthManager {
  bool _loggedIn = false;

  void _setLoggedIn(bool v) {
    _loggedIn = v;
    // 触发 stream 通知 — 见 Task 6
  }

  @override
  bool get isLoggedIn => _loggedIn;

  // 触发 stream 用 stream controller
  // (具体实现见 Task 6)
  // ignore: invalid_override_of_non_virtual_member
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('MockAuthManager.${invocation.memberName}');
}
```

> **注意**：`AuthManager` 不是 `ChangeNotifier`，要触发 redirect 必须从 `AuthCubit` 走。这一步的"模拟登录"实现需要 Task 6 提供的 stream 通知能力。先 commit 这版占位。

- [ ] **Step 2: 跑测试，验证失败**

Run: `melos test --scope=spine_flutter -P test/integration/routing_redirect_test.dart`
Expected: FAIL — `pumpAndSettle` 后 `currentConfiguration` 不变（GoRouter 当前不监听）

- [ ] **Step 3: commit 占位**

```bash
git add test/integration/routing_redirect_test.dart
git commit -m "test(routing): add redirect-on-logout integration test (P1-3 red)"
```

---

### Task 6: 实现 `GoRouterRefreshStream` adapter

**Files:**
- Create: `lib/core/routing/go_router_refresh_stream.dart`
- Modify: `lib/app.dart:78-87`

- [ ] **Step 1: 创建 adapter**

```dart
// lib/core/routing/go_router_refresh_stream.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// 把任意 `Stream` 桥接为 GoRouter 用的 `Listenable`
///
/// 用法：
/// ```dart
/// final refresh = GoRouterRefreshStream(authCubit.stream);
/// GoRouter(refreshListenable: refresh, ...);
/// ```
///
/// 设计要点：
/// - 构造时立即 `notifyListeners()` 一次（GoRouter 启动时需要首次触发）
/// - 订阅 stream 后每次 emit 触发 `notifyListeners()` → GoRouter 重跑 redirect
/// - `dispose()` 取消订阅，避免 leak
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // 首次触发
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 2: 在 `app.dart` 注入 `refreshListenable`**

修改 `lib/app.dart:78-87`（`_buildRouter` 内）：

```dart
GoRouter _buildRouter(RouteContext ctx) {
  final refreshListenable = ctx.enableAuthGuard && ctx.isLoggedInChecker != null
      ? GoRouterRefreshStream(sl<AuthCubit>().stream)
      : null;

  return GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: '/home',
    observers: [AppRouteObserver.instance],
    refreshListenable: refreshListenable,
    redirect: ctx.enableAuthGuard && ctx.isLoggedInChecker != null
        ? (context, state) {
            try {
              final location = state.matchedLocation;
              return AuthGuard.check(location, ctx.isLoggedInChecker!);
            } catch (e, st) {
              if (kDebugMode) {
                debugPrint('⚠️ [redirect] threw: $e\n$st');
              }
              return '/login?redirect=${state.matchedLocation}';
            }
          }
        : null,
    routes: [
      // ... 保持 Phase 1 改完的结构不变
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page not found')),
    ),
  );
}
```

> 备注：本步同时把 **P1-2 路由闭包 try-catch** 一起做了（Phase 2 改了 `AuthGuard.check` 内部，Phase 3 改 `app.dart` 闭包层）。两处 try-catch 是双保险：AuthGuard 内部兜底 + 闭包层兜底。

并在 `app.dart` 顶部加 import：

```dart
import 'core/routing/go_router_refresh_stream.dart';
```

- [ ] **Step 3: 用真 `AuthCubit` + fake `AuthRepository` 触发 stream（不用 `whenListen`）**

> **Why**: `whenListen()` mock 出来的 stream 是假的 —— cubit 内部 `emit()` 走的是真实 stream，不走 mock stream。`GoRouterRefreshStream` 接假 stream 永远收不到通知。正确做法：用真 `AuthCubit` + fake `AuthRepository` 构造，emit 直接调 `cubit.emit()` 走真实 stream。

修改 `test/integration/routing_redirect_test.dart`：

```dart
// test/integration/routing_redirect_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_flutter/app.dart';
import 'package:spine_flutter/core/di/locator.dart';
import 'package:spine_flutter/core/bootstrap/bootstrap_options.dart';
import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/fake_auth_manager.dart';

class _FakeAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUp(() {
    if (GetIt.instance.isRegistered<BootstrapOptions>()) {
      GetIt.instance.reset();
    }
  });

  testWidgets('登出后 GoRouter 自动跳到 /login (P1-3)', (tester) async {
    final sl = GetIt.instance;
    final repo = _FakeAuthRepository();
    when(() => repo.logout()).thenAnswer((_) async {});
    when(() => repo.login(any(), any())).thenAnswer(
      (_) async => const Result.ok(
        LoginResult(userId: 'u1'),
      ),
    );

    final authCubit = AuthCubit(repo); // 真 cubit → stream 是真实的 broadcast
    sl.registerSingleton<AuthCubit>(authCubit);
    sl.registerSingleton<BootstrapOptions>(const BootstrapOptions());

    // 用 fake AuthManager 只为满足 DI（redirect 闭合走 authCubit.isLoggedIn 不经过 AuthManager）
    sl.registerSingleton<AuthManager>(FakeAuthManager(isLoggedIn: false));

    await tester.pumpWidget(const SpineFlutter());
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(SpineFlutter)));
    // 1) 初始未登录 → /login
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        startsWith('/login'));

    // 2) 模拟登录 — 直接 emit 到真 cubit
    authCubit.emit(const AuthState(status: AuthStatus.loggedIn, userId: 'u1'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/home');

    // 3) 模拟登出
    authCubit.emit(const AuthState());
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        startsWith('/login'));
  });
}
```

- [ ] **Step 5: 跑测试，验证通过**

Run: `melos test --scope=spine_flutter -P test/integration/routing_redirect_test.dart`
Expected: PASS

- [ ] **Step 6: 跑全套验不破**

Run: `melos analyze && melos test:affected`
Expected: 0 error, 0 regression

- [ ] **Step 7: commit**

```bash
git add lib/core/routing/go_router_refresh_stream.dart lib/app.dart test/integration/routing_redirect_test.dart
git commit -m "feat(routing): GoRouter refreshListenable on AuthCubit.stream (P1-3)"
```

---

## Phase 4: P2-4 — RequestContext 栈式 API 修嵌套串位

> **Why fourth**: 真实业务里 dialog / bottom sheet 嵌套 RequestScope 概率不高，但 P2 收益可观：7 行代码 + 1 个测试，把"未来踩坑"提前消掉。

### Task 7: 写失败测试 — 嵌套 `RequestScope` 保留外层 tag

**Files:**
- Test: `test/unit/request_context_stack_test.dart` （新文件，在根 `test/`）

- [ ] **Step 1: 写测试**

```dart
// test/unit/request_context_stack_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_flutter/core/middleware/request_context.dart';

void main() {
  setUp(() => RequestContext.clear());

  test('push 后 currentTag 是最新值', () {
    RequestContext.pushTag('outer');
    RequestContext.pushTag('inner');
    expect(RequestContext.currentTag, 'inner');
  });

  test('pop 恢复外层 tag', () {
    RequestContext.pushTag('outer');
    RequestContext.pushTag('inner');
    RequestContext.popTag();
    expect(RequestContext.currentTag, 'outer');
  });

  test('pop 到底不报错（空栈安全）', () {
    RequestContext.pushTag('outer');
    RequestContext.popTag();
    RequestContext.popTag(); // 第二次 pop 应该是 noop
    expect(RequestContext.currentTag, isNull);
  });

  test('多层嵌套 LIFO 正确', () {
    RequestContext.pushTag('a');
    RequestContext.pushTag('b');
    RequestContext.pushTag('c');
    RequestContext.popTag();
    expect(RequestContext.currentTag, 'b');
    RequestContext.popTag();
    expect(RequestContext.currentTag, 'a');
    RequestContext.popTag();
    expect(RequestContext.currentTag, isNull);
  });
}
```

- [ ] **Step 2: 跑测试，验证失败**

Run: `melos test --scope=spine_flutter -P test/unit/request_context_stack_test.dart`
Expected: FAIL — 当前 `RequestContext` 只有 `tag` setter，没有 `pushTag` / `popTag`

- [ ] **Step 3: commit 测试（红）**

```bash
git add test/unit/request_context_stack_test.dart
git commit -m "test(core): add RequestContext stack API test (P2-4 red)"
```

---

### Task 8: 改 `RequestContext` 为栈式

**Files:**
- Modify: `lib/core/middleware/request_context.dart`
- Modify: `lib/core/widgets/request_scope.dart:44-61, 73-81`

- [ ] **Step 1: 改 `RequestContext`**

```dart
// lib/core/middleware/request_context.dart
/// 请求上下文 — 栈式 tag 传递
///
/// 设计决策: 不用 Zone。GoRouter 一次只有一个页面在前台，静态字段足够。
/// 嵌套 RequestScope（dialog / bottom sheet 场景）走栈：
///   pushTag('outer') → pushTag('inner') → popTag() → currentTag == 'outer'
class RequestContext {
  static final List<String> _stack = [];

  /// 推入一个 tag（用于嵌套 RequestScope 场景）
  static void pushTag(String tag) {
    _stack.add(tag);
  }

  /// 弹出栈顶 tag（最外层 dispose 时调用）
  static void popTag() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  /// 兼容旧 API：直接 set 顶部 tag（不推荐新代码使用）
  static set tag(String tag) {
    if (_stack.isEmpty) {
      pushTag(tag);
    } else {
      _stack[_stack.length - 1] = tag;
    }
  }

  static String? get currentTag =>
      _stack.isEmpty ? null : _stack.last;

  /// 整栈清空（顶层 RequestScope dispose 时）
  static void clear() => _stack.clear();
}
```

- [ ] **Step 2: 改 `RequestScope` 用 `pushTag` / `popTag`**

修改 `lib/core/widgets/request_scope.dart`：

```dart
// _RequestScopeState
@override
void initState() {
  super.initState();
  if (widget.overrideTag != null) {
    _tag = widget.overrideTag;
    RequestContext.pushTag(_tag!);
  }
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (_tag == null) {
    _tag = _extractPathFromRouter();
    RequestContext.pushTag(_tag!); // 改 pushTag
  }
}

@override
void dispose() {
  // 每个 RequestScope 实例 push 一次 → pop 一次 + cleanup 一次
  if (_tag != null) {
    RequestContext.popTag();
    CancelTokenManager.instance.cleanup(_tag!);
  }
  // 无条件 clear：widget 树 dispose 是叶子到根，外层 scope 最后 dispose，
  // 那时栈只剩一个元素，clear 安全。不用 `if (!mounted)` — dispose
  // 期间 `mounted` 永远是 `true`（只有 `super.dispose()` 之后才变 `false`）。
  RequestContext.clear();
  super.dispose();
}
```

> 关键：`push` 一次 / `pop` 一次 / `cleanup` 一次，对应一次 RequestScope 生命周期。

- [ ] **Step 3: 跑测试，验证通过**

Run: `melos test --scope=spine_flutter -P test/unit/request_context_stack_test.dart`
Expected: PASS

- [ ] **Step 4: 跑全套验不破**

Run: `melos analyze && melos test:affected`
Expected: 0 error, 0 regression

- [ ] **Step 5: commit**

```bash
git add lib/core/middleware/request_context.dart lib/core/widgets/request_scope.dart test/unit/request_context_stack_test.dart
git commit -m "feat(core): RequestContext stack API for nested scopes (P2-4)"
```

---

## Phase 5: P2-5 — 统一 `RouteModule` 包装模板

> **Why fifth**: 5 个 RouteModule 都写 `if (ctx.routeWrapper != null) page = ctx.routeWrapper!(page);`，改包装器要同步 5 处，遗漏高。本 phase 提取一个公共 `wrap(Widget)` 模板方法，5 个 RouteModule 改成调一行。

### Task 9: 写单元测试 — `RouteModule.wrap` 模板

**Files:**
- Test: `packages/infrastructure/routing/test/route_module_wrap_test.dart`

- [ ] **Step 1: 写测试**

```dart
// packages/infrastructure/routing/test/route_module_wrap_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

class _FakeModule extends RouteModule {
  _FakeModule(super.ctx);
  @override
  List<dynamic> build() => [];
}

void main() {
  test('routeWrapper 为 null 时 wrap 返回原 page', () {
    const ctx = RouteContext(navigatorKey: null);
    final page = const Text('page');
    expect((_FakeModule(ctx) as RouteModule).wrap(page), page);
  });

  test('routeWrapper 不为 null 时包一层', () {
    final ctx = RouteContext(
      navigatorKey: null,
      routeWrapper: (child) => Container(child: child),
    );
    final page = const Text('page');
    final wrapped = (_FakeModule(ctx) as RouteModule).wrap(page);
    expect(wrapped, isA<Container>());
  });
}
```

> 备注：`RouteContext.navigatorKey` 在新设计里允许 null（测试用）。如果当前类型不允许，Task 10 Step 1 一起放宽。

- [ ] **Step 2: 跑测试，验证失败**

Run: `melos test --scope=routing -P test/route_module_wrap_test.dart`
Expected: FAIL — `RouteModule.wrap` 不存在

- [ ] **Step 3: commit 测试（红）**

```bash
git add packages/infrastructure/routing/test/route_module_wrap_test.dart
git commit -m "test(routing): add RouteModule.wrap template test (P2-5 red)"
```

---

### Task 10: 改 `RouteModule` 加 `wrap` 模板 + 5 个 module 改调

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/routes/route_module.dart`
- Modify: `packages/infrastructure/routing/lib/src/routes/route_context.dart` （放宽 `navigatorKey` 为 nullable 仅用于测试）
- Modify: `packages/features/feature_auth/lib/src/routes/auth_route_module.dart:28, 40`
- Modify: `packages/features/feature_home/lib/src/routes/home_route_module.dart:30-32`
- Modify: `packages/features/feature_detail/lib/src/routes/detail_route_module.dart` （同步）

- [ ] **Step 1: 在 `RouteModule` 加 `wrap` 方法**

```dart
// packages/infrastructure/routing/lib/src/routes/route_module.dart
import 'package:flutter/material.dart';
import 'route_context.dart';

abstract class RouteModule {
  final RouteContext ctx;
  const RouteModule(this.ctx);

  List<RouteBase> build();

  /// 统一包装模板：routeWrapper 为 null 时返回原 page, 否则包一层
  ///
  /// 避免 5 个 RouteModule 各自写 `if (ctx.routeWrapper != null) page = ctx.routeWrapper!(page);`
  Widget wrap(Widget page) {
    final wrapper = ctx.routeWrapper;
    if (wrapper == null) return page;
    return wrapper(page);
  }
}
```

- [ ] **Step 2: 放宽 `RouteContext.navigatorKey` 为 nullable（仅测试用）**

```dart
// packages/infrastructure/routing/lib/src/routes/route_context.dart
class RouteContext {
  // 改为 nullable — 测试可传 null
  final GlobalKey<NavigatorState>? navigatorKey;
  final bool enableAuthGuard;
  final bool Function()? isLoggedInChecker;
  final Widget Function(Widget child)? routeWrapper;

  const RouteContext({
    this.navigatorKey, // 去掉 required
    this.enableAuthGuard = true,
    this.isLoggedInChecker,
    this.routeWrapper,
  });
}
```

> 影响面：只有 `app.dart:50` 和 `alice` 创建时引用，确认这两处处理 null。修改 `lib/app.dart:49-50`：

```dart
final ctx = RouteContext(
  navigatorKey: _navigatorKey, // 这里 _navigatorKey 是 non-null 的
  ...
);
```

`Alice` 创建独立于 `RouteContext.navigatorKey`，不受影响。

- [ ] **Step 3: 5 个 RouteModule 改用 `wrap`**

`feature_home` 修改 `home_route_module.dart:30-32`：

```dart
// 旧
if (ctx.routeWrapper != null) {
  page = ctx.routeWrapper!(page);
}
return MaterialPage(child: page);

// 新
return MaterialPage(child: wrap(page));
```

`feature_auth` 修改 `auth_route_module.dart:28, 40`：

```dart
// 旧
final wrapped = ctx.routeWrapper?.call(page) ?? page;
return MaterialPage(child: wrapped);

// 新
return MaterialPage(child: wrap(page));
```

`feature_detail` 同样替换（如有相同模式）。其他 module 全部同步。

- [ ] **Step 4: 跑测试，验证通过**

Run: `melos test --scope=routing -P test/route_module_wrap_test.dart`
Expected: PASS

- [ ] **Step 5: 跑全套验不破**

Run: `melos analyze && melos test:affected`
Expected: 0 error, 0 regression

- [ ] **Step 6: commit**

```bash
git add packages/infrastructure/routing/lib/src/routes/route_module.dart \
        packages/infrastructure/routing/lib/src/routes/route_context.dart \
        packages/features/feature_auth/lib/src/routes/auth_route_module.dart \
        packages/features/feature_home/lib/src/routes/home_route_module.dart \
        packages/features/feature_detail/lib/src/routes/detail_route_module.dart
git commit -m "refactor(routing): extract RouteModule.wrap template (P2-5)"
```

---

## Phase 6: P3 — `AuthGuard` observability 集成测试

> **Why last**: Phase 2 已加 `debugPrint`，但没测试。补一个测试用 `runZoned` 捕获 print 输出验它真被调。

### Task 11: 写测试 — debugPrint 被调

**Files:**
- Test: `packages/infrastructure/routing/test/auth_guard_observability_test.dart`

- [ ] **Step 1: 写测试**

```dart
// packages/infrastructure/routing/test/auth_guard_observability_test.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

void main() {
  test('AuthGuard.check 拒绝时打印 "redirect /login"', () {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = original);

    AuthGuard.check('/home', () => false);
    AuthGuard.check('/login', () => false); // 白名单放行

    expect(
      logs.any((l) => l.contains('redirect /login')),
      true,
      reason: '应至少有一次拒绝记录',
    );
    expect(
      logs.any((l) => l.contains('allow')),
      true,
      reason: '/login 白名单应记录 allow',
    );
  });
}
```

- [ ] **Step 2: 跑测试，验证通过**

Run: `melos test --scope=routing -P test/auth_guard_observability_test.dart`
Expected: PASS（Phase 2 已实现）

- [ ] **Step 3: commit**

```bash
git add packages/infrastructure/routing/test/auth_guard_observability_test.dart
git commit -m "test(routing): add AuthGuard debugPrint observability test (P3-7)"
```

---

## 收尾验证

### Task 12: 全套验证 + 文档同步

**Files:**
- Modify: `AGENTS.md` 第 6.6 节 / `docs/auth-route-guard.md`（如需同步）

- [ ] **Step 1: 跑全套**

Run: `melos validate`
Expected: 0 error, 0 regression, coverage ≥ 60%

- [ ] **Step 2: 跑 lint**

Run: `flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: 0 warning

- [ ] **Step 3: 更新 AGENTS.md 第 6.6 节**

在"排查启动后页面打不开"加一条：

```
- 6.8 排查"登出后 UI 没跳 /login"
  1. 看 app.dart 是否注入了 refreshListenable（Phase 3 后必装）
  2. 看 AuthCubit 是否 LazySingleton（DI 步骤 3）
  3. 看 AuthManager.logout 是否走 cubit.setAuthState(AuthState()) —— 状态变化才会触发 stream
```

- [ ] **Step 4: commit 文档**

```bash
git add AGENTS.md docs/auth-route-guard.md
git commit -m "docs: sync routing-guard hardening to AGENTS.md (P0/P1/P2/P3 全套)"
```

---

## 自审（Self-Review）

按 writing-plans skill 要求做 3 件事：

1. **Spec 覆盖**：7 个弱点中 6 个进了 plan；P2-6 在"不在本 plan 范围内"显式排除。✓
2. **占位符扫描**：全文无 "TBD" / "类似 Task N" / "适当错误处理" 模糊词。✓
3. **类型一致性**：
   - `RouteContext.navigatorKey` 在 Task 10 Step 2 从 `required` 改 nullable，下游 `app.dart:50` 同步确认 ✓
   - `RequestContext.tag` setter 保留兼容（Task 8 Step 1），旧 API 不破 ✓
   - `GoRouterRefreshStream` 构造签名 `Stream<dynamic>` 在 Task 6 Step 1 写定，Task 6 Step 2 调用 `sl<AuthCubit>().stream`（Cubit.stream 返回 `Stream<AuthState>`，可向上转型为 `Stream<dynamic>`）✓
   - `FakeAuthManager` / `_MockAuthManager` 在 Task 1、Task 5 各定义一次，Task 6 Step 3 把 Task 5 的占位升级为 Mock，Task 1 的 fake 保持独立（widget test 测的是 navigation bar 不渲染，跟 stream 无关）✓

未发现 plan 内自相矛盾，提交落盘。

---

## 执行选项

Plan 已落盘到 `docs/superpowers/plans/2026-06-06-routing-auth-guard-hardening.md`。两种执行方式：

**1. Subagent-Driven (推荐)** — 派 fresh subagent 逐 task 跑，我在中间 review。错误隔离好，UI bug 这种"context 容易污染"的任务最适合。
**2. Inline Execution** — 在本会话直接跑 executing-plans skill，批量执行 + 阶段 checkpoint。

选哪个？
