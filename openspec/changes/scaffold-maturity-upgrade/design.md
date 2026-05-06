## Context

当前脚手架已有完善分层架构（domain/infrastructure/services/features），但缺失以下能力：
- 路由无认证拦截，未登录用户可访问保护路径
- domain测试覆盖率低（仅1个test），快速迭代回归风险高
- 无设置页面，主题仅静态定义无动态切换
- CI 无覆盖率可视化，测试进度不可观测
- Hive存储无版本管理，数据结构变更无迁移机制
- 无FPS监控，性能瓶颈发现依赖用户反馈

**约束**：
- 遵循现有 Clean Architecture + Feature-First 模式
- 新模块需物理包隔离
- DI 遵循 Singleton/Factory 规范
- 测试遵循 unit/bloc/widget/golden 分层

## Goals / Non-Goals

**Goals**：
- 路由守卫作为可选模块，不影响现有路由逻辑
- Domain 测试覆盖 models、exceptions、usecases，100%目标
- 设置页作为新 feature 包，集成主题切换
- CI 自动生成覆盖率报告
- Hive迁移框架支持版本号+迁移函数注册
- FPS监控为可选服务包，不强制启用

**Non-Goals**：
- Sentry接入（待收费评估）
- Widget/Golden测试大幅扩充（ROI考量）
- 后端API对接（脚手架定位为模板）
- 路由守卫强制启用（保持可选）

## Decisions

### D1: 路由守卫实现位置

**决策**: 放在 `routing` 包，作为可选参数启用

**理由**:
- routing 已是基础设施层，路由相关逻辑集中
- 通过 `enableAuthGuard` 参数控制，不破坏现有用法
- AuthManager 通过 DI 获取，不直接依赖 services包

**替代方案**:
- 放在 services/auth → 违背分层原则（auth不应知道路由）
- 放在 lib/core → 违背模块化原则（core仅组装）

### D2: 主题切换状态管理

**决策**: 扩展 `LocaleCubit` → `AppPreferencesCubit`，或新建 `ThemeCubit`

**理由**:
- LocaleCubit 已管理语言偏好，同属「用户偏好」范畴
- 若合并 → 减少Singleton数量，状态集中
- 若分离 → 模块边界更清晰，职责单一

**推荐**: 新建 `ThemeCubit`（services/locale包内），职责单一

### D3: 数据迁移框架设计

**决策**: Hive版本号+迁移函数注册表

```
┌───────────────────────────────────────────────┐
│  MigrationFramework                           │
├───────────────────────────────────────────────┤
│                                               │
│  currentVersion: int (存储在Hive)             │
│  migrations: Map<int, MigrationFn>           │
│                                               │
│  registerMigration(version, fn)               │
│  runMigrations() → 逐版本执行                 │
│                                               │
└───────────────────────────────────────────────┘

示例:
registerMigration(2, (box) async {
  // v1 → v2: User添加profile字段
  final users = box.get('users');
  for (var u in users) {
    u['profile'] = {};
  }
  box.put('users', users);
});
```

**理由**:
- 版本号递增，迁移函数按版本注册
- 启动时自动执行 pending migrations
- 迁移失败 → 抛异常，阻止启动（数据安全优先）

**替代方案**:
- 每次全量迁移 → 复杂且不可靠
- 无迁移 → 版本升级崩溃风险

### D4: FPS监控实现方式

**决策**: 新建 `performance` 服务包，使用 Flutter PerformanceOverlay + 自定义追踪

**理由**:
- PerformanceOverlay 仅debug模式可见，需自定义生产监控
- FlutterBinding.instance.addTimingsCallback → 获取帧耗时
- 独立服务包，不污染现有模块

```
┌───────────────────────────────────────────────┐
│  FpsMonitor                                   │
├───────────────────────────────────────────────┤
│                                               │
│  frameTimes: List<double>                     │
│  onFpsDrop: Callback<int>?                    │
│                                               │
│  start() → 注册 timingsCallback               │
│  stop() → 移除 callback                       │
│  report() → FPS统计 + 卡顿次数                 │
│                                               │
└───────────────────────────────────────────────┘
```

### D5: Domain测试策略

**决策**: 每个domain文件对应一个test文件

```
test/unit/domain/
├── models/
│   ├── user_test.dart
│   └── theme_mode_test.dart
├── exceptions/
│   ├── domain_exception_test.dart
│   └── network_exception_test.dart
├── usecases/
│   └── get_user_usecase_test.dart
└── enums/
    └── enum_test.dart
```

**理由**:
- domain纯Dart，无Flutter依赖，mock简单
- 100%覆盖可行，ROI高
- 测试即文档，验证fromJson/toJson、边界值、异常匹配

### D6: CI Coverage Report

**决策**: GitHub Actions + codecov.io（免费）或生成HTML报告

**理由**:
- codecov.io 免费额度足够
- 自动生成覆盖率徽章，可视化展示
- 替代方案：本地生成HTML → 需手动查看，不便捷

```yaml
# .github/workflows/coverage.yml
- run: flutter test --coverage
- uses: codecov/codecov-action@v3
  with:
    files: coverage/lcov.info
```

## Risks / Trade-offs

### R1: 路由守卫与认证状态同步
**风险**: AuthManager状态变更后，路由守卫可能未及时响应
**缓解**:
- AuthManager 使用 Cubit，状态变更自动触发 rebuild
- 路由 redirect 函数每次导航都检查，不依赖缓存

### R2: 数据迁移失败阻塞启动
**风险**: 迁移函数bug导致App无法启动
**缓解**:
- 迁移函数需单元测试覆盖
- 提供 rollback 机制（备份旧数据）
- 迁移失败记录日志，后续可手动修复

### R3: FPS监控影响性能
**风险**: 监控本身消耗资源，可能影响实测FPS
**缓解**:
- 仅在debug/staging启用，prod禁用
- 使用轻量callback，避免复杂计算
- 采样而非逐帧记录（如每秒采样一次）

### R4: 设置页过度膨胀
**风险**: 设置页后续加功能变成「大杂烩」
**缓解**:
- 设置页仅放核心配置（主题、语言）
- 其他功能（通知、隐私）后续可拆分子页面
- Feature包结构清晰：cubit/repository/ui分离

## Decisions Locked

| Question | Decision | Rationale |
|----------|----------|-----------|
| Q1: codecov.io vs 本地HTML？ | **codecov免费方案** | 免费额度足够，自动化徽章，可视化便捷 |
| Q2: ThemeCubit放哪？ | **locale包内** | 同属用户偏好，减少包数量，状态集中管理 |
| Q3: FPS监控默认？ | **默认启用，环境控制** | debug/staging自动启用，prod禁用，通过EnvironmentConfig控制 |