## Context

`packages/infrastructure/api` 当前评分 5.0/10,经 6 轮代码深挖 + 5 轮 grep 确认存在 3 类问题:

1. **19 项零引用死文件/死砖块/死脚本污染仓库**: 6 个零调用 api 类(3 个 api 实际被用) + 3 个 spec.json + 6 个零引用 dart 文件 + 2 个死砖块 + 1 个残废脚本(232 行) + 1 个 README 描述不存在的 `RequestTracker`
2. **`renewal_token_intercaptor.dart` 716 行单文件**职责混杂: 1 个 enum + 1 个数据类 + 1 个主类 + 12 个私有方法塞在一起,2 个 90% 重复的排空方法(`_retryAllPendingRequests` line 495-551 / `_completeAllPendingRequestsWithOriginalResponse` line 555-600)
3. **`bricks/api` 砖块破坏 R3/R8 硬规则**: 生成代码不 `implements` 任何 domain 接口,4 处 `catch (e) { return Result.failure(NetworkException(e.toString())); }` 拼字符串,DI 注册键用 impl 类而非接口

经过 5 轮用户决策迭代(m0023-m0037),已锁定以下核心约束:

- **业务逻辑完全保留**: 4 条可验证约束(Dio 抓包 / Sentry 堆栈 / 锁与并发 / 时序)+ 5 条不动约束(batchSize 5/10 / 200ms 重试 / 10s 超时 / 50ms 批次间隔 / 5s 续期成功复用窗 / Set 去重 ==/hashCode / fire-and-forget / Dio 注入方式)
- **走 openspec spec-driven 流程**: proposal → specs + design → tasks,1 人项目写 minimal proposal
- **PR 顺位**: B(无风险死代码)→ A(token 拆分)→ C-1a(砖块契约)
- **误判纠正**: 原"3 个 impl 缺接口契约"经核实 `feature_home`/`feature_detail`/`services/auth` 3 个 impl 均已 `implements` 对应 domain 接口,且 `user_repository_impl._mapError` 反而比 `toDomainException` 更精确(处理 422 fieldErrors),不应回退。`repository-implements-enforcement` capability 已删除

## Goals / Non-Goals

**Goals**:

- 移除全部 19 项零引用产物,`melos analyze` + 4 步 pre-commit 零回归
- 把 716 行 token interceptor 拆成 3 个职责清晰文件(refresh_queue ≤120 行 / refresh_api ≤250 行 / 主胶水 ≤220 行),并入 `dio/` 目录保留 import 路径
- 合并 2 个 90% 重复排空方法为 `_drain(processor, {batchSize, fireAndForget})` 单参助手,**字节码等价**
- 修 1 个字节码等价的命名错误(`ovsx-app-token` → `''`)
- 新增 ≥12 个单测覆盖 refresh_queue 和 refresh_api 的纯函数
- 升级 `bricks/api` 砖块契约: `domainInterface` 必填变量 + `implements` 强制 + 4 处 `e.toString()` 改 `toDomainException` + DI 注册键改用接口

**Non-Goals**:

- 不改 Dio 拦截器 push 顺序(AGENTS.md R6)
- 不改 DI 装配(`lib/core/di/setup.dart:51` `TokenRenewalInterceptor(dio, tokenStorage: tokenStorage)` 不动)
- 不改 `_tokenStorage!` 4 处强解(interceptor line 413/429/481/626)— 改了就动行为
- 不统一 batchSize 5/10 — 维持现状
- 不修复 `user_repository_impl._mapError`(已优于 `toDomainException`,422 fieldErrors 不能丢)
- 不动 3 个已存在的 feature 包(砖块只影响新生成代码)
- 不集成 Sentry 客户端改造(R8 走 `ErrorReporter` 抽象已满足)
- 不改 melos.yaml 5 个 workspace 模式

## Decisions

### D1: 死代码清理范围严格按 19 项清单

**决策**: 删除 19 项零引用产物,严格按 `specs/dead-code-cleanup/spec.md` 的清单执行,每项必须配 grep 证据。

**依据**: 6 轮 explore 全部基于 `grep` 在 `packages/**/*.dart` 上跑过。`AuthApi`/`SessionApi`/`VehicleApi` 全仓 0 外部 import;`bricks/api_gen`/`bricks/api_gen_spec` 在 makefile/melos.yaml/pubspec.yaml/analysis_options.yaml/CI 全 0 引用;`scripts/gen_api.dart` 仓库自己声明"保留为备用"(makefile line 200 注释 + README line 777 声明)。

**替代方案**:

- 保留死代码加 `@Deprecated` 注解 → 拒: 与清理仓库目标冲突,且无下游迁移成本
- 保留 `gen_api.dart` 注释作 fallback → 拒: 字节码输出与 Mason 砖块完全一致(README line 1015),无功能差异

### D2: Token interceptor 按 4 文件边界拆分

**决策**: 把 716 行单文件拆成 4 部分(3 个 dart 文件 + 1 段 Mermaid 文档迁出),边界基于 8 段切片:

| 目标文件 | 源行号 | 内容 | 行数上限 |
|---|---|---|---|
| `lib/src/refresh/refresh_queue.dart` | 71-105, 141, 155-181, 494-600 (含 `_drain` 合并产物) | `PendingRequest` 类 + `_pendingRequests` + `_addToPendingRequests` + `_drain` | ≤120 |
| `lib/src/refresh/refresh_api.dart` | 398-457, 459-492, 602-658, 673-715 | `_performTokenRenewal` + `_processRenewalResponse` + `_retryRequestWithRetry` + `_retryRequest` + `_executeRenewalRequest` + `_configureProxy` | ≤250 |
| `lib/src/dio/renewal_token_intercaptor.dart`(路径不变) | 56-69, 107-153, 183-396, 660-671 | `TokenRenewalState` enum + 主类壳(ctor/fields/setters) + `onResponse` + `_handleRenewalResponse` + `_shouldRenewToken` | ≤220 |
| `design.md` 本文件 | 13-54 | Mermaid 流程图(从行注释迁出,作为权威架构图) | — |

**关键 import 路径不变**: `dio_factory.dart:51` 仍构造 `TokenRenewalInterceptor`,`TokenRenewalInterceptor` 仍 `import '../../api.dart'` 取 `HttpConstant`/`ApiBase`/`HeaderInterceptor`。`refresh_queue.dart` 和 `refresh_api.dart` 从 `lib/src/refresh/` 导入,被 `renewal_token_intercaptor.dart` 通过相对路径 `import '../refresh/refresh_queue.dart'` 引用。

**替代方案**:

- 拆成 5 个文件(把 `TokenRenewalState` enum 单独一个文件)→ 拒: enum 仅 13 行,过度拆分
- 保持 716 行单文件+ 加 `# region` 分块 → 拒: 不可单测,不可职责清晰,违反 DRY 拆分原则

### D3: `_drain` 合并是字节码等价

**决策**: 把 `_retryAllPendingRequests`(line 495-551)和 `_completeAllPendingRequestsWithOriginalResponse`(line 555-600)合并成:

```dart
Future<void> _drain(
  Future<void> Function(_PendingRequest) processor, {
  required int batchSize,
  required bool fireAndForget,
}) async {
  final all = _pendingRequests.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  _pendingRequests.clear();
  for (var i = 0; i < all.length; i += batchSize) {
    final batch = all.skip(i).take(batchSize);
    final futures = batch.map(processor);
    if (fireAndForget) {
      unawaited(Future.wait(futures));
    } else {
      await Future.wait(futures);
    }
    if (i + batchSize < all.length) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
```

**调用点**:

- 成功路径(line 271 / 282 附近): `_drain(processor: _retryRequestWithRetry, batchSize: 5, fireAndForget: false)`
- 失败路径(line 271 / 282 附近): `_drain(processor: (p) => p.completer.complete(p.originalResponse), batchSize: 10, fireAndForget: true)`

**字节码等价性**:
- `Set` 复制+排序+清空 时序一致(原 line 502, 562)
- 批次大小差异(5 vs 10)通过参数保留
- 50ms 延迟(line 544, 593)保留
- `await` 差异通过 `unawaited` + `fireAndForget` 标志保留
- `processor` 是回调函数,签名匹配原 `_retryRequestWithRetry` 和 `completer.complete`

**替代方案**:

- 用 Stream + `StreamController` 替代 Set+sort → 拒: 引入新并发原语,违反"不动"约束
- 完全保留 2 个方法,只共享私有 helper(只抽 batch 框架)→ 拒: 90% 重复,违反 DRY 原则

### D4: `ovsx-app-token` → `''` 是字节码等价修复

**决策**: 把 line 420 `accessKeyId: const String.fromEnvironment('ovsx-app-token')` 改为 `accessKeyId: const String.fromEnvironment('')`。

**字节码等价证据**: Dart 规范规定 `String.fromEnvironment(name)` 在 name 未通过 `--dart-define` 设置时编译期求值为 `''`。两个 const 表达式在编译期求值产物完全相同,生成的字节码无差异。

**命名错误证据**: `ovsx-app-token` 是 VSCode Marketplace(Open VSX Registry)的 API token 变量名,与 token 续期接口无关,纯命名残留。

**替代方案**:

- 改为 `null` 删字段 → 拒: 改变请求 headers 字节码
- 加 `@Deprecated` 注解保留 → 拒: 字段是 const,不能加注解
- 改为真实业务字段(如 `clientId`)→ 拒: 改行为,违反"业务逻辑不动"约束

### D5: 5 条不动约束

| # | 约束 | 来源行号 | 验证方法 |
|---|---|---|---|
| 1 | batchSize 5(成功) vs 10(失败) 不统一 | interceptor line 511, 571 | diff 中 `_drain(... batchSize: 5, ...)` 和 `_drain(... batchSize: 10, ...)` 两处 |
| 2 | 200ms 重试间隔 / 10s Completer 超时 / 50ms 批次延迟 / 5s 续期成功复用窗 | interceptor line 619, 313-319, 544/593, 253-256 | grep 4 个字面量 |
| 3 | `_PendingRequest` 自定义 `==`(path+method+params+data)+ `hashCode` | interceptor line 87-104 | diff 中 `operator ==` 和 `hashCode` override 保留 |
| 4 | 失败路径 fire-and-forget(`unawaited(Future.wait(...))`) | interceptor line 271, 282 | diff 中 `_drain(... fireAndForget: true)` 调用点 |
| 5 | 续期请求走 `_dio.request(...)`(构造注入),仅 `_executeRenewalRequest` 内部用 fresh `Dio()` | interceptor line 652, 680 | diff 中 `_dio.request` 出现 1 次,`Dio()` 出现 1 次(在 refresh_api.dart) |

### D6: 4 条可验证约束

| # | 验证项 | 验证方法 | 通过条件 |
|---|---|---|---|
| 1 | Dio 拦截器 push 顺序 | `diff dio_factory.dart` | 0 行变更(`interceptors.addAll([...])` 字节相同) |
| 2 | 续期 HTTP 请求字节相同 | Dio mock 抓包,对比 URL/headers/14 字段 Options | URL/Method/Headers/Options 全部 byte-identical |
| 3 | Sentry 错误堆栈不变 | 触发 422 + Sentry 抓包 | 堆栈帧位置(line number)和 `HttpEventBus.commit(EventKeys.logout)` 时机不变 |
| 4 | 锁与并发原语不变 | grep `Lock.synchronized` 出现次数 | 1 处(line 232 调用点保留) |

### D7: 砖块契约改动 4 项

**决策**: 升级 `bricks/api` 4 处,严格按 `specs/mason-brick-contract/spec.md`:

1. **`bricks/api/brick.yaml`** 新增 `domainInterface` 必填变量(type=string, 无 default, 描述含 I 前缀示例)
2. **`__brick__/lib/src/repository/{{name}}_repository_impl.dart` line 5** 改为 `class {{name.pascalCase()}}RepositoryImpl implements I{{name.pascalCase()}}Repository {`
3. **`__brick__/lib/src/repository/{{name}}_repository_impl.dart` line 16/25/35/44** 4 处 `catch (e)` 拆为 `on DioException catch (e) { return Result.failure(toDomainException(e)); } catch (e) { return Result.failure(UnknownException(e.toString())); }`
4. **`__brick__/lib/src/di/setup.dart` line 12-14** 改为 `sl.registerFactory<I{{name.pascalCase()}}Repository>(() => {{name.pascalCase()}}RepositoryImpl(sl<...>()));`

**新增文件** `bricks/api/README.md`(当前不存在): 文档化 `domainInterface` 变量,警告 mason 覆盖式写入不合并。

**pubspec.yaml 保留** `domain: path: ../../domain`(line 15-16)以让 `implements` 子句编译期可校验。

**替代方案**:

- 5 个 CRUD 方法改可配置(允许用户传 method 列表)→ 拒: 增加砖块复杂度,违反"最小代码"原则
- 不强制 `implements`,仅在 README 文档化 → 拒: 与硬规则 R3 冲突
- 在 `bricks/api_gen`/`bricks/api_gen_spec` 复活时再改 → 拒: 这 2 个砖块 PR-B 删除

## Risks / Trade-offs

### R1: Token interceptor 拆分引入新文件路径,`dio_factory.dart` 间接依赖

**风险**: `refresh_queue.dart` 和 `refresh_api.dart` 从 `lib/src/refresh/` 引入,被 `lib/src/dio/renewal_token_intercaptor.dart` 引用。`dio_factory.dart` 仍 import 主文件,不直接感知新文件。但如果未来有人 `import 'lib/src/refresh/refresh_queue.dart'`,跨层引用就出现(虽然 infrastructure 内部允许)。

**缓解**:
- 不在新文件加 `export`(只在 `api.dart` barrel 加 1 行 re-export,保持原 `lib/api.dart` 单入口)
- `refresh_queue.dart` 和 `refresh_api.dart` 标 `library;` directive 限可见性
- 在 design.md 写明:`refresh_queue` 和 `refresh_api` 是 `lib/src/` 内部组件,不应被外部 import

### R2: 砖块升级后,旧 feature 包不重生成,行为与新契约不一致

**风险**: 3 个已存在 feature 包(`feature_home`/`feature_detail`/`feature_auth`)的 impl 已经手写 `implements` 接口,但若用户运行 `make create-api` 重建同名模块,mason 会覆盖,丢失手写代码(impl 类名一致但内部可能有额外逻辑)。

**缓解**:
- 在砖块 README 显著位置加 **WARNING**: "mason 覆盖式写入,运行前请备份"
- 未来 PR(非本 change)考虑加 `--merge` 模式(超出当前 scope)

### R3: 字节码等价性在 dart 编译器升级后可能不等价

**风险**: `_drain` 合并假设 `Dart 3.x` 编译器的 `Set.toList()..sort()` 和 `Set` 直接迭代生成相同字节码。若未来 Dart 编译器对 Set 迭代顺序做规范化(目前无序),行为会变。

**缓解**:
- 在测试中显式断言 Set 迭代顺序稳定(`.sort((a, b) => a.timestamp.compareTo(b.timestamp))` 在 refresh_queue_test.dart 写一个 case)
- 5 条不动约束中"Set 去重 ==/hashCode 保留"已锁定

## Decisions Locked

| Question | Decision | Rationale |
|----------|----------|-----------|
| Q1: token interceptor 拆几个文件? | **3 个 dart + Mermaid 迁 design.md** | 8 段切片 → 4 个独立职责;3 文件匹配 RefreshQueue/RefreshApi/主胶水 |
| Q2: `_drain` 合并是字节码等价还是行为改? | **字节码等价** | 用户 m0035 升级"代码清洁但业务逻辑完全保留"立场 |
| Q3: 修 `ovsx-app-token` 命名错误吗? | **修,改为 `''`** | 字节码等价 + 命名正确性双赢 |
| Q4: `_tokenStorage!` 4 处强解改吗? | **不改** | 改了就动行为(NPE 防护逻辑),违反"业务逻辑不动" |
| Q5: 3 个 impl 缺接口契约是真的吗? | **不是,已误判纠正** | 3 个 impl 均已 `implements`,`user_repository_impl._mapError` 反而更优,不应回退 |
| Q6: batchSize 5/10 统一吗? | **不统一,参数化保留** | 行为改,维持现状,只抽参数 |
| Q7: 砖块加 `domainInterface` 必填还是可选? | **必填** | 留空时 mason 报错,防止生成破坏 R3 的代码 |
| Q8: 死代码一刀切还是留 deprecated? | **直接删** | 0 外部引用,无迁移成本 |
| Q9: PR 顺位? | **B → A → C-1a** | 风险递增,B 零风险先做,A 需要 4 条约束验证, C-1a 影响未来新代码 |
| Q10: PR-C-1b 保留吗? | **不保留,删 capability** | 误判纠正后该 PR 无价值,改 `_mapError` 反而劣化 |
