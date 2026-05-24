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

## 业务服务 vs UseCase 判断标准

| 维度 | 业务服务（AuthManager） | UseCase（GetUserInfoUseCase） |
|-----|----------------------|---------------------------|
| 生命周期 | app 级别（长期存在） | 请求级别（用完销毁） |
| 有状态 | ✓ 有（isLoggedIn） | ✗ 无状态 |
| 职责 | 提供某种**能力** | 执行某个**任务** |
| 方法数量 | 多个（login、logout） | 单一（execute） |
| 注册方式 | Singleton | Factory |

## 业务服务层 vs 业务功能层（容易搞混）

很多新接手的人容易把 **services/** 和 **features/** 搞混，两者的区别：

| 维度 | services/（业务服务层） | features/（业务功能层） |
|------|------------------------|------------------------|
| 有没有页面 | ❌ 没有 UI | ✅ 有页面，用户直接看到 |
| 面向谁 | 面向 features，提供全局能力 | 面向用户，用户可操作 |
| 跨功能？ | ✅ 是，任何 feature 都能用 | ❌ 否，一个 feature 只做一件事 |
| 生命周期 | 全局单例（registerSingleton） | 每次路由创建新实例（registerFactory） |
| 典型内容 | AuthCubit、NetworkCubit、LocaleCubit | HomeCubit+HomePage、DetailCubit+DetailPage |
| 依赖方向 | 依赖 infrastructure（Dio, Hive） | 依赖 services（通过 Repository 注入） |
| DI 注册位置 | `services/x/lib/src/di/setup.dart` | `features/x/lib/src/di/setup.dart` |

**依赖方向：features → services → infrastructure**

以登录为例：
- **services/auth** 提供 `AuthRepository`（认证能力）、`AuthCubit`（全局认证状态）
- **features/feature_auth** 使用这些能力，组装成 `LoginPage` + `LoginCubit`（用户能看到的登录页面）

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