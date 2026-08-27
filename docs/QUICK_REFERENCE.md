# 速查卡 · Quick Reference

> 给**开发者**和 **AI Agent** 的单页速查卡。
> 改代码前看 §1 硬约束；跑命令看 §2 / §3；想搞清架构看 §4。
> 详细理由 + 反例见 `AGENTS.md` 与 `README.md` 及各篇 `docs/*-guide.md`。

---

## 1. 硬约束 (R1–R10)

违反任意一条,`pre-commit` 钩子会**直接拒掉 commit**,或 CI 变红。

| # | 规则 | 怎么验证 | 违反后果 |
|---|------|----------|----------|
| R1 | feature 包**不得** `import package:spine_flutter/...` | `scripts/check_deps.sh` | CI 红 |
| R2 | domain 包**不得** import Flutter 任何包(`pubspec` SDK `^3.0` 无 flutter 依赖) | `flutter pub get` 失败 | 构建失败 |
| R3 | infrastructure **不依赖** services(反过来可以) | `scripts/check_deps.sh` | CI 红 |
| R4 | services **不依赖** features(反过来可以) | `scripts/check_deps.sh` | CI 红 |
| R5 | `EnvironmentConfig` 字段必须在 `env/.env.*` 三个文件里都有 | 启动时 assert | 启动崩溃 |
| R6 | 新 API 必须走 Retrofit 接口 + Dio 拦截器栈 | review | 数据裸奔 |
| R7 | 新路由必须注册到 `RouteModuleRegistry`(不要硬编码 `GoRouter`) | review | 路由不可达 |
| R8 | 错误必须走 `ErrorReporter` 抽象(生产 Sentry / 开发 Console) | review | 线上无信号 |
| R9 | KV 存储必须用 `PreferenceKey` enum + 类型化 get/set | review | 拼写错误静默失败 |
| R10 | commit message 遵循 Conventional Commits (`type(scope): subject`) | review | git log 难读 |

**依赖方向(单向):** `app → features → services → infrastructure → domain`
下层永不依赖上层;`domain` 纯 Dart 垫底,被所有层依赖但不依赖任何人。

---

## 2. Melos 命令(本项目 `melos.yaml` 已配置)

统一触发:`melos run <名>`。底层靠 `melos exec` 把命令批量分发到每个包。

| 命令 | 作用 | 底层 |
|------|------|------|
| `melos bs` | 一次性给所有 13 个包装依赖 | 扫描 `packages:` |
| `melos run analyze` | 全量静态分析(只拦 error) | `melos exec -- flutter analyze` |
| `melos run test` | 所有包跑测试 | `melos exec -- flutter test` |
| `melos run test:affected` | **只测改动相关包**(提交快的原因) | `melos exec --diff=origin/main` |
| `melos run test:coverage` | 测试 + 覆盖率 | `melos exec -- flutter test --coverage` |
| `melos run check:deps` | 依赖方向守卫(R1/R3/R4) | `scripts/check_deps.sh` |
| `melos run check:versions` | 检查关键依赖是否漂移 | `scripts/check_workspace_versions.dart` |
| `melos run validate` | 一键验收:deps→l10n→analyze→test | 串起上面几条 |
| `melos run check:coverage` | 卡覆盖率数据完整性红线 | 扫 `lcov.info` |

**通用 Melos 功能(本仓库不一定都启用):** `melos exec`(逐包执行任意命令,支持 `--scope/--exclude/--diff`)、`melos list`(列包)、`melos clean`(清产物)、`melos version`(统一升版本+CHANGELOG+tag)、`melos publish`(按拓扑发 pub.dev)、`melos create`(建包)、`melos upgrade`(升依赖)。

**Melos 在本项目的三个角色:** ① 工作区聚合(`bs` 一把装齐) ② 命令编排(`exec` 批量分发 + `test:affected` 增量) ③ **架构纪律执法者**(`check:deps` 强制单向依赖,`check:versions` 防漂移)。

---

## 3. Make 快捷命令

| 命令 | 说明 |
|------|------|
| `make get` / `make bs` | 安装所有包依赖(经 Melos) |
| `make lint` | 代码分析(`melos run analyze`) |
| `make test` | 跑所有包测试(Melos) |
| `make clean` | 清理构建缓存 |
| `make debug` / `make debug-simulator` | 调试运行 / iOS 模拟器 |
| `make dev` / `make staging` / `make prod` | 按环境运行(env/.env.*) |
| `make build-prod` | 生产构建 APK(env/.env.prod) |
| `make create-feature name=xxx` | 新建 Feature 包(生成+装依赖+freezed) |
| `make create-model name=xxx` | 建 @freezed 模型(domain 包) |
| `make create-api name=xxx baseUrl=/api/v1 [modelName=xxx]` | 建 Retrofit API 模块 |
| `make scaffold-api name=xxx baseUrl=/api/v1` | 一键 Model+API |
| `make create-hive-model name=xxx typeId=N` | 建 @HiveType 本地存储模型 |
| `make scaffold-check` | 脚手架健康检查(契约测试+workspace 验证) |

---

## 4. 架构一瞥

- **分层:** `lib/core`(根组装)+ `packages/{domain,infrastructure,services,features/*}`,由 Melos 管理。
- **DI:** `get_it`(`sl` 别名)+ 每模块自注册 `setupXxx(sl)` + 根 `lib/core/di/setup.dart` 按拓扑顺序装配。三种粒度:`registerSingleton`(启动即建)/`registerLazySingleton`(首次取用)/`registerFactory`(每次新建,页面级)。依赖靠**接口**解析,debug 可换 `Mock` 实现。
- **数据流(单向环流):** `UI 事件 → Cubit → Repository(接口) → Dio 拦截器链 → 后端`;响应以 `FutureResult` 回流 → `result.when(success/failure)` → `emit` 不可变 freezed state → `BlocBuilder` 重建 UI。
- **路由:** 插件式,Feature 在自身 `setup` 里 `RouteModuleRegistry.instance.register(...)`,App 层统一组装 `StatefulShellRoute`。
- **配置:** `--dart-define-from-file` 编译期注入;`prod` 环境对 `API_HOST/API_ACCESS_KEY_ID/OSS_*` 做 fail-fast 校验。

---

## 5. Config 存放与流向（单点定义，避免散落硬编码）

**结论：当前存放位置合理。** 配置采用「三层」结构，单一事实来源（`env/.env.*`）→ 编译期读取（`EnvironmentConfig`）→ 接口桥接（`IAppConfig`）→ DI 注入各层。域名(API_HOST)等高频项**只有一个定义入口**，不散落硬编码。

**流向图（箭头 = 数据方向）：**

```
env/.env.{dev,staging,prod}          ← 真实值唯一来源（API_HOST / OSS_* 等）
        │  --dart-define-from-file（编译期注入）
        ▼
lib/config.dart  →  EnvironmentConfig   ← 运行时唯一读取 dart-define 的地方
        │  （仅被下面两处 app 层代码直接读，见下注）
        ▼
lib/core/config/app_config.dart  →  EnvAppConfig implements IAppConfig   ← 唯一「桥接」实现
        │  DI 注入（sl<IAppConfig>()）
        ▼
packages/domain/.../app_config.dart  →  IAppConfig 接口   ← 干净契约，无 dart-define 依赖，可测
        │  被 features / services 通过 sl<IAppConfig>() 消费
        ▼
EnvApiConfig.host ← IAppConfig.apiHost   →  Dio baseUrl（setup.dart）
```

**各角色与文件：**

| 角色 | 文件 | 说明 |
|------|------|------|
| 真实值来源 | `env/.env.{dev,staging,prod}` | 三个环境文件，缺字段启动崩溃(R5)。`API_HOST` 为 API 根地址**权威源** |
| 编译期读取(唯一) | `lib/config.dart` → `EnvironmentConfig` | `String.fromEnvironment`；`prod` 对 `API_HOST/API_ACCESS_KEY_ID/OSS_*` fail-fast |
| 派生 | `EnvironmentConfig.apiBaseUrl` | = `https://$apiHost`（派生，非独立 dart-define；已消除 `API_BASE_URL` 冗余） |
| 接口契约(干净) | `packages/domain/lib/src/config/app_config.dart` → `IAppConfig` | 不含 dart-define，可单测 |
| 桥接实现(唯一 reader) | `lib/core/config/app_config.dart` → `EnvAppConfig` | 把 `EnvironmentConfig` 适配成 `IAppConfig` |
| 网络落地 | `packages/infrastructure/api/.../api_config.dart` → `EnvApiConfig` | `host ← IAppConfig.apiHost`，Dio baseUrl 走 `IAppConfig.apiBaseUrl` |

**直接读 `EnvironmentConfig` 的两处（均为 app 层 bootstrap，符合规则精神）：**
1. `lib/core/config/app_config.dart`（`EnvAppConfig`）—— 设计意图中的唯一 reader。
2. `lib/core/startup/launcher.dart` —— **启动期校验环境变量**，此时 DI 尚未装配(`setupDependencies` 在它之后)，无法走 `sl<IAppConfig>()`，故直接读 `EnvironmentConfig`。这是合理例外，非违规。

**单点定义（已消除冗余）：** `API_HOST` 是 API 根地址的**唯一权威源**；`apiBaseUrl` 由 `https://$apiHost` 派生，不再有独立的 `API_BASE_URL` dart-define。改域名只需改 `env/.env.*` 里的 `API_HOST` 一处。

---

## 6. 常用工作流

| 要做的事 | 命令 / 位置 |
|----------|------------|
| 加新 feature | `make create-feature name=xxx` → 在根 `lib/core/di/setup.dart` 加一行 register |
| 加新 API | `make scaffold-api name=xxx baseUrl=/...` → 走 Retrofit + Dio 拦截器 |
| 修复依赖/版本漂移 | `melos run check:versions` 查 → 对齐 `.fvmrc` 与 CI(`3.35.8`) |
| 一键健康检查 | `melos run validate` |
| 提交前自验 | pre-commit 自动跑(check_deps→l10n→analyze→增量 test) |

> 技术栈版本锁定见 `AGENTS.md` §2;完整理由与反例见 `docs/di-discipline.md`、`docs/architecture-analysis-2026-05-07.md`、`docs/api-layer-guide.md`。

---

## 7. 组件库 & 规范文档

### 组件库（`package:component_library`）
统一设计令牌 + 通用组件,**调用方只传业务内容、不传样式**。所有尺寸走令牌 / `.sp` / `.r`,禁止裸写绝对像素。

| 组件 | 用途 |
|------|------|
| `AppCell` | **列表项**(左图标 + 标题/副标题 + 右箭头/Switch/自定义) → 设置/详情页高频 |
| `AppCard` / `AppSection` | 卡片容器 / 分组标题 |
| `AppButton` / `LoadingButton` | 按钮(loading/disabled) |
| `EmptyState` / `ErrorCard` | 空态 / 错误态 |
| `AppTextField` / `AppDialog` / `AppToast` / `CustomAppBar` / `AppScaffold` | 输入 / 弹窗 / Toast / 导航栏 / 页面骨架 |

> 文字样式统一用 `context.textStyles.titleLarge` 等语义名(见 `lib/src/theme/app_text_styles.dart`);颜色用 `context.colors.*`。

### 规范文档（新增 API / 缓存 / 模块时必读）
- **缓存模型规范**:`docs/cache-model-guide.md` —— DTO⇄Entity⇄CacheModel 边界、何时独立 CacheModel、新增可缓存 API 的 5 步 checklist、迁移框架接法。
- **字体缩放策略**:`docs/font-scaling-guide.md`(P2-1) —— 锁定系统缩放 + `.sp` 等比自适应的刻意组合、为何不跟随系统字号、要支持无障碍时改哪一处。
- **模块结构命名映射**:`docs/module-structure-guide.md`(P2-2) —— 团队「presentation/domain/data」↔ 本仓 monorepo 跨包分层(packages/features·domain·infrastructure·services)的对应表与落点速记。
- 依赖注入纪律:`docs/di-discipline.md` · API 层:`docs/api-layer-guide.md`（含 11 层拦截器链、弱网重试/熔断/离线队列、统一信封、通用缓存、请求签名、全局取消 `cancelAll`）· 路由依赖反转:`docs/routing-dependency-inversion.md` · 鉴权路由守卫:`docs/auth-route-guard.md`
