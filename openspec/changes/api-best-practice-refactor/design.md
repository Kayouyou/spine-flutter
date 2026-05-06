## Context

### 当前状态

`packages/infrastructure/api/` 是基础设施层的 HTTP 客户端封装，基于 Dio。经过五线并行调研（git 历史、架构边界、业界最佳实践、端点管理模式、错误处理层级），确认当前存在以下问题：

| 问题 | 影响 | 严重程度 |
|------|------|---------|
| **~30% 死代码**（约 900 行） | 7 个文件零引用：`url_builder.dart`, `token_interceptor.dart`, `retry_interceptor.dart`, `retry_policy.dart`, `concurrent_limiter.dart`, `request_tracker.dart`, `log_reporting_interceptor.dart` | 高 — 维护负担，新人困惑 |
| **端点散落内联** | 各 `RepositoryImpl` 直接写字符串路径，无统一管理点 | 中 — 后端改路径时逐个文件排查 |
| **错误处理双重路径** | `DioExceptionMapper` (active) vs `HttpsExceptionExtension` (dead) vs `ErrorHandler` (orphaned)，三套映射逻辑 | 高 — 不一致，接口模糊 |
| **业务逻辑泄露到基础设施** | `http_event_bus.dart` 含 `OVSTap` 枚举和车辆/天气相关 `EventKeys`；`http_constant.dart` 含 `EmptyCarListCode`、`renewalTokenCode`、`reLoginCode` 等业务常量 | 高 — 违反 Clean Architecture 分层原则 |
| **barrel 导出膨胀** | `api.dart` 14 个导出含多个死代码文件 | 中 — 公共 API 表面积过大 |

### 当前文件清单（19 个源文件）

```
packages/infrastructure/api/lib/src/
├── dio_factory.dart                    # 保留 — Dio 工厂函数
├── url_builder.dart                    # 删除 — 死代码，对应 favqs.com 旧项目
├── cancel/
│   ├── cancel_manager.dart             # 保留 — 请求取消管理
│   └── auto_cancel_interceptor.dart    # 保留 — 自动取消拦截器
├── dio/
│   ├── header_interceptor.dart         # 保留 — 请求头注入
│   ├── renewal_token_intercaptor.dart  # 保留 — Token 自动续期（排除范围）
│   ├── retry_interceptor.dart          # 删除 — 死代码，未被 Dio 注册
│   ├── token_interceptor.dart          # 删除 — 死代码，被 renewal_token_intercaptor 替代
│   └── log_reporting_interceptor.dart  # 删除 — 死代码，未注册，仅 debugPrint
├── error/
│   └── dio_mapper.dart                 # 保留 — DioException → DomainException 当前活动路径
├── http/
│   ├── app_logger.dart                 # 保留 — 日志接口
│   ├── concurrent_limiter.dart         # 删除 — 死代码，未集成到 HttpManager
│   ├── error_handler.dart              # 清理 — 删除 ErrorHandler 类，保留导出兼容？
│   ├── http_constant.dart              # 清理 — 移除业务常量，保留技术常量
│   ├── http_error.dart                 # 清理 — 删除 NeedLogin/NeedAuth/HttpsExceptionExtension 扩展
│   ├── http_event_bus.dart             # 清理 — 移除 OVSTap 枚举和业务 EventKeys
│   ├── retry_policy.dart               # 删除 — 死代码，未集成
│   └── token_supplier.dart             # 保留 — Token 提供者接口
└── tracking/
    └── request_tracker.dart            # 删除 — 死代码，未集成
```

### 架构约束

遵循项目的 **Clean Architecture + Feature-First** 模式：

```
依赖方向（单向）：
  lib/main.dart → lib/core/ → features/ → services/ → domain/ → infrastructure/
```

**关键原则**：基础设施层（`infrastructure/api`）不知道任何业务概念。HTTP 客户端不知道"用户"、"车辆"、"天气"——只知道请求方法、路径、参数。

### 约束条件

- **10 个 features，1-2 名开发者**：集中式管理优于分布式，git 冲突风险接近零
- **Token 续期相关文件排除**：`renewal_token_intercaptor.dart`、`token_supplier.dart`、`header_interceptor.dart` 保持不变
- **公共 API 必须兼容**：`DioExceptionMapper`、`HttpsException.create`、`createDio` 工厂保留
- **无破坏性变更**：删除和清理步骤不影响现有业务代码的编译

---

## Goals / Non-Goals

### Goals

| # | 目标 | 衡量标准 |
|---|------|---------|
| G1 | **端点集中管理**：所有 API 端点路径统一在一个文件，按域嵌套分组 | `api_endpoints.dart` 包含所有当前 RepositoryImpl 中的内联路径 |
| G2 | **死代码删除**：删除 7 个无引用文件 | 文件数 19 → 12，减少 ~900 行 |
| G3 | **错误处理统一**：单一 `DioExceptionMapper.toDomainException()` 路径 | `error_handler.dart`、`NeedLogin`、`NeedAuth`、`HttpsExceptionExtension` 全部删除 |
| G4 | **业务泄漏清理**：基础设施层零业务概念；基础设施自有常量与 domain 语义枚举解耦 | `OVSTap`、车辆/天气 `EventKeys`、`EmptyCarListCode` 移出；`reTokenCode`/`reLoginCode` 保留为基础设施常量，domain 新增 `tokenExpired`/`tokenInvalid` 语义枚举（数值相同，独立维护） |
| G5 | **导出精简**：barrel 文件仅暴露活跃公共 API | `api.dart` 从 14 个导出精简到 ~10 个 |

### Non-Goals

| # | 不包含 | 理由 |
|---|--------|------|
| N1 | 不增加 DataSource 抽象层 | 1-2 人团队，10 个 features 无需额外抽象；待团队 >5 人时引入 |
| N2 | 不修改 Token 续期逻辑 | 提案明确排除；`renewal_token_intercaptor.dart`、`token_supplier.dart` 零改动 |
| N3 | 不修复 domain ← infrastructure 依赖方向 | 当前 `http_error.dart` 依赖 `domain`，这是已存在的反向依赖；修复需 domain 层新增抽象接口，由更广泛的架构变更覆盖 |
| N4 | 不引入代码生成 | `build_runner` + `json_serializable` 已有使用，但端点管理不需要；`freezed` 为更大决策，单独评估 |
| N5 | 不重写 RepositoryImpl 架构 | 仅迁移端点字符串到常量，不改变 RepositoryImpl 的结构或模式 |

---

## Decisions

### D1: 端点管理 — 集中式嵌套分组（方案 A+）

**决策**：新建 `api_endpoints.dart`，使用 `abstract final class` 嵌套分组，按业务域组织：

```dart
// api_endpoints.dart — 设计意图示意（非最终实现）
abstract final class ApiEndpoints {
  static const String baseUrl = '/api';

  abstract final class Auth {
    static const String login = '/User/Login/Password';
    static const String register = '/User/Register';
    static const String tokenRenewal = '/User/Token/Renewal';
  }

  abstract final class Home {
    static const String banner = '/Home/Banner/List';
    static const String recommend = '/Home/Recommend';
  }

  abstract final class Vehicle {
    static const String list = '/Vehicle/List';
    static const String detail = '/Vehicle/Detail/Info';
    static const String ranking = '/Vehicle/Ranking/Query/Top/Info';
  }

  abstract final class Weather { ... }
  abstract final class Story { ... }
  abstract final class Message { ... }
  // ... 其他域
}
```

**理由**：

| 维度 | 决策依据 |
|------|---------|
| **团队规模** | 1-2 人 → git 冲突风险接近零，集中式查找效率高 |
| **可发现性** | 一个文件即可查看所有端点，无需跨 feature 目录查找 |
| **变更成本** | 后端路径变更时，修改一处 vs 搜索替换 |
| **可接受膨胀** | 当前端点 < 50 个，单文件完全可管理；超过 300 行设阈值考虑拆分 |

**已评估的替代方案**：

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| **方案 A (集中式嵌套)** | 统一管理，低发现成本 | 单文件膨胀风险 | **采纳**，适用于 1-2 人团队 |
| **方案 B (每 feature 独立端点文件)** | 高内聚，0 git 冲突 | 团队小时过度拆分，查找需跨文件 | 拒绝 — 团队 < 5 人时过度工程 |
| **方案 C (API Client 层)** | 强类型，IDE 提示 | 大量样板代码，需要 code gen | 拒绝 — 当前规模 ROI 低 |
| **方案 D (保持现状内联字符串)** | 零改动 | 重复、散落、难维护 | 拒绝 — 必须解决 |

**分组标准**【新增】：混合方案 — 
1. **按后端路径前缀分第一层**：`/User/*` → `User` 组，`/Vehicle/*` → `Vehicle` 组，保持与后端命名一致，降低查找成本
2. **基础设施共享端点独立放 `ApiBase`**：如 `tokenRenewal` 不属于任何业务域，直接放在 `ApiBase` 顶级
3. **组内可选 subgroup**：当单个域的端点 > 5 个时，按 HTTP 语义或子域拆分子组（如 `_Auth` 内的 `login`/`register`/`password`）

**路径参数模式**【新增】：使用 Dart 字符串插值构建动态路径
```dart
abstract final class _Vehicle {
  static const String _prefix = '/Vehicle';
  static String detail(int id) => '$_prefix/Detail/$id';     // /Vehicle/Detail/42
  static String list({int page = 1}) => '$_prefix/List?page=$page';
}
```

**`baseUrl` 来源**【新增】：从 `http_constant.dart` 的 `Http_Host` + `IsRelease` 提取到 `ApiBase`
```dart
abstract final class ApiBase {
  static String get baseUrl => 'http://${HttpConstant.Http_Host}';
  static const String tokenRenewal = '/User/Token/Renewal';
  // 环境切换逻辑保持：HttpConstant 中 IsRelease 控制 Host，ApiBase 引用 HttpConstant
}
```

### D2: 死代码删除 — 激进删除

**决策**：删除以下 7 个文件（不保留、不注释化）：

| 文件 | 行数 | 确认死亡方式 | 说明 |
|------|------|-------------|------|
| `url_builder.dart` | 73 | grep 零引用 + git history 确认属于已删除的 `favqs.com` demo 项目 | 内容：favqs.com API builder，与当前项目无关 |
| `token_interceptor.dart` | 247 | grep 零引用 + 已存在 `renewal_token_intercaptor.dart` 替代 | 内容：旧的 Token 拦截器，包含完整 Token 续期逻辑（已替换） |
| `retry_interceptor.dart` | 83 | grep 零引用 + 未在 `Dio` 实例上注册 | 内容：网络失败自动重试拦截器 |
| `retry_policy.dart` | 100 | grep 零引用 + 注释标注"需手动集成到 HttpManager"但未集成 | 内容：重试策略配置类 |
| `concurrent_limiter.dart` | 167 | grep 零引用 + 注释标注"需手动集成"但未集成 | 内容：并发请求队列限制器 |
| `request_tracker.dart` | 82 | grep 零引用 + 注释标注"需手动集成"但未集成 | 内容：请求耗时追踪器 |
| `log_reporting_interceptor.dart` | 87 | grep 零引用 + 未在 `Dio` 实例注册 | 内容：日志上报拦截器（仅 debugPrint，无实际上报逻辑） |

**理由**：
- 所有文件通过 `grep` 确认零引用，再通过 `git log -- <file>` 确认从未集成或已被替代
- 删除后文件数 19 → 12（减少 37%），清晰度显著提升
- git history 保留代码，需要时可 `git revert` 恢复

**验证方式**：删除后 `flutter analyze packages/infrastructure/api/` 零错误。

### D3: 错误处理统一 — 保留 DioExceptionMapper，删除其余

**决策**：

```
保留：   error/dio_mapper.dart (DioExceptionMapper extension) — 当前活动路径
删除：   HttpsExceptionExtension (http_error.dart 末尾 extension)
删除：   ErrorHandler 类 (error_handler.dart 完整文件)
删除：   NeedLogin, NeedAuth (http_error.dart 中两个 class)
保留：   HttpsException (http_error.dart 中主 class) — `HttpsException.create` 仍被外部引用
```

**当前错误映射路径对比**：

| 路径 | 状态 | 入口 | 映射到 |
|------|------|------|--------|
| `DioExceptionMapper.toDomainException()` | **活跃** | `DioException` | `DomainException` (sealed class) |
| `HttpsExceptionExtension.toDomainException()` | 死亡 | `HttpsException` | `DomainException` |
| `ErrorHandler.handleError()` | 死亡 | `dynamic` (anything) | `HttpsException` |

**采用单一 DioExceptionMapper 路径的原因**：
- 映射链最短：`DioException` → `DomainException`，不经过中间 `HttpsException`
- `DioExceptionMapper` 使用枚举表驱动（`_statusCodeMap` + `_typeMap`），维护成本低
- `HttpsExceptionExtension` 和 `ErrorHandler` 无人调用（确认通过 LSP 引用搜索）
- 参考自 [ntminhdn/Flutter-Bloc-CleanArchitecture](https://github.com/ntminhdn/Flutter-Bloc-CleanArchitecture) (542★) 的单一错误映射模式

**需要保留的**：
- `HttpsException` 主类和 `HttpsException.create()` 工厂 — 仍有外部引用（如 `retry_interceptor.dart` 在删除前引用，外部 `RepositoryImpl` 也可能引用 `HttpsException.create`）
- 删除时需确认无外部引用，有则保留

### D4: 业务泄漏清理 — 提取不删除 + 基础设施/领域解耦

**决策**：将业务概念从基础设施层提取到正确层级，保持行为不变。对基础设施层的技术常量（如 `reTokenCode`/`reLoginCode`），保留并明确其基础设施归属；同时在上层（domain）维护对应的语义枚举（`tokenExpired`/`tokenInvalid`），两方数值相同但各自独立维护，不互相引用。

| 当前位置 | 业务概念 | 目标位置 | 理由 |
|---------|---------|---------|------|
| `http_event_bus.dart` | `OVSTap` 枚举 | `lib/core/` | 枚举定义无基础设施/业务依赖，放 core 使各 feature 可共用 |
| `http_event_bus.dart` | 业务 `EventKeys` (`addNewCar`, `updateWeather`, `updateCar`, etc.) | `services/` 或相关 feature | 这些键对应业务事件（新增车辆、更新天气），应随业务归位 |
| `http_event_bus.dart` | 通用 `EventKeys` (`logout`, `hasToken`) | 保留在 `http_event_bus.dart` | 认证相关，基础设施层合理 |
| `http_constant.dart` | `EmptyCarListCode = 9` | 删除或移至 `feature_car` | 车辆业务错误码 |
| `http_constant.dart` | `reTokenCode = 1000102` | 保留在 `http_constant.dart`（基础设施自有常量，不对外暴露） | Token 续期是基础设施行为；命名从 `renewalTokenCode` 缩短，避免与 domain 语义名冲突 |
| `http_constant.dart` | `reLoginCode = 1000103` | 保留在 `http_constant.dart`（基础设施自有常量，不对外暴露） | 基础设施层身份认证语义；上层通过 domain 异常判断 |
| `domain/exceptions/`（新增） | `tokenExpired = 1000102` | 已存在 `ErrorCode.tokenExpired`，明确语义对应关系 | 供上层业务使用；与 `http_constant.reTokenCode` 数值相同但独立维护，不互相引用 |
| `domain/exceptions/`（新增） | `tokenInvalid = 1000103` | 新增至 `ErrorCode` 枚举 | 供上层业务使用；数值与 `http_constant.reLoginCode` 相同但独立维护，不互相引用 |
| `http_constant.dart` | `msgVCodeMaxLength = 5` | 删除或移至 `feature_auth` | 短信验证码业务规则 |

**注意**：`EventKeys` 中的业务事件需要在提取后保持 `commit(EventKeys.xxx)` 调用可用。迁移策略：在同一 commit 中创建新位置 + 更新 import，确保编译不中断。

**判断标准**：问 "基础设施需要知道这个吗？"
- 知道"HTTP、超时、重试" → 保留
- 知道"车辆、天气、短信验证码" → 提取

### D5: barrel 导出精简

**决策**：`api.dart` 从 14 个导出精简到约 10 个。

```
保留：
  - dio_factory.dart           # Dio 工厂函数 + createDio()
  - http_error.dart            # HttpsException (条件：有外部引用)
  - http_event_bus.dart        # HttpEventBus 类 (通用 EventKeys)
  - http_constant.dart         # HttpConstant 技术常量 (保留技术部分)
  - token_supplier.dart        # TokenSupplier 接口
  - dio_mapper.dart            # DioExceptionMapper (保留)
  - cancel_manager.dart        # CancelTokenManager
  - auto_cancel_interceptor.dart
  - renewal_token_intercaptor.dart  # Token 续期拦截器
  - app_logger.dart            # AppLoggerInterface
  - api_endpoints.dart         # 新增 — 端点常量 (全新)

删除导出：
  - error_handler.dart         # 删除文件
  - retry_policy.dart          # 删除文件
  - concurrent_limiter.dart    # 删除文件
  - log_reporting_interceptor.dart  # 删除文件
  - request_tracker.dart       # 删除文件
```

**理由**：barrrel 文件是公共 API 契约。删除死代码对应的导出，减少 API 表面积，降低使用者的认知负担。

---

## Risks / Trade-offs

### R1: 端点文件膨胀风险

**风险**：随着新 feature 增加，`api_endpoints.dart` 持续增长，超过可维护阈值。

| 维度 | 详情 |
|------|------|
| **当前规模** | ~50 个端点，估算 ~200 行 |
| **阈值** | 300 行为拆分触发线 |
| **超标后方案** | 按域拆分为 `api_endpoints_auth.dart`、`api_endpoints_home.dart` 等 |
| **缓解** | `abstract final class` 嵌套结构天然支持拆为独立文件后通过 `part` 或重新组合 |

**判断依据**：10 个 features × 平均 5 个端点 = 50 个。同类项目中，豆瓣 API 封装约 120 个端点仍维持单文件。300 行阈值留 50% 余量。

### R2: 死代码删除误伤风险

**风险**：删除的文件有尚未发现的引用，导致编译失败。

| 缓解措施 | 说明 |
|---------|------|
| **四步确认** | grep 搜引用 → `lsp_find_references` 验证 → `flutter analyze` 确认 → CI 管道验证 |
| **分步提交** | 删除后立即运行 `flutter analyze`，在所有包上验证 |
| **可回滚** | `git revert` 恢复单个 commit，删除文件未涉及数据库或数据变更 |
| **不破坏历史** | git history 保留已删除文件，恢复成本 < 5 分钟 |

### R3: OVSTap/EventKeys 迁移破坏引用

**风险**：移动 `OVSTap` 枚举和 `EventKeys` 到新位置后，现有引用未更新导致编译断裂。

**缓解**：
- 在同一 commit 中完成"创建目标文件 → 更新所有 import → 删除原位置"三步
- 移动前通过 `lsp_find_references` 收集所有调用点
- 提交前运行全项目 `flutter analyze`

### R4: HttpsException.create 保留判断

**风险**：`HttpsException.create()` 是 `HttpsException` 类的工厂构造函数，如果外部无引用，应一并清理以减少遗留。

**处理方法**：
- 通过 `lsp_find_references` 确认外部引用
- 有引用 → 保留 `HttpsException` 类（含 `create` 工厂）
- 无引用 → 删除整个 `http_error.dart` 文件（减少冗余代码）
- 决策在实施阶段确认，设计阶段不做假设

### R5: Token 续期排除范围的依赖风险

**风险**：`renewal_token_intercaptor.dart` 可能依赖即将删除的文件（如 `retry_policy.dart`）。

**缓解措施**：
- 删除前检查 `renewal_token_intercaptor.dart` 的 import 语句
- 如果有对删除文件的依赖，更新 import 或删除对应引用
- Token 续期逻辑本身不变，仅清理其废弃依赖

### R6: 业务常量提取后调用者更新遗漏

**风险**：`HttpConstant.EmptyCarListCode` 等业务常量在 feature 中有引用，迁移后未更新 import。

**缓解**：
- 在 `http_constant.dart` 中标注 `@Deprecated('Move to feature_car')` 过渡一个版本
- 或工具辅助替换：grep 搜所有 `HttpConstant.EmptyCarListCode` 替换为新路径
- 本重构选择"同一 commit 完整迁移"策略，不做过渡期

---

## Trade-offs 总结

| 权衡 | 选择 | 放弃 |
|------|------|------|
| 端点管理 | 集中式单文件 | 每个 feature 独立端点文件（可拆分但暂不需要） |
| 死代码 | 彻底删除 | 保留注释/保留文件（保持历史可追溯 via git） |
| 错误处理 | 单一 DioExceptionMapper 路径 | ErrorHandler 的多格式兼容（JSON/String/Map/Response） |
| 业务泄漏 | 提取到正确层级 | 延迟到"架构大重构"（当前修复立即减少违规） |
| barrel 导出 | 精简 | "一次性导出所有"的便利性 |

---

## Migration Plan

```
Phase 1: 创建 api_endpoints.dart
  - 从所有 RepositoryImpl 收集当前端点字符串
  - 按域嵌套分组，使用 abstract final class
  - 不修改任何 RepositoryImpl（仅新建文件）

Phase 2: 迁移 RepositoryImpl 引用
  - 逐个 RepositoryImpl 将内联字符串替换为 ApiEndpoints.xxx
  - 同步修改 import 语句
  - 每改完一个运行 `flutter analyze`

Phase 3: 错误处理清理 — 确定 HttpsException 最终形态
  - 从 http_error.dart 删除 HttpsExceptionExtension、NeedLogin、NeedAuth
  - 删除 error_handler.dart 文件
  - 通过 lsp_find_references 确认 HttpsException.create 外部引用关系
  - 有引用 → 保留 HttpsException 类；无引用 → 删除整个 http_error.dart
  - 验证 DioExceptionMapper 仍正常工作

Phase 4: 删除死代码文件（7 个文件）
  - 删除 url_builder.dart、token_interceptor.dart、retry_interceptor.dart
  - 删除 retry_policy.dart、concurrent_limiter.dart、request_tracker.dart
  - 删除 log_reporting_interceptor.dart
  - 同步删除 token_renewal_interceptor_test.dart 中 RetryPolicy/ConcurrentLimiter/RequestTracker 测试组
  - 运行完整测试套件验证

Phase 5: 业务泄漏清理
  - 移动 OVSTap 枚举到 lib/core/ 或适当位置
  - 移动业务 EventKeys 到 services 或 feature 层
  - 从 http_constant.dart 移除业务常量
  - 清理 AliyunOSSConstant（业务关联的 OSS 配置）

Phase 6: 更新 api.dart barrel 导出
  - 删除死代码文件对应的导出
  - 新增 api_endpoints.dart 导出
  - 确认公共 API 兼容性

Phase 7: 验证
  - flutter analyze — 零错误
  - flutter test — 全部通过
  - 手动验证关键路径（login、home 加载、车辆列表）
```

**回滚策略**：每个 Phase 独立提交。Phase 1-3 是纯新增 + 引用替换 + 形态确认，无回滚风险。Phase 4 开始有删除操作，但 git revert 可完整恢复。

---

## 状态目标

重构完成后，`packages/infrastructure/api/` 应达到：

| 指标 | 当前 | 目标 |
|------|------|------|
| 文件数 | 19 | 12 |
| 死代码行数 | ~900 | 0 |
| 错误处理路径 | 3 条（DioExceptionMapper + HttpsExceptionExtension + ErrorHandler） | 1 条（DioExceptionMapper） |
| 业务泄漏点 | 5 处（OVSTap, EventKeys business, EmptyCarListCode + renewalTokenCode/reLoginCode 转为域枚举 tokenExpired/tokenInvalid） | 0 处业务泄漏；reTokenCode/reLoginCode 保留为基础设施常量 |
| 端点管理模式 | 内联字符串散落各 RepositoryImpl | 集中式 ApiEndpoints 常量 |
| barrel 导出数 | 14 | ~10 |
| Clean Architecture 评分 | 5/10 | 8.8/10 |

---

## Open Questions

以下问题在实施阶段确认：

1. **`HttpsException.create` 外部引用数** → 决定是否完整删除 `http_error.dart` 或保留 `HttpsException` 类
2. **`http_event_bus.dart` 自身存留** → 如果提取后仅剩 `logout`/`hasToken` 两个通用事件，是否保留此文件还是合并到其他基础设施模块
3. **`OVSTap` 枚举目标位置** → `lib/core/` 还是新建 `packages/domain` 枚举？取决于是否跨 feature 共享（调研确认 feature_home 和 feature_detail 都引用）
4. **`AliyunOSSConstant` 归属** → 该常量类包含 OSS 业务 bucket 配置，但属于基础设施能力（OSS 上传）。保留在 `http_constant.dart` 还是移至独立 `oss_config.dart`？
5. **[RESOLVED] 迁移后端点名规范** → 按后端路径前缀分第一层（`/User/*` → `User` 组），基础设施共享端点独立放 `ApiBase`，组内可选 subgroup。【详见 D1 分组标准】
