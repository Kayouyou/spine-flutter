# API 层架构指南

## 概述

API 层（`packages/infrastructure/api`）封装所有网络请求逻辑。核心职责：
- Retrofit 声明式 API 接口
- 6 层拦截器链（认证、续期、取消、错误上报、日志、调试）
- Token 自动续期（RxDart 并发安全）
- 请求自动取消（页面退出时）

## 6 层拦截器链

请求方向（从外到内）：

| # | 拦截器 | 文件 | 职责 |
|---|--------|------|------|
| 0 | `AutoCancelInterceptor` | `cancel/auto_cancel_interceptor.dart` | 读 RequestScope tag，生成 CancelToken |
| 1 | `TokenRenewalInterceptor` | `dio/renewal_token_intercaptor.dart` | 检测 code=1000102，排队续期 |
| 2 | `InterceptorsWrapper` | `dio_factory.dart` | 注入 token header + 网络断开回调 |
| 3 | `ErrorInterceptor` | `dio/error_interceptor.dart` | 5xx/网络错误上报（callback 注入，遵守 R3） |
| 4 | `LogInterceptor` | `dio_factory.dart` | Debug 模式记录请求/响应日志 |
| 5 | `AliceInterceptor` | `dio_factory.dart` | Debug 模式 HTTP Inspector |

## Token 自动续期

当 API 返回 code=1000102 时：
1. `TokenRenewalInterceptor` 锁定 Dio（`dio.lock()`）
2. 调用 `/User/Token/Renewal` 刷新 token
3. 后续并发请求进入 `RefreshQueue` 排队
4. 续期成功后解锁 Dio，队列中的请求用新 token 重试
5. 续期失败 → 触发登出

**关键设计**：用 RxDart `PublishSubject` 广播续期结果，所有排队请求监听同一个流。

## 请求自动取消

通过 `RequestScope` widget 实现：
- 每个路由页面被 `RequestScope` 包裹
- 页面内的 API 请求自动携带当前页面的 tag
- 页面退出时，`RequestScope.dispose()` 取消该 tag 下所有未完成的请求

**使用方式**：`app.dart` 中 `RouteContext.routeWrapper` 已自动包裹。

## 错误处理路径

```
Dio 抛出 DioException
  ↓
ErrorInterceptor.onError()
  ├─ 4xx → 不上报（业务期望），handler.next(err)
  └─ 5xx/网络错误 → 调用 onDioError callback
                          ↓
                    AppErrorHandler.instance.reportError()
                          ↓
                    SentryReporter / ConsoleReporter
```

**callback 注入**：`ErrorInterceptor` 不直接依赖 `AppErrorHandler`（R3 规则），
由 `setup.dart` 的 `createDio(onDioError: ...)` 注入。

## 新增 API endpoint 标准流程

```bash
# 1. 生成 API 砖块
make create-api name=orders baseUrl=/api/v1/orders model=OrderModel

# 2. 编辑生成的 Retrofit 接口
# packages/infrastructure/api/lib/src/api/orders_api.dart

# 3. 生成代码
dart run build_runner build --delete-conflicting-outputs

# 4. 在 domain 层加 Repository 接口
# packages/domain/lib/src/repositories/i_order_repository.dart

# 5. 实现 Repository（在 api 包的 repository/ 目录）

# 6. 在 feature 包使用
```

## 关键文件索引

| 文件 | 职责 |
|------|------|
| `dio_factory.dart` | Dio 实例创建 + 拦截器组装 |
| `dio/renewal_token_intercaptor.dart` | Token 续期（251 行，最复杂） |
| `dio/error_interceptor.dart` | 错误上报过滤 |
| `cancel/auto_cancel_interceptor.dart` | 请求自动取消 |
| `refresh/refresh_queue.dart` | 续期等待队列 |
| `api/*.dart` | Retrofit 接口定义 |
| `http/http_event_bus.dart` | 全局 HTTP 事件总线 |
