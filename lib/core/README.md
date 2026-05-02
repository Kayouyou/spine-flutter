# core 模块

## 职责

`lib/core/` 是主 app 的组装车间，只负责：

1. **依赖注入配置**（di/）— 注册服务
2. **启动流程编排**（startup/）— App 启动入口
3. **多语言**（l10n/）— ARB 国际化
4. **工具**（utils/）— AppLogger 等

> 全局状态（NetworkCubit、LocaleCubit）已迁移至 packages/services/。
