# services 目录

业务服务包的组织目录。

## 目录下有哪些包

- auth/ - 认证服务包（独立 package）
- data_sync/ - 数据同步服务包（独立 package）

## 为什么每个服务是独立 package？

| 维度 | 独立 package | 单一 package |
|-----|-------------|-------------|
| 编译器约束 | ✓ 独立依赖约束 | ✗ 混在一起 |
| 独立测试 | ✓ 单独运行 | ✗ 必须跑整体 |
| 依赖控制 | ✓ feature 只依赖需要的 | ✗ 依赖所有 |

## UseCase vs 业务服务 vs 业务功能（三个概念的区别）

很多新接手的人容易把这三个搞混，用一句话记忆：

> **UseCase** → "一次任务"（调用 execute，做完就走）
> **Service** → "一个管家"（全局管家，长期在位）
> **Feature** → "一间店铺"（有门面有内容，用户直接逛）

| 维度 | UseCase（domain/usecases） | Service（services/） | Feature（features/） |
|------|---------------------------|---------------------|---------------------|
| **一句话** | 执行一个业务任务 | 提供一种全局能力 | 提供一个用户功能页面 |
| **在哪层** | domain（最核心） | services（中间层） | features（最外层） |
| **有状态？** | ❌ 无状态，用完就丢 | ✅ 有状态，长期存活 | ✅ 有状态，随页面生命周期 |
| **方法数** | 只有 `execute()` 一个 | 多个（login/logout/refresh...） | 多个（Cubit/Page 组合） |
| **面向谁** | 面向调用者，编排逻辑 | 面向 features，提供能力 | 面向用户，展示界面 |
| **生命周期** | Factory（每次新建） | Singleton（全局唯一） | Factory（路由创建时新建） |
| **注册位置** | domain 或 services 的 setup | services/x/di/setup.dart | features/x/di/setup.dart |

**以"用户登录"为例，三者怎么协作：**

```
用户操作 → LoginPage（Feature）
              │
              │ 调用 LoginCubit.login()
              ▼
        LoginCubit（Feature 层）
              │
              │ 调用 UseCase 或直接调用 Repository
              ▼
        LoginUseCase（domain/usecases）
              │
              │ 编排多个操作：验证 → 调 API → 存 Token → 触发同步
              ▼
        AuthRepository（services/auth）
              │
              │ 发起真实 HTTP 请求
              ▼
        AuthManager（services/auth）
              │
              │ 登录后全局状态管理：isLoggedIn、token、用户信息
```

## 业务服务层 vs 业务功能层（补充说明）

| 维度 | services/（业务服务层） | features/（业务功能层） |
|------|------------------------|------------------------|
| 有没有页面 | ❌ 没有 UI | ✅ 有页面，用户直接看到 |
| 跨功能？ | ✅ 是，任何 feature 都能用 | ❌ 否，一个 feature 只做一件事 |
| 依赖方向 | 依赖 infrastructure（Dio, Hive） | 依赖 services（通过 Repository 注入） |

**依赖方向：features → services → infrastructure**

## 与其他层协作

### 调用 UseCase

构造函数注入 UseCase，在业务流程中调用。

### 触发数据同步

在 AuthManager.login() 成功后调用 DataSyncManager.sync()。

## 添加新 service

1. 创建 packages/services/<service_name>/ 目录
2. 创建 pubspec.yaml
3. 创建 barrel file + manager.dart + di/setup.dart
4. 创建 README.md
5. 主 app 添加依赖并调用 setup

## 约定

- 每个服务独立 package
- 注册为 Singleton