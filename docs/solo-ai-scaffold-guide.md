# Solo + AI Scaffold Guide

## 先看这 6 条

1. 新增 feature 后，必须去 `lib/core/di/setup.dart` 显式注册
2. Feature 不允许直接调用 `GetIt.instance`
3. App 级能力只能放在 `lib/`，不要放进 feature 包
4. 共享模型放 `packages/domain/`
5. `make scaffold-check` 是改完脚手架后的第一条验收命令
6. `services/data_sync`、调试面板、升级提醒默认都按可选模块理解
