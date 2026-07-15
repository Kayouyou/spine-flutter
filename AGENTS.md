# AGENTS.md

> AI Agent 工作守则 (Cursor / Claude Code / OpenCode / Codex / 其他)
> 项目方: Kayouyou
> 协议: MIT
> 适用版本: 0.1.x 起的 spine-flutter 公共骨架

---

## 0. 这是什么 (Read this first)

这是一个 **Flutter monorepo 公共骨架** (Clean Architecture, 4 层分仓 + Melos + Mason)。
AI Agent 接手时, 第一步是读完本文件, 再动手改代码。

**本骨架承诺**:
- 任何 feature 都能用 `make create-feature name=xxx` 一行命令生成
- 任何依赖方向违规在 commit 前被 pre-commit 钩子拦截
- 任何代码改动在合 main 前被 4 个 CI status check 卡住

**本骨架不承诺**:
- 业务模块 (登录/支付/订单 等需要按 feature 自己实现)
- UI 设计 (component_library 提供基础组件, 业务页面自己拼)

---

## 1. 硬规则 (违反任意一条, 你的 commit 会被 pre-commit 拒掉)

| # | 规则 | 怎么验证 | 违反后果 |
|---|---|---|---|
| R1 | feature 包**不得** import `package:spine_flutter/...` | `scripts/check_deps.sh` | CI 红 |
| R2 | domain 包**不得** import Flutter 任何包 | `pubspec.yaml` 里 SDK = `^3.0` 无 flutter 依赖 | `flutter pub get` 失败 |
| R3 | infrastructure 不依赖 services (反过来可以) | `scripts/check_deps.sh` | CI 红 |
| R4 | services 不依赖 features (反过来可以) | `scripts/check_deps.sh` | CI 红 |
| R5 | 所有 `EnvironmentConfig` 字段必须在 `env/.env.*` 3 个文件里都有 | 启动时 assert | 启动崩溃 |
| R6 | 所有新加的 API endpoint 必须走 Retrofit 接口 + Dio 拦截器栈 | review | 数据裸奔 |
| R7 | 所有新加的路由必须注册到 `RouteModuleRegistry`, 不要硬编码 `GoRouter` 路由 | review | 启动后路由不可达 |
| R8 | 所有错误必须走 `ErrorReporter` 抽象 (生产 Sentry, 开发 Console) | review | 线上无 Sentry 信号 |
| R9 | 所有 KV 存储必须用 `PreferenceKey` enum + 类型化 get/set | review | 拼写错误静默失败 |
| R10 | 所有 commit message 遵循 Conventional Commits (`type(scope): subject`) | lint 不强制, review 强制 | git log 难读 |

完整理由 + 反例见 `docs/di-discipline.md` 和 `docs/architecture-analysis.md`。

---

## 2. 技术栈 (锁版本, 别乱升)

| 层 | 包 | 版本 |
|---|---|---|
| 状态管理 | flutter_bloc | 9.x (HydratedBloc 走 hydrated_bloc) |
| 路由 | go_router | 14.x |
| DI | get_it + injectable | 7.x / 2.x |
| 网络 | dio + retrofit | 5.x / 4.x |
| 本地存储 | hive + hive_flutter | 2.x |
| 错误上报 | sentry_flutter | 8.14.2 |
| 版本升级 | upgrader | 10.3.0 |
| 调试 | alice (HTTP) | — |
| 包管理 | melos | latest |
| 砖块 | mason | latest |
| Flutter | 3.35.8-ohos-1.0.1 (FVM 锁 **OHOS fork**, 用于 OpenHarmony 适配) | — |
| Dart | 3.9.2 | — |

### 2.1 OpenHarmony (OHOS) 适配要点

- **Flutter 是 OHOS fork**：`3.35.8-ohos-1.0.1`（由 `.fvmrc` 锁定，与参考项目 `ovs_upgrade_335` 版本**完全一致**）。本骨架在 OHOS 上能跑，依赖 CPF-Flutter 提供带 ohos 原生实现的插件分支。
- **插件覆盖必须写进 `pubspec_overrides.yaml`（不是 `pubspec.yaml`）**：本项目用 Melos 管理 monorepo，`pubspec_overrides.yaml` 由 melos 自动生成并**接管** `dependency_overrides`。写在 `pubspec.yaml` 的 `dependency_overrides` 会被忽略。`flutter pub get` 时会打印 `routing ... (overridden in ./pubspec_overrides.yaml)`。当前已用 CPF 分支覆盖 9 个插件：`path_provider`、`shared_preferences`、`url_launcher`、`connectivity_plus`、`device_info_plus`、`package_info_plus`、`sensors_plus`、`share_plus`、`permission_handler`（具体分支与版本见 `pubspec_overrides.yaml` 与 `docs/ohos_plugin_compatibility_audit.md`）。
- **平台检测约定**：本 fork **没有** `Platform.isOHOS`，统一用 `Platform.operatingSystem == 'ohos'` 判断（禁止写 `Platform.isOHOS`）。
- **OHOS 专用守卫**：`upgrader` 用 `shouldWrapUpgrade()` 跳过（OHOS 无应用商店）；`sentry_flutter` 在 `lib/core/startup/launcher.dart` 用同样的 `isOhos` 守卫跳过 `SentryFlutter.init()`、改用 `ConsoleReporter`（CPF 无 sentry ohos 分支）。
- **构建走 make**：`make ohos-build` / `make ohos-deploy` / `make ohos-run` 已封装（内部 `FLUTTER_SUPPRESS_ANALYTICS=true` + 直接调 pinned SDK 二进制，规避坏代理下 `fvm flutter` 卡死）。详见 `README.md` 的 OpenHarmony 构建段与本文第 13 节。

**升级前必读**: `docs/runtime-infrastructure.md` 和 `openspec/changes/` 里同主题变更。

---

## 3. 仓库结构 (进新仓库时先认路)

```
.
├── lib/                          # 入口 (AppLauncher 启动)
│   ├── main.dart                 # 14 行: AppLauncher.launch(SpineFlutter())
│   ├── app.dart                  # StatefulShellRoute + RouteModuleRegistry 装配
│   └── core/
│       ├── bootstrap/            # BootstrapOptions (enable* flag)
│       ├── di/                   # setup.dart 显式 5 步注册
│       └── startup/              # launcher.dart 4 阶段启动
│
├── packages/
│   ├── domain/                   # 纯 Dart, 无 Flutter 依赖
│   │   └── lib/
│   │       ├── entities/         # 业务实体 (User, Order)
│   │       ├── repositories/     # 抽象接口 (IUserRepository)
│   │       ├── usecases/         # 业务用例 (GetUserUseCase)
│   │       └── result/           # Result<T,E> sealed class
│   │
│   ├── infrastructure/           # Flutter 实现
│   │   ├── api/                  # Dio + Retrofit 拦截器栈
│   │   ├── key_value_storage/    # Hive + PreferenceKey enum + SchemaVersion
│   │   ├── list_cache/           # 4 策略缓存 (CacheConfig)
│   │   ├── component_library/    # AppScaffold / CustomAppBar / LoadingButton
│   │   └── routing/              # RouteModule / FeatureRegistry / AuthGuard
│   │
│   ├── services/                 # 业务服务 (依赖 domain 接口, 不依赖 features)
│   │   ├── auth/                 # AuthManager + AuthCubit + 2 个 Repository 实现
│   │   ├── network/              # NetworkCubit + 弱网检测
│   │   ├── locale/               # LocaleCubit (HydratedBloc 持久化)
│   │   ├── error/                # SentryReporter + ErrorReporter 抽象
│   │   └── data_sync/            # StartupSyncable + DataSyncManager
│   │
│   └── features/                 # 业务特性 (按 feature 分包)
│       ├── feature_home/         # 示例
│       ├── feature_detail/       # 示例
│       └── feature_auth/         # 示例 (含登录流程)
│           └── lib/
│               ├── di/           # 显式注册 cubit/repository/usecase
│               ├── cubit/        # 状态管理
│               ├── repository/   # 仓库实现
│               ├── ui/           # 页面 + widget
│               └── routes/       # FeatureRouteModule (给 RouteRegistry 装配)
│
├── env/
│   ├── .env.dev                  # 占位符, 启动时 assert 字段齐全
│   ├── .env.staging
│   └── .env.prod
│
├── docs/                         # 11 篇指南 + 1 个 README 索引 (架构/测试/路由 等)
│   ├── architecture-analysis.md
│   ├── di-discipline.md
│   ├── auth-route-guard.md
│   ├── coverage-guide.md
│   ├── di-injection-flow.md
│   ├── hydrated_bloc-migration-guide.md
│   ├── ui-lifecycle-patterns-guide.md
│   ├── deep-link-guide.md
│   └── README.md             # 文档地图 (按主题分组)
│
├── openspec/changes/             # 4 个规范变更 (设计决策历史)
├── .sisyphus/notepads/           # AI 学习笔记 (本骨架作者的学习轨迹)
├── scripts/                      # 守门脚本 (check_deps.sh, check_l10n.sh, add_feature_dependency.py)
├── .githooks/pre-commit          # 4 步守门
├── .github/
│   ├── workflows/ci.yml          # 主 CI (analyze/test/build)
│   ├── workflows/dependabot-pr.yml  # Dependabot PR CI (只跑依赖改动)
│   ├── workflows/coverage.yml    # 覆盖率
│   └── dependabot.yml            # Dependabot 配置 (5 个 group 合并 PR)
│
├── melos.yaml                    # monorepo 管理
├── mason.yaml                    # 6 个砖块 (feature/api/model/hive_model/api_gen/api_gen_spec)
├── makefile                      # 25+ 命令
├── analysis_options.yaml         # 静态分析
└── pubspec.yaml                  # 根包 (path deps 12 个 + 第三方 15 个)
```

---

## 4. 常用命令 (改代码前先看)

### 4.1 新建/修改 模块

| 需求 | 命令 |
|---|---|
| 加新 feature | `make create-feature name=xxx` (一行装包+装依赖+跑 build_runner) |
| 加新 API client | `make create-api name=xxx` (Retrofit + Dio + json_serializable) |
| 加新 data model | `make create-model name=xxx` |
| 加新 Hive model | `make create-hive-model name=xxx` |
| 刷新 API 砖块 (API 改了重新生成) | `make refresh-api-mason` |
| 检查脚手架是否健康 | `make scaffold-check` |

### 4.2 monorepo 维护

| 需求 | 命令 |
|---|---|
| 装所有包 | `melos bs` (bootstrap) |
| 跑所有 analyze | `melos analyze` |
| 跑所有测试 | `melos test` |
| 跑受影响包测试 (快) | `melos test:affected` |
| 看覆盖率 | `melos test:coverage` |
| 检查依赖方向 (R1/R3/R4) | `./scripts/check_deps.sh` |
| 检查 ARB 翻译 | `./scripts/check_l10n.sh` |
| 检查版本兼容 | `melos check:versions` |
| 检查依赖过期 | `melos check:deps` |
| 全套 validate | `melos validate` |

### 4.3 启动 (3 套环境)

```bash
flutter run --dart-define=ENV=dev      # 默认
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=prod
```

### 4.4 调试 (BootstrapOptions 三件套, 默认全关)

- Alice (HTTP 拦截面板): `enableDebugTools: true`
- 数据预拉 (StartupSyncable): `enableDataSync: true`
- 弹升级提示 (Upgrader): `enableUpgradePrompt: true`

### 4.5 OpenHarmony (OHOS) 构建

| 需求 | 命令 |
|---|---|
| 全量构建 HAP (env=dev) | `make ohos-build` |
| 全量构建 + 装真机 | `make ohos-deploy OHOS_ENV=dev` |
| 仅改 ArkTS 时快速打包 | `make ohos-build-fast OHOS_ENV=dev` |
| release 构建 | `make ohos-build-release OHOS_ENV=prod` |
| 列设备 / 部署 + 抓日志 | `make ohos-devices` / `make ohos-run OHOS_ENV=dev` |
| 多平台统一入口 | `make build-android` / `make build-ios` / `make build-web` / `make build-ohos` |

⚠️ 首次构建需在 DevEco Studio 勾选 `Automatically generate signature` 生成调试证书（绑定本工程 `bundleName`）。底层命令与已知坑见 `README.md` OpenHarmony 段和本文第 13 节。
⚠️ 跑 Flutter 命令请用 make 或裸 `.fvm/flutter_sdk/bin/flutter`，**不要**用 `fvm flutter`（坏代理下会卡死）。

---

## 5. 关键概念 (5 分钟理解, 跳过这个会写错代码)

### 5.1 显式 DI (不要用 barrel / 副作用)

```dart
// ✅ 正确: 在 features/feature_xxx/lib/di/feature_xxx_module.dart 里显式 getIt.register
@injectable
class FeatureXxxModule {
  static void register(GetIt sl) {
    sl.registerLazySingleton<IXxxRepository>(() => XxxRepositoryImpl(sl()));
  }
}
```

为什么不用 `package:spine_flutter/core/di/setup.dart` barrel: barrel 会触发所有 feature 加载, 启动时 N 个 import 排队, 还要解决循环依赖。显式注册按需加载。

### 5.2 FeatureRegistry (启动期统一装配)

```dart
// ✅ feature 包在 lib/di/feature_xxx_di.dart 暴露一个 registerXxxRoutes
class FeatureXxxRouteModule implements RouteModule {
  @override List<GoRoute> routes() => [GoRoute(path: '/xxx', builder: (_, __) => XxxPage())];
}

// ✅ lib/app.dart 启动时统一调:
FeatureRegistry.runAll();  // 调用所有 feature 的 register
```

为什么: feature 包互不依赖, 启动期按字典序拼装, 加新 feature 不用改 app.dart。

### 5.3 AuthGuard (路由级守卫)

```dart
// ✅ 在 RouteModule 里给路由加守卫
GoRoute(
  path: '/settings',
  builder: (_, __) => const SettingsPage(),
  redirect: authGuardRedirect,  // 没登录踢到 /login
),
```

### 5.4 Result<T, E> 模式

```dart
// ✅ domain 层用 Result 而不是抛异常
sealed class Result<T, E> {
  const Result();
  factory Result.ok(T value) = Ok<T, E>;
  factory Result.err(E error) = Err<T, E>;
}

// ✅ 调 API 自动包成 Result
final result = await dio.get(...).toResult();
switch (result) {
  case Ok(:final value): ...
  case Err(:final error): ...
}
```

### 5.5 三层 Config (EnvironmentConfig → EnvAppConfig → IAppConfig)

```dart
// ✅ domain 抽象
abstract class IAppConfig {
  String get apiBaseUrl;
  String get sentryDsn;
}

// ✅ infrastructure 读 .env 实现
class EnvAppConfig implements IAppConfig { ... }

// ✅ 启动时
final config = EnvironmentConfig.fromEnv();  // 校验 .env 字段齐全
sl.registerSingleton<IAppConfig>(EnvAppConfig(config));
```

### 5.6 认证流程 (LoginCubit → AuthManager → AuthCubit)

```dart
// ✅ feature_auth 层: LoginCubit 驱动 UI 状态
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;
  final AuthManager _authManager;  // ← 注入 AuthManager
  
  Future<void> login() async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _authRepository.login(username, password);
    result.when(
      success: (loginResult) async {
        await _authManager.handleLoginSuccess(loginResult);  // ← 协调 token 保存
        emit(state.copyWith(status: LoginStatus.success));
      },
      failure: (error) => emit(state.copyWith(status: LoginStatus.error)),
    );
  }
}

// ✅ services 层: AuthManager 协调 token 保存和状态更新
class AuthManager {
  Future<void> handleLoginSuccess(LoginResult loginResult) async {
    await saveToken(loginResult.token, loginResult.userId);
    _authCubit.setAuthState(
      AuthState(status: AuthStatus.loggedIn, userId: loginResult.userId),
    );
  }
  
  Future<void> logout() async {
    await clearAuth();
    _authCubit.setAuthState(const AuthState());  // ← 直接 setAuthState
  }
}

// ✅ services 层: AuthCubit 只管理状态，不做业务逻辑
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());  // ← 无参构造
  bool get isLoggedIn => state.status == AuthStatus.loggedIn;
  void setAuthState(AuthState newState) => emit(newState);
  // ❌ 不要加 login()/logout() — 那是 AuthManager 的职责
}
```

**职责分离**:
- `LoginCubit` (feature_auth): 只关心 UI 状态 (loading/success/error)
- `AuthManager` (services/auth): 协调 token 持久化 + AuthCubit 状态更新
- `AuthCubit` (services/auth): 纯状态容器，setAuthState 是唯一写入入口

**为什么不能跳过 AuthManager**: AuthGuard 检查 `AuthCubit.isLoggedIn`，LoginCubit 必须通过 AuthManager 更新状态，否则 AuthGuard 会踢回 /login。

---

## 6. 常见修改场景 (改之前先查这里)

### 6.1 加新 feature 包
1. `make create-feature name=billing`
2. 在 `packages/billing/lib/di/billing_module.dart` 注册 cubit/repository
3. 在 `packages/billing/lib/routes/billing_route_module.dart` 实现 `RouteModule`
4. 跑 `melos bs` (新包被 Melos 认到)
5. 跑 `melos analyze && melos test:affected`
6. 在 `packages/billing/CHANGELOG.md` 写一行 "feat(billing): initial scaffold"

### 6.2 加新 API endpoint
1. `make create-api name=orders` (生成 api 包 + Retrofit + json_serializable)
2. 在新包的 `lib/src/orders_api.dart` 加 `@GET('/orders')` 注解
3. 跑 `dart run build_runner build` (生成 _api.g.dart)
4. 在 domain 包加 `IOrderRepository` 接口
5. 在 services 包加 `OrderRepositoryImpl` 实现
6. 在 feature 包加 cubit + page
7. 写测试: domain usecase 单测, repository 集成测, cubit bloc_test

### 6.3 改 dependencies
1. 改对应包 `pubspec.yaml` 的 dependencies 段
2. 跑 `melos bs` (同步到 path deps)
3. 跑 `melos analyze && melos test:affected`
4. 跑 `melos check:versions` (确认兼容)
5. 在 CHANGELOG 写 "deps(scope): bump xxx from 1.2.3 to 1.3.0"

⚠️ Dependabot 周一早上会自动提 PR, 走 dependabot-pr.yml CI 验证, 你 review + merge 即可。

### 6.4 加新路由
1. 在 `packages/feature_xxx/lib/routes/xxx_route_module.dart` 加 GoRoute
2. 不要直接改 `lib/app.dart` 的 StatefulShellRoute (那是壳)
3. 在 `RouteModuleRegistry` 加新模块 (一般 `create-feature` 会自动加)

### 6.5 加新多语言字符串
1. 在 `lib/l10n/app_en.arb` 和 `lib/l10n/app_zh.arb` 同时加
2. pre-commit `check_l10n.sh` 会校验两边一致
3. 跑 `flutter gen-l10n` 生成 dart 代码

### 6.6 排查"启动后页面打不开"
1. 看 `RouteModuleRegistry` 有没有把这个 feature 的 RouteModule 注册进去
2. 看 `FeatureRegistry.runAll()` 有没有执行 (lib/app.dart)
3. 看 `AuthGuard` 有没有把路径 redirect 到 /login

### 6.7 排查"API 401 但 token 没过期"
1. 看 Dio 拦截器栈的 TokenInterceptor 顺序 (`infrastructure/api/lib/src/interceptors/`)
2. 看 TokenStorage 是不是被双开 (Hive box 重复 open)
3. 看 401 是不是被自动续期吞了 (RxDart 流式续期)

### 6.8 排查"登出后 UI 没跳 /login"
1. 看 app.dart 是否注入了 refreshListenable (P1-3 后必装, `GoRouterRefreshStream`)
2. 看 AuthCubit 是否 LazySingleton (DI 步骤 3)
3. 看 AuthManager.logout 是否走 `_authCubit.setAuthState(AuthState())` — 状态变化才会触发 stream
4. 看 feature 层登出逻辑是否调用了 `AuthManager.logout()` 而不是直接改 UI 状态

### 6.9 排查"登录后被踢回 /login"
1. 看 LoginCubit.login() 是否调用了 `AuthManager.handleLoginSuccess(loginResult)` — 这是关键
2. 看 AuthManager 是否正确保存 token 到 TokenStorage
3. 看 AuthCubit 状态是否变为 loggedIn — 可通过 AuthCubit.stream 观察
4. 看 AuthGuard 的 publicRoutes 配置 — /login 必须在公开路由列表里

---

## 7. 测试策略 (改完代码必须跑)

| 测什么 | 工具 | 位置 |
|---|---|---|
| 业务用例 | 纯 dart test + mocktail | `packages/domain/test/` |
| Cubit / Bloc | bloc_test | `packages/services/test/` 和 `packages/features/*/test/` |
| Repository | mocktail mock Dio / Hive | `packages/infrastructure/*/test/` |
| Widget | flutter_test | `packages/features/*/test/widget_test.dart` |
| 集成 | integration_test | `integration_test/` (目前未启用, 1-2 人可省略) |

跑法: `melos test` 全量, `melos test:affected` 只跑受影响的包 (快)。

---

## 8. 提交 + PR 流程

### 8.1 commit message (Conventional Commits)

```
<type>(<scope>): <subject>

<body>

<footer>
```

| type | 用途 | 例 |
|---|---|---|
| feat | 新功能 | `feat(billing): add subscription cancel flow` |
| fix | 修 bug | `fix(auth): prevent 401 redirect loop` |
| refactor | 重构 | `refactor(routing): extract AuthGuard to mixin` |
| docs | 文档 | `docs: add AGENTS.md` |
| test | 测试 | `test(cubit): cover null user state` |
| deps | 依赖 | `deps(infrastructure): bump dio to 5.7.0` |
| chore | 杂事 | `chore: bump melos to 6.0.0` |

subject ≤ 50 字符, body 72 换行, footer 引 issue。

### 8.2 commit 前自检 (pre-commit hook 会强制)

1. `melos check:deps` — 依赖没过期
2. `./scripts/check_l10n.sh` — ARB 同步
3. `melos analyze` — 静态分析
4. `melos test:affected` — 受影响包测试

不通过: 不要 `--no-verify` 跳过, 改到通过。

### 8.3 PR 流程 (1 人项目也走)

1. `git checkout -b feat/xxx`
2. 写代码 + 跑 pre-commit
3. `git push -u origin feat/xxx`
4. 开 PR, 写清楚变更说明 + 截图 (UI 改动)
5. 等 CI 4 个 status check 全过 (analyze/test/build/analyze-and-test)
6. 自我 review diff 一遍
7. Squash merge (linear history 强制)

⚠️ **直接 push main** 会绕过 status check, pre-commit 钩子是唯一守门, 别偷懒。

### 8.4 紧急回滚

```bash
# 1. 看哪条 commit 出了问题
git log --oneline -20

# 2. revert 那条
git revert <sha>

# 3. push
git push
```

⚠️ 不要用 `git reset --hard` (branch protection 禁止 force push)。

---

## 9. 错误处理 (生产红线)

### 9.1 上报分层

```
UI (page) → Cubit → Repository → Dio
                              ↓ 失败
                         ErrorReporter (抽象)
                              ↓
                  SentryReporter (prod) | ConsoleReporter (dev)
```

### 9.2 强制走 AppErrorHandler

```dart
// ✅ 正确: 通过单例上报，内部走 ErrorReporter 抽象
try {
  await api.fetch();
} catch (e, st) {
  AppErrorHandler.instance.reportError(e, st);
  rethrow;  // 让 cubit 决定 UI 怎么显示
}

// ❌ 错: 自己 print + 不上报
} catch (e) {
  print(e);
}
```

> 说明: 实际上报实现由 `ErrorReporter` 接口承载，生产用 `SentryReporter`，开发用 `ConsoleReporter`。
> `AppErrorHandler` 是统一入口（内含 LRU 去重），**不**通过 GetIt DI 注入，直接 `AppErrorHandler.instance` 调用。
> Dio 层和 BlocObserver 已自动接入，业务层通常无需手动上报。详见 `packages/services/error/README.md`。

### 9.3 Sentry 必开配置

- `env/.env.prod` 的 `SENTRY_DSN=` 必须填真实 DSN
- `release` 自动从 `pubspec.yaml` 的 version 读
- `environment` 从 `ENV` 读 (dev/staging/prod)
- ⚠️ **OHOS 例外**：`lib/core/startup/launcher.dart` 用 `Platform.operatingSystem == 'ohos'` 守卫跳过 `SentryFlutter.init()`，错误上报改走 `ConsoleReporter`。原因：CPF-Flutter 没有 sentry 的 ohos 分支，OHOS 上无原生 SDK 可初始化。不要在 OHOS 上强行初始化 Sentry。

---

## 10. 监控 + 升级 (你不用管, 但要知道)

| 工具 | 干什么 | 开关 |
|---|---|---|
| Sentry | 崩溃 + 性能 | `bootstrap_options.enable_data_sync=false` 不影响, Sentry 永远开 |
| Upgrader | 弹升级提示 (OHOS 上被 `shouldWrapUpgrade` 守卫跳过, 无应用商店) | `bootstrap_options.enable_upgrade_prompt=true` |
| Alice | HTTP 拦截面板 | `bootstrap_options.enable_debug_tools=true` (仅 dev) |
| Dependabot | 周一早上扫依赖, 提 PR | 全自动, 你只需 review |
| CI | push/PR 触发 | 4 个 check (analyze/test/build/analyze-and-test) |

---

## 11. 文档地图 (找东西来这里)

| 我想... | 看 |
|---|---|
| 了解整体架构 | `docs/architecture-analysis.md` |
| 了解 DI 注入流程 | `docs/di-injection-flow.md` |
| 了解路由守卫 | `docs/auth-route-guard.md` |
| 了解 DI 纪律 (为什么不能 barrel) | `docs/di-discipline.md` |
| 跑覆盖率 | `docs/coverage-guide.md` |
| HydratedBloc 迁移 | `docs/hydrated_bloc-migration-guide.md` |
| UI 生命周期 mixin | `docs/ui-lifecycle-patterns-guide.md` |
| 深链接处理 | `docs/deep-link-guide.md` |
| 文档地图 (按主题分组) | `docs/README.md` |
| 看设计决策历史 | `openspec/changes/` |
| 看 AI 学习笔记 | `.sisyphus/notepads/` |
| OHOS 插件兼容性审计 | `docs/ohos_plugin_compatibility_audit.md` |

---

## 12. AI 守则 (写完代码后, 你必须做)

### 12.1 完成前自查 (Verification before completion)

- [ ] 代码改了, `melos analyze` 通过
- [ ] 改了 domain 逻辑, `melos test:affected` 跑过
- [ ] 加了新依赖, `melos bs` 跑过
- [ ] 改了 README/CHANGELOG, 跑过 `mkdocs serve` 预览 (如有)
- [ ] commit message 符合 Conventional Commits
- [ ] 没引入新的 lint warning (`flutter analyze --no-fatal-infos --no-fatal-warnings` 0 warning)

### 12.2 自我怀疑 (Iron Law)

- 看到 "should work" → 跑一遍 verify
- 看到 "probably fine" → 跑一遍 verify
- 看到 "I think" → 跑一遍 verify

"应该" / "可能" / "我觉得" 都是"未验证"的同义词。

### 12.3 不要做的事

- ❌ 跳过 pre-commit (`git commit --no-verify`)
- ❌ 跳过 CI (`gh pr merge --admin`)
- ❌ 改 `lib/main.dart` (那是入口, 改它等于改所有)
- ❌ barrel import (`import 'package:spine_flutter/core/...'`)
- ❌ feature 包之间互相 import
- ❌ 强推 (`git push --force`)
- ❌ amend 已经 push 的 commit

### 12.4 推荐的做事节奏

1. 读本文件 (5 分钟)
2. 读对应模块的 README (packages/xxx/README.md) (5 分钟)
3. 跑一次 `melos bs && melos analyze` 确认环境干净 (2 分钟)
4. 改代码
5. 跑 `melos test:affected` (2 分钟)
6. commit + push
7. 开 PR, 自我 review

---

## 13. OpenHarmony (OHOS) 适配与已知坑

> 完整插件兼容性审计见 `docs/ohos_plugin_compatibility_audit.md`。以下为 AI Agent **改代码 / 加依赖** 时最容易踩的坑，违反会导致空白屏、构建失败或崩溃。

### 13.1 空白屏根因（最高优先级）
- **现象**：`flutter build hap` 装真机后界面空白，`onAbilityDied` 约 5 秒崩溃。
- **根因**：`path_provider` / `shared_preferences` 等插件在 pub.dev 镜像版**无 ohos 原生实现**，`AppLauncher` 在 `runApp()` 前调用 `initPlugins`（含 `getApplicationDocumentsDirectory()`）抛异常，原生窗口一直空白。
- **解决**：用 CPF-Flutter 的 ohos 分支覆盖这些插件（见 2.1）。**加任何新插件都要先确认它有 ohos 支持**，否则同样空白屏。

### 13.2 插件覆盖必须写进 pubspec_overrides.yaml
- Melos 生成的 `pubspec_overrides.yaml` 会**接管** `dependency_overrides`；写在 `pubspec.yaml` 里的同名段会被忽略。
- 改依赖覆盖时**两个文件都加**（`pubspec.yaml` 方便人读 + `pubspec_overrides.yaml` 让 melos 生效）。`pubspec_overrides.yaml` 顶部有 `melos_managed_dependency_overrides` 注释，melos 重新 bootstrap 时会**保留**手写段。

### 13.3 sensors_plus 分支改名
- `br_sensors_plus-v7.0.0_ohos` 分支把 `pubspec.yaml` 的 `name` 改成了 `sensors_plus_ohos`，pub 报 `name doesn't match`。改用 `br_sensors_plus-v6.1.1_ohos`（保持原名，且匹配代码里的 `List<ConnectivityResult>` API，无需升 7.0.0 改代码）。

### 13.4 permission_handler 分支无 ohos 声明
- `br_v12.0.1_ohos` 分支未在其 `pubspec.yaml` 声明 ohos 平台，覆盖对 ohos **无效**（它只是把版本升到 12.0.1）。OVS 靠手动在 `oh-package.json5` 加 `permission_handler_ohos` 才跑通。本项目业务代码未直接使用 `permission_handler`（仅 transitive），暂不阻塞；若以后要用需补原生包。

### 13.5 fvm 卡死 / 坏代理
- 坏代理下 `fvm flutter --version` 会卡 ~3 分钟。make/脚本统一用裸 `.fvm/flutter_sdk/bin/flutter` + `FLUTTER_SUPPRESS_ANALYTICS=true`。Agent 跑命令也请用这个，别用 `fvm flutter`。

### 13.6 pre-commit 用错 SDK
- pre-commit 钩子若用全局 `fvm default` 的旧 SDK，会报上千个 URI 错误。钩子内每条命令 `export PATH="$(pwd)/.fvm/flutter_sdk/bin:$PATH"`，确保走项目 pinned SDK。当前全局 Flutter 也已为 `3.35.8-ohos-1.0.1`，冲突已消除。

### 13.7 签名按 bundleName 绑定
- 调试签名证书绑定 `bundleName`（本工程 `com.scaffold.spine_flutter`）。**不要**借用别的工程的 `.p7b`/material，否则 `SignHap 00303074`（bundleName 不匹配）。解决：DevEco `Automatically generate signature` 生成匹配证书，写回 `ohos/build-profile.json5`。签名 material 在 `~/.ohos/config/`，机器相关，换机需重新生成。

### 13.8 引擎内部噪声（可忽略）
- 真机日志里 `undefined is not callable` 来自 `@ohos/flutter_ohos` 引擎自带 `NavigationChannel.ets:167`（`notifyPageChanged` 读 `get` 属性为 null），是 flutter_ohos 3.35.8 fork 的已知内部 bug，**非应用/插件问题**，不影响渲染（页面正常 `page/2 first show`），Dart 侧无法修复，忽略即可。

### 13.9 其他 OHOS 限制
- OHOS 不支持 `--dart-define-from-file`：env 注入统一走 `ohos_utils/ohos_build.sh` 把 `KEY=VALUE` 展开为 `--dart-define`。
- `flutter build hap` 会重生成 `GeneratedPluginRegistrant.ets`（已 gitignore），`ohos_utils/ohos_fix.sh` 兜底清理 stale lock。

---

## 14. 紧急联系 + 维护

- 仓库: https://github.com/Kayouyou/spine-flutter
- 维护者: Kayouyou
- License: MIT
- 协议版本: 0.1.x

发现骨架 bug → 在仓库开 issue。
本文件也需要维护, 改了别忘了同步更新。
