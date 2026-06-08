# spine-flutter 脚手架优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复脚手架 7 项已知质量问题（版本漂移、仓库卫生、覆盖率门槛、缺失砖块、Cubit 防重入、路由守卫、集成测试），提升可维护性和 CI 守门力度。

**Architecture:** 按优先级排序的 7 个独立任务：版本统一 → 仓库清理 → CI 覆盖率 → Mason usecase 砖块 → HomeCubit 防重入 → AuthGuard 前缀匹配 → 集成测试骨架。每个任务独立可测试、可提交。

**Tech Stack:** Flutter 3.38.10, Dart 3.x, Melos, Mason, bloc_test, mocktail, GoRouter

**排除项（不在此计划内）：**
- SENTRY_DSN 为空：脚手架设计，故意留空
- 错误处理逻辑优化：另一个 Agent 正在处理（见 `docs/superpowers/plans/2026-06-08-error-handler-business-layer.md`）

---

## 文件变更地图

| 操作 | 文件 | 职责 |
|------|------|------|
| Modify | `scripts/check_workspace_versions.dart` | 扩展跟踪包列表 |
| Modify | `packages/domain/pubspec.yaml` | 统一 mocktail/lints 版本 |
| Modify | `packages/services/data_sync/pubspec.yaml` | 统一 mocktail 版本 |
| Modify | `packages/infrastructure/key_value_storage/pubspec.yaml` | 统一 lints/hive_generator 版本 |
| Modify | `packages/features/feature_home/pubspec.yaml` | 统一 dio 版本 |
| Modify | `packages/features/feature_detail/pubspec.yaml` | 统一 dio 版本 |
| Delete | `packages/features/feature_sf_check/` | 空壳残留包 |
| Delete | 6 个 `.bak` 文件 | pubspec 备份残留 |
| Modify | `.gitignore` | 添加 `*.bak` 规则 |
| Create | `scripts/check_coverage.sh` | 覆盖率门槛检查脚本 |
| Modify | `melos.yaml` | 添加 check:coverage:threshold 脚本 |
| Modify | `.github/workflows/coverage.yml` | 添加门槛检查步骤 |
| Create | `bricks/usecase/brick.yaml` | Usecase 砖块定义 |
| Create | `bricks/usecase/__brick__/` | Usecase 模板文件 |
| Modify | `mason.yaml` | 注册 usecase 砖块 |
| Modify | `makefile` | 添加 create-usecase 命令 |
| Modify | `packages/features/feature_home/lib/src/cubit/home_cubit.dart` | 添加防重入守卫 |
| Modify | `packages/features/feature_home/test/home_cubit_cache_test.dart` | 添加防重入测试 |
| Modify | `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart` | 砖块模板同步防重入 |
| Modify | `packages/infrastructure/routing/lib/src/guards/public_routes.dart` | 添加 publicRoutePrefixes |
| Modify | `packages/infrastructure/routing/lib/src/guards/auth_guard.dart` | 支持前缀匹配 |
| Modify | `packages/infrastructure/routing/test/guards/auth_guard_path_test.dart` | 更新+新增测试 |
| Create | `integration_test/app_test.dart` | 集成测试骨架 |
| Modify | `.github/workflows/ci.yml` | 添加集成测试 job |

---

### Task 1: 版本号漂移修复

**目标：** 统一所有子包间的依赖版本，扩展版本漂移检查脚本覆盖已发现的漂移包。

**版本漂移清单：**

| 包 | 当前各包版本 | 统一目标 |
|---|---|---|
| mocktail | root `^1.0.5`, domain `^0.3.0`, data_sync `^0.3.0` | `^1.0.5` |
| dio | root `^5.2.0+1`, feature_home `^5.4.0`, feature_detail `^5.4.0` | `^5.4.0` |
| alice | root `^0.4.2`, feature_home `^0.4.0` | `^0.4.2` |
| lints | domain `^2.0.0`, key_value_storage `^1.0.1` | 保持各自（纯 Dart 包用 `lints`, Flutter 包用 `flutter_lints`，不同生态） |
| hive_generator | root `^2.0.0`, key_value_storage `^1.1.0` | `^2.0.0` |

**Files:**
- Modify: `scripts/check_workspace_versions.dart`
- Modify: `packages/domain/pubspec.yaml`
- Modify: `packages/services/data_sync/pubspec.yaml`
- Modify: `packages/infrastructure/key_value_storage/pubspec.yaml`
- Modify: `packages/features/feature_home/pubspec.yaml`
- Modify: `packages/features/feature_detail/pubspec.yaml`

- [ ] **Step 1: 扩展 check_workspace_versions.dart 跟踪列表**

打开 `scripts/check_workspace_versions.dart`，将 `trackedPackages` 常量替换为：

```dart
const trackedPackages = [
  'get_it',
  'go_router',
  'flutter_bloc',
  'freezed_annotation',
  'freezed',
  'build_runner',
  'mocktail',
  'dio',
  'alice',
  'hive_generator',
  'bloc_test',
  'retrofit',
  'json_annotation',
  'json_serializable',
];
```

- [ ] **Step 2: 运行版本检查确认漂移**

Run: `dart run scripts/check_workspace_versions.dart`
Expected: 输出 mocktail/dio/alice/hive_generator 的 Version drift 信息，exit code 1

- [ ] **Step 3: 修复 mocktail 版本（domain + data_sync）**

`packages/domain/pubspec.yaml` — 找到：
```yaml
  mocktail: ^0.3.0
```
替换为：
```yaml
  mocktail: ^1.0.5
```

`packages/services/data_sync/pubspec.yaml` — 找到：
```yaml
  mocktail: ^0.3.0
```
替换为：
```yaml
  mocktail: ^1.0.5
```

- [ ] **Step 4: 修复 dio 版本（root → 对齐 feature 包）**

`pubspec.yaml`（根目录）— 找到：
```yaml
  dio: ^5.2.0+1
```
替换为：
```yaml
  dio: ^5.4.0
```

- [ ] **Step 5: 修复 alice 版本（feature_home → 对齐 root）**

`packages/features/feature_home/pubspec.yaml` — 找到：
```yaml
  alice: ^0.4.0
```
替换为：
```yaml
  alice: ^0.4.2
```

- [ ] **Step 6: 修复 hive_generator 版本（key_value_storage → 对齐 root）**

`packages/infrastructure/key_value_storage/pubspec.yaml` — 找到：
```yaml
  hive_generator: ^1.1.0
```
替换为：
```yaml
  hive_generator: ^2.0.0
```

- [ ] **Step 7: melos bootstrap 同步依赖**

Run: `melos bs`
Expected: 无报错，所有包依赖解析成功

- [ ] **Step 8: 运行版本检查确认修复**

Run: `dart run scripts/check_workspace_versions.dart`
Expected: 无输出，exit code 0

- [ ] **Step 9: 运行分析+测试确认无回归**

Run: `melos analyze && melos test`
Expected: 全量通过

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "fix(scaffold): unify dependency version drift across packages

- mocktail: ^0.3.0 → ^1.0.5 (domain, data_sync)
- dio: ^5.2.0+1 → ^5.4.0 (root)
- alice: ^0.4.0 → ^0.4.2 (feature_home)
- hive_generator: ^1.1.0 → ^2.0.0 (key_value_storage)
- Expand trackedPackages in check_workspace_versions.dart (+8)"
```

---

### Task 2: 代码仓库卫生清理

**目标：** 移除残留空壳包、备份文件、已追踪的 .DS_Store，添加 gitignore 规则防止再犯。

**清理清单：**

| 类型 | 数量 | 位置 |
|------|------|------|
| 空壳包 | 1 | `packages/features/feature_sf_check/` |
| .bak 文件 | 6 | `packages/infrastructure/*/pubspec.yaml.bak.20250403150306`, `packages/domain/pubspec.yaml.bak.20250403150306` |
| .DS_Store | 12+ | `packages/`, `packages/features/`, `packages/infrastructure/api/` 等 |

**Files:**
- Delete: `packages/features/feature_sf_check/`
- Delete: 6 个 `.bak` 文件
- Modify: `.gitignore`

- [ ] **Step 1: 删除空壳包 feature_sf_check**

```bash
rm -rf packages/features/feature_sf_check/
```

- [ ] **Step 2: 删除所有 .bak 文件**

```bash
find packages/ -name "*.bak.*" -type f -delete
```

验证：`find packages/ -name "*.bak.*" -type f` 应返回空

- [ ] **Step 3: 从 git 追踪中移除 .DS_Store 和 .iml 文件**

当前 `.gitignore` 已有 `.DS_Store` 和 `*.iml` 规则，但这些文件在规则添加前已被 git 追踪。执行：

```bash
git rm -r --cached '**/.DS_Store' 2>/dev/null || true
git rm -r --cached '**/*.iml' 2>/dev/null || true
```

- [ ] **Step 4: 在 .gitignore 中添加 *.bak 规则**

打开 `.gitignore`，在 `# Misc` 段（`.DS_Store` 附近）添加：

```
# Backup files
*.bak
*.bak.*
```

- [ ] **Step 5: 验证 scaffold 健康**

Run: `make scaffold-check`
Expected: 通过（feature_sf_check 不再被 Melos 扫描到，因为无 pubspec.yaml 已删除）

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: clean up repository artifacts

- Remove empty feature_sf_check package (residual .iml only)
- Delete 6 pubspec.yaml.bak backup files
- Untrack .DS_Store and .iml files (already in .gitignore)
- Add *.bak/ *.bak.* to .gitignore"
```

---

### Task 3: CI 覆盖率门槛

**目标：** 在 CI 中添加最低覆盖率检查，防止代码质量退化。默认门槛 80%。

**Files:**
- Create: `scripts/check_coverage.sh`
- Modify: `melos.yaml`
- Modify: `.github/workflows/coverage.yml`

- [ ] **Step 1: 创建覆盖率门槛检查脚本**

创建 `scripts/check_coverage.sh`：

```bash
#!/bin/bash
# 检查所有包的合并覆盖率是否达到最低门槛
# 用法: ./scripts/check_coverage.sh [min_percent]
#   min_percent: 最低覆盖率百分比 (默认 80)

set -e

MIN="${1:-80}"

# 合并所有 lcov.info
MERGED="/tmp/lcov_merged.info"
> "$MERGED"

found=0
for f in $(find . -name "lcov.info" -not -path "*/.dart_tool/*" -not -path "*/build/*"); do
  cat "$f" >> "$MERGED"
  found=$((found + 1))
done

if [ "$found" -eq 0 ]; then
  echo "❌ 未找到任何 lcov.info 文件，请先运行 melos test:coverage"
  exit 1
fi

echo "📊 合并了 $found 个 lcov.info 文件"

# 用 lcov 计算行覆盖率
TOTAL=$(grep "^DA:" "$MERGED" | wc -l | tr -d ' ')
HIT=$(grep "^DA:" "$MERGED" | awk -F, '$2 > 0' | wc -l | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
  echo "❌ lcov 中无 DA: 行数据"
  exit 1
fi

PERCENT=$((HIT * 100 / TOTAL))

echo "📈 行覆盖率: ${HIT}/${TOTAL} = ${PERCENT}% (门槛: ${MIN}%)"

if [ "$PERCENT" -lt "$MIN" ]; then
  echo "❌ 覆盖率 ${PERCENT}% 低于门槛 ${MIN}%"
  exit 1
fi

echo "✅ 覆盖率检查通过"
```

```bash
chmod +x scripts/check_coverage.sh
```

- [ ] **Step 2: 在 melos.yaml 中添加覆盖率门槛脚本**

在 `melos.yaml` 的 `scripts:` 段添加：

```yaml
  check:coverage:threshold:
    run: |
      ./scripts/check_coverage.sh 80
    description: 检查合并覆盖率是否达到 80% 门槛
```

- [ ] **Step 3: 修改 coverage.yml 添加门槛检查**

在 `.github/workflows/coverage.yml` 的 "Run tests with coverage" 步骤之后、"Upload to codecov" 之前，添加：

```yaml
      - name: Check coverage threshold
        run: ./scripts/check_coverage.sh 80
```

完整的 coverage.yml 步骤顺序变为：
1. checkout
2. flutter-action
3. melos install + bs
4. Run tests with coverage (`melos test:coverage`)
5. **Check coverage threshold** (新增)
6. Upload to codecov
7. Upload artifact

- [ ] **Step 4: 本地验证**

Run: `melos test:coverage && ./scripts/check_coverage.sh 80`
Expected: 输出合并文件数和覆盖率百分比，根据实际覆盖率决定通过/失败

- [ ] **Step 5: Commit**

```bash
git add scripts/check_coverage.sh melos.yaml .github/workflows/coverage.yml
git commit -m "feat(ci): add 80% minimum coverage threshold

- Add scripts/check_coverage.sh to merge and check lcov.info files
- Add melos check:coverage:threshold script
- Integrate threshold check into coverage.yml CI workflow"
```

---

### Task 4: Mason usecase 砖块

**目标：** 新增 `usecase` Mason 砖块，一行命令生成 domain 层 UseCase 文件（含 Result 返回类型）。

**AGENTS.md 提到但当前缺失的砖块。**

**Files:**
- Create: `bricks/usecase/brick.yaml`
- Create: `bricks/usecase/__brick__/{{name}}_use_case.dart`
- Create: `bricks/usecase/hooks/pre_gen.dart`（可选，用于命名规范化）
- Modify: `mason.yaml`
- Modify: `makefile`

- [ ] **Step 1: 创建 brick.yaml**

创建 `bricks/usecase/brick.yaml`：

```yaml
name: usecase
description: 生成 Domain 层 UseCase 类（含 Repository 依赖 + Result 返回类型）
version: 0.1.0

vars:
  name:
    type: string
    description: UseCase 名称 (不含 UseCase 后缀, 如 GetUser → getUser)
    prompt: UseCase 名称 (如: getUser, fetchOrders)
  repository:
    type: string
    description: Repository 接口名 (不含 I 前缀, 如 User → IUserRepository)
    prompt: Repository 接口名 (如: User, Order)
```

- [ ] **Step 2: 创建模板文件**

创建 `bricks/usecase/__brick__/{{name}}_use_case.dart`：

```dart
import 'package:domain/domain.dart';

/// {{name.pascalCase()}} 用例
///
/// 职责: {{name.pascalCase()}} 业务逻辑封装
/// 依赖: I{{repository.pascalCase()}}Repository (domain 层接口)
class {{name.pascalCase()}}UseCase {
  final I{{repository.pascalCase()}}Repository _repository;

  const {{name.pascalCase()}}UseCase(this._repository);

  /// 执行 {{name.pascalCase()}} 操作
  ///
  /// 返回 Result<T, DomainException>, 调用方需穷尽匹配处理成功/失败
  Future<Result<dynamic, DomainException>> call() async {
    final result = await _repository.get{{repository.pascalCase()}}();
    return result;
  }
}
```

- [ ] **Step 3: 注册到 mason.yaml**

在 `mason.yaml` 的 `bricks:` 段添加：

```yaml
  usecase:
    path: bricks/usecase
```

- [ ] **Step 4: 验证砖块可用**

Run: `mason list`
Expected: 输出包含 `usecase` 砖块

- [ ] **Step 5: 在 makefile 中添加 create-usecase 命令**

在 makefile 的 Mason 生成命令段（`create-hive-model` 附近）添加：

```makefile
## 生成 usecase (domain 层 UseCase)
create-usecase:
	@if [ -z "$(name)" ] || [ -z "$(repo)" ]; then \
		echo "用法: make create-usecase name=xxx repo=yyy"; \
		echo "  name: UseCase 名称 (不含 UseCase 后缀)"; \
		echo "  repo: Repository 名称 (不含 I 前缀)"; \
		echo "示例: make create-usecase name=getUser repo=User"; \
		exit 1; \
	fi
	@echo "▸ 生成 UseCase: $(name)..."
	@mason make usecase --name $(name) --repository $(repo) --on-conflict overwrite
	@echo "✅ UseCase $(name) 已生成"
	@echo "⚠️  提醒: 确认 packages/domain/lib/src/repositories/ 已有 I$(repo)Repository 接口"
	@echo "⚠️  提醒: 在 packages/domain/lib/domain.dart 中导出新 UseCase"
```

- [ ] **Step 6: 测试砖块生成**

Run: `mason make usecase --name testExample --repository TestExample --on-conflict overwrite`
Expected: 生成 `test_example_use_case.dart`

验证文件内容后清理：

```bash
cat test_example_use_case.dart
rm test_example_use_case.dart
```

- [ ] **Step 7: Commit**

```bash
git add bricks/usecase/ mason.yaml makefile
git commit -m "feat(scaffold): add usecase Mason brick

- Generate domain-layer UseCase with Repository dependency + Result return type
- Add make create-usecase name=xxx repo=yyy command
- Register usecase brick in mason.yaml"
```

---

### Task 5: HomeCubit 防重复加载

**目标：** 为 HomeCubit.loadData() 添加防重入守卫，防止连续调用触发重复请求。同步更新砖块模板。

**问题：** 当前 `loadData()` 和 `refreshData()` 都没有 `isLoading` 检查，快速连续调用会触发多个并发请求。`refreshData()` 允许重入（下拉刷新场景），但 `loadData()` 不应重入。

**Files:**
- Modify: `packages/features/feature_home/lib/src/cubit/home_cubit.dart`
- Modify: `packages/features/feature_home/test/home_cubit_cache_test.dart`
- Modify: `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart`

- [ ] **Step 1: 编写防重入测试**

在 `packages/features/feature_home/test/home_cubit_cache_test.dart` 的 `group('HomeCubit with caching')` 内，现有测试之后添加：

```dart
    blocTest<HomeCubit, HomeState>(
      'loadData ignores concurrent calls when already loading',
      build: () {
        when(() => mockRepo.getHomeData()).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 100),
            () => Result.success<HomeData, DomainException>(
              const HomeData(title: 'test'),
            ),
          ),
        );
        return HomeCubit(mockRepo);
      },
      act: (cubit) async {
        cubit.loadData();
        // 立即再调一次，应被忽略
        cubit.loadData();
        // 等待第一个请求完成
        await Future.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
        // 不应出现第二次 loading → loaded
      ],
      verify: (_) {
        verify(() => mockRepo.getHomeData()).called(1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'loadData allows call after previous completes',
      build: () {
        when(() => mockRepo.getHomeData()).thenAnswer(
          (_) async => Result.success<HomeData, DomainException>(
            const HomeData(title: 'test'),
          ),
        );
        return HomeCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.loadData();
        await cubit.loadData();
      },
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
    );
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/features/feature_home && flutter test test/home_cubit_cache_test.dart`
Expected: 第一个测试失败（loadData 被调用 2 次而非 1 次）

- [ ] **Step 3: 在 HomeCubit 中添加防重入守卫**

修改 `packages/features/feature_home/lib/src/cubit/home_cubit.dart`：

在类中添加一个私有字段：

```dart
  bool _isLoading = false;
```

修改 `loadData()` 方法，在开头添加守卫：

```dart
  Future<void> loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      emit(const HomeState.loading());

      final result = await _repository.getHomeData();
      result.when(
        success: (data) => emit(HomeState.loaded(data: data)),
        failure: (error) => emit(HomeState.error(errorCode: error.message)),
      );
    } finally {
      _isLoading = false;
    }
  }
```

注意：`refreshData()` **不添加**防重入守卫——下拉刷新场景需要允许重入。

- [ ] **Step 4: 运行测试确认通过**

Run: `cd packages/features/feature_home && flutter test test/home_cubit_cache_test.dart`
Expected: 全部通过

- [ ] **Step 5: 同步更新 Feature 砖块模板**

修改 `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart`：

替换整个文件内容为：

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/{{name}}_repository.dart';
import '{{name}}_state.dart';

/// {{name.pascalCase()}} 状态管理 Cubit
class {{name.pascalCase()}}Cubit extends Cubit<{{name.pascalCase()}}State> {
  final {{name.pascalCase()}}Repository _repository;
  bool _isLoading = false;

  {{name.pascalCase()}}Cubit(this._repository) : super(const {{name.pascalCase()}}State.initial());

  Future<void> loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      emit(const {{name.pascalCase()}}State.loading());

      final result = await _repository.get{{name.pascalCase()}}Data();
      result.when(
        success: (data) => emit({{name.pascalCase()}}State.loaded(data: data)),
        failure: (error) => emit({{name.pascalCase()}}State.error(errorCode: error.message)),
      );
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refreshData() async {
    emit(const {{name.pascalCase()}}State.loading());

    final result = await _repository.refresh{{name.pascalCase()}}Data();
    result.when(
      success: (data) => emit({{name.pascalCase()}}State.loaded(data: data)),
      failure: (error) => emit({{name.pascalCase()}}State.error(errorCode: error.message)),
    );
  }

  Future<void> retry() async {
    await loadData();
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add packages/features/feature_home/lib/src/cubit/home_cubit.dart \
       packages/features/feature_home/test/home_cubit_cache_test.dart \
       "bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart"
git commit -m "fix(home): add double-load guard to HomeCubit.loadData()

- Add _isLoading flag to prevent concurrent loadData() calls
- refreshData() intentionally allows re-entry (pull-to-refresh)
- Add bloc_test verifying concurrent calls are ignored
- Sync feature brick cubit template with guard pattern"
```

---

### Task 6: AuthGuard 前缀匹配支持

**目标：** 为 AuthGuard 添加可选的路径前缀匹配机制，支持 `/public/*` 类路由自动放行。保持现有严格匹配的默认行为不变。

**现状：** `publicRoutes` 是 `Set<String>` 严格匹配。已有测试明确断言 `/home/list` **不**被 `/home` 覆盖。

**方案：** 新增 `publicRoutePrefixes` 列表，与现有 `publicRoutes` 并存。`isPublic` 判断变为：精确匹配 Set **或** 前缀匹配任一 prefix。

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/guards/public_routes.dart`
- Modify: `packages/infrastructure/routing/lib/src/guards/auth_guard.dart`
- Modify: `packages/infrastructure/routing/test/guards/auth_guard_path_test.dart`

- [ ] **Step 1: 编写前缀匹配测试**

在 `packages/infrastructure/routing/test/guards/auth_guard_path_test.dart` 末尾（`main()` 内），添加新 group：

```dart
  group('AuthGuard.check with publicRoutePrefixes', () {
    test('path matching a public prefix is allowed', () {
      // publicRoutePrefixes 默认包含 '/public/'
      expect(AuthGuard.check('/public/anything', () => false), isNull);
      expect(AuthGuard.check('/public/deep/nested/path', () => false), isNull);
    });

    test('path not matching any prefix falls back to strict set match', () {
      // /public-settings 不匹配 /public/ 前缀（缺少斜杠）
      expect(
        AuthGuard.check('/public-settings', () => false),
        '/login?redirect=/public-settings',
      );
    });

    test('exact publicRoutes still work alongside prefixes', () {
      expect(AuthGuard.check('/login', () => false), isNull);
      expect(AuthGuard.check('/home', () => false), isNull);
    });

    test('authenticated user bypasses all checks', () {
      expect(AuthGuard.check('/private/path', () => true), isNull);
    });
  });
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/infrastructure/routing && flutter test test/guards/auth_guard_path_test.dart`
Expected: 新 group 中的测试失败（`publicRoutePrefixes` 未定义）

- [ ] **Step 3: 在 public_routes.dart 中添加前缀列表**

替换 `packages/infrastructure/routing/lib/src/guards/public_routes.dart` 全部内容：

```dart
/// 精确匹配的公开路由（无需登录即可访问）
const publicRoutes = {'/', '/home', '/login', '/register'};

/// 前缀匹配的公开路由（路径以此前缀开头即放行）
///
/// 注意：前缀应包含尾部斜杠以避免误匹配
/// 例如 '/public/' 匹配 '/public/anything' 但不匹配 '/public-settings'
const publicRoutePrefixes = <String>[
  '/public/',
];
```

- [ ] **Step 4: 在 auth_guard.dart 中添加前缀匹配逻辑**

在 `auth_guard.dart` 的 `check` 方法中，找到：

```dart
    final isPublic = publicRoutes.contains(path);
```

替换为：

```dart
    final isPublic = publicRoutes.contains(path) ||
        publicRoutePrefixes.any((prefix) => path.startsWith(prefix));
```

- [ ] **Step 5: 运行全部 routing 测试确认通过**

Run: `cd packages/infrastructure/routing && flutter test`
Expected: 所有测试通过（原有严格匹配测试 + 新前缀测试）

- [ ] **Step 6: Commit**

```bash
git add packages/infrastructure/routing/lib/src/guards/public_routes.dart \
       packages/infrastructure/routing/lib/src/guards/auth_guard.dart \
       packages/infrastructure/routing/test/guards/auth_guard_path_test.dart
git commit -m "feat(routing): add publicRoutePrefixes to AuthGuard

- Add opt-in prefix matching alongside existing strict set match
- Default prefix: '/public/' — matches /public/anything but not /public-settings
- Existing publicRoutes behavior unchanged (security-first)
- Add tests for prefix matching, fallback, and coexistence"
```

---

### Task 7: 集成测试骨架

**目标：** 搭建集成测试基础设施，提供一个可运行的冒烟测试，CI 中集成执行。

**现状：** `integration_test/` 目录未启用，AGENTS.md 标注"目前未启用, 1-2 人可省略"。

**Files:**
- Create: `integration_test/app_test.dart`
- Modify: `.github/workflows/ci.yml`
- Modify: `melos.yaml`

- [ ] **Step 1: 创建集成测试冒烟测试**

创建 `integration_test/app_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spine_flutter/main.dart' as app;

/// 集成测试冒烟测试
///
/// 验证应用能正常启动并完成基本渲染。
/// 在真机或模拟器上运行:
///   flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App 冒烟测试', () {
    testWidgets('应用启动后渲染首页', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证应用成功启动（不白屏、不崩溃）
      expect(find.byType(app.SpineFlutter), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 在 melos.yaml 添加集成测试脚本**

在 `melos.yaml` 的 `scripts:` 段添加：

```yaml
  test:integration:
    run: |
      flutter test integration_test/app_test.dart
    description: 运行集成测试 (需要模拟器/真机)
```

- [ ] **Step 3: 在 ci.yml 添加集成测试 job**

在 `.github/workflows/ci.yml` 中，在 `build:` job 之后添加：

```yaml
  integration-test:
    name: 集成测试
    runs-on: macos-latest
    needs: [analyze, test]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.10'
          channel: 'stable'
      - run: dart pub global activate melos
      - run: melos bs
      - name: Run integration tests
        uses: nick-fields/retry@v3
        with:
          timeout_minutes: 10
          max_attempts: 2
          command: flutter test integration_test/app_test.dart
```

注意：集成测试需要 macOS runner（支持 iOS 模拟器）。如果团队不想承担 macOS runner 成本，可以：
- 改为 `runs-on: ubuntu-latest` + Android 模拟器（需额外配置）
- 或暂不加入 CI，仅本地运行

- [ ] **Step 4: 本地验证集成测试可运行**

Run: `flutter test integration_test/app_test.dart`（需模拟器运行中）
Expected: 测试通过，应用成功启动

如果不方便运行模拟器，可跳过此步骤，CI 会验证。

- [ ] **Step 5: Commit**

```bash
git add integration_test/app_test.dart .github/workflows/ci.yml melos.yaml
git commit -m "feat(test): add integration test scaffold

- Add app smoke test verifying app launches and renders
- Add melos test:integration script
- Add integration-test job to CI (macOS runner for iOS simulator)"
```

---

## 执行顺序建议

```
Task 1 (版本漂移) → Task 2 (卫生清理) → Task 3 (覆盖率门槛)
                                         ↓
Task 4 (usecase 砖块) ← 独立             ↓
Task 5 (HomeCubit 防重入) ← 独立         ↓
Task 6 (AuthGuard 前缀) ← 独立           ↓
Task 7 (集成测试骨架) ← 独立             ↓
                                         ↓
                              melos validate (全量验收)
```

Task 1-3 建议按顺序执行（基础设施类）。Task 4-7 相互独立，可并行或按优先级选择。

**全部完成后验收：**
```bash
melos validate
./scripts/check_coverage.sh 80
dart run scripts/check_workspace_versions.dart
```
