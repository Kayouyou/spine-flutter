# core 模块

## 职责

`lib/core/` 是**主 app 的组装车间**，只负责：

1. **依赖注入配置**（di/）— 注册哪些服务、用哪个实现
2. **启动流程编排**（startup/）— App 怎么启动、先初始化什么
3. **全局状态管理**（global/）— 跨 feature 共享的应用级状态

## 判断标准

> 如果某个模块放的是"具体业务实现"而不是"组装逻辑"，就该提为包。

### 可以放进来的

| 类型 | 示例 | 说明 |
|------|------|------|
| 组装逻辑 | `di/locator.dart` | 全局服务定位器 |
| 组装逻辑 | `di/setup.dart` | 注册服务、调 feature 自注册函数 |
| 启动流程 | `startup/launcher.dart` | App 启动入口编排 |
| 启动流程 | `startup/initializer.dart` | SDK 初始化调用 |
| 启动流程 | `startup/profiler.dart` | 启动性能计时 |
| 全局状态 | `global/network/` | NetworkCubit + NetworkBanner |
| 全局状态 | `global/locale/` | LocaleCubit |

### 不该放进来的

| 内容 | 应该放哪 | 原因 |
|------|----------|------|
| AuthManager | `packages/auth/` | 业务实现，不是组装逻辑 |
| DataSyncManager | `packages/data_sync/` | 业务实现，多 feature 共享 |
| AppLogger | `packages/app_logger/` | 基础设施工具 |
| AppConstants | `packages/app_constants/` | 配置常量，应该被包引用 |
| 某个 feature 的页面/状态/数据 | `packages/features/feature_X/` | 业务模块 |

## 依赖规则

- **core 可以依赖**：基础设施包（api、domain_models、auth...）、feature 包
- **core 不可以被依赖**：feature 包不能 import `package:my_app/core/`
- **core 不实现业务逻辑**：它只负责"把东西组装起来"
