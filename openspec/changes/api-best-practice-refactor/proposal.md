## Why

`packages/infrastructure/api/` 当前存在 ~30% 死代码（约900行）、业务逻辑泄露到基础设施层、错误处理双重路径、端点散落内联等问题。经过五线并行调研（git历史、架构边界、业界最佳实践、端点管理模式、错误处理层级），确定的改进方案可一次性解决代码冗余和架构违规，将 api 包从 5/10 提升到 8.8/10 的 Clean Architecture 标准。

## What Changes

- **端点集中管理**：新建 `api_endpoints.dart`，集中式嵌套分组（按域：auth/home/vehicle等），替换散落各 RepositoryImpl 的内联字符串
- **死代码删除**：删除 7 个无引用文件（~900行）：`url_builder.dart`, `token_interceptor.dart`, `retry_interceptor.dart`, `retry_policy.dart`, `concurrent_limiter.dart`, `request_tracker.dart`, `log_reporting_interceptor.dart`
- **错误处理统一**：删除 `ErrorHandler`、`NeedLogin`、`NeedAuth`、`HttpsExceptionExtension`，统一到 `DioExceptionMapper.toDomainException()` 单一路径
- **业务泄露清理**：从 `http_event_bus.dart` 移除 `OVSTap` 枚举和业务 `EventKeys`；从 `http_constant.dart` 移除 `EmptyCarListCode`；`renewalTokenCode`/`reLoginCode` 保留为基础设施自有常量（重命名为 `reTokenCode`/`reLoginCode`），同时在 domain 层新增语义枚举 `tokenExpired`/`tokenInvalid`，两方独立维护不互相引用
- **导出精简**：`api.dart` barrel 文件清理死代码导出，新增 `api_endpoints.dart` 导出
- Token 续期相关文件（`renewal_token_intercaptor.dart`, `token_supplier.dart`, `header_interceptor.dart`）保持不变

## Capabilities

### New Capabilities
- `api-endpoints`: 集中式 API 端点管理，按域嵌套分组，单一 baseUrl 管理点
- `api-error-handling`: DioException → DomainException 单一路径错误处理，统一的异常映射规范

### Modified Capabilities
<!-- 无现有 specs，首次建立 -->

## Impact

- **受影响的包**: `infrastructure/api` (核心), `features/feature_home`, `features/feature_detail` (端点引用迁移)
- **受影响的文件**: ~20 个（7 删除 + ~10 修改 + 1 新建）
- **删除代码**: ~900 行，19 文件 → 12 文件（减少 37%）
- **依赖变更**: 删除 api → domain 的 `HttpsExceptionExtension` 依赖路径
- **无破坏性变更**: 保留的公共 API（`DioExceptionMapper`, `HttpsException.create`, `createDio` 工厂）保持不变
- **测试影响**: 删除死代码对应的测试用例
