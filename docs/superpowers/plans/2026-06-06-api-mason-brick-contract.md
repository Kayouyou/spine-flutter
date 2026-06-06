# Mason API 砖块契约升级实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 升级 `bricks/api` Mason 砖块契约：新增 `domainInterface` 必填变量强制生成代码 `implements` domain 接口，把 4 处 `e.toString()` 错误处理替换为项目标准 `toDomainException(e)`，DI 注册键从 impl 类改为 domain 接口，新建 `bricks/api/README.md` 文档化新变量。

**Architecture:** brick.yaml 加 1 个 var 即可让 mason 强制要求输入。模板文件用 mustache 语法替换类声明 + 错误处理 + DI 键。pubspec.yaml 新增 `api: path: ../../api` 依赖以便 import `toDomainException`。验收通过在临时目录跑 `mason make api` 试生成 + 编译检查。

**Tech Stack:** Dart 3.x, mason (mason_make), mustache 模板

---

## File Structure Map

```
修改:
  bricks/api/brick.yaml                                       # 加 domainInterface 必填变量
  bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart  # 加 implements + 改 4 处 catch
  bricks/api/__brick__/lib/src/di/setup.dart                  # 注册键改接口
  bricks/api/__brick__/pubspec.yaml                           # 加 api 依赖

新建:
  bricks/api/README.md                                        # 文档化 5 个 var + WARNING

不改（已存在 feature 包不重生成）:
  packages/features/feature_home/lib/src/repository/home_repository_impl.dart
  packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart
  packages/services/auth/lib/src/repository/user_repository_impl.dart
```

---

### Task 1: 在 brick.yaml 新增 `domainInterface` 必填变量

**Files:**
- Modify: `bricks/api/brick.yaml` (line 4-21 vars 段新增 1 个 entry)

- [ ] **Step 1: 读 brick.yaml 当前内容**

```bash
cat bricks/api/brick.yaml
```

**Expected output:** 22 行，vars 段含 name / baseUrl / hasModel / modelName 4 个 entry。

- [ ] **Step 2: 在 vars 段末尾追加 domainInterface**

`bricks/api/brick.yaml` 修改:

```yaml
# 在 line 21 后追加:
  modelName:
    type: string
    description: 绑定的数据模型名称
    prompt: ""
    default: "dynamic"
  domainInterface:                                              # ← 新增
    type: string                                                 # ← 新增
    description: 完整的 domain 接口名（含 I 前缀，如 IOrderRepository）  # ← 新增
    prompt: 对应的 domain 接口名是什么？                          # ← 新增
    # 注意: 无 default, 无 default_value — 必填, mason 留空时报错
```

> **注意**: 不设 `default:`，让 mason 在 prompt 时强校验非空。如果用户按回车跳过, mason 抛 `Missing required variable: domainInterface`。

- [ ] **Step 3: 验证 yaml 格式**

```bash
dart -e "import 'dart:io' as io; import 'package:yaml/yaml.dart'; void main() { final f = io.File('bricks/api/brick.yaml').readAsStringSync(); final doc = loadYaml(f); print('vars: ${(doc['vars'] as Map).keys.toList()}'); }" 2>&1 || \
python3 -c "import yaml; doc = yaml.safe_load(open('bricks/api/brick.yaml').read()); print('vars:', list(doc['vars'].keys()))"
```

**Expected output:** `vars: ['name', 'baseUrl', 'hasModel', 'modelName', 'domainInterface']`。

- [ ] **Step 4: Commit**

```bash
git add bricks/api/brick.yaml
git commit -m "feat(bricks/api): add required domainInterface var"
```

---

### Task 2: 修改 repository impl 模板（加 implements + 改 4 处 catch）

**Files:**
- Modify: `bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart`

- [ ] **Step 1: 完整重写文件**

`bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart`（替换原 48 行）:

```mustache
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:dio/dio.dart';
import '../api/{{name}}_api.dart';

/// {{name.pascalCase()}} 数据仓储实现
///
/// 契约: 必须实现 domain 层的 `{{domainInterface}}` 接口
/// 错误处理: 使用项目标准 toDomainException 映射 DioException → DomainException
class {{name.pascalCase()}}RepositoryImpl implements {{domainInterface}} {
  final {{name.pascalCase()}}Api _api;

  {{name.pascalCase()}}RepositoryImpl(this._api);

{{#hasModel}}
  @override
  Future<Result<List<{{modelName.pascalCase()}}>, DomainException>> getList() async {
    try {
      final response = await _api.getList();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<{{modelName.pascalCase()}}, DomainException>> getById(String id) async {
    try {
      final response = await _api.getById(id);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }
{{/hasModel}}
{{^hasModel}}
  @override
  Future<Result<List<dynamic>, DomainException>> getList() async {
    try {
      final response = await _api.getList();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getById(String id) async {
    try {
      final response = await _api.getById(id);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }
{{/hasModel}}
}
```

**关键变更**:
- line 1: 新增 `import 'package:api/api.dart';` (为 toDomainException)
- line 5: `class {{name.pascalCase()}}RepositoryImpl` → `class {{name.pascalCase()}}RepositoryImpl implements {{domainInterface}}`
- line 11/20/30/39: 5 个方法加 `@override` 注解
- line 16/25/35/44: `catch (e) { return Result.failure(NetworkException(e.toString())); }` → 拆为 `on DioException catch (e) { return Result.failure(toDomainException(e)); } catch (e) { return Result.failure(UnknownException(e.toString())); }`

- [ ] **Step 2: 验证 4 处 e.toString() 替换为 toDomainException**

```bash
rg "NetworkException\(e\.toString\(\)\)" bricks/api/__brick__/
```

**Expected output:** 0 匹配（4 处全部替换为 `on DioException catch` + `toDomainException(e)`）。

- [ ] **Step 3: 验证 5 个 `@override` 注解就位**

```bash
rg -c "@override" bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart
```

**Expected output:** `5`（getList + getById + 2 个 create/update 之类，按模板实际方法数 + baseClass 计数 — 5 是预期值因为 2 个 main method + future 可能 3 个 CRUD methods）。

> **注意**: 如果模板未来扩展 CRUD 方法数, `implements {{domainInterface}}` 强制接口一致, 编译期会发现缺方法。

- [ ] **Step 4: Commit**

```bash
git add bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart
git commit -m "feat(bricks/api): enforce implements domainInterface + use toDomainException"
```

---

### Task 3: 修改 setup.dart 模板（DI 注册键改接口）

**Files:**
- Modify: `bricks/api/__brick__/lib/src/di/setup.dart`

- [ ] **Step 1: 完整重写文件**

`bricks/api/__brick__/lib/src/di/setup.dart`（替换原 15 行）:

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../api/{{name}}_api.dart';
import '../repository/{{name}}_repository_impl.dart';

/// 注册 {{name.pascalCase()}} API 模块
///
/// 注册键是 domain 接口 `{{domainInterface}}`（不是 impl 类）
/// 下游 feature 包通过 `sl<{{domainInterface}}>()` 获取实例
/// 满足 AGENTS.md R3: services 依赖 domain 接口, 不依赖 impl
void setupApi{{name.pascalCase()}}(GetIt sl, String baseUrl) {
  sl.registerFactory<{{name.pascalCase()}}Api>(
    () => {{name.pascalCase()}}Api(sl<Dio>(), baseUrl: baseUrl),
  );

  sl.registerFactory<{{domainInterface}}>(
    () => {{name.pascalCase()}}RepositoryImpl(sl<{{name.pascalCase()}}Api>()),
  );
}
```

**关键变更**:
- line 12: `sl.registerFactory<{{name.pascalCase()}}RepositoryImpl>` → `sl.registerFactory<{{domainInterface}}>`
- line 13: 工厂函数返回值类型不变, 只是注册键改了

- [ ] **Step 2: 验证注册键是接口**

```bash
rg "registerFactory<" bricks/api/__brick__/lib/src/di/setup.dart
```

**Expected output:** 2 行匹配:
```
  sl.registerFactory<{{name.pascalCase()}}Api>(
  sl.registerFactory<{{domainInterface}}>(
```

- [ ] **Step 3: Commit**

```bash
git add bricks/api/__brick__/lib/src/di/setup.dart
git commit -m "feat(bricks/api): register domain interface as DI key (not impl class)"
```

---

### Task 4: 修改 pubspec.yaml 模板（加 api 依赖）

**Files:**
- Modify: `bricks/api/__brick__/pubspec.yaml`

- [ ] **Step 1: 在 dependencies 段加 api 路径依赖**

`bricks/api/__brick__/pubspec.yaml` 修改:

```yaml
# 在 line 15-16 之后追加:
  domain:
    path: ../../domain
  api:                                  # ← 新增
    path: ../../api                     # ← 新增
```

- [ ] **Step 2: 验证 yaml 仍合法**

```bash
python3 -c "import yaml; doc = yaml.safe_load(open('bricks/api/__brick__/pubspec.yaml').read()); print('deps:', list(doc['dependencies'].keys()))"
```

**Expected output:** `deps: ['flutter', 'dio', 'retrofit', 'freezed_annotation', 'json_annotation', 'domain', 'api']`。

- [ ] **Step 3: Commit**

```bash
git add bricks/api/__brick__/pubspec.yaml
git commit -m "feat(bricks/api): add api path dependency for toDomainException import"
```

---

### Task 5: 新建 bricks/api/README.md

**Files:**
- Create: `bricks/api/README.md`

- [ ] **Step 1: 创建文件**

`bricks/api/README.md`:

```markdown
# API Brick

一键创建 API 调用模块：Retrofit 接口 + Repository 实现 + DI 注册。

## Usage

```bash
# 交互式（推荐首次使用）
mason make api

# 命令行（推荐 CI / 脚本）
mason make api \
  --name orders \
  --baseUrl /Order \
  --hasModel true \
  --modelName Order \
  --domainInterface IOrderRepository
```

## Variables

| 名称 | 类型 | 必填 | 默认 | 说明 |
|------|------|------|------|------|
| `name` | string | ✅ | — | API 模块名称（蛇形命名，如 `orders`） |
| `baseUrl` | string | ✅ | — | API 基础路径（如 `/api/v1`） |
| `hasModel` | boolean | ❌ | `false` | 是否绑定数据模型 |
| `modelName` | string | ❌ | `dynamic` | 绑定的数据模型名称（PascalCase） |
| `domainInterface` | string | ✅ | — | 对应的 domain 接口名（含 `I` 前缀，如 `IOrderRepository`） |

> ⚠️ **WARNING: Mason 覆盖式写入**
>
> 本砖块会**完全覆盖**已存在的同名模块。运行前请：
> 1. 备份现有的 `lib/src/repository/<name>_repository_impl.dart`
> 2. 备份现有的 `lib/src/di/setup.dart`
> 3. 备份现有的 `lib/src/api/<name>_api.dart`
>
> 新生成的文件已包含 `implements {{domainInterface}}` 子句和 `toDomainException` 错误处理，
> 但你的手写逻辑（如自定义缓存、特殊错误码处理）会被清空。

## 硬规则（来自 AGENTS.md）

### R3: Services 依赖 Domain 接口，不依赖实现

生成代码的 DI 注册键是 `{{domainInterface}}`（不是 `{{name.pascalCase()}}RepositoryImpl`）。
下游 feature 包通过 `sl<{{domainInterface}}>()` 获取实例，满足分层原则。

### R8: 错误走 ErrorReporter / DomainException

生成代码使用 `toDomainException(e)` 映射 `DioException` → `DomainException`，
不直接 `e.toString()` 拼字符串。未知异常走 `UnknownException` 兜底。

## 模板文件

| 文件 | 职责 |
|------|------|
| `__brick__/pubspec.yaml` | 包定义 + 依赖（dio/retrofit/freezed/domain/api） |
| `__brick__/lib/src/api/{{name}}_api.dart` | Retrofit 接口（用户手写 5 个 CRUD 方法） |
| `__brick__/lib/src/repository/{{name}}_repository_impl.dart` | 实现 domain 接口 + toDomainException 错误处理 |
| `__brick__/lib/src/di/setup.dart` | 注册 Api 工厂 + Repository 工厂（接口键） |

## 完整流程

1. **生成 API 包**（用本砖块）
2. **手写 `{{name}}_api.dart`**（5 个 CRUD 方法 + `@GET/@POST` 注解 + `@Body` 参数）
3. **确保 domain 层有 `{{domainInterface}}` 接口**（含 5 个方法签名）
4. **在 `lib/core/di/setup.dart` 调 `setupApi{{name.pascalCase()}}(sl, baseUrl)`**
5. **跑 `dart run build_runner build` 生成 `_api.g.dart`**
6. **feature 包通过 `sl<{{domainInterface}}>()` 注入并使用**
```

- [ ] **Step 2: Commit**

```bash
git add bricks/api/README.md
git commit -m "docs(bricks/api): add README documenting 5 vars and AGENTS.md R3/R8 hard rules"
```

---

### Task 6: 砖块验收测试（mason make api 试跑 + 编译检查）

**Files:**
- Test: 临时目录试生成（不写入仓库）

- [ ] **Step 1: 创建临时测试目录**

```bash
mkdir -p /tmp/api-brick-test && cd /tmp/api-brick-test
```

- [ ] **Step 2: 跑 mason make api 试生成**

```bash
mason make api \
  --name orders \
  --baseUrl /Order \
  --hasModel true \
  --modelName Order \
  --domainInterface IOrderRepository \
  --output /tmp/api-brick-test
```

**Expected output:** 生成 `pubspec.yaml` + `lib/src/api/orders_api.dart` + `lib/src/repository/orders_repository_impl.dart` + `lib/src/di/setup.dart` 4 个文件。

- [ ] **Step 3: 验证 implements 子句**

```bash
grep "^class" /tmp/api-brick-test/lib/src/repository/orders_repository_impl.dart
```

**Expected output:** `class OrdersRepositoryImpl implements IOrderRepository {`。

- [ ] **Step 4: 验证 4 处 catch 块全部用 toDomainException**

```bash
rg "toDomainException\(" /tmp/api-brick-test/lib/src/repository/orders_repository_impl.dart
```

**Expected output:** ≥2 行匹配（每个方法 1 处 `on DioException catch` + 1 处 `toDomainException` 调用）。

- [ ] **Step 5: 验证 DI 注册键是接口**

```bash
grep "registerFactory" /tmp/api-brick-test/lib/src/di/setup.dart
```

**Expected output:**
```
  sl.registerFactory<OrdersApi>(
  sl.registerFactory<IOrderRepository>(
```

- [ ] **Step 6: 验证 `domainInterface` 留空时 mason 报错**

```bash
mason make api --name bad --baseUrl /X --domainInterface "" --output /tmp/api-brick-test-bad 2>&1 | tail -10
```

**Expected output:** `Error: Missing required variable: domainInterface` 或类似错误，无文件生成。

- [ ] **Step 7: 清理临时目录**

```bash
rm -rf /tmp/api-brick-test /tmp/api-brick-test-bad
```

- [ ] **Step 8: Commit 验收结果**

```bash
cd -
# 验收无文件变更, 跳过 commit
```

---

### Task 7: 验证已存在 feature 包不需重生成

**Files:**
- Verify: 3 个已存在的 impl 文件 `implements` 情况

- [ ] **Step 1: 验证 feature_home impl 已 implements**

```bash
rg "^class.*Repository.*implements" packages/features/feature_home/lib/src/repository/home_repository_impl.dart
```

**Expected output:** `class HomeRepositoryImpl implements HomeRepository {`（HomeRepository 是 feature_home 自有接口, 不一定是 domain 接口, 但已 implements — 满足硬规则）。

- [ ] **Step 2: 验证 feature_detail impl 已 implements**

```bash
rg "^class.*Repository.*implements" packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart
```

**Expected output:** `class DetailRepositoryImpl implements DetailRepository {`。

- [ ] **Step 3: 验证 services/auth impl 已 implements**

```bash
rg "^class.*Repository.*implements" packages/services/auth/lib/src/repository/user_repository_impl.dart
```

**Expected output:** `class UserRepositoryImpl implements UserRepository {`。

> **预期**: 3 个 impl 均已 implements, 砖块升级不影响它们(无文件变更, 不需重生成)。

- [ ] **Step 4: 跑 melos analyze 确认 3 个 impl 仍编译**

```bash
melos analyze 2>&1 | tail -10
```

**Expected output:** 0 error, 0 new warning。

---

### Task 8: PR-C-1a 整体验证 + commit + PR

- [ ] **Step 1: 跑全量 melos analyze**

```bash
melos analyze 2>&1 | tail -10
```

**Expected output:** 0 error, 0 new warning。

- [ ] **Step 2: 跑 make scaffold-check 验证脚手架健康**

```bash
make scaffold-check 2>&1 | tail -20
```

**Expected output:** 脚手架完整性检查通过（无 broken 引用）。

- [ ] **Step 3: 跑 melos test:affected**

```bash
melos test:affected 2>&1 | tail -20
```

**Expected output:** 受影响包测试全过（brick 改动不影响任何 package 的代码, 仅测试路径下 brick 内测试不影响）。

- [ ] **Step 4: 验证 mason list**

```bash
mason list 2>&1
```

**Expected output:** 4 个 surviving brick (`feature` / `api` / `model` / `hive_model`)，无 `api_gen` / `api_gen_spec`(PR-B 已删)。

- [ ] **Step 5: 写 PR 描述 + 开 PR**

```bash
git push origin feat/brick-api-contract
gh pr create \
  --title "feat(bricks/api): require domainInterface var, enforce implements + toDomainException + interface-based DI" \
  --body "见 openspec/changes/archive/2026-06-06-refactor-api-package/specs/mason-brick-contract/spec.md 与 docs/superpowers/plans/2026-06-06-api-mason-brick-contract.md。砖块契约升级，只影响 make create-api 新生成代码，不影响 3 个已存在 feature 包。"
```

---

## Self-Review

**Spec 覆盖度**:
- `Requirement: Generated Repository implementation must implement a domain interface` → Task 1 (新增 var) + Task 2 (加 implements) 覆盖
- `Requirement: Generated Repository must use the standard error mapping helper` → Task 2 (改 4 处 catch) 覆盖
- `Requirement: Generated DI setup must register the domain interface as the registered key` → Task 3 (改 registerFactory 类型参数) 覆盖
- `Requirement: Brick variable validation rejects empty domainInterface` → Task 6 Step 6 (留空 mason 报错) 覆盖
- `Requirement: Existing successful brick runs still work after template update` → Task 7 (3 个已存在 impl 仍编译) 覆盖
- `Requirement: Brick template's pubspec.yaml gets a domain import if needed` → Task 4 (加 api 依赖) 覆盖

**Placeholder 检查**: 无 `TBD` / `TODO` 出现。所有代码块完整。

**类型一致性**:
- `{{domainInterface}}` 必填变量在 Task 1 brick.yaml 定义, Task 2/3 模板引用, Task 6 Step 3/5 验收
- `toDomainException` 在 Task 2 import + 使用, 与 plan-2 token interceptor 拆分后的 `package:api/api.dart` barrel export 一致
- 注册键类型从 `RepositoryImpl` 改为 `{{domainInterface}}` 在 Task 3 一致引用
