# API 包死代码清理实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 删除 `packages/infrastructure/api` 包内 19 项零引用产物（dart 文件 / spec.json / 死砖块 / 残废脚本 + 3 个 zero-call API 类），同步清理 mason.yaml / makefile / pubspec.yaml 中相关引用，确保 `melos analyze` + 4 步 pre-commit 零回归。

**Architecture:** 不引入新文件、不重命名、不改 DI 装配。每一项删除都基于已 grep 验证的"零外部引用"证据，按 `api 包内文件 → component_library 残留 → 死 api 类 → 死 spec → 死砖块 → 残废脚本 → 工具链引用清理 → 验证` 7 个阶段顺序执行。

**Tech Stack:** Dart 3.x, Flutter, Melos, Mason, make, ripgrep

---

## File Structure Map

```
删除（19 项）:
  packages/infrastructure/api/lib/src/constants/api_constants.dart           # 10 行, 0 外部 import
  packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart          # 82 行, 0 外部 import
  packages/infrastructure/api/lib/src/http/http_constant.dart                # 53 行, 0 外部 import
  packages/infrastructure/api/lib/src/http/http_event_bus.dart               # 37 行, 0 外部 import
  packages/infrastructure/api/lib/src/http/app_logger.dart                  # 63 行, 0 外部 import
  packages/infrastructure/api/lib/src/http/token_supplier.dart              # 15 行, 0 外部 import
  packages/infrastructure/api/lib/src/tracking/README.md                    # 描述不存在的 RequestTracker
  packages/infrastructure/api/lib/src/error/README.md                       # orphan 文档
  packages/infrastructure/component_library/lib/src/constants/api_constants.dart  # 16 行, 0 外部 import
  packages/infrastructure/api/lib/src/api/auth_api.dart          + auth_api.g.dart
  packages/infrastructure/api/lib/src/api/session_api.dart       + session_api.g.dart
  packages/infrastructure/api/lib/src/api/vehicle_api.dart       + vehicle_api.g.dart
  packages/infrastructure/api/spec/auth.json                                # 55 行, 死 spec
  packages/infrastructure/api/spec/session.json                             # 32 行, 死 spec
  packages/infrastructure/api/spec/vehicle.json                             # 33 行, 死 spec
  bricks/api_gen/                                                          # 整目录
  bricks/api_gen_spec/                                                     # 整目录
  scripts/gen_api.dart                                                     # 232 行残废脚本

修改（4 项）:
  mason.yaml                                  # 删 api_gen + api_gen_spec 两段
  makefile                                    # 删 gen-api/gen-all-apis/refresh-api 三个 target
  pubspec.yaml (根)                           # 删 mason: 依赖（前提: 仅被这 2 个砖块使用）
  packages/infrastructure/api/lib/api.dart    # 删 3 个 dead api 的 export（line 11-13）

验证:
  melos analyze
  .githooks/pre-commit
  melos test:affected
```

---

### Task 1: 删除 api 包内 6 个零引用 dart 文件

**Files:**
- Delete: `packages/infrastructure/api/lib/src/constants/api_constants.dart` (10 lines)
- Delete: `packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart` (82 lines)
- Delete: `packages/infrastructure/api/lib/src/http/http_constant.dart` (53 lines)
- Delete: `packages/infrastructure/api/lib/src/http/http_event_bus.dart` (37 lines)
- Delete: `packages/infrastructure/api/lib/src/http/app_logger.dart` (63 lines)
- Delete: `packages/infrastructure/api/lib/src/http/token_supplier.dart` (15 lines)

- [ ] **Step 1: 验证零引用 (grep 全部 6 个文件)**

```bash
rg -l "api_constants\.dart|api_endpoints\.dart|http_constant\.dart|http_event_bus\.dart|app_logger\.dart|token_supplier\.dart" \
   packages/ --type dart
```

**Expected output:** 空（无匹配），或仅匹配 `packages/infrastructure/api/lib/api.dart`（barrel re-export 在 PR-B 后续 Task 5.1 处理）。

- [ ] **Step 2: 删除 6 个文件**

```bash
git rm \
  packages/infrastructure/api/lib/src/constants/api_constants.dart \
  packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart \
  packages/infrastructure/api/lib/src/http/http_constant.dart \
  packages/infrastructure/api/lib/src/http/http_event_bus.dart \
  packages/infrastructure/api/lib/src/http/app_logger.dart \
  packages/infrastructure/api/lib/src/http/token_supplier.dart
```

- [ ] **Step 3: 验证 pubspec 是否需要清理 `event_bus` 依赖**

```bash
rg "package:event_bus" packages/ --type dart
```

**Expected output:** 仅匹配 `packages/services/auth/lib/src/...`（auth 包自用），`packages/infrastructure/api/` 下 0 匹配 → api 包 pubspec.yaml 已有 `event_bus` 依赖即可保留（不影响）。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(api): remove 6 zero-reference dart files in infrastructure/api"
```

---

### Task 2: 删除 2 个 orphan README

**Files:**
- Delete: `packages/infrastructure/api/lib/src/tracking/README.md`
- Delete: `packages/infrastructure/api/lib/src/error/README.md`

- [ ] **Step 1: 验证零引用**

```bash
rg -l "RequestTracker" packages/ --type dart
```

**Expected output:** 空（全仓 0 匹配 `RequestTracker` 类，跟 `tracking/README.md` 描述的存在性矛盾）。

- [ ] **Step 2: 删除 2 个 README**

```bash
git rm \
  packages/infrastructure/api/lib/src/tracking/README.md \
  packages/infrastructure/api/lib/src/error/README.md
```

- [ ] **Step 3: 验证 lib/src/ 下残留**

```bash
ls packages/infrastructure/api/lib/src/tracking/ packages/infrastructure/api/lib/src/error/ 2>&1
```

**Expected output:** `tracking/` 和 `error/` 目录仍存在但内容为空（dio_mapper.dart 还在 error/ 下，README 是孤儿；tracking/ 下 README 删后目录空）。空目录需保留以便 git 跟踪，或者一并 `rmdir`。

- [ ] **Step 4: 删除空目录（如存在）**

```bash
rmdir packages/infrastructure/api/lib/src/tracking 2>/dev/null || true
```

- [ ] **Step 5: Commit**

```bash
git commit -m "chore(api): remove 2 orphan READMEs in tracking/ and error/"
```

---

### Task 3: 删除 component_library 内 1 个零引用文件

**Files:**
- Delete: `packages/infrastructure/component_library/lib/src/constants/api_constants.dart` (16 lines)

- [ ] **Step 1: 验证零引用**

```bash
rg -l "packages/infrastructure/component_library/lib/src/constants/api_constants\.dart" \
   packages/ --type dart
```

**Expected output:** 仅匹配该文件本身 + `component_library.dart` barrel。

- [ ] **Step 2: 删除文件**

```bash
git rm packages/infrastructure/component_library/lib/src/constants/api_constants.dart
```

- [ ] **Step 3: 验证 component_library.dart barrel 仍编译**

```bash
melos analyze 2>&1 | head -20
```

**Expected output:** 0 error（barrel re-export 该文件的 line 同步清理在 Task 5.2 处理；若此处有 error 说明 barrel 仍在 export 该文件，跳到 Task 5.2 提前处理）。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(component_library): remove zero-reference api_constants.dart"
```

---

### Task 4: 删除 3 个零调用 api 类

**Files:**
- Delete: `packages/infrastructure/api/lib/src/api/auth_api.dart` + `auth_api.g.dart`
- Delete: `packages/infrastructure/api/lib/src/api/session_api.dart` + `session_api.g.dart`
- Delete: `packages/infrastructure/api/lib/src/api/vehicle_api.dart` + `vehicle_api.g.dart`

- [ ] **Step 1: 验证 3 个 api 类零外部调用**

```bash
rg -w "AuthApi|SessionApi|VehicleApi" packages/ --type dart \
   --glob '!packages/infrastructure/api/lib/src/api/**' \
   --glob '!packages/infrastructure/api/lib/api.dart'
```

**Expected output:** 0 匹配（`--glob '!api.dart'` 排除 barrel；`--glob '!lib/src/api/**'` 排除自身定义）。

- [ ] **Step 2: 删除 6 个文件（3 个手写 + 3 个 .g.dart 生成）**

```bash
git rm \
  packages/infrastructure/api/lib/src/api/auth_api.dart \
  packages/infrastructure/api/lib/src/api/auth_api.g.dart \
  packages/infrastructure/api/lib/src/api/session_api.dart \
  packages/infrastructure/api/lib/src/api/session_api.g.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.g.dart
```

- [ ] **Step 3: 验证 3 个 surviving api 仍可发现**

```bash
ls packages/infrastructure/api/lib/src/api/
```

**Expected output:** `home_api.dart` + `home_api.g.dart` + `detail_api.dart` + `detail_api.g.dart` + `user_api.dart` + `user_api.g.dart`（6 个 surviving 文件，3 对 dart+g.dart）。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(api): remove 3 zero-call api classes (auth/session/vehicle)"
```

---

### Task 5: 清理 api.dart barrel re-exports

**Files:**
- Modify: `packages/infrastructure/api/lib/api.dart` (line 11-13 删 3 个 export, line 16-24 删 9 个 DTO export 中的 3 个)

- [ ] **Step 1: 读 api.dart 当前内容**

```bash
cat packages/infrastructure/api/lib/api.dart
```

**Expected output:** 36 行 barrel，包含 3 个 dead api 类的 export（auth_api/session_api/vehicle_api）+ 9 个 DTO 的 export。

- [ ] **Step 2: 删除 3 个 dead api 的 export**

```dart
// 在 packages/infrastructure/api/lib/api.dart 中:
- export 'src/api/auth_api.dart';
- export 'src/api/session_api.dart';
- export 'src/api/vehicle_api.dart';
```

- [ ] **Step 3: 删除 3 个死 DTO 类型的 export（如果存在）**

```bash
rg "LoginRequest|LoginResponse|SignInRequest|SessionResult|VehicleData" packages/infrastructure/api/lib/api.dart
```

**Expected output:** 如果 barrel 当前 export 了 `auth_request.dart` / `auth_response.dart` / `session_result.dart` / `vehicle_data.dart` 等死 DTO 文件，删除对应 export 行（每行格式 `export 'src/models/<name>.dart';`）。

- [ ] **Step 4: 验证 api.dart 仍 export 6 个 surviving api + surviving DTO**

```bash
cat packages/infrastructure/api/lib/api.dart
```

**Expected output:** 仅 export `home_api.dart` / `detail_api.dart` / `user_api.dart`（3 个 api）+ surviving DTOs（按 spec 实际定义保留）。

- [ ] **Step 5: Commit**

```bash
git commit -m "chore(api): prune dead exports from api.dart barrel"
```

---

### Task 6: 删除 3 个对应 spec.json

**Files:**
- Delete: `packages/infrastructure/api/spec/auth.json` (55 lines)
- Delete: `packages/infrastructure/api/spec/session.json` (32 lines)
- Delete: `packages/infrastructure/api/spec/vehicle.json` (33 lines)

- [ ] **Step 1: 验证 3 个 spec 零消费者**

```bash
rg -l "spec/auth\.json|spec/session\.json|spec/vehicle\.json" \
   . --glob '!openspec/**' --glob '!docs/**' --glob '!openspec/changes/archive/**'
```

**Expected output:** 0 匹配（spec 文件历史上仅被 `scripts/gen_api.dart` 读取，gen_api 在 Task 8 删除）。

- [ ] **Step 2: 删除 3 个 spec 文件**

```bash
git rm \
  packages/infrastructure/api/spec/auth.json \
  packages/infrastructure/api/spec/session.json \
  packages/infrastructure/api/spec/vehicle.json
```

- [ ] **Step 3: 验证 spec/ 目录残留**

```bash
ls packages/infrastructure/api/spec/
```

**Expected output:** 仅 `detail.json` / `home.json` / `user.json`（3 个 surviving spec，对应 3 个被实际调用的 api 类）。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(api): remove 3 dead spec files (auth/session/vehicle)"
```

---

### Task 7: 删除 2 个死砖块整目录

**Files:**
- Delete: `bricks/api_gen/` (entire directory)
- Delete: `bricks/api_gen_spec/` (entire directory)

- [ ] **Step 1: 验证 2 个砖块零引用**

```bash
rg "api_gen|api_gen_spec" makefile melos.yaml pubspec.yaml analysis_options.yaml .github/workflows/ 2>&1
```

**Expected output:** 0 匹配（mason.yaml 引用在 Task 9.1 清理）。

- [ ] **Step 2: 读 mason.yaml 当前内容**

```bash
cat mason.yaml
```

**Expected output:** 13 行，6 个 brick entry。

- [ ] **Step 3: 删除 2 个砖块目录（不在 git 跟踪时用 rm -rf）**

```bash
git rm -r bricks/api_gen/ 2>/dev/null || rm -rf bricks/api_gen/
git rm -r bricks/api_gen_spec/ 2>/dev/null || rm -rf bricks/api_gen_spec/
```

- [ ] **Step 4: 验证 4 个 surviving brick**

```bash
ls bricks/
```

**Expected output:** `feature/` / `api/` / `model/` / `hive_model/`（4 个目录，2 个死砖块已删）。

- [ ] **Step 5: Commit**

```bash
git commit -m "chore(bricks): remove 2 dead bricks (api_gen, api_gen_spec)"
```

---

### Task 8: 删除残废脚本

**Files:**
- Delete: `scripts/gen_api.dart` (232 lines)

- [ ] **Step 1: 验证 gen_api.dart 仅由 makefile 引用（makefile 引用在 Task 9.2 删）**

```bash
rg "gen_api\.dart" melos.yaml pubspec.yaml analysis_options.yaml .github/workflows/ scripts/ 2>&1
```

**Expected output:** 0 匹配（仅 makefile 引用，Task 9.2 处理）。

- [ ] **Step 2: 删除脚本**

```bash
git rm scripts/gen_api.dart
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(scripts): remove deprecated gen_api.dart (replaced by mason api brick)"
```

---

### Task 9: 清理 mason.yaml / makefile / pubspec.yaml 引用

**Files:**
- Modify: `mason.yaml` (删 2 个 entry)
- Modify: `makefile` (删 3 个 target + 注释)
- Modify: `pubspec.yaml` 根 (删 `mason:` 依赖)

- [ ] **Step 1: 验证 `mason:` 依赖仅被这 2 个砖块使用**

```bash
rg "mason:" pubspec.yaml
rg "mason:" . --glob '!openspec/**' --glob '!docs/**' --glob '!bricks/**' --glob '!pubspec.yaml' --glob '!pubspec_overrides.yaml' 2>&1
```

**Expected output:** 第一行匹配根 `pubspec.yaml`，第二行（项目其它位置）0 匹配 → 可安全删。

- [ ] **Step 2: 修改 mason.yaml（删 2 个 entry）**

```yaml
# 在 mason.yaml 中:
  api_gen:
    path: bricks/api_gen
  api_gen_spec:
    path: bricks/api_gen_spec
```

删除这 2 段（共 4 行），保留 `feature` / `api` / `model` / `hive_model` 4 个 entry。

- [ ] **Step 3: 修改 makefile（删 3 个 target）**

读 makefile line 195-230 区域，删除以下 target（及其依赖注释）:

```makefile
# 在 makefile 中删除:
gen-api:
	@echo "🚧 API 代码生成已迁移到 Mason 砖块，请使用 'make create-api name=xxx baseUrl=yyy'"

gen-all-apis:
	@echo "🚧 批量生成已迁移到 Mason 砖块，请使用 'make create-api' 逐个生成"

refresh-api:
	@echo "🚧 刷新已迁移到 Mason 砖块，请使用 'make create-api' 重新生成"
```

（注：实际 makefile 内容可能与示例略有差异，按 `rg -n 'gen-api|gen-all-apis|refresh-api' makefile` 找到的真实行号精准删除）

- [ ] **Step 4: 修改根 pubspec.yaml（删 mason 依赖）**

```yaml
# 在 pubspec.yaml 根 dependencies 段:
- mason: ^0.1.0  # 实际版本按 pubspec.yaml 现状
```

整行删除。

- [ ] **Step 5: 重新解析依赖**

```bash
melos bootstrap 2>&1 | tail -20
```

**Expected output:** "Resolving dependencies" 成功，无 `mason` 引用警告。

- [ ] **Step 6: 验证 mason 命令仍可用（4 个 surviving brick）**

```bash
mason list 2>&1
```

**Expected output:** 显示 `feature` / `api` / `model` / `hive_model` 4 个 brick（不再含 `api_gen` / `api_gen_spec`）。

- [ ] **Step 7: Commit**

```bash
git add mason.yaml makefile pubspec.yaml
git commit -m "chore: prune mason.yaml/makefile/pubspec.yaml for removed bricks"
```

---

### Task 10: PR-B 整体验证

- [ ] **Step 1: 跑 melos analyze**

```bash
melos analyze 2>&1 | tail -30
```

**Expected output:** 0 error, 0 new warning（与删除前 baseline 对比）。

- [ ] **Step 2: 跑 pre-commit 4 步**

```bash
bash .githooks/pre-commit 2>&1 | tail -10
```

**Expected output:** "✓ pre-commit 检查通过"（4 步全过：check_deps.sh → check_l10n.sh → flutter analyze → melos test:affected）。

- [ ] **Step 3: 跑 melos test:affected**

```bash
melos test:affected 2>&1 | tail -20
```

**Expected output:** 所有受影响包测试数与删除前一致（`packages/infrastructure/api` 仍 15 个测试，3 个 component 包测试不变）。

- [ ] **Step 4: 验证 19 项全部删除**

```bash
for f in \
  packages/infrastructure/api/lib/src/constants/api_constants.dart \
  packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart \
  packages/infrastructure/api/lib/src/http/http_constant.dart \
  packages/infrastructure/api/lib/src/http/http_event_bus.dart \
  packages/infrastructure/api/lib/src/http/app_logger.dart \
  packages/infrastructure/api/lib/src/http/token_supplier.dart \
  packages/infrastructure/api/lib/src/tracking/README.md \
  packages/infrastructure/api/lib/src/error/README.md \
  packages/infrastructure/component_library/lib/src/constants/api_constants.dart \
  packages/infrastructure/api/lib/src/api/auth_api.dart \
  packages/infrastructure/api/lib/src/api/auth_api.g.dart \
  packages/infrastructure/api/lib/src/api/session_api.dart \
  packages/infrastructure/api/lib/src/api/session_api.g.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.g.dart \
  packages/infrastructure/api/spec/auth.json \
  packages/infrastructure/api/spec/session.json \
  packages/infrastructure/api/spec/vehicle.json \
  bricks/api_gen/ \
  bricks/api_gen_spec/ \
  scripts/gen_api.dart; do
  [ -e "$f" ] && echo "STILL EXISTS: $f" || echo "OK: $f"
done | grep -v "^OK:" || echo "All 19 items deleted."
```

**Expected output:** "All 19 items deleted."（无 `STILL EXISTS` 行）。

- [ ] **Step 5: git status 干净**

```bash
git status --short
```

**Expected output:** 空（已 commit 全部变更）。

- [ ] **Step 6: 写 PR 描述 + 开 PR**

```bash
git push origin chore/api-dead-code-cleanup
gh pr create \
  --title "chore(api): remove 19 dead artifacts (zero external references)" \
  --body "见 openspec/changes/archive/2026-06-06-refactor-api-package/specs/dead-code-cleanup/spec.md 与 docs/superpowers/plans/2026-06-06-api-dead-code-cleanup.md。零风险，0 公共 API 变更，0 DI 装配变更。"
```

---

## Self-Review

**Spec 覆盖度**:
- `Requirement: All deleted artifacts have zero external references` → Task 1-8 各自 Step 1 验证
- `Requirement: All deletion points are enumerated with their evidence` → File Structure Map 列出 19 项 + Task 10 Step 4 复核
- `Requirement: No public API or DI assembly changes` → Task 1-8 仅 `git rm` 不修改代码
- `Requirement: Verification commands pass after deletion` → Task 10 完整验证

**Placeholder 检查**: 无 `TBD` / `TODO` / `实现细节` 出现。

**类型一致性**: 不涉及类型定义（纯删除），无 mismatch 风险。
