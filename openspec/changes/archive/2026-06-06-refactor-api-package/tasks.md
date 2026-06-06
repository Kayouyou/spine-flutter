## 1. PR-B: 死代码清理 (零风险,顺位第 1)

### 1.1 删除 api 包内 6 个零引用 dart 文件

- [ ] 1.1.1 删除 `packages/infrastructure/api/lib/src/constants/api_constants.dart`(10 行,grep 验证 0 外部 import)
- [ ] 1.1.2 删除 `packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart`(82 行,grep 验证 0 外部 import)
- [ ] 1.1.3 删除 `packages/infrastructure/api/lib/src/http/http_constant.dart`(53 行,grep 验证 0 外部 import)
- [ ] 1.1.4 删除 `packages/infrastructure/api/lib/src/http/http_event_bus.dart`(37 行,grep 验证 0 外部 import)
- [ ] 1.1.5 删除 `packages/infrastructure/api/lib/src/http/app_logger.dart`(63 行,grep 验证 0 外部 import)
- [ ] 1.1.6 删除 `packages/infrastructure/api/lib/src/http/token_supplier.dart`(15 行,grep 验证 0 外部 import)

### 1.2 删除 2 个 orphan README

- [ ] 1.2.1 删除 `packages/infrastructure/api/lib/src/tracking/README.md`(描述不存在的 `RequestTracker`,全仓 0 引用)
- [ ] 1.2.2 删除 `packages/infrastructure/api/lib/src/error/README.md`(orphan 文档)

### 1.3 删除 component_library 内 1 个零引用文件

- [ ] 1.3.1 删除 `packages/infrastructure/component_library/lib/src/constants/api_constants.dart`(16 行,grep 验证 0 外部 import)

### 1.4 删除 3 个零调用 api 类 + 3 个 .g.dart

- [ ] 1.4.1 删除 `packages/infrastructure/api/lib/src/api/auth_api.dart` + `auth_api.g.dart`(26 行 + 生成代码,grep `\bAuthApi\b` 在 packages/ 下 0 外部匹配)
- [ ] 1.4.2 删除 `packages/infrastructure/api/lib/src/api/session_api.dart` + `session_api.g.dart`(19 行 + 生成代码,grep `\bSessionApi\b` 在 packages/ 下 0 外部匹配)
- [ ] 1.4.3 删除 `packages/infrastructure/api/lib/src/api/vehicle_api.dart` + `vehicle_api.g.dart`(21 行 + 生成代码,grep `\bVehicleApi\b` 在 packages/ 下 0 外部匹配)

### 1.5 删除 3 个对应 spec.json

- [ ] 1.5.1 删除 `packages/infrastructure/api/spec/auth.json`(55 行,死 spec,auth 流程实际走 `user.json` → `UserApi`,见 `services/auth/lib/src/di/setup.dart:14`)
- [ ] 1.5.2 删除 `packages/infrastructure/api/spec/session.json`(32 行,死 spec)
- [ ] 1.5.3 删除 `packages/infrastructure/api/spec/vehicle.json`(33 行,死 spec)

### 1.6 删除 2 个死砖块整目录

- [ ] 1.6.1 `rm -rf bricks/api_gen/`(全目录,grep 验证 makefile/melos.yaml/pubspec.yaml/analysis_options.yaml/CI 全 0 引用)
- [ ] 1.6.2 `rm -rf bricks/api_gen_spec/`(全目录,同上验证)

### 1.7 删除残废脚本

- [ ] 1.7.1 删除 `scripts/gen_api.dart`(232 行,仓库自标"保留为备用",推荐路径走 Mason 砖块)

### 1.8 清理 mason.yaml 和 makefile 引用

- [ ] 1.8.1 在 `mason.yaml` 删除 `api_gen` 和 `api_gen_spec` 两段(各 2 行,共 4 行)
- [ ] 1.8.2 在 `makefile` 删除 `gen-api` / `gen-all-apis` / `refresh-api` 三个 target + 相关注释(makefile line 200-228 区域)
- [ ] 1.8.3 在根 `pubspec.yaml` 删除 `mason:` 依赖(需先确认仅被这 2 个砖块使用 — grep `mason:` 在 packages/ 下应仅 1 处,根 pubspec)
- [ ] 1.8.4 跑 `dart pub get` 重新解析依赖,确认 `mason:` 删除无副作用

### 1.9 PR-B 验证

- [ ] 1.9.1 跑 `melos analyze` 确认 0 error 0 新 warning
- [ ] 1.9.2 跑 `.githooks/pre-commit` 4 步全过(check_deps.sh → check_l10n.sh → flutter analyze → melos test:affected)
- [ ] 1.9.3 跑 `melos test:affected` 确认受影响包测试数 = 删除前(无回归)
- [ ] 1.9.4 commit message: `chore(api): remove 19 dead artifacts (zero external references)`(遵循 AGENTS.md R10)

## 2. PR-A: Token interceptor 拆分 + boilerplate 合并 + 1 等价 bug (低风险,顺位第 2)

### 2.1 提取 RefreshQueue

- [ ] 2.1.1 新建 `packages/infrastructure/api/lib/src/refresh/refresh_queue.dart`
- [ ] 2.1.2 迁移 `TokenRenewalState` enum(原 line 57-69,13 行)
- [ ] 2.1.3 迁移 `PendingRequest` 类(原 line 72-105,34 行,保留 `==`/`hashCode` override)
- [ ] 2.1.4 迁移 `_pendingRequests` Set 字段(原 line 141)
- [ ] 2.1.5 迁移 `_addToPendingRequests` 方法(原 line 156-181,26 行)
- [ ] 2.1.6 实现 `_drain(processor, {batchSize, fireAndForget})` 合并助手(吸收原 `_retryAllPendingRequests` line 495-551 + `_completeAllPendingRequestsWithOriginalResponse` line 555-600,字节码等价)
- [ ] 2.1.7 确认 refresh_queue.dart 总行数 ≤120

### 2.2 提取 RefreshApi

- [ ] 2.2.1 新建 `packages/infrastructure/api/lib/src/refresh/refresh_api.dart`
- [ ] 2.2.2 迁移 `_performTokenRenewal`(原 line 399-457,59 行)
- [ ] 2.2.3 迁移 `_processRenewalResponse`(原 line 460-492,33 行)
- [ ] 2.2.4 迁移 `_retryRequestWithRetry`(原 line 603-620,18 行)
- [ ] 2.2.5 迁移 `_retryRequest`(原 line 623-658,36 行,保留 14 字段 Options 重建)
- [ ] 2.2.6 迁移 `_executeRenewalRequest`(原 line 674-699,26 行)
- [ ] 2.2.7 迁移 `_configureProxy`(原 line 702-715,14 行)
- [ ] 2.2.8 修字节码等价 bug:line 420 `const String.fromEnvironment('ovsx-app-token')` → `const String.fromEnvironment('')`
- [ ] 2.2.9 确认 refresh_api.dart 总行数 ≤250

### 2.3 瘦化主胶水文件

- [ ] 2.3.1 保留 `packages/infrastructure/api/lib/src/dio/renewal_token_intercaptor.dart` 路径(import 不变)
- [ ] 2.3.2 删除已迁出的 enum / PendingRequest / RefreshApi / 排空方法
- [ ] 2.3.3 保留 `TokenRenewalInterceptor` 类壳(原 line 107-153),9 个字段不变
- [ ] 2.3.4 保留 `onResponse`(原 line 185-301)
- [ ] 2.3.5 保留 `_handleRenewalResponse`(原 line 304-396)
- [ ] 2.3.6 保留 `_shouldRenewToken`(原 line 661-671,8 行)
- [ ] 2.3.7 删除原 line 13-54 Mermaid 块注释(迁出到 design.md)
- [ ] 2.3.8 改 `import '../refresh/refresh_queue.dart'` 和 `import '../refresh/refresh_api.dart'`
- [ ] 2.3.9 确认主胶水文件总行数 ≤220

### 2.4 调用点更新

- [ ] 2.4.1 在 `onResponse` 成功路径调用 `_drain(processor: _retryRequestWithRetry, batchSize: 5, fireAndForget: false)`(原 line 271)
- [ ] 2.4.2 在 `onResponse` 失败路径调用 `_drain(processor: (p) => p.completer.complete(p.originalResponse), batchSize: 10, fireAndForget: true)`(原 line 282)
- [ ] 2.4.3 验证 `dio_factory.dart:51` 构造 `TokenRenewalInterceptor(dio, tokenStorage: tokenStorage)` **0 行变更**

### 2.5 新增单测

- [ ] 2.5.1 新建 `packages/infrastructure/api/test/refresh/refresh_queue_test.dart`
- [ ] 2.5.2 测 `_PendingRequest.==` 同 path+method+params+data 返回 true
- [ ] 2.5.3 测 `_PendingRequest.==` 不同 path 返回 false
- [ ] 2.5.4 测 `_PendingRequest.hashCode` 满足 `==` 契约
- [ ] 2.5.5 测 `_drain` 空队列:0 processor 调用,立即完成
- [ ] 2.5.6 测 `_drain` N=12 + batchSize=5:3 批次,50ms × 2 间隔
- [ ] 2.5.7 测 `_drain` fireAndForget=true:caller Future 在 processor 完成前 resolve
- [ ] 2.5.8 新建 `packages/infrastructure/api/test/refresh/refresh_api_test.dart`
- [ ] 2.5.9 测 `_shouldRenewToken` code == reTokenCode 返回 true
- [ ] 2.5.10 测 `_shouldRenewToken` 其他 code 返回 false
- [ ] 2.5.11 测 `_shouldRenewToken` 非 JSON / null data 返回 false
- [ ] 2.5.12 测 `_retryRequest` 重建 14 字段 Options 与原 RequestOptions 一致
- [ ] 2.5.13 测 `_configureProxy` 产出 IOHttpClientAdapter 含正确 findProxy 回调
- [ ] 2.5.14 测 `_executeRenewalRequest` 接受任意 HTTP status(validateStatus 行为)
- [ ] 2.5.15 跑测试确认新测 ≥12 个

### 2.6 PR-A 4 条可验证约束验收

- [ ] 2.6.1 `git diff dio_factory.dart` 显示 **0 行变更**(Dio 拦截器 push 顺序约束)
- [ ] 2.6.2 写一个临时 Dio mock 抓包,验证续期 HTTP 请求 URL/method/headers/14 字段 Options 与 PR-A 前 byte-identical
- [ ] 2.6.3 触发 422 + Sentry mock,验证堆栈帧位置不变 + `HttpEventBus.commit(EventKeys.logout)` 时机不变
- [ ] 2.6.4 `grep -c '_renewalLock.synchronized' lib/src/dio/renewal_token_intercaptor.dart` = 1(锁调用点保留)

### 2.7 PR-A 5 条不动约束 grep 验收

- [ ] 2.7.1 `grep -nE 'batchSize: 5|batchSize: 10' lib/src/refresh/refresh_queue.dart` 出现 2 次(成功 5,失败 10)
- [ ] 2.7.2 `grep -nE 'Duration\(milliseconds: 200\)|Duration\(seconds: 10\)|Duration\(milliseconds: 50\)|Duration\(seconds: 5\)' lib/src/` 全部出现
- [ ] 2.7.3 `grep -nE 'operator ==|int get hashCode' lib/src/refresh/refresh_queue.dart` 各 1 次
- [ ] 2.7.4 `grep -nE 'unawaited\(' lib/src/dio/renewal_token_intercaptor.dart` 出现 ≥1 次
- [ ] 2.7.5 `grep -nE '_dio\.request\(|Dio\(\)' lib/src/refresh/refresh_api.dart` 各 1 次(1 个 `_dio.request` + 1 个 fresh `Dio()`)

### 2.8 PR-A 验证 + commit

- [ ] 2.8.1 跑 `melos analyze` 确认 0 error 0 新 warning
- [ ] 2.8.2 跑 `melos test:affected` 确认 15 个旧测试(token_renewal_interceptor_test.dart 9 + auto_cancel_interceptor_test.dart 3 + dio_factory_test.dart 3)+ 12 个新测试全过
- [ ] 2.8.3 跑 `./scripts/check_deps.sh` 确认 R1/R3/R4 不被破坏
- [ ] 2.8.4 commit message: `refactor(api): split 716-line token interceptor into refresh_queue + refresh_api + glue (bytecode-equivalent)`

## 3. PR-C-1a: Mason 砖块契约升级 (低风险,顺位第 3)

### 3.1 brick.yaml 新增 domainInterface 必填变量

- [ ] 3.1.1 在 `bricks/api/brick.yaml` 的 `vars:` 段新增 1 个 entry:
  ```yaml
  domainInterface:
    type: string
    description: 完整的 domain 接口名（含 I 前缀，如 IOrderRepository）
    prompt: 对应的 domain 接口名是什么？
  ```
- [ ] 3.1.2 确认无 default 值(必填,mason 留空会报错)
- [ ] 3.1.3 验证现有 4 个 var(name/baseUrl/hasModel/modelName)不受影响

### 3.2 repository impl 模板加 implements + 错误处理

- [ ] 3.2.1 在 `bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart` line 5 改为:
  ```dart
  class {{name.pascalCase()}}RepositoryImpl implements I{{name.pascalCase()}}Repository {
  ```
- [ ] 3.2.2 在 line 1 保留 `import 'package:domain/domain.dart';`
- [ ] 3.2.3 在 line 1 新增 `import 'package:api/api.dart';`(为 toDomainException)
- [ ] 3.2.4 把 line 16 / 25 / 35 / 44 的 `catch (e)` 拆为:
  ```dart
  } on DioException catch (e) {
    return Result.failure(toDomainException(e));
  } catch (e) {
    return Result.failure(UnknownException(e.toString()));
  }
  ```
- [ ] 3.2.5 验证 4 个 catch 块全部替换(grep `NetworkException(e.toString())` 在砖块中 0 匹配)
- [ ] 3.2.6 验证 5 个默认 CRUD 方法(getList/getById/create/update/delete)保留(业务沿用)

### 3.3 DI setup 模板改用接口注册

- [ ] 3.3.1 在 `bricks/api/__brick__/lib/src/di/setup.dart` line 12-14 改为:
  ```dart
  sl.registerFactory<I{{name.pascalCase()}}Repository>(
    () => {{name.pascalCase()}}RepositoryImpl(sl<{{name.pascalCase()}}Api>()),
  );
  ```
- [ ] 3.3.2 删除旧的 `sl.registerFactory<{{name.pascalCase()}}RepositoryImpl>(...)` 行
- [ ] 3.3.3 保留 `sl.registerLazySingleton<{{name.pascalCase()}}Api>(...)` 段(Dio 注入不变)

### 3.4 新建 bricks/api/README.md

- [ ] 3.4.1 新建 `bricks/api/README.md`(当前不存在,42 行)
- [ ] 3.4.2 文档化 5 个 var(name/baseUrl/hasModel/modelName/domainInterface)各自用途和示例
- [ ] 3.4.3 加 **WARNING** 章节:"mason 覆盖式写入,运行前请备份现有 feature 包"
- [ ] 3.4.4 给完整命令示例:`mason make api --name orders --baseUrl /Order --domainInterface IOrderRepository`
- [ ] 3.4.5 引用 AGENTS.md R3 / R8 硬规则说明 implements + toDomainException 的必要性

### 3.5 pubspec.yaml 模板保留 domain path dep

- [ ] 3.5.1 验证 `bricks/api/__brick__/pubspec.yaml` line 15-16 保留:
  ```yaml
  dependencies:
    domain:
      path: ../../domain
  ```
- [ ] 3.5.2 验证 line 18 `api: path: ../../api`(原 api 包)保留,toDomainException 依赖此 import

### 3.6 砖块验收测试

- [ ] 3.6.1 在临时目录跑 `mason make api --name orders --baseUrl /Order --domainInterface IOrderRepository`
- [ ] 3.6.2 检查生成 `lib/src/repository/orders_repository_impl.dart:5` 含 `implements IOrdersRepository`
- [ ] 3.6.3 检查 4 处 catch 块全部用 `toDomainException` + `UnknownException`(grep `e.toString()` 应仅 1 处,即 `UnknownException` 构造内)
- [ ] 3.6.4 检查 `lib/src/di/setup.dart` 注册键为 `IOrdersRepository`
- [ ] 3.6.5 跑 `mason make api --name orders --baseUrl /Order --domainInterface ""` 验证 mason 报错并 abort
- [ ] 3.6.6 删除临时测试目录

### 3.7 PR-C-1a 验证

- [ ] 3.7.1 验证 3 个已存在 feature 包(feature_home/feature_detail/feature_auth)**不需改动**(brick 模板升级只影响新生成)
- [ ] 3.7.2 跑 `melos analyze` 确认 0 error 0 新 warning
- [ ] 3.7.3 跑 `make scaffold-check` 验证脚手架健康
- [ ] 3.7.4 commit message: `feat(bricks/api): require domainInterface var, enforce implements + toDomainException + interface-based DI`

## 4. 跨 PR 验证 (全 PR 落地后跑)

- [ ] 4.1 跑全量 `melos analyze` 0 error 0 warning
- [ ] 4.2 跑全量 `melos test` 确认无回归
- [ ] 4.3 跑全量 `melos test:coverage` 确认覆盖率不下降(预期上升 ≥1% 因新增 12 个单测)
- [ ] 4.4 跑 `./scripts/check_deps.sh` 确认 R1/R3/R4 仍合规
- [ ] 4.5 跑 `./scripts/check_l10n.sh` 确认 ARB 一致
- [ ] 4.6 跑 3 套环境启动命令(`flutter run --dart-define=ENV=dev/staging/prod`),确认 0 启动崩溃
- [ ] 4.7 更新根 `CHANGELOG.md` 三条 entry(每 PR 一条)
- [ ] 4.8 更新 `openspec/changes/refactor-api-package/` 的 `proposal.md` 顶部加归档日期(本 change 走 archive 流程前)
- [ ] 4.9 跑 `openspec validate refactor-api-package --strict` 0 error(本任务的最后一步)
