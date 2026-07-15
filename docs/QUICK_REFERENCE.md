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

## 5. 常用工作流

| 要做的事 | 命令 / 位置 |
|----------|------------|
| 加新 feature | `make create-feature name=xxx` → 在根 `lib/core/di/setup.dart` 加一行 register |
| 加新 API | `make scaffold-api name=xxx baseUrl=/...` → 走 Retrofit + Dio 拦截器 |
| 修复依赖/版本漂移 | `melos run check:versions` 查 → 对齐 `.fvmrc` 与 CI(`3.35.8`) |
| 一键健康检查 | `melos run validate` |
| 提交前自验 | pre-commit 自动跑(check_deps→l10n→analyze→增量 test) |

> 技术栈版本锁定见 `AGENTS.md` §2;完整理由与反例见 `docs/di-discipline.md`、`docs/architecture-analysis-2026-05-07.md`、`docs/api-layer-guide.md`。
