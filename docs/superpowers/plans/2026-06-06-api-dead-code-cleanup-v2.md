# API 包死代码清理实施计划 v2 (Plan-1 Revised)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 删除 `packages/infrastructure/api` 包内**精确零引用**产物（已逐项验证，0 真实符号使用），同步清理 mason.yaml / makefile / api.dart barrel re-exports。

**Architecture:** v1 计划基于"文件名 grep"误判 5 个真在用文件为"零引用"（`http_constant.dart` / `http_event_bus.dart` / `app_logger.dart` / `token_supplier.dart` / `api_endpoints.dart`），v2 改用"符号使用 grep + 排除 barrel re-export"。每项删除前再过一遍 `grep` 二次确认。

**Tech Stack:** Dart 3.x, Flutter, Melos, Mason, make

---

## v2 vs v1 关键变更

| 类别 | v1 误判 | v2 真实 |
|---|---|---|
| `api_constants.dart` | ✅ 0 引用 | ✅ 0 引用(barrel 同步清) |
| `api_endpoints.dart` | ✅ 0 引用 | ❌ `ApiBase.tokenRenewal` 被 interceptor 真用,保留 |
| `http_constant.dart` | ✅ 0 引用 | ❌ interceptor + 2 测试真用,保留 |
| `http_event_bus.dart` | ✅ 0 引用 | ❌ interceptor 真用,保留 |
| `app_logger.dart` | ✅ 0 引用 | ❌ dio_factory + interceptor + 测试真用,保留 |
| `token_supplier.dart` | ✅ 0 引用 | ❌ dio_factory + 测试真用,保留 |
| 3 个 zero-call api 类 | ✅ 0 调用 | ✅ 0 调用(保留) |
| 3 个 dead DTO(login_request/response/sign_in_request/session_result/vehicle_data) | **未列** | ✅ 5 个 DTO × 3 文件 = 15 个文件死(因 spec 死) |
| `tracking/README.md` | ✅ 1 项 | ✅ + `tracking/` 整目录(README 是其唯一文件) |
| `error/README.md` | ✅ 1 项 | ✅ 保留(error/ 目录有真在用 dio_mapper.dart) |
| 2 死 spec.json | ✅ | ✅ 保留 |
| 2 死砖块 | ✅ | ✅ 保留 |
| `scripts/gen_api.dart` | ✅ | ✅ 保留 |
| `mason.yaml` 2 entry | ✅ | ✅ 保留 |
| `makefile` 3 target | ✅ | ✅ 升级到 6 target(gen-api-mason / gen-all-apis-mason / refresh-api-mason 也删) |
| **根 `pubspec.yaml` `mason:` 依赖** | ✅ 删 | ❌ 根 pubspec.yaml 实际**无** `mason:` 依赖(plan v1 误判,保留) |
| 5 个死 DTO × 3 文件 = 15 个 | 漏列 | ✅ 新增 |

---

## File Structure Map (v2 精确版)

```
删除（18 项,含目录）:
  packages/infrastructure/api/lib/src/constants/api_constants.dart                         # 10 行, 0 引用
  packages/infrastructure/component_library/lib/src/constants/api_constants.dart            # 16 行, 0 引用
  packages/infrastructure/api/lib/src/tracking/README.md                                    # 描述不存在的 RequestTracker
  packages/infrastructure/api/lib/src/tracking/                                             # 整目录(README 是其唯一文件)
  packages/infrastructure/api/lib/src/error/README.md                                       # orphan 文档
  packages/infrastructure/api/lib/src/api/auth_api.dart          + auth_api.g.dart
  packages/infrastructure/api/lib/src/api/session_api.dart       + session_api.g.dart
  packages/infrastructure/api/lib/src/api/vehicle_api.dart       + vehicle_api.g.dart
  packages/infrastructure/api/lib/src/models/login_request.dart         + .freezed.dart + .g.dart  # auth_api 死,对应 DTO 死
  packages/infrastructure/api/lib/src/models/login_response.dart        + .freezed.dart + .g.dart  # auth_api 死
  packages/infrastructure/api/lib/src/models/sign_in_request.dart       + .freezed.dart + .g.dart  # session_api 死
  packages/infrastructure/api/lib/src/models/session_result.dart         + .freezed.dart + .g.dart  # session_api 死
  packages/infrastructure/api/lib/src/models/vehicle_data.dart          + .freezed.dart + .g.dart  # vehicle_api 死
  packages/infrastructure/api/spec/auth.json                                             # 55 行
  packages/infrastructure/api/spec/session.json                                          # 32 行
  packages/infrastructure/api/spec/vehicle.json                                          # 33 行
  bricks/api_gen/                                                                          # 整目录
  bricks/api_gen_spec/                                                                     # 整目录
  scripts/gen_api.dart                                                                     # 232 行

修改（4 项）:
  packages/infrastructure/api/lib/api.dart                  # 删 line 19 (api_constants) + 24-26 (3 dead api) + 27-28 (login_*) + 32-34 (sign_in/session_result/vehicle_data) 共 9 行
  packages/infrastructure/component_library/lib/component_library.dart  # 删 line 7 (api_constants)
  mason.yaml                                                                       # 删 api_gen + api_gen_spec 2 段
  makefile                                                                         # 删 .PHONY 6 项 + 6 个 target (line 204-220, 232-248)

不改:
  packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart        # ApiBase.tokenRenewal 被 interceptor line 434-435 真用
  packages/infrastructure/api/lib/src/http/http_constant.dart              # interceptor + 2 测试真用
  packages/infrastructure/api/lib/src/http/http_event_bus.dart             # interceptor line 470 真用
  packages/infrastructure/api/lib/src/http/app_logger.dart                 # dio_factory + interceptor + 测试真用
  packages/infrastructure/api/lib/src/http/token_supplier.dart             # dio_factory + 测试真用
  packages/infrastructure/api/lib/src/error/                               # 目录保留(内有 dio_mapper.dart 真在用)
  根 pubspec.yaml                                                          # 无 mason: 依赖(plan v1 误判)

验证:
  melos analyze
  .githooks/pre-commit
  melos test:affected
  20 个 api 包测试仍全过
```

---

### Task 1: 删除 api_constants.dart + component_library api_constants.dart

**Files:**
- Delete: `packages/infrastructure/api/lib/src/constants/api_constants.dart` (10 lines)
- Delete: `packages/infrastructure/component_library/lib/src/constants/api_constants.dart` (16 lines)

- [ ] **Step 1: 二次确认零引用(符号 grep,排除 barrel re-export)**

```bash
grep -rn "\\bApiConstants\\b" packages/ --include="*.dart" 2>&1 | grep -v "lib/api\.dart" | grep -v "lib/component_library\.dart" | grep -v "lib/src/constants/api_constants\.dart"
grep -rn "api_constants\.dart" packages/ --include="*.dart" 2>&1 | grep -v "lib/api\.dart" | grep -v "lib/component_library\.dart"
```

**Expected output:** 0 匹配(无业务 import,无业务符号引用)。

- [ ] **Step 2: 删除 2 个文件**

```bash
git rm \
  packages/infrastructure/api/lib/src/constants/api_constants.dart \
  packages/infrastructure/component_library/lib/src/constants/api_constants.dart
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(api): remove 2 zero-reference api_constants.dart files"
```

---

### Task 2: 清理 api.dart + component_library.dart barrel exports

**Files:**
- Modify: `packages/infrastructure/api/lib/api.dart` (删 9 行)
- Modify: `packages/infrastructure/component_library/lib/component_library.dart` (删 1 行)

- [ ] **Step 1: api.dart 删 line 19 (api_constants export)**

```bash
sed -i.bak "/export 'src\/constants\/api_constants.dart';/d" packages/infrastructure/api/lib/api.dart
rm packages/infrastructure/api/lib/api.dart.bak
```

- [ ] **Step 2: api.dart 删 line 24-26 (3 dead api exports)**

```bash
sed -i.bak "/export 'src\/api\/auth_api.dart';/d" packages/infrastructure/api/lib/api.dart
sed -i.bak "/export 'src\/api\/session_api.dart';/d" packages/infrastructure/api/lib/api.dart
sed -i.bak "/export 'src\/api\/vehicle_api.dart';/d" packages/infrastructure/api/lib/api.dart
rm packages/infrastructure/api/lib/api.dart.bak
```

- [ ] **Step 3: api.dart 删 line 27-28 (login_request + login_response DTOs)**

```bash
sed -i.bak "/export 'src\/models\/login_request.dart';/d" packages/infrastructure/api/lib/api.dart
sed -i.bak "/export 'src\/models\/login_response.dart';/d" packages/infrastructure/api/lib/api.dart
rm packages/infrastructure/api/lib/api.dart.bak
```

- [ ] **Step 4: api.dart 删 line 32-34 (sign_in_request + session_result + vehicle_data DTOs)**

```bash
sed -i.bak "/export 'src\/models\/sign_in_request.dart';/d" packages/infrastructure/api/lib/api.dart
sed -i.bak "/export 'src\/models\/session_result.dart';/d" packages/infrastructure/api/lib/api.dart
sed -i.bak "/export 'src\/models\/vehicle_data.dart';/d" packages/infrastructure/api/lib/api.dart
rm packages/infrastructure/api/lib/api.dart.bak
```

- [ ] **Step 5: component_library.dart 删 line 7 (api_constants export)**

```bash
sed -i.bak "/export 'src\/constants\/api_constants.dart';/d" packages/infrastructure/component_library/lib/component_library.dart
rm packages/infrastructure/component_library/lib/component_library.dart.bak
```

- [ ] **Step 6: 验证 barrel 仍 export 全部 surviving 模块**

```bash
cat packages/infrastructure/api/lib/api.dart
echo "---"
cat packages/infrastructure/component_library/lib/component_library.dart
```

**Expected output:**
- api.dart: 仍 export `dio_factory` / `http_event_bus` / `http_constant` / `token_supplier` / `dio_mapper` / `cancel_manager` / `auto_cancel_interceptor` / `renewal_token_intercaptor` / `app_logger` / `endpoints/api_endpoints` / 4 个 surviving api(home/detail/user/...auth是死的不出现) + 4 个 surviving DTO(home_data/detail_data/user_profile/update_profile_request)
- component_library.dart: 仍 export theme/font_size/spacing + app_constants + cache_constants + 5 个 widgets

- [ ] **Step 7: 跑 melos analyze 确认 barrel 仍编译**

```bash
melos analyze 2>&1 | tail -10
```

**Expected output:** 0 error, 0 new warning。

- [ ] **Step 8: Commit**

```bash
git add packages/infrastructure/api/lib/api.dart packages/infrastructure/component_library/lib/component_library.dart
git commit -m "chore(api): prune dead exports from api.dart and component_library.dart barrels"
```

---

### Task 3: 删除 2 个 orphan README + tracking 整目录

**Files:**
- Delete: `packages/infrastructure/api/lib/src/tracking/README.md` (describes nonexistent `RequestTracker`)
- Delete: `packages/infrastructure/api/lib/src/tracking/` (entire dir)
- Delete: `packages/infrastructure/api/lib/src/error/README.md` (orphan doc, error/ dir kept due to dio_mapper.dart)

- [ ] **Step 1: 二次确认 RequestTracker 不存在**

```bash
grep -rn "\\bRequestTracker\\b" packages/ --include="*.dart" 2>&1
```

**Expected output:** 0 匹配(`RequestTracker` 类在仓库 0 实现,只有 README 描述)。

- [ ] **Step 2: 删除 tracking/ 整目录 + error/README.md**

```bash
git rm -rf packages/infrastructure/api/lib/src/tracking
git rm packages/infrastructure/api/lib/src/error/README.md
```

- [ ] **Step 3: 验证 error/ 目录仍存在(因 dio_mapper.dart)**

```bash
ls packages/infrastructure/api/lib/src/error/
```

**Expected output:** `dio_mapper.dart` 仍存在(error/ 目录保留,只 README 删了)。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(api): remove tracking/ dir (describes nonexistent RequestTracker) + error/README.md"
```

---

### Task 4: 删除 3 个 zero-call api 类 + 3 个 .g.dart

**Files:**
- Delete: `packages/infrastructure/api/lib/src/api/auth_api.dart` + `auth_api.g.dart`
- Delete: `packages/infrastructure/api/lib/src/api/session_api.dart` + `session_api.g.dart`
- Delete: `packages/infrastructure/api/lib/src/api/vehicle_api.dart` + `vehicle_api.g.dart`

- [ ] **Step 1: 二次确认 3 类零调用(排除自身 + barrel + .g.dart)**

```bash
for cls in AuthApi SessionApi VehicleApi; do
  echo "--- $cls ---"
  grep -rln "\\b${cls}\\b" packages/ --include="*.dart" 2>/dev/null \
    | grep -v "lib/src/api/${cls,,}.dart" \
    | grep -v "lib/api.dart" \
    | grep -v ".g.dart"
done
```

**Expected output:** 3 个 `---` 段后均 0 匹配(0 外部调用)。

- [ ] **Step 2: 删除 6 个文件**

```bash
git rm \
  packages/infrastructure/api/lib/src/api/auth_api.dart \
  packages/infrastructure/api/lib/src/api/auth_api.g.dart \
  packages/infrastructure/api/lib/src/api/session_api.dart \
  packages/infrastructure/api/lib/src/api/session_api.g.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.g.dart
```

- [ ] **Step 3: 验证 3 个 surviving api 仍存在**

```bash
ls packages/infrastructure/api/lib/src/api/
```

**Expected output:** `home_api.dart` + `.g.dart` + `detail_api.dart` + `.g.dart` + `user_api.dart` + `.g.dart`(3 对)。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(api): remove 3 zero-call api classes (auth/session/vehicle)"
```

---

### Task 5: 删除 5 个 dead DTO(因 spec 死)

**Files:**
- Delete: `packages/infrastructure/api/lib/src/models/login_request.dart` + `.freezed.dart` + `.g.dart`
- Delete: `packages/infrastructure/api/lib/src/models/login_response.dart` + `.freezed.dart` + `.g.dart`
- Delete: `packages/infrastructure/api/lib/src/models/sign_in_request.dart` + `.freezed.dart` + `.g.dart`
- Delete: `packages/infrastructure/api/lib/src/models/session_result.dart` + `.freezed.dart` + `.g.dart`
- Delete: `packages/infrastructure/api/lib/src/models/vehicle_data.dart` + `.freezed.dart` + `.g.dart`

- [ ] **Step 1: 二次确认 5 个 DTO 零使用**

```bash
for cls in LoginRequest LoginResponse SignInRequest SessionResult VehicleData; do
  echo "--- $cls ---"
  grep -rln "\\b${cls}\\b" packages/ --include="*.dart" 2>/dev/null \
    | grep -v "lib/src/models/${cls,}.dart" \
    | grep -v ".freezed.dart" \
    | grep -v ".g.dart" \
    | grep -v "lib/api.dart"
done
```

**Expected output:** 5 个 `---` 段后均 0 匹配。

- [ ] **Step 2: 删除 15 个文件(5 DTO × 3 文件)**

```bash
git rm \
  packages/infrastructure/api/lib/src/models/login_request.dart \
  packages/infrastructure/api/lib/src/models/login_request.freezed.dart \
  packages/infrastructure/api/lib/src/models/login_request.g.dart \
  packages/infrastructure/api/lib/src/models/login_response.dart \
  packages/infrastructure/api/lib/src/models/login_response.freezed.dart \
  packages/infrastructure/api/lib/src/models/login_response.g.dart \
  packages/infrastructure/api/lib/src/models/sign_in_request.dart \
  packages/infrastructure/api/lib/src/models/sign_in_request.freezed.dart \
  packages/infrastructure/api/lib/src/models/sign_in_request.g.dart \
  packages/infrastructure/api/lib/src/models/session_result.dart \
  packages/infrastructure/api/lib/src/models/session_result.freezed.dart \
  packages/infrastructure/api/lib/src/models/session_result.g.dart \
  packages/infrastructure/api/lib/src/models/vehicle_data.dart \
  packages/infrastructure/api/lib/src/models/vehicle_data.freezed.dart \
  packages/infrastructure/api/lib/src/models/vehicle_data.g.dart
```

- [ ] **Step 3: 验证 4 个 surviving DTO 仍存在**

```bash
ls packages/infrastructure/api/lib/src/models/
```

**Expected output:** `detail_data.dart` + `home_data.dart` + `update_profile_request.dart` + `user_profile.dart` + 各自 `.freezed.dart` + `.g.dart`(4 对 12 个文件)。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(api): remove 5 dead DTOs (login_request/response, sign_in_request, session_result, vehicle_data)"
```

---

### Task 6: 删除 3 个 dead spec.json

**Files:**
- Delete: `packages/infrastructure/api/spec/auth.json` (55 lines)
- Delete: `packages/infrastructure/api/spec/session.json` (32 lines)
- Delete: `packages/infrastructure/api/spec/vehicle.json` (33 lines)

- [ ] **Step 1: 二次确认 3 spec 零消费者(排除 mason 砖块目录,因 Task 7 删)**

```bash
grep -rln "spec/auth\.json\|spec/session\.json\|spec/vehicle\.json" . \
  --include="*.dart" --include="*.yaml" --include="Makefile" --include="makefile" 2>/dev/null \
  | grep -v "openspec/" \
  | grep -v "docs/superpowers/plans" \
  | grep -v "openspec/changes/archive" \
  | grep -v "bricks/api_gen_spec/"
```

**Expected output:** 0 匹配。

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

**Expected output:** `detail.json` / `home.json` / `user.json` 3 个 surviving。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(api): remove 3 dead spec files (auth/session/vehicle)"
```

---

### Task 7: 删除 2 个死砖块整目录

**Files:**
- Delete: `bricks/api_gen/` (entire directory)
- Delete: `bricks/api_gen_spec/` (entire directory)

- [ ] **Step 1: 验证 2 砖块零引用(注:会被 Task 9 mason.yaml + makefile 一并清,这里先确认仅 4 处引用)**

```bash
grep -rn "api_gen\|api_gen_spec" mason.yaml makefile 2>/dev/null | wc -l
```

**Expected output:** 4 行匹配(mason.yaml 2 段 + makefile 2 行)。

- [ ] **Step 2: 删除 2 个砖块目录**

```bash
git rm -rf bricks/api_gen/
git rm -rf bricks/api_gen_spec/
```

- [ ] **Step 3: 验证 4 个 surviving brick**

```bash
ls bricks/
```

**Expected output:** `feature/` / `api/` / `model/` / `hive_model/`。

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(bricks): remove 2 dead bricks (api_gen, api_gen_spec)"
```

---

### Task 8: 删除残废脚本

**Files:**
- Delete: `scripts/gen_api.dart` (232 lines)

- [ ] **Step 1: 二次确认 gen_api.dart 仅在 makefile(待清)引用**

```bash
grep -rn "gen_api\.dart" melos.yaml pubspec.yaml analysis_options.yaml .github/workflows/ scripts/ 2>/dev/null
```

**Expected output:** 0 匹配(仅 makefile 引用,Task 9 清)。

- [ ] **Step 2: 删除脚本**

```bash
git rm scripts/gen_api.dart
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(scripts): remove deprecated gen_api.dart (replaced by mason api brick)"
```

---

### Task 9: 清理 mason.yaml + makefile 引用

**Files:**
- Modify: `mason.yaml` (删 2 段,共 4 行)
- Modify: `makefile` (删 6 个 target + 6 个 .PHONY 列表项,共 12 行)

- [ ] **Step 1: mason.yaml 删 api_gen + api_gen_spec 2 段**

```bash
sed -i.bak '/^  api_gen:$/,/^  api_gen_spec:$/{/^  api_gen_spec:$/!d;}' mason.yaml
sed -i.bak '/^  api_gen_spec:$/,/^    path: bricks\/api_gen_spec$/{/^    path: bricks\/api_gen_spec$/!d;}' mason.yaml
rm mason.yaml.bak
```

> **更稳的写法**: 用 Edit 工具精准删除 2 段(L8-13),sed 链式易出错。改用 Read + Edit。

实际改用 Read + Edit:

```bash
# Read first
cat mason.yaml
```

**Expected output:** 13 行,L1 `bricks:`, L2-3 `feature:`, L4-5 `api:`, L6-7 `model:`, L8-9 `hive_model:`, L10-11 `api_gen:`, L12-13 `api_gen_spec:`。

Edit 删除 L10-13 这 4 行(保留 9 行)。

- [ ] **Step 2: 验证 mason.yaml 仍有 4 个 surviving brick**

```bash
cat mason.yaml
```

**Expected output:** 9 行,4 个 entry。

- [ ] **Step 3: 跑 mason list 验证砖块消失**

```bash
mason list 2>&1
```

**Expected output:** 4 个 brick(`feature` / `api` / `model` / `hive_model`),不再含 `api_gen` / `api_gen_spec`。

- [ ] **Step 4: makefile 删 6 个 gen-* 名称(从 .PHONY 列表)**

`.PHONY` 在 line 1,需要从 28 个目标列表中删除 6 项: `gen-api` / `gen-all-apis` / `refresh-api` / `gen-api-mason` / `gen-all-apis-mason` / `refresh-api-mason`。

```bash
# Read first
sed -n '1p' makefile
```

> **实际更稳**: 用 Edit 工具精准删除 L1 中的 6 个标识符(保留其他)。

- [ ] **Step 5: makefile 删 6 个 target 段**

- 删 `gen-api`(L204-208) + `gen-all-apis`(L210-216) + `refresh-api`(L218-220)
- 删 `gen-api-mason`(L232-236) + `gen-all-apis-mason`(L238-244) + `refresh-api-mason`(L246-248)

> 用 Edit 工具精准删除整段(避免行号漂移)。

- [ ] **Step 6: 验证 makefile help 仍可执行**

```bash
make help 2>&1 | tail -10
```

**Expected output:** 不再含 6 个 `gen-*` 命令,但其他命令(create-api / create-feature / scaffold-check 等)仍在。

- [ ] **Step 7: Commit**

```bash
git add mason.yaml makefile
git commit -m "chore: prune mason.yaml + makefile for removed bricks/scripts"
```

---

### Task 10: PR-B 整体验证 + push + PR

- [ ] **Step 1: 跑 melos analyze**

```bash
melos analyze 2>&1 | tail -10
```

**Expected output:** 0 error, 0 new warning。

- [ ] **Step 2: 跑 pre-commit 4 步**

```bash
bash .githooks/pre-commit 2>&1 | tail -10
```

**Expected output:** "✓ pre-commit 检查通过"。

- [ ] **Step 3: 跑 api 包测试,确认 20 个全过**

```bash
cd packages/infrastructure/api
flutter test 2>&1 | tail -10
```

**Expected output:** `All tests passed!` 20 个测试(与 baseline 持平)。

- [ ] **Step 4: 跑 melos test:affected 跨包测试**

```bash
cd ../../..
melos test:affected 2>&1 | tail -20
```

**Expected output:** 跨包测试全过(`services/auth` / `features/feature_home` / `features/feature_detail` 仍编译并测试通过)。

- [ ] **Step 5: 验证 18 项全部删除 + 4 项已修改**

```bash
for f in \
  packages/infrastructure/api/lib/src/constants/api_constants.dart \
  packages/infrastructure/component_library/lib/src/constants/api_constants.dart \
  packages/infrastructure/api/lib/src/tracking/README.md \
  packages/infrastructure/api/lib/src/tracking \
  packages/infrastructure/api/lib/src/error/README.md \
  packages/infrastructure/api/lib/src/api/auth_api.dart \
  packages/infrastructure/api/lib/src/api/auth_api.g.dart \
  packages/infrastructure/api/lib/src/api/session_api.dart \
  packages/infrastructure/api/lib/src/api/session_api.g.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.dart \
  packages/infrastructure/api/lib/src/api/vehicle_api.g.dart \
  packages/infrastructure/api/lib/src/models/login_request.dart \
  packages/infrastructure/api/lib/src/models/login_request.freezed.dart \
  packages/infrastructure/api/lib/src/models/login_request.g.dart \
  packages/infrastructure/api/lib/src/models/login_response.dart \
  packages/infrastructure/api/lib/src/models/login_response.freezed.dart \
  packages/infrastructure/api/lib/src/models/login_response.g.dart \
  packages/infrastructure/api/lib/src/models/sign_in_request.dart \
  packages/infrastructure/api/lib/src/models/sign_in_request.freezed.dart \
  packages/infrastructure/api/lib/src/models/sign_in_request.g.dart \
  packages/infrastructure/api/lib/src/models/session_result.dart \
  packages/infrastructure/api/lib/src/models/session_result.freezed.dart \
  packages/infrastructure/api/lib/src/models/session_result.g.dart \
  packages/infrastructure/api/lib/src/models/vehicle_data.dart \
  packages/infrastructure/api/lib/src/models/vehicle_data.freezed.dart \
  packages/infrastructure/api/lib/src/models/vehicle_data.g.dart \
  packages/infrastructure/api/spec/auth.json \
  packages/infrastructure/api/spec/session.json \
  packages/infrastructure/api/spec/vehicle.json \
  bricks/api_gen \
  bricks/api_gen_spec \
  scripts/gen_api.dart; do
  [ -e "$f" ] && echo "STILL EXISTS: $f" || echo "OK: $f"
done | grep -v "^OK:" || echo "All 32 deletion paths confirmed."
```

**Expected output:** "All 32 deletion paths confirmed."(无 `STILL EXISTS` 行)。

- [ ] **Step 6: git status 干净**

```bash
git status --short
```

**Expected output:** 空(全部已 commit)。

- [ ] **Step 7: 写 PR 描述 + push + 开 PR**

```bash
git push origin refactor/dead-code-cleanup
gh pr create \
  --title "chore(api): remove 18 zero-reference artifacts (precise audit)" \
  --body "见 openspec/changes/archive/2026-06-06-refactor-api-package/specs/dead-code-cleanup/spec.md + docs/superpowers/plans/2026-06-06-api-dead-code-cleanup-v2.md。零风险,0 公共 API 变更,0 DI 装配变更。"
```

---

## Self-Review

**Spec 覆盖度**:
- `Requirement: All deleted artifacts have zero external references` → Task 1-8 各自 Step 1 二次确认(用符号 grep 而非文件 grep)
- `Requirement: All deletion points are enumerated with their evidence` → File Structure Map 18 项 + Task 10 Step 5 验证
- `Requirement: No public API or DI assembly changes` → Task 1-8 仅删除,无公共 API 变更
- `Requirement: Verification commands pass after deletion` → Task 10 完整验证

**v1 → v2 修正说明**:
- 5 个文件从删除清单移除:`http_constant.dart` / `http_event_bus.dart` / `app_logger.dart` / `token_supplier.dart` / `api_endpoints.dart`(均被业务真用)
- 5 个 dead DTO × 3 文件 = 15 个文件新增到删除清单(因 spec 死)
- `tracking/` 整目录新增(README 是其唯一文件)
- `makefile` 删除 3 → 6 个 target(`gen-api-mason` 等 3 个也调死砖块)
- 根 `pubspec.yaml` 误判的 `mason:` 依赖删除(实际不存在)

**Placeholder 检查**: 无 `TBD` / `TODO` 出现。
