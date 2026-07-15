# 模块结构命名映射 · Module Structure Mapping

> 团队口语常说「presentation / domain / data」三层。本项目是 **Melos monorepo 跨包分层**，物理组织不同，但**思想完全一致**——不是缺陷，只是换了个摆放方式。
> 本文把「团队口语」↔「本仓实际目录」对应关系列清楚，降低新人上手成本。

---

## 1. 一句话对照

| 团队口语（逻辑层） | 本仓实际位置（物理包/目录） | 说明 |
|--------------------|------------------------------|------|
| **presentation（表现层）** | `packages/features/*/lib/src/ui/`（页面与组件）<br>`packages/features/*/lib/src/cubit/`（状态）<br>`packages/infrastructure/component_library`（共享令牌与组件） | UI 与状态都按 feature 分包；共享样式/组件在 component_library |
| **domain（领域层）** | `packages/domain/lib/src/` | 纯 Dart，**无 Flutter 依赖**；实体、仓库接口、用例、错误、结果类型 |
| **data（数据层）** | `packages/features/*/lib/src/repository/`（仓库实现）<br>`packages/infrastructure/api`（远程，Dio/Retrofit）<br>`packages/infrastructure/key_value_storage`、`list_cache`（本地）<br>`packages/services/*`（network/auth/data_sync/error/locale 等横切能力） | 实现 domain 定义的仓库接口；远程 + 本地 + 横切服务 |

> 区别只在：团队把三层放在「同一个包内的三个文件夹」，本仓把三层拆成「多个独立 pub 包」。依赖方向、职责边界一模一样。

---

## 2. 仓库实际结构（已核对）

```
packages/
├── domain/                      # ← domain 层（纯 Dart，垫底，被所有层依赖）
│   └── lib/src/
│       ├── models/              #   实体 Entity
│       ├── repositories/        #   仓库接口（auth_repository / home_repository ...）接口，无实现
│       ├── usecases/            #   用例（login / get_home_data ...）
│       ├── exceptions/ result.dart enums/ config/   # 错误、FutureResult、枚举、配置接口
├── infrastructure/              # ← data 层能力（meta 包，聚合多个子包）
│   ├── api/                     #   远程数据（Dio + Retrofit 拦截器链）
│   ├── component_library/       #   共享设计令牌 + 通用组件（presentation 共享件）
│   ├── key_value_storage/       #   本地 KV（CacheData<T> + MigrationRunner）
│   ├── list_cache/              #   本地列表缓存
│   └── routing/                 #   路由依赖反转辅助
├── services/                    # ← 横切服务（被 data/feature 复用）
│   ├── network/ auth/ data_sync/ error/ locale/
└── features/                    # ← presentation + 各 feature 自带 data 实现
    ├── feature_auth/    lib/src/{cubit,di,routes,ui}          # 登录态无独立 repository
    ├── feature_home/    lib/src/{cubit,di,models,repository,routes,ui}
    ├── feature_detail/  lib/src/{cubit,di,models,repository,routes,ui}
    └── feature_settings/lib/src/{di,routes,ui}                # 设置页多走 services，无本地 repository
```

> 注意：`feature_*` 是**垂直切片**——一个业务功能需要的 presentation + 该功能的 repository 实现都放同一个包里；真正跨功能共享的 domain 契约在 `packages/domain`，共享数据能力在 `infrastructure`/`services`。

---

## 3. 依赖方向（单向，永不可反向）

```
app(lib/core) → features → services → infrastructure → domain
```

- `domain` 纯 Dart 垫底，不依赖任何人；所有上层都可依赖它，但它不依赖任何上层。
- `infrastructure` 不依赖 `services`（R3）；`services` 不依赖 `features`（R4）；`feature` 不得 `import package:spine_flutter/...`（R1）。
- 仓库**接口**定义在 `domain`，**实现**在 `feature/*/repository` 或 `infrastructure/api`；上层只依赖接口，不依赖具体实现（依赖反转）。

---

## 4. 常见困惑解答

**Q：为什么看不到单独的 `data/` 文件夹？**
A：data 层被拆到了 `infrastructure/`（api、存储）、`services/`（网络/鉴权等）、以及各 `feature/*/repository/`。没有「一个大 data 包」，但 data 职责一个不少。

**Q：presentation 不是应该包含 state 管理吗？怎么在 feature 里？**
A：是的。presentation = `ui/`（Widget/Page）+ `cubit/`（Bloc/Cubit 状态）。它们都在 `feature_*` 包内，因为状态和页面同属一个业务功能，垂直切片更内聚。

**Q：component_library 算哪层？**
A：它提供的是 presentation 的共享件（令牌、通用组件），本身不含业务逻辑，被所有 feature 依赖。它属于「表现层基础设施」，不归入 domain/data。

---

## 5. 新增功能时往哪放（速记）

| 你要加的东西 | 放哪 |
|--------------|------|
| 页面 / Widget | `packages/features/feature_xxx/lib/src/ui/` |
| 状态（Cubit/Bloc） | `packages/features/feature_xxx/lib/src/cubit/` |
| 实体 / 仓库接口 / 用例 | `packages/domain/lib/src/...` |
| 仓库实现（调 API/本地） | `packages/features/feature_xxx/lib/src/repository/` |
| 远程 API 模块 | `packages/infrastructure/api`（或 `make scaffold-api`） |
| 本地存储模型 | `packages/infrastructure/key_value_storage`（或 `make create-hive-model`） |
| 跨功能横切能力 | `packages/services/*` |
| 共享样式/组件 | `packages/infrastructure/component_library` |

> 一句话：**业务功能垂直切进 `features/*`；跨功能共享的契约进 `domain`、能力进 `infrastructure`/`services`、UI 件进 `component_library`。**
