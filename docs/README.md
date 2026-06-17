# docs/ — 文档地图

> 项目所有指南文档的入口索引. 按主题分组, 给出推荐阅读顺序 + 一句话摘要.
> 创建动机: SCAFFOLD_REVIEW_RETROSPECTIVE.md §4 L-9 (docs/ 无 README 索引).

---

## 🗺️ 快速导航 (按用途)

### 新人入职 (按顺序读这 3 篇)

1. **[architecture-analysis-2026-05-07.md](./architecture-analysis-2026-05-07.md)** — Clean Architecture + 4 层分仓 + Melos 全景图
2. **[di-injection-flow.md](./di-injection-flow.md)** — 启动期 5 步 DI 注册 + FeatureRegistry 装配机制
3. **[api-layer-guide.md](./api-layer-guide.md)** — Dio 6 层拦截器链 + Retrofit 声明式 API

### 写新 feature / 业务模块

1. **[di-discipline.md](./di-discipline.md)** — 为什么不能 `barrel import`, 显式 DI 规则
2. **[ui-lifecycle-patterns-guide.md](./ui-lifecycle-patterns-guide.md)** — UI 层 mixin / 页面骨架 / BlocConsumer 模式
3. **[auth-route-guard.md](./auth-route-guard.md)** — 加新路由 + 守卫

### 调 bug / 排查问题

| 症状 | 看哪篇 |
|------|--------|
| 启动后页面打不开 | `auth-route-guard.md` §排查 |
| API 401 但 token 没过期 | `api-layer-guide.md` §拦截器 |
| 登出后 UI 没跳 /login | `auth-route-guard.md` + `api-layer-guide.md` |
| 登录后被踢回 /login | `auth-route-guard.md` + `auth-route-guard.md` |
| HydratedBloc 状态丢失 | `hydrated_bloc-migration-guide.md` |
| Deep Link 打不开 | `deep-link-guide.md` |

### 提升质量

| 任务 | 看哪篇 |
|------|--------|
| 跑覆盖率 / 看 CI 门槛 | `coverage-guide.md` |
| 跑 mutation test | `coverage-guide.md` §Mutation |
| HydratedBloc 替代 SharedPreferences | `hydrated_bloc-migration-guide.md` |
| 加深链接路由 | `deep-link-guide.md` |

---

## 📚 完整文档列表 (按主题分组)

### 🏛️ 架构 / 分层

| 文档 | 一句话摘要 |
|------|-----------|
| [architecture-analysis-2026-05-07.md](./architecture-analysis-2026-05-07.md) | 14 个本地包 + 4 层分仓的全面架构分析 (含评分, 2026-05-07 版本) |
| [api-layer-guide.md](./api-layer-guide.md) | `packages/infrastructure/api` 包的职责 / 6 层拦截器链 / Token 续期机制 |

### 💉 DI / 启动流程

| 文档 | 一句话摘要 |
|------|-----------|
| [di-injection-flow.md](./di-injection-flow.md) | 从 `main.dart` 到 `FeatureRegistry.runAll()` 的完整启动 DI 链路图 |
| [di-discipline.md](./di-discipline.md) | DI 纪律: 为什么禁止 barrel import, 显式注册 vs 副作用注入 |

### 🛣️ 路由

| 文档 | 一句话摘要 |
|------|-----------|
| [auth-route-guard.md](./auth-route-guard.md) | RouteModule + AuthGuard 配置 / public routes / 登录态刷新 |

### 🧪 测试 / 质量

| 文档 | 一句话摘要 |
|------|-----------|
| [coverage-guide.md](./coverage-guide.md) | flutter test --coverage 生成 lcov, CI 80% 门槛, mutation test |

### 🧱 状态管理 / 持久化

| 文档 | 一句话摘要 |
|------|-----------|
| [hydrated_bloc-migration-guide.md](./hydrated_bloc-migration-guide.md) | HydratedBloc 适用场景 + 从 SharedPreferences 迁移路径 + 与 Hive 对比 |

### 🎨 UI / 生命周期

| 文档 | 一句话摘要 |
|------|-----------|
| [ui-lifecycle-patterns-guide.md](./ui-lifecycle-patterns-guide.md) | UI 层统一页面骨架 / BlocConsumer / 生命周期 mixin / 导航栏规范 |

### 🔗 深度链接

| 文档 | 一句话摘要 |
|------|-----------|
| [deep-link-guide.md](./deep-link-guide.md) | Custom scheme + Universal Links 配置 / GoRouter 处理 / 冷启动处理 |

---

## 📂 文档治理记录

- **2026-06-17**: 删除 2 个 stub 文档 (domain-testing-guide.md / solo-ai-scaffold-guide.md), 文档从 13 → 11
- **2026-06-17**: 创建本文档, 解决 SCAFFOLD_REVIEW_RETROSPECTIVE.md L-9 (无 README 索引)
- **维护原则**: 文档内容必须实质, 不接受 stub 占位. 新增文档请同步更新本文档.

---

## 🔗 相关入口

- **AGENTS.md §11** — 文档地图简版 (在项目根目录)
- **openspec/changes/** — 设计决策历史 (架构变更提案)
- **.sisyphus/notepads/** — AI 学习笔记 (本骨架作者的学习轨迹)
- **SCAFFOLD_REVIEW_RETROSPECTIVE.md** — 项目健康度复盘报告