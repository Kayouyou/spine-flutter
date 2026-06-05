# Plan A: Flutter 架构对齐 (P0 + P1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复架构一致性 — 路由连接 Feature 页面、统一路由常量、统一 state 模式为 freezed、Repository 接口归位 domain 层、PreferencesService key 类型化。

**Architecture:** 不改变任何业务逻辑，纯粹的结构对齐。每个 task 独立可验证：Task 完成后 `flutter analyze` 零错误、现有测试全通过。

**Tech Stack:** Flutter 3.19+, Dart 3.3+, flutter_bloc 9.x, freezed 2.4.0, build_runner, GoRouter 14.x, GetIt 7.x

**预估工期:** 2-3 天 (1人顺序推进)

**依赖关系:** Task 1 → Task 2 → Task 3 → Task 4 → Task 5（Task 3-5 可并行，但建议顺序做以降低风险）

---

## 文件影响范围总览

| Task | 新建 | 修改 | 删除 |
|------|------|------|------|
| 1. 路由连线 | 0 | 3 | 0 |
| 2. 路由常量 | 0 | 5 | 0 |
| 3. State 统一 | 0 | 5 (重写) | 0 |
| 4. Repository 归位 | 3 | 5 | 1 |
| 5. Preferences Key | 1 | 1 | 0 |

---

### Task 1: 路由连线 Feature 页面

**目标:** module_a.dart 和 module_b.dart 返回实际 Feature 页面，而非 Scaffold 占位符。router.dart 的 /detail 路由使用 DetailPage。

**文件:**
- 修改: `packages/infrastructure/routing/lib/src/routes/module_a.dart:14-30`
- 修改: `packages/infrastructure/routing/lib/src/routes/module_b.dart:17-28`
- 修改: `packages/infrastructure/routing/lib/src/routes/router.dart:41-47`

**前置检查:** module_a 需要 import feature_home，module_b 需要 import TabBPage 和 routing exports。确认 pubspec.yaml 已有 feature_home 和 feature_detail 依赖（分析报告确认: ✅ 已存在）。

- [ ] **Step 1: 修改 module_a.dart — /home 路由返回 HomePage**

```dart
// packages/infrastructure/routing/lib/src/routes/module_a.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:feature_home/feature_home.dart';

import 'route_context.dart';
import 'route_module.dart';

/// Module A — Home tab route
class ModuleARouteModule extends RouteModule {
  ModuleARouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          Widget page = const HomePage();
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

**关键变更:**
- 添加 `import 'package:feature_home/feature_home.dart';`
- `Scaffold(body: Center(child: Text('Home Tab')))` → `const HomePage()`

- [ ] **Step 2: 验证 — flutter analyze 零错误**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter analyze packages/infrastructure/routing/lib/src/routes/module_a.dart
```
预期: `No issues found!`

- [ ] **Step 3: 修改 module_b.dart — /settings 路由返回 TabBPage**

```dart
// packages/infrastructure/routing/lib/src/routes/module_b.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:component_library/component_library.dart';

import 'route_context.dart';
import 'route_module.dart';

/// Module B — Settings tab route
class ModuleBRouteModule extends RouteModule {
  ModuleBRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) {
          Widget page = AppScaffold(
            title: 'Settings',
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _InfoTile(label: 'Framework', value: 'Flutter'),
                _InfoTile(label: 'Architecture', value: 'Clean Architecture + Feature-First'),
                _InfoTile(label: 'State', value: 'flutter_bloc (Cubit)'),
                _InfoTile(label: 'HTTP', value: 'Dio'),
                _InfoTile(label: 'Storage', value: 'Hive + SharedPreferences'),
                _InfoTile(label: 'DI', value: 'GetIt'),
              ],
            ),
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
      // ... login + register routes unchanged
    ];
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text(value),
        ],
      ),
    );
  }
}
```

**设计决策**: TabBPage 当前在 `lib/src/ui/tab_b_page.dart`，但该位置不在 routing 包的依赖链中。方案选择:
- ❌ routing 包反向依赖 lib/（破坏依赖方向）
- ✅ 将 TabBPage 的展示逻辑内联到 module_b.dart（路由层可以有自己的简单展示 widget）

后续 P2 计划会将 TabBPage 的展示升级为 feature_settings 包，届时替换内联 widget。

- [ ] **Step 4: 验证 — flutter analyze 零错误**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter analyze packages/infrastructure/routing/
```
预期: `No issues found!`

- [ ] **Step 5: 修改 router.dart — /detail 路由使用 DetailPage**

```dart
// packages/infrastructure/routing/lib/src/routes/router.dart
// 在文件顶部添加 import
import 'package:feature_detail/feature_detail.dart';

// 修改 /detail 路由 (约第 41-47 行)
GoRoute(
  path: '/detail',
  builder: (context, state) => const DetailPage(),
),
```

**完整 router.dart 变更:**
```dart
// 新增 import
import 'package:feature_detail/feature_detail.dart';

// 修改第 41-47 行的 /detail 路由
GoRoute(
  path: '/detail',
  builder: (context, state) => const DetailPage(),
),
```

- [ ] **Step 6: 验证全项目 — flutter analyze + flutter test**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter
flutter analyze
flutter test
```
预期: analyze 零错误，所有已有测试通过。

- [ ] **Step 7: Commit**

```bash
git add packages/infrastructure/routing/lib/src/routes/module_a.dart
git add packages/infrastructure/routing/lib/src/routes/module_b.dart
git add packages/infrastructure/routing/lib/src/routes/router.dart
git commit -m "fix(routing): wire feature pages to route modules

Replace Scaffold placeholders in module_a (HomePage) and
module_b (TabBPage inline). Use DetailPage in /detail route."
```

---

### Task 2: 路由常量统一 — AppRoutes 替换硬编码字符串

**目标:** 所有页面内的 `context.push('/detail')` 等硬编码路由字符串，替换为 `AppRoutes.detail` 等常量引用。

**文件:**
- 修改: `packages/infrastructure/routing/lib/src/routes/app_routes.dart` — 补充 login, register 常量
- 修改: `packages/features/feature_home/lib/src/ui/home_page.dart:93` — `/detail` → `AppRoutes.detail`
- 修改: `packages/features/feature_auth/lib/src/ui/login_page.dart:34,69` — 硬编码 → 常量
- 修改: `packages/features/feature_auth/lib/src/ui/register_page.dart:34,69` — 硬编码 → 常量

- [ ] **Step 1: 补充 AppRoutes 常量**

```dart
// packages/infrastructure/routing/lib/src/routes/app_routes.dart
/// App route path constants
class AppRoutes {
  AppRoutes._();
  static const String home = '/home';
  static const String settings = '/settings';
  static const String detail = '/detail';
  static const String login = '/login';
  static const String register = '/register';
}
```

- [ ] **Step 2: 修改 home_page.dart — 替换硬编码路由**

```dart
// packages/features/feature_home/lib/src/ui/home_page.dart
// 添加 import
import 'package:routing/routing.dart';

// 第 93 行: 替换
// 旧: onPressed: () => context.push('/detail'),
// 新:
onPressed: () => context.push(AppRoutes.detail),
```

**完整变更:**
- 添加 `import 'package:routing/routing.dart';` 到 imports
- 第 93 行: `'/detail'` → `AppRoutes.detail`

- [ ] **Step 3: 修改 login_page.dart — 替换硬编码路由**

```dart
// packages/features/feature_auth/lib/src/ui/login_page.dart
// 添加 import
import 'package:routing/routing.dart';

// 第 34 行: 替换
// 旧: final target = redirect ?? '/home';
// 新:
final target = redirect ?? AppRoutes.home;

// 第 69 行: 替换
// 旧: onPressed: () => context.go('/register?redirect=$redirect'),
// 新:
onPressed: () => context.go('${AppRoutes.register}?redirect=$redirect'),
```

- [ ] **Step 4: 修改 register_page.dart — 替换硬编码路由**

```dart
// packages/features/feature_auth/lib/src/ui/register_page.dart
// 添加 import
import 'package:routing/routing.dart';

// 第 34 行: 替换
// 旧: final target = redirect ?? '/home';
// 新:
final target = redirect ?? AppRoutes.home;

// 第 69 行: 替换
// 旧: onPressed: () => context.go('/login?redirect=$redirect'),
// 新:
onPressed: () => context.go('${AppRoutes.login}?redirect=$redirect'),
```

- [ ] **Step 5: 验证 — flutter analyze + flutter test**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter
flutter analyze
flutter test
```
预期: analyze 零错误，所有已有测试通过。

- [ ] **Step 6: Commit**

```bash
git add packages/infrastructure/routing/lib/src/routes/app_routes.dart
git add packages/features/feature_home/lib/src/ui/home_page.dart
git add packages/features/feature_auth/lib/src/ui/login_page.dart
git add packages/features/feature_auth/lib/src/ui/register_page.dart
git commit -m "refactor(routing): replace hardcoded route strings with AppRoutes constants"
```

---

### Task 3: 统一 State 类模式 — 全部改为 freezed

**目标:** 统一项目中混用的 3 种 state 模式（sealed+Equatable / Equatable+copyWith / freezed）→ 全部使用 freezed。

**设计决策:**

| State 类 | 当前模式 | 改为 freezed 原因 |
|----------|----------|-------------------|
| HomeState | sealed class + Equatable | 减少样板代码，auto-generated copyWith/==/toString |
| DetailState | sealed class + Equatable | 同上 |
| AuthState | Equatable + copyWith | copyWith 手动编写容易出错 |
| LoginState | Equatable + copyWith | 同上 |
| NetworkState | Equatable + copyWith | 同上 |
| LocaleState | ✅ 已是 freezed | 不动 |

**不改为 freezed 的例外:**
- `DomainException`（sealed class）— 异常体系用 sealed class 更清晰，且不需要 copyWith
- Feature 本地 models — 简单 POJO，不需要 freezed，保持轻量

**文件（全部重写）:**
- 修改: `packages/features/feature_home/lib/src/cubit/home_state.dart`
- 修改: `packages/features/feature_detail/lib/src/cubit/detail_state.dart`
- 修改: `packages/services/auth/lib/src/cubit/auth_state.dart`
- 修改: `packages/features/feature_auth/lib/src/cubit/login_state.dart`
- 修改: `packages/services/network/lib/src/network_state.dart`

**⚠️ 注意:** 修改 state 类后，所有引用这些 state 的 Cubit 和 Widget 都需要同步修改。下面每个 Step 包含完整的连锁修改。

- [ ] **Step 1: 重写 HomeState 为 freezed**

```dart
// packages/features/feature_home/lib/src/cubit/home_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({required Map<String, dynamic> data}) = HomeLoaded;
  const factory HomeState.error({required String errorCode}) = HomeError;
}
```

- [ ] **Step 2: 重写 DetailState 为 freezed + 同步修改 DetailCubit 和 DetailPage**

```dart
// packages/features/feature_detail/lib/src/cubit/detail_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'detail_state.freezed.dart';

@freezed
sealed class DetailState with _$DetailState {
  const factory DetailState.initial() = DetailInitial;
  const factory DetailState.loading() = DetailLoading;
  const factory DetailState.loaded({required Map<String, dynamic> data}) = DetailLoaded;
  const factory DetailState.error({required String errorCode}) = DetailError;
}
```

**同步修改 DetailCubit** — 更新 emit 调用（freezed 的工厂构造函数不需要 `new`，直接调用构造函数）:

```dart
// 旧写法（sealed class）:
emit(DetailLoading());
emit(DetailLoaded(data));
emit(DetailError(errorCode));

// 新写法（freezed）— 不变！freezed 工厂构造函数语法与原来的 sealed class 子类构造一致。
// 无变化，直接兼容。
```

**同步修改 DetailPage** — switch 模式匹配语法不变（Dart 3 sealed + freezed 都支持）:
```dart
// 无需修改 — switch 语法对 freezed sealed class 完全兼容
return switch (state) {
  DetailInitial() => _buildInitial(context),
  DetailLoading() => _buildLoading(context),
  DetailLoaded(data: final data) => _buildLoaded(context, data),
  DetailError(errorCode: final errorCode) => _buildError(context, errorCode),
};
```

- [ ] **Step 3: 重写 AuthState 为 freezed + 同步修改 AuthCubit**

```dart
// packages/services/auth/lib/src/cubit/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    String? userId,
    String? errorMessage,
  }) = _AuthState;
}

enum AuthStatus { initial, loading, loggedIn, error }
```

**同步修改 AuthCubit** — copyWith 语法变化:

```dart
// 旧写法:
emit(state.copyWith(status: AuthStatus.loading));
emit(state.copyWith(status: AuthStatus.loggedIn, userId: result.id));
emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));

// 新写法 — freezed 的 copyWith 语法完全相同！无需修改。
// freezed 的 copyWith 签名和 Equatable 的 copyWith 完全一致。
```

- [ ] **Step 4: 重写 LoginState 为 freezed + 同步修改 LoginCubit**

```dart
// packages/features/feature_auth/lib/src/cubit/login_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    @Default(LoginStatus.initial) LoginStatus status,
    String? errorMessage,
    @Default('') String username,
    @Default('') String password,
  }) = _LoginState;
}

enum LoginStatus { initial, loading, success, error }
```

**同步修改 login_page.dart** — 枚举引用语法变化:

`LoginStatus.success` 和 `LoginStatus.loading` 保持不变（枚举在主文件定义，freezed 不改变枚举引用方式）。

- [ ] **Step 5: 重写 NetworkState 为 freezed + 同步修改 NetworkCubit**

```dart
// packages/services/network/lib/src/network_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_state.freezed.dart';

@freezed
class NetworkState with _$NetworkState {
  const factory NetworkState({
    required NetworkStatus status,
    DateTime? lastDisconnectedAt,
    @Default(NetworkUIStyle.banner) NetworkUIStyle uiStyle,
  }) = _NetworkState;

  const NetworkState._();

  bool get isConnected => status == NetworkStatus.connected;
}

enum NetworkStatus { connected, disconnected }
enum NetworkUIStyle { banner, toast, snackbar, dialog, none }
```

**⚠️ 关键:** `isConnected` getter 必须放在 `const NetworkState._()` 私有构造函数内，因为 freezed 不允许在 factory 中定义方法。

**同步修改 NetworkCubit** — copyWith 语法不变，无需修改。

- [ ] **Step 6: 运行 build_runner 生成 freezed 代码**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter
dart run build_runner build --delete-conflicting-outputs
```
预期: 成功生成 5 个 `.freezed.dart` 文件。

- [ ] **Step 7: 验证 — flutter analyze（检查遗漏）**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter analyze
```
预期: `No issues found!`

- [ ] **Step 8: 验证 — flutter test（确认行为不变）**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter test
```
预期: 所有已有测试通过。如果测试直接引用旧 state 构造函数（如 `HomeLoading()`），会因为 freezed 改用工厂方法而编译失败——此时需同步修改测试文件。

**已知需要同步修改的测试:**
- `packages/features/feature_home/test/home_cubit_test.dart` — `HomeLoading()` → `HomeState.loading()`（如果测试中有直接引用）

- [ ] **Step 9: 清理 — 移除不再需要的 equatable import**

检查以下文件是否仍需 `import 'package:equatable/equatable.dart'`:
- `home_state.dart` — ✅ 改为 freezed 后可移除（equatable 可能仍是其他类的依赖，保留）
- `detail_state.dart` — 同上
- `auth_state.dart` — 同上
- `login_state.dart` — 同上
- `network_state.dart` — 同上

注意: 不移除 pubspec.yaml 中的 equatable 依赖（domain 层和其他文件仍在使用）。

- [ ] **Step 10: Commit**

```bash
git add packages/features/feature_home/lib/src/cubit/home_state.dart
git add packages/features/feature_detail/lib/src/cubit/detail_state.dart
git add packages/services/auth/lib/src/cubit/auth_state.dart
git add packages/features/feature_auth/lib/src/cubit/login_state.dart
git add packages/services/network/lib/src/network_state.dart
git add "**/*.freezed.dart"
# 如果有测试文件修改:
# git add packages/features/feature_home/test/home_cubit_test.dart
git commit -m "refactor(state): unify state classes to freezed pattern

Convert HomeState, DetailState (sealed+Equatable) and
AuthState, LoginState, NetworkState (Equatable+copyWith) to
@freezed for consistency with LocaleState. No behavior change."
```

---

### Task 4: 统一 Repository 接口到 domain 层

**目标:** 将 feature 包中定义的 Repository 接口（HomeRepository, DetailRepository, AuthRepository）移到 domain 层，实现依赖倒置——上层依赖下层接口。

**文件:**
- 新建: `packages/domain/lib/src/repositories/home_repository.dart`
- 新建: `packages/domain/lib/src/repositories/detail_repository.dart`
- 新建: `packages/domain/lib/src/repositories/auth_repository.dart`
- 修改: `packages/domain/lib/domain.dart` — 新增 3 个 export
- 修改: `packages/features/feature_home/lib/src/repository/home_repository_impl.dart` — import 路径
- 修改: `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart` — import 路径
- 修改: `packages/features/feature_auth/lib/src/cubit/login_cubit.dart` — import 路径
- 删除: `packages/features/feature_auth/lib/src/repository/auth_repository.dart` — 移到 domain

**设计决策:** 三个接口都是纯 Dart（无 Flutter 依赖），可以安全放在 domain 层。

- [ ] **Step 1: 创建 domain 层 Repository 接口**

创建三个新文件（与已有的 `user_repository.dart` 放在同一目录）:

```dart
// packages/domain/lib/src/repositories/home_repository.dart
/// 首页数据仓库接口
abstract class HomeRepository {
  Future<Map<String, dynamic>> getHomeData();
  Future<Map<String, dynamic>> refreshHomeData();
}
```

```dart
// packages/domain/lib/src/repositories/detail_repository.dart
/// 详情数据仓库接口
abstract class DetailRepository {
  Future<Map<String, dynamic>> getDetailData(String id);
}
```

```dart
// packages/domain/lib/src/repositories/auth_repository.dart
/// 认证仓库接口
///
/// 定义认证操作的基础契约：登录、注册、登出。
/// 服务层 (AuthManager) 和 feature 层 (LoginCubit) 依赖此接口。
abstract class AuthRepository {
  Future<bool> login(String username, String password);
  Future<bool> register(String username, String password);
  Future<void> logout();
}
```

- [ ] **Step 2: 更新 domain.dart barrel file**

```dart
// packages/domain/lib/domain.dart
// 在现有 exports 后追加:
export 'src/repositories/home_repository.dart';
export 'src/repositories/detail_repository.dart';
export 'src/repositories/auth_repository.dart';
```

- [ ] **Step 3: 删除 feature_auth 中的本地 AuthRepository 接口**

```bash
rm /Users/yeyangyang/Desktop/spine_flutter/packages/features/feature_auth/lib/src/repository/auth_repository.dart
```

- [ ] **Step 4: 更新 feature_auth/feature_auth.dart barrel file — 移除已删除文件的 export**

找到 `packages/features/feature_auth/lib/feature_auth.dart`，检查是否有 `export 'src/repository/auth_repository.dart';` 行，如有则删除。
（该文件替换为从 domain 层 import。）

- [ ] **Step 5: 更新所有 import 路径**

**home_repository_impl.dart:**
```dart
// 旧: import '../repository/home_repository.dart';
// 新:
import 'package:domain/domain.dart';
```

**detail_repository_impl.dart:**
```dart
// 旧: import '../repository/detail_repository.dart';
// 新:
import 'package:domain/domain.dart';
```

**login_cubit.dart:**
```dart
// 旧: import '../repository/auth_repository.dart';
// 新:
import 'package:domain/domain.dart';
```

- [ ] **Step 6: 更新 feature_auth 包的 pubspec.yaml — 确认依赖 domain**

```bash
grep -r "domain" /Users/yeyangyang/Desktop/spine_flutter/packages/features/feature_auth/pubspec.yaml
```
如果不存在 domain 依赖，添加:
```yaml
dependencies:
  domain:
    path: ../../domain
```
(预期: 大部分 feature 包已有 domain 依赖，但 feature_auth 的 AuthRepository 之前是本地的，可能没有。需要验证。)

- [ ] **Step 7: 更新 feature_auth 的 feature_auth.dart barrel file**

```dart
// 移除:
// export 'src/repository/auth_repository.dart';   // 该文件已删除

// 确认仍然导出:
export 'src/repository/mock_auth_repository.dart';  // Mock 实现保留
```

- [ ] **Step 8: 验证 — flutter analyze**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter analyze
```
预期: `No issues found!`。如果出现 import 找不到的错误，按错误提示修正。

- [ ] **Step 9: 验证 — flutter test**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter test
```
预期: 所有已有测试通过。

**已知变更:** LoginCubit 的 import 从本地路径改为 `package:domain/domain.dart`——但 `AuthRepository` 接口签名完全不变，行为零变化。

- [ ] **Step 10: Commit**

```bash
git add packages/domain/lib/src/repositories/home_repository.dart
git add packages/domain/lib/src/repositories/detail_repository.dart
git add packages/domain/lib/src/repositories/auth_repository.dart
git add packages/domain/lib/domain.dart
git rm packages/features/feature_auth/lib/src/repository/auth_repository.dart
git add packages/features/feature_home/lib/src/repository/home_repository_impl.dart
git add packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart
git add packages/features/feature_auth/lib/src/cubit/login_cubit.dart
git add packages/features/feature_auth/lib/feature_auth.dart
git commit -m "refactor(domain): centralize Repository interfaces in domain layer

Move HomeRepository, DetailRepository, AuthRepository interfaces
from feature packages to packages/domain/lib/src/repositories/.
Delete local auth_repository.dart in feature_auth.
All impls now import interfaces from domain package."
```

---

### Task 5: PreferencesService key 抽取为 enum

**目标:** 将 PreferencesService 中 40+ 个静态 String 常量抽取为类型安全的 `PreferenceKey` enum。

**文件:**
- 新建: `packages/infrastructure/key_value_storage/lib/src/preference_key.dart`
- 修改: `packages/infrastructure/key_value_storage/lib/src/shared_preference_storage.dart`

**设计决策:** 使用 enum 而非单独常量类，因为:
1. 编译器保证 switch 穷尽性
2. IDE 自动补全所有 key
3. 类型安全——函数签名 `getString(PreferenceKey key)` 防止传入任意字符串

- [ ] **Step 1: 创建 PreferenceKey enum**

```dart
// packages/infrastructure/key_value_storage/lib/src/preference_key.dart
/// SharedPreferences 存储键枚举
///
/// 所有 SharedPreferences key 集中管理，类型安全，IDE 自动补全。
enum PreferenceKey {
  // --- 隐私 & 协议 ---
  agreePrivacyAndProtocol('agree_privacy_and_protocol'),
  agreePrivacyDriverLicense('agree_privacy_driver_license'),
  agreeLocationDeviceAgreement('agree_location_device_agreement'),

  // --- 引导页 ---
  firstLaunchOnboardingCompleted('first_launch_onboarding_completed'),

  // --- 登录方式 ---
  loginByUserName('login_by_user_name'),
  loginByWeChat('login_by_we_chat'),
  registerByUserName('register_by_user_name'),

  // --- 位置 ---
  locationCityName('location_city_name'),
  locationCityCode('location_city_code'),
  locationFocusDeviceId('mine_location_focus_device_id'),
  locationSelectedDeviceIds('mine_location_selected_device_ids'),
  locationIsExpand('mine_location_is_expand'),
  locationIsLine('mine_location_is_line'),

  // --- 行程信息 ---
  tripInfoSelectedCarIds('trip_info_car_ids'),
  tripInfoSelectedDate('trip_info_date'),

  // --- 行程统计 ---
  tripStatisticSelectedCarIds('trip_statistic_car_ids'),
  tripStatisticSelectedDate('trip_statistic_date'),
  tripStatisticSelectedYear('trip_statistic_year'),
  tripStatisticSelectedMonth('trip_statistic_month'),
  tripStatisticSelectedYearOrMonth('trip_statistic_year_or_month'),
  tripStatisticSelectedYearMonth('trip_statistic_year_month'),

  // --- 围栏统计 ---
  fenceStatisticSelectedYear('fence_statistic_selected_year'),
  fenceStatisticSelectedYearMonth('fence_statistic_year_month'),
  fenceStatisticSelectedMonth('fence_statistic_selected_month'),
  fenceStatisticIsMonth('fence_statistic_is_month'),
  fenceStatisticSelectedYearOrMonth('fence_statistic_year_or_month'),

  // --- 围栏记录 ---
  fenceRecordSelectedCarIds('fence_record_car_ids'),
  fenceRecordSelectedDate('fence_record_date'),
  fenceRecordFenceIds('fence_record_fence_id'),

  // --- 收支统计 ---
  incomeExpenseStatisticSelectedCarIds('income_expense_statistic_car_ids'),
  incomeExpenseStatisticSelectedYear('income_expense_statistic_year'),

  // --- 能耗统计 ---
  energyConsumptionStatisticSelectedCarIds('energy_consumption_statistic_car_ids'),
  energyConsumptionStatisticSelectedDate('energy_consumption_statistic_date'),

  // --- 新手引导 ---
  circleIntro('circle_intro'),
  rectangleIntro('rectangle_intro'),
  polygonIntro('polygon_intro'),

  // --- 速度分段 ---
  carEventInputLimit('car_event_input_limit'),
  smallCarSpeedSegmentConfig('small_car_speed_segment_config'),
  truckSpeedSegmentConfig('truck_speed_segment_config'),
  motorcycleSpeedSegmentConfig('motorcycle_speed_segment_config'),
  electricCarSpeedSegmentConfig('electric_car_speed_segment_config'),
  otherSpeedSegmentConfig('other_speed_segment_config'),

  // --- 广告 ---
  adConfigVersion('ad_config_version'),

  // --- 提醒 ---
  reminderSelectedCarIds('reminder_car_ids'),
  reminderSelectedStatusIds('reminder_status_ids'),
  reminderSelectedDate('reminder_date'),
  reminderSelectedStatus('reminder_status'),

  // --- 车辆列表 ---
  carListDataMode('car_list_data_mode'),
  ;

  final String rawKey;
  const PreferenceKey(this.rawKey);
}
```

- [ ] **Step 2: 重写 PreferencesService 使用 PreferenceKey**

将所有方法签名从 `String key` 改为 `PreferenceKey key`。修改范围：所有 set/get/remove/saveMap/readMap/saveListMap/readListMap 方法签名。

**关键修改示例:**

```dart
// packages/infrastructure/key_value_storage/lib/src/shared_preference_storage.dart
// 旧:
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
//
// class PreferencesService {
//   static String AgreePrivacyAndProtocol = 'agree_privacy_and_protocol';
//   static String AgreePrivacyDriverLicense = 'agree_privacy_driver_license';
//   // ... 40+ 个静态 String ...
//
//   Future<void> setString(String key, String value) async { ... }
//   Future<String?> getString(String key) async { ... }
//   Future<void> setBool(String key, bool value) async { ... }
//   Future<bool?> getBool(String key) async { ... }
//   ...

// 新:
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preference_key.dart';

class PreferencesService {
  // 删除所有静态 String 常量
  // 保留 PreSharedPreferences getter（改为 private）

  late Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  SharedPreferences? _instance;
  Future<SharedPreferences> get _sp async {
    _instance ??= await _prefs;
    return _instance!;
  }

  Future<void> setString(PreferenceKey key, String value) async {
    final prefs = await _sp;
    await prefs.setString(key.rawKey, value);
  }

  Future<String?> getString(PreferenceKey key) async {
    final prefs = await _sp;
    return prefs.getString(key.rawKey);
  }

  Future<void> setInt(PreferenceKey key, int value) async {
    final prefs = await _sp;
    await prefs.setInt(key.rawKey, value);
  }

  Future<int?> getInt(PreferenceKey key) async {
    final prefs = await _sp;
    return prefs.getInt(key.rawKey);
  }

  Future<void> setBool(PreferenceKey key, bool value) async {
    final prefs = await _sp;
    await prefs.setBool(key.rawKey, value);
  }

  Future<bool?> getBool(PreferenceKey key) async {
    final prefs = await _sp;
    return prefs.getBool(key.rawKey) ?? false;
  }

  Future<void> saveMap(Map<String, dynamic> map, PreferenceKey key) async {
    final prefs = await _sp;
    String jsonString = jsonEncode(map);
    await prefs.setString(key.rawKey, jsonString);
  }

  Future<Map<String, dynamic>> readMapFromSharedPreferences(PreferenceKey key) async {
    final prefs = await _sp;
    String? jsonString = prefs.getString(key.rawKey);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    } else {
      return {};
    }
  }

  Future<void> saveListMap(List<dynamic> dataList, PreferenceKey key) async {
    final jsonString = jsonEncode(dataList);
    final prefs = await _sp;
    await prefs.setString(key.rawKey, jsonString);
  }

  Future<List<dynamic>> readListMap(PreferenceKey key) async {
    final prefs = await _sp;
    final jsonString = prefs.getString(key.rawKey);
    return jsonString != null
        ? jsonDecode(jsonString) as List<dynamic>
        : [];
  }

  Future<bool> remove(PreferenceKey key) async {
    final prefs = await _sp;
    return await prefs.remove(key.rawKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    final privacyProtocol = prefs.getBool(PreferenceKey.agreePrivacyAndProtocol.rawKey);
    final driverLicense = prefs.getBool(PreferenceKey.agreePrivacyDriverLicense.rawKey);
    final firstLaunchOnboardingCompleted = prefs.getBool(PreferenceKey.firstLaunchOnboardingCompleted.rawKey);

    await prefs.clear();

    if (privacyProtocol == true) {
      await prefs.setBool(PreferenceKey.agreePrivacyAndProtocol.rawKey, true);
    }
    if (driverLicense == true) {
      await prefs.setBool(PreferenceKey.agreePrivacyDriverLicense.rawKey, true);
    }
    if (firstLaunchOnboardingCompleted == true) {
      await prefs.setBool(PreferenceKey.firstLaunchOnboardingCompleted.rawKey, true);
    }
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

**⚠️ clear() 方法中的 key 引用:** 因为 `clear()` 是 static 方法，无法使用实例方法 `.rawKey`，需通过 `PreferenceKey.xxx.rawKey` 访问。这是设计取舍——enum 的静态成员可以被 static 方法访问。

- [ ] **Step 3: 更新 key_value_storage barrel file — 导出 preference_key.dart**

```bash
grep "preference" /Users/yeyangyang/Desktop/spine_flutter/packages/infrastructure/key_value_storage/lib/key_value_storage.dart
```
如果不存在，添加:
```dart
export 'src/preference_key.dart';
```

- [ ] **Step 4: 查找并更新所有 PreferencesService 调用方**

搜索所有使用 `PreferencesService.AgreePrivacyAndProtocol` 等静态常量的地方:

```bash
cd /Users/yeyangyang/Desktop/spine_flutter
rg "PreferencesService\.[A-Z]" --type dart
```

对每个调用方，将:
```dart
// 旧:
prefs.setBool(PreferencesService.AgreePrivacyAndProtocol, true);
prefs.getBool(PreferencesService.FirstLaunchOnboardingCompleted);

// 新:
prefs.setBool(PreferenceKey.agreePrivacyAndProtocol, true);
prefs.getBool(PreferenceKey.firstLaunchOnboardingCompleted);
```

**注意:** 函数签名变了（`String key` → `PreferenceKey key`），所有调用方都需要更新。如果调用方数量多（>10处），先做全局搜索确认范围。

- [ ] **Step 5: 验证 — flutter analyze 全项目**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter analyze
```
预期: `No issues found!`。可能出现 type error 因为方法签名变更——按错误提示逐一修复调用方。

- [ ] **Step 6: 验证 — flutter test**

```bash
cd /Users/yeyangyang/Desktop/spine_flutter && flutter test
```
预期: 所有已有测试通过。

- [ ] **Step 7: Commit**

```bash
git add packages/infrastructure/key_value_storage/lib/src/preference_key.dart
git add packages/infrastructure/key_value_storage/lib/src/shared_preference_storage.dart
git add packages/infrastructure/key_value_storage/lib/key_value_storage.dart
# git add <所有调用方修改的文件>
git commit -m "refactor(storage): extract PreferencesService keys to PreferenceKey enum

Replace 40+ static String constants with type-safe PreferenceKey enum.
All set/get/remove methods now accept PreferenceKey instead of String.
This eliminates magic strings and provides IDE autocomplete."
```

---

## 验证清单（全部 Task 完成后）

- [ ] `flutter analyze` — 零错误、零 warning
- [ ] `flutter test` — 所有已有测试通过
- [ ] `fvm flutter test --coverage` — 覆盖率不下降
- [ ] App 启动验证（模拟器）— 首页显示 HomePage，设置页显示 Settings info

---

## 回滚策略

每个 Task 独立 commit。如果某个 Task 出现问题：
1. `git log --oneline` 找到该 Task 的 commit hash
2. `git revert <commit-hash>` — 回滚该 Task 的所有变更
3. 后续 Task 不受影响（因为每个 Task 独立）
