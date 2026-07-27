# Dio 网络层增强实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在保持当前项目架构优势（Retrofit 强类型、DomainException/Result<T,E> 错误分层、R3 合规的 callback 注入、Token 续期状态机）的前提下，补齐弱网三件套（重试 / 熔断 / 离线队列）、动态超时、统一业务 envelope、缓存拦截器，并把请求签名接入主链、补充「退出 App / 切换账号」全局取消能力。

**Architecture:** 延续 `createDio()` 工厂 + 单一职责拦截器风格。新增拦截器保持 **infra 包内、不依赖 services（R3）**：网络质量 / 连通性信号通过 infra 内定义的抽象接口（`NetworkEnvironment`）由 `services/network` 实现并工厂注入，复用现有 `NetworkCubit` + `connectivity_plus`。所有新拦截器通过 `createDio(...)` 入参注入，不变更调用点契约。文档随代码同步更新（含使用方式）。

**Tech Stack:** Dio、`synchronized`(Lock)、`connectivity_plus`（已被 NetworkCubit 使用、OHOS 已覆盖）、`flutter_bloc`(NetworkCubit)、现有 `AppLoggerInterface`、现有 `list_cache` 基础设施、`domain` 包错误体系。

---

## 0. 已确认的设计决策（来自用户验收口径）

1. **保持当前项目更优解，不盲从 Gitee**：架构分层、Retrofit 强类型、`DomainException`/`Result<T,E>`、R3 callback 注入、Token 续期状态机 **一律以当前项目为准**（不引入 Gitee 的 `AuthInterceptor` 401 方案）。
2. **正常请求需要签名**：把 `dio/header_interceptor.dart`（sha1 请求签名）接入主拦截器链（当前仅在 refresh 请求使用）。
3. **Token 续期维持现状**；鉴权 header 默认保持当前 `token` 形式，**不引入 Bearer 双协议**（除非后端团队明确要求）。
4. **补齐范围**：P0 弱网三件套 + 动态超时 + 离线队列；P1 统一 envelope + 缓存拦截器；P2 签名接入主链 + 清理 `debugPrint` + 全局 `cancelAllRequests()`。
5. **文档必须同步更新，且包含使用方式**。
6. **不提交代码**：所有改动在本地工作区 / 临时分支进行，全程不执行 `git commit`，**待用户验收通过后再统一提交**（Conventional Commits + R10）。

---

## 1. 解耦方案（R3 合规核心）

infra 不能 `import 'package:services/...'`。因此网络质量 / 连通性通过 infra 内抽象暴露：

- 新建 `packages/infrastructure/api/lib/src/network/network_environment.dart`：
  ```dart
  /// 网络环境抽象——打破 infra 对 services/network 的反向依赖（R3）
  abstract class NetworkEnvironment {
    /// 当前网络质量（良网 / 弱网 / 断开）
    NetworkQuality get quality;
    /// 质量变化流（用于动态超时）
    Stream<NetworkQuality> get qualityStream;
    /// 当前是否已连接
    Future<bool> isConnected();
    /// 连通性变化流（离线入队 / 恢复重发）
    Stream<bool> get connectionChanges;
  }

  /// 网络质量枚举（与 services/network 的 NetworkQuality 对齐，但定义在 infra）
  enum NetworkQuality { good, poor, disconnected }
  ```
- `services/network` 新增一个实现类 `InfraNetworkEnvironment implements NetworkEnvironment`，桥接 `NetworkCubit.currentQuality` / `qualityStream` / `Connectivity`。在 `services/network` 的 `setup.dart` 装配并传给 `createDio(networkEnvironment: ...)`。
- 新拦截器（Retry / NetworkStatus / 动态超时）只依赖 `NetworkEnvironment` 抽象，不直接碰 `NetworkCubit` 或 `connectivity_plus`。

---

## 2. 最终拦截器链顺序（在 `dio_factory.dart` 中）

请求方向（从外到内 add 顺序）：

| # | 拦截器 | 文件 | 职责 |
|---|--------|------|------|
| 0 | `AutoCancelInterceptor` | `cancel/auto_cancel_interceptor.dart` | 读 pageTag，生成 CancelToken |
| 1 | `NetworkStatusInterceptor` | `dio/network_status_interceptor.dart`（新） | 断网入队、恢复重发 |
| 2 | `TokenRenewalInterceptor` | `dio/renewal_token_interceptor.dart` | 续期（保持现状） |
| 3 | `InterceptorsWrapper`(Auth) | `dio_factory.dart` | 注入 `token` header + 断网回调 |
| 4 | `ErrorInterceptor` | `dio/error_interceptor.dart` | 5xx/网络错误上报（R3 callback） |
| 5 | `RetryInterceptor` | `dio/retry_interceptor.dart`（新） | 指数退避+抖动重试（**add 在 Error 之后**，使 onError 逆序时 Retry 先于 Error 执行） |
| 6 | `ResponseEnvelopeInterceptor` | `dio/response_envelope_interceptor.dart`（新） | 解包 `data['data']` + 业务码→DomainException |
| 7 | `HeaderInterceptor`(签名) | `dio/header_interceptor.dart`（改） | sha1 请求签名（接入主链） |
| 8 | `CacheInterceptor` | `dio/cache_interceptor.dart`（新，P1） | 策略化缓存 |
| 9 | `LatencyMonitorInterceptor` | `dio/latency_monitor_interceptor.dart` | 延迟监控 |
| 10 | `LogInterceptor` / `AliceInterceptor` | `dio_factory.dart` | Debug 日志 / Inspector |

> 签名拦截器放在 envelope 之后、cache 之前，确保签名覆盖最终出参；cache 在签名之后避免缓存未签名请求。动态超时在 `dio_factory` 内通过 `networkEnvironment.qualityStream` 监听改写 `dio.options.connectTimeout/receiveTimeout`（同 Gitee 思路）。

---

## 3. P0 任务（高价值低风险，建议立即做）

### Task 1: 新增 `NetworkEnvironment` 抽象 + services 实现
**Files:** Create `packages/infrastructure/api/lib/src/network/network_environment.dart`; Modify `packages/services/network/lib/network.dart` + `setup.dart` 增加 `InfraNetworkEnvironment`。
**Step 1:** 写测试 `network_environment_test.dart` 验证实现类把 `NetworkCubit.quality` 与 `Connectivity` 正确桥接。
**Step 2:** 实现抽象与桥接类；`setup.dart` 中 `createDio(networkEnvironment: InfraNetworkEnvironment(networkCubit))`。
**Step 3:** `melos analyze` + 单测通过。

### Task 2: `CircuitBreaker`（移植 + 注入日志）
**Files:** Create `packages/infrastructure/api/lib/src/dio/circuit_breaker.dart`
**Step 1:** 写失败测试：连续 `recordFailure()` 达阈值→`allowRequest==false`；半开探测成功→回到 `closed`；冷却后→`halfOpen`。
**Step 2:** 移植 Gitee `circuit_breaker.dart` 状态机，把所有 `debugPrint` 改为注入的 `AppLoggerInterface`（参考 `AppLoggerInterface`/`DefaultLogger`）。
**Step 3:** 单测通过。

### Task 3: `RetryInterceptor`（指数退避 + 抖动 + 弱网区分 + 熔断联动）
**Files:** Create `packages/infrastructure/api/lib/src/dio/retry_interceptor.dart`
**Step 1:** 写测试：验证 `baseDelay*2^(n-1)+jitter` 计算；弱网用 `poorNetworkMaxRetryCount`；非可重试类型（badResponse/cancel）直接放行；熔断打开时跳过。
**Step 2:** 移植 Gitee `retry_interceptor.dart`，改动点：
- 网络质量来自注入的 `NetworkEnvironment.quality`（替代 `NetworkStatusService.instance`）；
- `debugPrint` → `AppLoggerInterface`；
- 共享 `CircuitBreaker` 实例由工厂注入。
**Step 3:** 单测通过。

### Task 4: `RequestQueue`（离线队列）
**Files:** Create `packages/infrastructure/api/lib/src/dio/request_queue.dart`
**Step 1:** 写测试：enqueue 超限丢弃最旧；`flush(fetch)` 顺序重发并 `handler.resolve`；`clear(reason)` 全部 reject。
**Step 2:** 移植 Gitee `request_queue.dart`（`QueuedRequest` 持有 `RequestOptions`+`handler`），`debugPrint`→logger。

### Task 5: `NetworkStatusInterceptor`（断网入队 + 恢复重发）
**Files:** Create `packages/infrastructure/api/lib/src/dio/network_status_interceptor.dart`
**Step 1:** 写测试：离线时 `onRequest` 入队且不 `handler.next`；`connectionChanges` 变 true 时 `flush`；`extra['enqueueOnOffline']==false` 直接 reject。
**Step 2:** 移植 Gitee `network_status_interceptor.dart`，连通性来自 `NetworkEnvironment`；保留 `enqueueOnOffline` extra 开关；拿掉 `ToastService`（UI 不进 infra，R3）。

### Task 6: 工厂装配 P0 拦截器 + 动态超时
**Files:** Modify `packages/infrastructure/api/lib/src/dio_factory.dart`（含头部拦截器链注释）、`api.dart` 导出新类型；Modify `packages/services/network/setup.dart` 注入 `networkEnvironment`/共享 `CircuitBreaker`。
**Step 1:** 在 `createDio` 增加入参 `NetworkEnvironment? networkEnvironment`、`CircuitBreaker? circuitBreaker`、`RetryConfig? retryConfig`，并按第 2 节顺序 add 拦截器；新增 `_setupDynamicTimeout()` 监听 `qualityStream` 改写超时。
**Step 2:** 更新 `dio_factory.dart` 顶部拦截器链注释为最新顺序。
**Step 3:** `melos analyze` + 受影响的 `melos test`。

---

## 4. P1 任务（高价值，需设计衔接）

### Task 7: 业务 envelope 统一拦截器 + DomainException 衔接
**Files:** Create `packages/infrastructure/api/lib/src/dio/response_envelope_interceptor.dart`; Create `packages/domain/lib/src/exceptions/business_exception.dart`（`BusinessException extends DomainException` 携带 `code`+`message`）；Modify `packages/infrastructure/api/lib/src/error/dio_mapper.dart` 增加短路：`if (err.error is DomainException) return err.error;`
**Step 1:** 写测试：envelope 把 `{'code':0,'data':{...}}` 解包为 `response.data={...}`；`code!=0` 且非续期码 → reject 携带 `BusinessException`；`toDomainException()` 对已被包装的 `DomainException` 直接返回。
**Step 2:** 实现 envelope：成功码（默认 `0`，可配）解包；`reTokenCode`/`reLoginCode` 透传给续期/登出逻辑（`handler.next`）；其余业务码→`DioException(error: BusinessException(code,message))`。
**Step 3:** 单测通过；确认与 `future_result.dart` 的 `toResult()` 衔接无误（不二次映射）。

### Task 8: `CacheInterceptor`（策略化缓存，复用 `list_cache`）
**Files:** Create `packages/infrastructure/api/lib/src/dio/cache_interceptor.dart`
**Step 1:** 写测试：GET 命中 `cacheFirst` 直接返回；`networkFirst` 网络成功后写缓存；网络失败且 `networkFirst` 走缓存；非 GET 不缓存。
**Step 2:** 移植 Gitee `cache_interceptor.dart` 的策略（`cacheFirst/networkFirst/cacheOnly/networkOnly` + 错误降级），底层存储改为调用现有 `packages/infrastructure/lib/list_cache`（实现时核对其 API），`debugPrint`→logger。

---

## 5. P2 任务（清理 / 增强，低优先）

### Task 9: 签名拦截器接入主链 + 清理 debugPrint
**Files:** Modify `dio/header_interceptor.dart`（加 `AppLoggerInterface logger` setter，替换 `debugPrint`）；Modify `dio_factory.dart` 在 #7 位置 add `HeaderInterceptor`（需确保工厂持有其实例；复用 `AppLoggerInterface`）。
**Step 1:** 写测试：签名拦截器对正常请求产出 `sign` header，且日志走注入 logger。
**Step 2:** 接入主链；确认 refresh 请求仍可用（其独立 tokenDio 也已挂 `HeaderInterceptor`）。

### Task 10: `CancelTokenManager.cancelAll()` 全局取消
**Files:** Modify `packages/infrastructure/api/lib/src/cancel/cancel_manager.dart`
**Step 1:** 写测试：`cancelAll('app logout')` 取消所有 pageTag 下的 token 并清空映射。
**Step 2:** 新增 `cancelAll([String? reason])` 遍历 `_pageTokens` 全部 `token.cancel` 并 `clear()`；在「退出 App / 切换账号」流程（auth 的 logout / 切换账号）调用。保持 `token` header 不变（决策 3）。

---

## 6. 文档更新任务（必须含使用方式）

### Task 11: 重写 `docs/api-layer-guide.md`
当前文档已过时（写「6 层拦截器链」、文件名 `renewal_token_intercaptor.dart` 拼写错误、称续期用 RxDart 实为 `synchronized`+`RefreshQueue`）。需：
- 更新「拦截器链」表为第 2 节最终 11 层顺序，文件名修正为 `renewal_token_interceptor.dart`。
- 修正「Token 自动续期」段：去掉 RxDart 描述，改为 Lock + RefreshQueue 状态机（与 `renewal_token_interceptor.dart` 一致）。
- 新增**使用方式**小节：
  - 弱网重试/熔断：如何配 `RetryConfig`（正常/弱网次数、baseDelay、jitter）、`CircuitBreaker` 阈值；熔断触发后的表现。
  - 动态超时：行为说明（随网络质量自动调整 connect/receiveTimeout）。
  - 离线队列：`enqueueOnOffline` extra 开关、恢复自动重发、队列上限。
  - 统一 envelope：业务码约定（成功 `0`、续期码、业务错误码 → `BusinessException`），调用方如何用 `toResult()` 拿到 `Result<T,DomainException>`。
  - 缓存策略：`cacheFirst/networkFirst/cacheOnly/networkOnly` 用法与 `extra` 传参。
  - 请求签名：默认已开启，无需调用方处理。
  - 全局取消：`CancelTokenManager.cancelAll()` 在退出 App / 切换账号时的调用示例。
- 更新「关键文件索引」表，加入新文件。

### Task 12: 补充 `docs/QUICK_REFERENCE.md` 与 `dio_factory.dart` 头部注释
- `QUICK_REFERENCE.md`：若有拦截器/网络层条目，补一句并链接 `api-layer-guide.md`。
- `dio_factory.dart` 顶部拦截器链注释同步为最新顺序（Task 6 已含，此处核对）。
- 检查仓库根 `README.md` 是否提及网络层，必要时补一句 + 链接。

---

## 7. 验收标准（用户验收门）

- [ ] `melos analyze`（infrastructure + services + domain + affected）零错误。
- [ ] `./scripts/check_deps.sh` 通过（**R3：infra 不依赖 services**；新拦截器只 import dio / flutter / infra 内部 / `network_environment` 抽象）。
- [ ] `melos test`（至少 infra + services + domain 受影响包）全绿；新拦截器均有单测（退避计算、熔断状态机、队列 flush、envelope 映射、cancelAll）。
- [ ] `createDio` 构建的 Dio 含全部拦截器；手测/集成验证：签名 header 存在、超时可触发重试、连续失败熔断打开、断网请求入队且恢复后重发、envelope 正确解包、全局 `cancelAll` 取消所有请求。
- [ ] `docs/api-layer-guide.md` 已重写并含上述使用方式；QUICK_REFERENCE / README 已补充。
- [ ] **全程无 `git commit`**；改动停留在工作区 / 临时分支 `feat/dio-network-enhancement`，由用户 review 后统一提交。

---

## 8. 约束与流程

- **不提交代码**：本计划执行期间任何步骤都**不执行 `git commit`**；所有产物先落地到工作区，完成 P0–P2 + 文档后整体交给用户验收，验收通过后才按 Conventional Commits 提交。
- **R1–R10 全程遵守**：新增代码不得让 infra import services；通过 `NetworkEnvironment` 抽象 + 工厂注入实现解耦。
- **保持当前更优解**：Token 续期、错误分层、强类型 API 一律以当前项目实现为准，不回退到 Gitee 方案。
- 建议在临时分支 `feat/dio-network-enhancement` 上工作（不提交），便于用户 diff 验收。

## 9. 风险与回滚

- **envelope 与 `toResult()` 二次映射**：已用 `dio_mapper` 短路解决；若回归，回滚 Task 7 并保留调用方 `try/catch`。
- **签名接入主链导致正常请求体变化**：若后端不期望全量签名，Task 9 可降级为「仅对指定 extra 开启签名」，不影响其他拦截器。
- **离线队列与 TokenRenewal 交互**：续期走独立 tokenDio（不经主链 NetworkStatusInterceptor），不会入队；若异常，Task 5 回滚即可。
- 任意 Task 失败均可独立回退（新建文件直接删除 / 修改文件 `git checkout`），因尚未提交。
