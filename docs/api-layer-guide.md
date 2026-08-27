# API 层架构指南

> 最后更新：2026-07-26（Dio 网络层增强：弱网重试 / 熔断 / 离线队列 / 动态超时 / 统一信封 / 通用缓存 / 请求签名 / 全局取消）

## 概述

API 层（`packages/infrastructure/api`）封装所有网络请求逻辑。核心职责：
- Retrofit 声明式 API 接口（强类型，编译期校验）
- 11 层拦截器链（自动取消 / 缓存 / 断网入队 / 续期 / 鉴权 / 签名 / 错误上报 / 重试熔断 / 延迟监控 / 日志 / 信封解包）
- Token 自动续期（`synchronized` 锁 + RefreshQueue 并发安全，**非 RxDart**）
- 请求自动取消（页面级 `RequestScope` + 全局 `cancelAll`）
- 弱网优化（指数退避重试 + 熔断 + 动态超时 + 离线队列）
- 统一业务信封（`code → BusinessException`，与 `Result<T, DomainException>` 衔接）
- 通用 GET 响应缓存（默认关闭，按需 opt-in）

> **设计原则**：infra 不反向依赖 services/network（R3）。弱网所需的网络质量 / 连通性信号通过
> `NetworkEnvironment` 抽象获取，由 `services/network` 的 `InfraNetworkEnvironment` 桥接注入
> （`NetworkCubit` + `Connectivity`）。
>
> 网络质量（good/slow/poor/disconnected）的具体评估算法（请求延迟中位数 + 阈值）详见
> `packages/services/network/README.md`。

---

## 11 层拦截器链

请求方向（从外到内，响应方向相反）：

| # | 拦截器 | 文件 | 职责 | 默认 / 开关 |
|---|--------|------|------|------|
| 0 | `AutoCancelInterceptor` | `cancel/auto_cancel_interceptor.dart` | 读 `RequestScope` tag，生成 `CancelToken` 并登记 | 调用方注入 |
| 1 | `CacheInterceptor` | `dio/cache_interceptor.dart` | 通用 GET 响应缓存 | 默认 `none`（透明），`extra['cacheStrategy']` 开启 |
| 2 | `NetworkStatusInterceptor` | `dio/network_status_interceptor.dart` | 断网入队/暂停，恢复后重发 | 注入 `networkEnvironment` 时启用 |
| 3 | `TokenRenewalInterceptor` | `dio/renewal_token_interceptor.dart` | 检测 code=1000102，锁定 + 排队续期 | 常开 |
| 4 | `InterceptorsWrapper`（Auth） | `dio_factory.dart` | 注入 `token` header + 网络断开回调 | 常开 |
| 5 | `HeaderInterceptor`（签名） | `dio/header_interceptor.dart` | 请求 sha1 签名，写入 `sign` header | 常开（必须位于 Auth 之后） |
| 6 | `ErrorInterceptor` | `dio/error_interceptor.dart` | 5xx/网络错误上报（callback 注入，遵守 R3） | `onDioError` 注入时启用 |
| 7 | `RetryInterceptor` | `dio/retry_interceptor.dart` | 网络错误指数退避重试 + 熔断联动 | 常开（无 `networkEnvironment` 时按良网重试） |
| 8 | `LatencyMonitorInterceptor` | `dio/latency_monitor_interceptor.dart` | 记录请求延迟（喂给 `NetworkCubit` 质量评估） | `onLatencyRecord` 注入时启用 |
| 9 | `LogInterceptor` | `dio_factory.dart` | Debug 模式记录请求/响应日志 | 仅 `kDebugMode` |
| 10 | `AliceInterceptor` | `dio_factory.dart` | Debug 模式 HTTP Inspector | 仅 `kDebugMode` 且传入 `alice` |
| 11 | `ResponseEnvelopeInterceptor` | `dio/response_envelope_interceptor.dart` | 统一信封解包 + 业务码→`BusinessException` | `enableEnvelope`（默认 `true`） |

> 链顺序的要点：
> - 签名（#5）必须在 Auth（#4）之后，才能读到 `token` header 参与签名。
> - 重试（#7）放在错误上报（#6）之后，每次重试尝试仍会走上报（与原行为一致）。
> - 信封解包（#11）放在链尾，响应方向上最先执行，解包后的干净 payload 优先于日志被记录。
> - 离线入队（#2）在缓存（#1）之后、续期（#3）之前，确保断网前缓存可短路命中。

---

## Token 自动续期

> ⚠️ 历史文档曾误写为「RxDart `PublishSubject` 广播」。**真实实现使用 `synchronized` 的 `Lock` + `RefreshQueue`**，无 RxDart 依赖。

当 API 返回 `code=1000102`（token 失效）时：
1. `TokenRenewalInterceptor` 用 `_renewalLock.synchronized(...)` 加锁，保证并发请求仅触发**一次**续期。
2. 首个请求执行续期（POST `/User/Token/Renewal`，刷新请求经 `HeaderInterceptor` 签名）。
3. 并发到达的其他请求进入 `RefreshQueue` 排队等待。
4. 续期成功后，队列中的请求用新 token **批量重试**（避免雪崩，重试用新 token）。
5. 续期失败 → 通过 `HttpEventBus` 提交登出事件，由上层处理重新登录。

**优势（相对外部仓库的 401 单例守卫方案）**：状态机 + 批量重试 + 雪崩守卫，并发更稳，不会因多次 401 触发多次续期风暴。

---

## 请求自动取消

### 页面级取消（AutoCancel + RequestScope）
- 每个路由页面被 `RequestScope` 包裹（见 `app.dart` 的 `RouteContext.routeWrapper`）。
- 页面内请求的 `AutoCancelInterceptor` 读取 `RequestScope` 的 tag，生成 `CancelToken` 并登记到 `CancelTokenManager`。
- 页面退出时 `RequestScope.dispose()` → `CancelTokenManager.cancelPage(tag)` 取消该 tag 下所有在途请求。

### 全局取消（cancelAll）— 本次新增
覆盖「退出 App / 切换账号」等需立即终止**全部**在途请求的场景：

```dart
// 已接入 AuthManager.logout()：登出/切换账号时自动调用
CancelTokenManager.instance.cancelAll('用户登出');
```

> 与 `clearAll()` 的区别：`clearAll()` 仅清记录不取消请求；`cancelAll()` 真正对每个 `CancelToken` 触发取消，
> 避免旧账号请求在切换后回流污染新会话。`cancelAll` 调用后原 `token header` 不受影响。

---

## 弱网优化（P0）

> 弱网能力通过注入的 `NetworkEnvironment`（来自 `NetworkCubit` 质量评估）驱动，无需在 infra 内依赖 services。

### 1. RetryInterceptor（指数退避 + 抖动 + 弱网区分）
- 重试延迟 = `baseDelay * 2^(attempt-1)`，clamp 到 `maxDelay`；开启 `enableJitter` 时叠加随机抖动。
- 重试次数上限按网络质量区分：`good/slow` 用 `normalMaxRetryCount`，`poor/disconnected` 用 `poorNetworkMaxRetryCount`。
- 仅 `retryableTypes`（默认 连接超时 / 发送超时 / 接收超时 / 连接错误）重试；`cancel` 与 `badResponse`（4xx）**直接放行**不重试。
- 熔断打开（`CircuitBreaker.allowRequest == false`）时跳过重试。
- 通过 `extra['retry_count']` 防死循环。

**配置方式**：
```dart
createDio(
  // ...
  retryConfig: RetryConfig(
    normalMaxRetryCount: 2,
    poorNetworkMaxRetryCount: 4,
    baseDelay: const Duration(milliseconds: 500),
    maxDelay: const Duration(seconds: 8),
    enableJitter: true,
  ),
);
```

### 2. CircuitBreaker（熔断状态机）
共享实例由 `createDio(circuitBreaker:)` 注入（不传则工厂创建默认实例与 RetryInterceptor 共享）。
- 状态：`closed` → 连续失败达 `failureThreshold`（默认 10）转 `open`；`open` 冷却 `resetDuration`（默认 30s）后转 `halfOpen`；`halfOpen` 探测成功 `halfOpenMaxCalls`（默认 3）次回到 `closed`。
- 日志走注入的 `AppLoggerInterface`。

```dart
final breaker = CircuitBreaker(
  failureThreshold: 10,
  resetDuration: const Duration(seconds: 30),
  halfOpenMaxCalls: 3,
);
createDio(/* ... */ circuitBreaker: breaker);
```

### 3. NetworkStatusInterceptor + RequestQueue（断网入队 / 恢复重发）
- 离线时 `onRequest` 把请求入队（`QueuedRequest`）并暂停（不 `handler.next`）。
- `networkEnvironment.connectionChanges` 恢复为 `true` 且队列非空时，`flush` 顺序重发并 `handler.resolve`。
- 可通过 `extra['enqueueOnOffline'] = false` 关闭某请求的入队行为（离线直接拒绝，适合「必须实时」的请求）：

```dart
dio.get('/api/urgent', options: Options(
  extra: {'enqueueOnOffline': false},
));
```

### 4. 动态超时
注入 `networkEnvironment` 后，工厂订阅 `qualityStream`，按质量自动调整 `connectTimeout`/`receiveTimeout`：
`good`(10s/10s) → `slow`(15s/20s) → `poor`(30s/40s)。断网时请求由离线队列接管，保持当前值。

---

## 统一业务信封（P1）

`ResponseEnvelopeInterceptor` 统一处理后端 `{code, message, data}` 信封：
- `code == 0`：成功，解包 `data` 为 `response.data`，下游 Retrofit/调用方直接拿到业务 payload。
- `code == 1000102`：续期码，**原样放行**给 `TokenRenewalInterceptor`（不可在此拦截）。
- `code != 0` 且非续期码：业务错误，以 `BusinessException(code, message)` 拒绝本次请求。

**智能识别**：仅当响应是 `{code, message, data}` 结构时才解包/拦截；裸 payload（如文件流、非信封接口）原样放行，**不破坏既有 Retrofit 解析**。

**与 `Result<T, DomainException>` 衔接**：
- `toResult()`（`future_result.dart`）已把 `DioException` 转 `DomainException`；
- `dio_mapper.toDomainException()` 对**已是 `DomainException`** 的错误短路返回（不二次包装）；
- 因此 `BusinessException` 经 `toResult()` 直接收口为 `Result.failure`，UI 用 `result.when(failure: (e) => ...)` 处理：

```dart
final result = await userApi.getProfile().toResult();
result.when(
  success: (profile) => /* 渲染 */,
  failure: (e) {
    if (e is BusinessException) {
      // e.code / e.message 即后端业务码
    }
  },
);
```

> 若后端接口**未**统一信封（裸 payload），将 `createDio(enableEnvelope: false)` 关闭即可，无副作用。

---

## 通用缓存（P1）

`CacheInterceptor` 提供通用 GET 响应缓存，**默认 `none`（对所有现有请求完全透明）**，仅当请求显式携带 `extra['cacheStrategy']` 时生效：

| `extra['cacheStrategy']` | 行为 |
|---|------|
| `none`（默认） | 不缓存，直接走网络 |
| `cacheFirst` | 命中缓存直接返回；未命中走网络并写缓存 |
| `networkFirst` | 先请求网络，成功写缓存；网络失败用缓存兜底 |
| `cacheOnly` | 只读缓存，永不请求网络 |
| `networkOnly` | 只请求网络，永不缓存 |

`extra['cacheMaxAge']`（`Duration`，默认 5 分钟）控制缓存有效期。

```dart
dio.get('/api/config', options: Options(extra: {
  'cacheStrategy': 'cacheFirst',
  'cacheMaxAge': Duration(minutes: 10),
}));
```

> **与 `list_cache` 的区别**：`CacheInterceptor` 是通用 GET 响应内存缓存（opt-in）；
> `packages/infrastructure/list_cache` 是**分页列表**专用缓存（按 `cacheKey`+`page` 存 `List<T>`，底层 Hive），
> 两者职责不同，列表端点仍应在仓储层使用 `ListCacheManager`。

---

## 请求签名（HeaderInterceptor）

`HeaderInterceptor` 对所有主链请求做 sha1 签名并写入 `sign` header，**默认开启**：
- 签名材料：`accessKeyId` / `token` / `signType` / `timestamp` / `version` / `nonce` + 请求 body。
- 必须位于 Auth 拦截器（#4）之后，才能读到 `token` header 参与签名（与刷新请求一致）。
- 仅对 JSON body（`Map`）参与签名；GET / 下载等非 Map body 跳过，避免空指针。
- 日志走注入的 `AppLoggerInterface`（替换原 `debugPrint` 调试残留）。

如需关闭（如第三方接口不校验签名）：
```dart
// 工厂不挂载 HeaderInterceptor 即可；当前为常开，如需全局开关可在此处条件化。
```

---

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
  ↓（响应方向）ResponseEnvelopeInterceptor
  └─ code != 0 → BusinessException，由 toResult() 收口为 Result.failure
```

**callback 注入**：`ErrorInterceptor` 不直接依赖 `AppErrorHandler`（R3 规则），
由 `setup.dart` 的 `createDio(onDioError: ...)` 注入。`toResult()` 同样通过 `dio_mapper` 的 callback 衔接。

---

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

# 6. 在 feature 包使用，并用 .toResult() 收口
```

---

## 关键文件索引

| 文件 | 职责 |
|------|------|
| `dio_factory.dart` | Dio 实例创建 + 11 层拦截器组装 + 动态超时 |
| `dio/renewal_token_interceptor.dart` | Token 续期（`synchronized` Lock + RefreshQueue） |
| `dio/error_interceptor.dart` | 错误上报过滤（callback 注入，R3） |
| `dio/header_interceptor.dart` | 请求 sha1 签名 |
| `dio/retry_interceptor.dart` | 指数退避重试（弱网区分 + 抖动） |
| `dio/circuit_breaker.dart` | 熔断状态机 |
| `dio/network_status_interceptor.dart` | 断网入队 / 恢复重发 |
| `dio/request_queue.dart` | 离线请求队列 |
| `dio/response_envelope_interceptor.dart` | 统一信封解包 + 业务码→`BusinessException` |
| `dio/cache_interceptor.dart` | 通用 GET 响应缓存（opt-in） |
| `dio/latency_monitor_interceptor.dart` | 延迟监控（喂网络质量） |
| `cancel/auto_cancel_interceptor.dart` | 页面级请求自动取消 |
| `cancel/cancel_manager.dart` | 取消管理（`cancelPage` / `cancelAll` 全局取消） |
| `network/network_environment.dart` | 网络环境抽象（R3 解耦桥） |
| `refresh/refresh_queue.dart` | 续期等待队列 |
| `error/dio_mapper.dart` | DioException → DomainException（含 DomainException 短路） |
| `error/future_result.dart` | `toResult()` 收口为 `Result<T, DomainException>` |
| `api/*.dart` | Retrofit 接口定义 |
| `http/http_event_bus.dart` | 全局 HTTP 事件总线（登出等） |
| `services/network/lib/src/infra_network_environment.dart` | `NetworkEnvironment` 桥接实现（注入 `NetworkCubit` + `Connectivity`） |
