## Why

Flutter项目缺少标准化架构，导致：
1. 代码组织混乱，页面/逻辑/数据混杂
2. 无统一状态管理规范，团队协作困难
3. 错误处理、日志、国际化等基础设施缺失
4. API调用管理分散，取消机制不完善
5. 缺少测试模板，难以保证代码质量

目标是建立开箱可用的骨架项目，新项目可快速启动，团队有统一开发规范。

## What Changes

### 核心架构
- **BREAKING**: 重构lib目录结构，按Feature划分
- 引入Bloc状态管理，替代现有手动状态管理
- 引入GetIt依赖注入，统一管理服务实例
- 建立三层分层架构：Repository → Cubit → Page，复杂场景增加UseCase层
- 建立全局Bloc机制管理共享数据（用户信息、购物车等）

### 补充要素
- 新增国际化支持（中英文），基于Flutter intl
- 新增统一日志系统AppLogger（分级、格式化）
- 新增统一错误处理，三层体系（网络层→业务层→UI层），支持国际化
- 新增网络监听NetworkCubit，UI断网提示组件
- 新增常量管理AppConstants集中配置
- 扩展Hive缓存，支持复杂对象、过期机制

### API优化
- ApiBuilder增强：支持cancelTag、retry
- 新增CancelTokenManager：自动清理、页面级取消
- 新增RequestScope：页面级请求管理Widget
- API模块按Feature分组（UserApiMixin、HomeApiMixin、OrderApiMixin）
- 新增RequestTracker：请求追踪调试
- 新增ConcurrentLimiter：并发请求限制
- Token续期逻辑保持，仅改用AppLogger

### 测试
- 新增blocTest测试模板
- 新增mocktail mock示例
- 新增Cubit/Repository/UseCase测试模板

## Capabilities

### New Capabilities

- `state-management`: Bloc状态管理体系，Cubit封装，全局Bloc机制
- `dependency-injection`: GetIt服务定位器配置，Singleton/Factory注册规则
- `feature-structure`: Feature划分规范，repo/cubit/ui三层结构，usecase按需
- `internationalization`: Flutter intl配置，中英文arb文件，LocaleCubit切换
- `logging`: AppLogger分级日志系统，格式化输出，生产环境配置
- `error-handling`: 三层错误体系，errorCode映射，国际化错误消息
- `network-monitoring`: NetworkCubit全局监听，NetworkBanner UI组件
- `constants-management`: AppConstants/APIConstants/CacheConstants集中配置
- `hive-cache`: HiveCache扩展，TypeAdapter注册，过期机制
- `api-management`: ApiBuilder增强，CancelTokenManager，RequestScope，RequestTracker，ConcurrentLimiter
- `api-modules`: 按Feature分组API mixin（UserApi、HomeApi、OrderApi）
- `testing-templates`: blocTest模板，mock示例，测试结构规范

### Modified Capabilities

- `api-layer`: 改errorCode替代硬编码中文消息，改AppLogger替代debugPrint
- `domain-models`: 改DomainException支持errorCode，新增HiveType注解
- `key-value-storage`: 扩展HiveCache支持复杂对象和过期机制

## Impact

### 新增文件（约25个）
```
lib/core/
  ├── global/network/network_cubit.dart
  ├── global/locale/locale_cubit.dart
  ├── l10n/arb/app_zh.arb, app_en.arb
  ├── utils/logger.dart, error_handler.dart
  ├── constants/app_constants.dart, api_constants.dart, cache_constants.dart
  ├── widgets/network_banner.dart, error_widget.dart, request_scope.dart

packages/api/src/
  ├── http/cancel_token_manager.dart
  ├── http/request_tracker.dart
  ├── http/concurrent_limiter.dart
  ├── modules/user/user_api.dart
  ├── modules/home/home_api.dart
  ├── modules/order/order_api.dart

packages/key_value_storage/src/
  ├── hive_cache.dart
  ├── cache_data.dart

test/
  ├── helpers/mock_api.dart, mock_storage.dart
  ├── features/*/cubit/*_test.dart
  ├── features/*/repository/*_test.dart
```

### 改造文件（约10个）
```
packages/api/src/api_builder.dart
packages/api/src/http/http_manager.dart
packages/api/src/http/dio_adapter.dart
packages/api/src/http/http_error.dart
packages/api/src/http/renewal_token_intercaptor.dart
packages/domain_models/src/exceptions.dart
packages/domain_models/src/demo/demo_user.dart
packages/key_value_storage/lib/key_value_storage.dart
lib/main.dart
```

### 依赖变更
- 新增: flutter_bloc, get_it, bloc_test, mocktail
- 现有保持: dio, hive, connectivity_plus, go_router

### 破坏性变更
- lib/src/ui/* 迁移至 features/*/ui/
- RepositoryFactory 改用 GetIt
- 错误消息改errorCode需国际化支持