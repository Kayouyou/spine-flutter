## Why

当前脚手架架构评分 9.0/10，但存在 8 项部分完成的要素。基于「通用模板 + 快速迭代 + 近期上线」的定位，需补充关键缺失能力以提升脚手架成熟度，为后续快速版本迭代奠定基础。

本次升级聚焦 6 项核心能力：路由守卫、测试覆盖、设置页/主题切换、CI覆盖率报告、数据迁移框架、FPS监控。Sentry接入待收费评估后决定。

## What Changes

- **路由守卫模块**：新增可选认证拦截机制，支持未登录用户访问保护路径时自动跳转
- **Domain测试**：补充 domain 层单元测试（User、Exception、UseCase），目标覆盖率 100%
- **设置页UI + 主题切换**：新增设置页面，集成 Light/Dark 主题动态切换与持久化
- **CI Coverage Report**：GitHub Actions集成测试覆盖率报告生成与展示
- **数据迁移框架**：Hive 存储版本管理 + 自动迁移机制，支持快速迭代数据结构变更
- **FPS监控**：运行时帧率监控 + 启动性能追踪扩展，检测卡顿与性能瓶颈

## Capabilities

### New Capabilities

- `auth-route-guard`: 路由认证守卫模块，提供可选的路径访问控制机制
- `domain-test-suite`: Domain层测试套件，覆盖models、exceptions、usecases
- `settings-page`: 设置页面模块，包含主题切换、语言选择等配置项
- `theme-switching`: 动态主题切换能力，支持Light/Dark模式切换与持久化
- `ci-coverage-report`: CI测试覆盖率报告生成与可视化展示
- `storage-migration`: Hive数据迁移框架，版本号管理+迁移函数注册
- `fps-monitoring`: 运行时帧率监控，FPS追踪+卡顿检测+性能报告

### Modified Capabilities

无现有 spec 被修改。本次为全新能力引入。

## Impact

**新增代码**：
- `packages/infrastructure/routing/lib/src/guards/` — 路由守卫实现
- `packages/features/feature_settings/` — 设置页 Feature包
- `packages/infrastructure/key_value_storage/lib/src/migration/` — 数据迁移框架
- `packages/services/performance/` — FPS监控服务包（新建）
- `test/unit/domain/` — Domain 测试文件
- `.github/workflows/coverage.yml` — Coverage报告workflow

**修改代码**：
- `packages/services/locale/lib/src/cubit/locale_cubit.dart` — 添加主题状态
- `packages/domain/lib/src/models/` — 可能新增 ThemeMode 模型
- `lib/core/startup/launcher.dart` — 注册 FPS 监控
- `lib/core/di/setup.dart` — DI 注册新模块

**依赖变化**：
- 新增 `feature_settings` 包依赖
- 新增 `performance` 包依赖（可选）
- 无破坏性变更