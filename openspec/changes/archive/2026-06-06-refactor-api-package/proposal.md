## Why

`packages/infrastructure/api` 当前评分 5.0/10，存在 3 类问题：(1) 19 项零引用死文件/死砖块/死脚本污染仓库，干扰 review；(2) `renewal_token_intercaptor.dart` 716 行单文件，职责混杂导致无法单测；(3) 砖块 `bricks/api` 生成的 repository 不 `implements` 任何 domain 接口，且 catch 块用 `e.toString()` 拼字符串，破坏 AGENTS.md R3/R8 硬规则（infrastructure 不应注册为 services key；错误应走 DomainException 而非字符串）。任一项都会随脚手架传播给下游所有项目。

注意：原分析中提到的"3 个 repository impl 缺接口契约"是误判——经核实 `feature_home`/`feature_detail`/`services/auth` 3 个 impl 均已 `implements` 对应 domain 接口（见 `home_repository_impl.dart:6` / `detail_repository_impl.dart:6` / `user_repository_impl.dart:10`），且 `user_repository_impl._mapError` 反而比 `toDomainException` 更精确（处理 422 fieldErrors），不应回退。该 capability 已删除。

## What Changes

- **PR-B（无风险）**：删除 19 项零引用文件/砖块/脚本（详见 `specs/dead-code-cleanup/spec.md`）
- **PR-A（低风险，5 条不动约束 + 4 条可验证约束）**：把 716 行单文件拆成 3 个职责清晰的小文件 + 合并 2 个 90% 重复的排空方法 + 修 1 个字节码等价的命名错误 + 新增 ≥12 个单测（详见 `specs/token-refresh-modularization/spec.md`）
- **PR-C-1a（低风险）**：砖块 `bricks/api` 新增 `domainInterface` 必填变量，强制生成代码 `implements` domain 接口 + 修 4 处 `e.toString()` 错误处理（用 `toDomainException`）+ di 注册键从 impl 类改为 domain 接口（详见 `specs/mason-brick-contract/spec.md`）

**BREAKING**：无。所有改动要么是删除（无下游引用），要么是同包内文件拆分（import 路径不变，DI 装配不变），要么是砖块模板升级（只影响 `make create-api` 新生成代码，不影响已存在的 feature 包）。

## Capabilities

### New Capabilities
- `dead-code-cleanup`: 删除 19 项零引用文件/砖块/脚本
- `token-refresh-modularization`: 拆分 716 行 token interceptor + 合并 boilerplate + 修 1 等价 bug + 新增单测
- `mason-brick-contract`: 砖块 `bricks/api` 强制生成代码 `implements` domain 接口 + 改用 `toDomainException` + di 注册键改用接口

### Modified Capabilities
- 无现有 spec 被修改

## Impact

**新增代码**（PR-A）：
- `packages/infrastructure/api/lib/src/refresh/refresh_queue.dart`（≤120 行）
- `packages/infrastructure/api/lib/src/refresh/refresh_api.dart`（≤250 行）
- `packages/infrastructure/api/test/refresh/refresh_queue_test.dart`（≥6 用例）
- `packages/infrastructure/api/test/refresh/refresh_api_test.dart`（≥6 用例）

**修改代码**：
- `packages/infrastructure/api/lib/src/dio/renewal_token_intercaptor.dart`（PR-A，716 → ~200 行主胶水）
- `packages/infrastructure/api/lib/src/dio/dio_factory.dart`（PR-A，import 路径不变）
- `bricks/api/brick.yaml`（PR-C-1a，新增 `domainInterface` var）
- `bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart`（PR-C-1a，加 `implements`、改用 `toDomainException`）
- `bricks/api/__brick__/lib/src/di/setup.dart`（PR-C-1a，改用接口注册）
- `bricks/api/README.md`（PR-C-1a，文档化新 var，**当前不存在需新建**）

**删除代码**（PR-B，全部零外部引用，详见 `specs/dead-code-cleanup/spec.md` 的 19 项清单）：
- 9 个零引用 dart 文件（api 包 6 个 + component_library 1 个 + 2 个 README）
- 3 个零调用 api + 3 个对应 .g.dart
- 3 个对应 spec.json（auth/session/vehicle）
- 2 个死砖块（api_gen/api_gen_spec 整目录）
- 1 个残废脚本（gen_api.dart）
- makefile 中 3 个 target + mason.yaml 中 2 行注册
- pubspec.yaml 根 `mason:` 依赖（需先确认仅被这 2 个砖块使用）

**依赖变化**：
- PR-A：`synchronized` 保留；`event_bus` 移除（`http_event_bus.dart` 是其在 api 包的唯一下游，PR-B 删除该文件后 api 包不再依赖 `event_bus`，根 pubspec 是否清理视其他包而定）
- PR-C-1a：无新依赖
- 无破坏性 API 变更；无破坏性 DI 装配变更
