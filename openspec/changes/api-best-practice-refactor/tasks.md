## 1. 端点集中管理

- [ ] 1.1 创建 `packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart`，包含 `ApiBase`（baseUrl + 版本前缀 + token续期路径）和按域嵌套分组（_Auth, _Home, _Vehicle 等）
- [ ] 1.2 从 `feature_home/repository/home_repository_impl.dart` 提取所有端点路径到 `api_endpoints.dart` 的 `_Home` 分组，RepositoryImpl 改为引用 `ApiEndpoints.home.*`
- [ ] 1.3 从 `feature_detail/repository/detail_repository_impl.dart` 提取所有端点路径到 `api_endpoints.dart` 的 `_Detail`（或对应域）分组
- [ ] 1.4 检查其他 feature RepositoryImpl 中的内联端点字符串，全部提取到 `api_endpoints.dart`
- [ ] 1.5 将 `renewal_token_intercaptor.dart` 中硬编码的 `/User/Token/Renewal` 路径改为引用 `ApiBase.tokenRenewal`
- [ ] 1.6 在 `api.dart` barrel 文件中新增 `export 'src/endpoints/api_endpoints.dart';`

## 2. 错误处理统一（先确认 HttpsException 形态）

- [ ] 2.1 通过 `lsp_find_references` 确认 `HttpsException.create` 外部引用关系 → 有引用则保留 HttpsException 类，无引用则删除整个 `http_error.dart`
- [ ] 2.2 删除 `src/http/error_handler.dart`（ErrorHandler.handleError 零调用，147行死代码）
- [ ] 2.3 从 `src/http/http_error.dart` 中删除 `NeedLogin` 类（零实例化）
- [ ] 2.4 从 `src/http/http_error.dart` 中删除 `NeedAuth` 类（零实例化）
- [ ] 2.5 从 `src/http/http_error.dart` 中删除 `HttpsExceptionExtension.toDomainException()` 扩展（重复映射，零调用）
- [ ] 2.6 验证 `DioExceptionMapper.toDomainException()` 是唯一活跃的错误映射路径
- [ ] 2.7 确认 `feature_home` 和 `feature_detail` 的 RepositoryImpl 使用 `DioExceptionMapper` 无变化
- [ ] 2.8 从 `api.dart` barrel 清理 `error_handler.dart` 导出；若 HttpsException 无外部引用则一并移除导出

## 3. 死代码删除

- [ ] 3.1 删除 `src/url_builder.dart`（FavQs 业务代码，零引用）
- [ ] 3.2 删除 `src/dio/token_interceptor.dart`（旧版，被 renewal_token_intercaptor 替代，零引用）
- [ ] 3.3 删除 `src/dio/retry_interceptor.dart`（从未激活，DioAdapter 中已注释）
- [ ] 3.4 删除 `src/http/retry_policy.dart`（为已删除的 HttpManager 设计，零生产调用）
- [ ] 3.5 删除 `src/http/concurrent_limiter.dart`（同上，零生产调用）
- [ ] 3.6 删除 `src/tracking/request_tracker.dart`（同上，零生产调用）
- [ ] 3.7 删除 `src/dio/log_reporting_interceptor.dart`（从未加入拦截器链，零引用）
- [ ] 3.8 同步删除 `token_renewal_interceptor_test.dart` 中 RetryPolicy/ConcurrentLimiter/RequestTracker 测试组
- [ ] 3.9 清理 `api.dart` barrel 文件中对应的 7 个死代码导出

## 4. 业务泄露清理

- [ ] 4.1 从 `src/http/http_event_bus.dart` 中移除 `OVSTap` 枚举，移动到 `lib/core/events/` 或 services 层
- [ ] 4.2 从 `src/http/http_event_bus.dart` 中移除业务 `EventKeys`（addNewCar, updateCar, updateWeather, updateLogs, exchangeTab 等），保留通用事件（logout, hasToken）
- [ ] 4.3 从 `src/http/http_constant.dart` 中移除 `EmptyCarListCode`（业务错误码）
- [ ] 4.4 将 `src/http/http_constant.dart` 中的 `renewalTokenCode` 重命名为 `reTokenCode`（基础设施自有常量保留），同时在 domain 层 `ErrorCode` 枚举中确认 `tokenExpired = 1000102` 已存在（或新增），新增 `tokenInvalid = 1000103` 语义枚举（两方独立维护不互相引用）
- [ ] 4.5 从 `src/http/http_constant.dart` 中移除 `msgVCodeMaxLength`（短信业务规则）
- [ ] 4.6 更新引用了被移除常量的代码（token 续期拦截器、错误处理器等）
- [ ] 4.7 从 `api.dart` barrel 清理不再导出的符号

## 5. 测试清理与验证

- [ ] 5.1 删除或更新引用已删除文件的测试用例（`api_test.dart` 中的死代码测试、`token_renewal_interceptor_test.dart` 中的 RetryPolicy/ConcurrentLimiter/RequestTracker 测试组）
- [ ] 5.2 为 `api_endpoints.dart` 编写单元测试（验证端点常量可访问、baseUrl 单一来源、分组结构正确）
- [ ] 5.3 运行 `lsp_diagnostics` 确认零新增错误
- [ ] 5.4 运行 `flutter analyze` 确认代码分析通过
- [ ] 5.5 运行 `flutter test` 确认全部测试通过
