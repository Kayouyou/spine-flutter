# Dev Tooling Implementation Plan — Melos + Mason

> **For agentic workers:** Use `task` to delegate each task to a subagent. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 引入 Melos 多包管理（修复 CI 测试盲区）和 Mason 代码模板生成（Feature brick）

**Architecture:** Melos 作为顶层 monorepo 管理工具，Makefile 保留构建命令；Mason 提供 `feature` brick 模板

**Tech Stack:** melos, mason_cli, mustache 模板语法

---

## 文件结构

| 文件 | 类型 | 职责 |
|------|------|------|
| `melos.yaml` | 新增 | Melos monorepo 配置 |
| `Makefile` | 修改 | `get`/`test`/`lint` 改为 Melos 命令 |
| `.github/workflows/ci.yml` | 修改 | test job 改为 `melos test` |
| `.github/workflows/coverage.yml` | 修改 | 改为 `melos test --coverage` |
| `.githooks/pre-commit` | 修改 | 改为 `melos exec --since` |
| `mason.yaml` | 新增 | Mason 注册 |
| `bricks/feature/` | 新增 | Feature brick 模板文件 |
| `pubspec.yaml` | 不修改 | （Melos/Mason 不需要 pubspec 改动） |

---

### Task 1: 安装 Melos 并创建 melos.yaml

- [ ] **Step 1: 安装 melos**

```bash
dart pub global activate melos
```

- [ ] **Step 2: 创建 melos.yaml**

在项目根目录创建 `melos.yaml`：

```yaml
name: spine_flutter
packages:
  - packages/domain
  - packages/infrastructure/*
  - packages/services/*
  - packages/features/*

scripts:
  analyze:
    run: |
      melos exec -- flutter analyze
    description: 全量代码分析

  test:
    run: |
      melos exec -- flutter test
    description: 所有包测试

  test:affected:
    run: |
      melos exec --since=origin/main --diff=origin/main -- flutter test
    description: 只测变更相关包

  test:coverage:
    run: |
      melos exec -- flutter test --coverage
    description: 全量测试+覆盖率
```

- [ ] **Step 3: 验证**

```bash
melos bs
# 应自动扫描并安装所有 14 个包依赖
```

---

### Task 2: 修改 Makefile（与 Melos 共存）

- [ ] **Step 1: 修改 `get` target**

将当前 14 行手动 `cd packages/xxx && fvm flutter pub get` 替换为：

```makefile
get:
	@dart run melos bs
```

- [ ] **Step 2: 修改 `test` target**

```makefile
test:
	@dart run melos test
```

- [ ] **Step 3: 修改 `lint` target**

```makefile
lint:
	@dart run melos analyze
```

- [ ] **Step 4: 保持构建命令不变**

`debug`, `debug-simulator`, `release`, `dev`, `staging`, `prod`, `build-prod` — 全部保留。

- [ ] **Step 5: 验证**

```bash
make get
# 应调用 melos bs，正确安装依赖
```

---

### Task 3: 修改 CI 配置

- [ ] **Step 1: 修改 ci.yml 的 test job**

当前 test job 只有 `flutter test --coverage`，改为：

```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.22.3'
        channel: 'stable'
    - run: dart pub global activate melos
    - run: melos bs
    - run: melos test
```

- [ ] **Step 2: 修改 ci.yml 的 analyze job**

```yaml
analyze:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.22.3'
        channel: 'stable'
    - run: dart pub global activate melos
    - run: melos bs
    - run: ./scripts/check_l10n.sh
    - run: melos analyze
```

- [ ] **Step 3: 修改 coverage.yml**

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: subosito/flutter-action@v2
    with:
      flutter-version: '3.22.3'
      channel: 'stable'
  - run: dart pub global activate melos
  - run: melos bs
  - run: melos test:coverage
  - uses: codecov/codecov-action@v4
    with:
      token: ${{ secrets.CODECOV_TOKEN }}
      fail_ci_if_error: false
```

---

### Task 4: 修改 Pre-commit Hook

- [ ] **Step 1: 读取并修改 `.githooks/pre-commit`**

当前内容中 `flutter test test/unit/ test/bloc/` 改为：

```bash
#!/bin/bash
set -e

# Check localization
./scripts/check_l10n.sh

# Lint (errors only)
flutter analyze lib/ packages/ --no-fatal-infos --no-fatal-warnings

# Test affected packages only (fast)
dart run melos test:affected
```

- [ ] **Step 2: 验证**

```bash
# 在一个有未推送 commit 的分支上
.githooks/pre-commit
# 应只跑变更相关包的测试
```

---

### Task 5: 初始化 Mason 并创建 Feature Brick

- [ ] **Step 1: 安装并初始化**

```bash
dart pub global activate mason_cli
mason init
```

这会生成 `mason.yaml`。

- [ ] **Step 2: 创建 brick 目录**

```bash
mkdir -p bricks/feature/__brick__
```

- [ ] **Step 3: 创建 `bricks/feature/brick.yaml`**

```yaml
name: feature
description: Generate a complete Flutter feature package with cubit, repository, and UI.
version: 1.0.0
vars:
  name:
    type: string
    description: Feature name (snake_case, e.g. 'settings')
    prompt: What is the feature name?
```

- [ ] **Step 4: 创建 `bricks/feature/__brick__/pubspec.yaml`**

使用 Mustache 模板：

```yaml
name: feature_{{name}}
description: {{name}} feature module
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.1.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  get_it: ^7.6.4
  freezed_annotation: ^2.4.1
  domain:
    path: ../../domain
  infrastructure:
    path: ../../infrastructure

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5
  build_runner: ^2.4.8
  freezed: ^2.5.2
```

- [ ] **Step 5: 创建导出入口 `__brick__/lib/feature_{{name}}.dart`**

```dart
export 'di/setup.dart';
export 'cubit/{{name}}_cubit.dart';
export 'ui/{{name}}_page.dart';
```

- [ ] **Step 6: 创建 DI `__brick__/lib/di/setup.dart`**

```dart
import 'package:get_it/get_it.dart';
import '../cubit/{{name}}_cubit.dart';
import '../repository/{{name}}_repository.dart';
import 'package:domain/domain.dart';
import 'package:infrastructure/infrastructure.dart';

void setupFeature{{#pascalCase}}{{name}}{{/pascalCase}}(ServiceLocator sl) {
  sl.registerFactory<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>(
    () => {{#pascalCase}}{{name}}{{/pascalCase}}RepositoryImpl(
      sl<HttpClient>(),
    ),
  );
  sl.registerFactory<{{#pascalCase}}{{name}}{{/pascalCase}}Cubit>(
    () => {{#pascalCase}}{{name}}{{/pascalCase}}Cubit(
      sl<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>(),
    ),
  );
}
```

（注意：实际模板中 `{{#pascalCase}}{{name}}{{/pascalCase}}` 应替换为 `{{name.pascalCase()}}`）

- [ ] **Step 7: 创建 State `__brick__/lib/cubit/{{name}}_state.dart`**

```dart
part of '{{name}}_cubit.dart';

@freezed
class {{name.pascalCase()}}State with _${{name.pascalCase()}}State {
  const factory {{name.pascalCase()}}State.initial() = _Initial;
  const factory {{name.pascalCase()}}State.loading() = _Loading;
  const factory {{name.pascalCase()}}State.loaded({
    required List<String> items,
  }) = _Loaded;
  const factory {{name.pascalCase()}}State.error({
    required String message,
  }) = _Error;
}
```

- [ ] **Step 8: 创建 Cubit `__brick__/lib/cubit/{{name}}_cubit.dart`**

```dart
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../repository/{{name}}_repository.dart';

part '{{name}}_state.dart';
part '{{name}}_cubit.freezed.dart';

class {{name.pascalCase()}}Cubit extends Cubit<{{name.pascalCase()}}State> {
  final {{name.pascalCase()}}Repository _repository;
  
  {{name.pascalCase()}}Cubit(this._repository) : super(const {{name.pascalCase()}}State.initial());

  Future<void> load() async {
    emit(const {{name.pascalCase()}}State.loading());
    try {
      final data = await _repository.fetch();
      emit({{name.pascalCase()}}State.loaded(items: data));
    } catch (e) {
      emit({{name.pascalCase()}}State.error(message: e.toString()));
    }
  }
}
```

- [ ] **Step 9: 创建 Repository `__brick__/lib/repository/{{name}}_repository.dart`**

```dart
abstract class {{name.pascalCase()}}Repository {
  Future<List<String>> fetch();
}

class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  final HttpClient _api;
  
  {{name.pascalCase()}}RepositoryImpl(this._api);

  @override
  Future<List<String>> fetch() async {
    final response = await _api.get('/{{name}}');
    return (response.data as List).cast<String>();
  }
}
```

- [ ] **Step 10: 创建 Page `__brick__/lib/ui/{{name}}_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/{{name}}_cubit.dart';

class {{name.pascalCase()}}Page extends StatelessWidget {
  const {{name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => context.read<{{name.pascalCase()}}Cubit>()..load(),
      child: const _{{name.pascalCase()}}View(),
    );
  }
}

class _{{name.pascalCase()}}View extends StatelessWidget {
  const _{{name.pascalCase()}}View();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (items) => ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(title: Text(items[i])),
          ),
          error: (message) => Center(child: Text('Error: $message')),
        );
      },
    );
  }
}
```

- [ ] **Step 11: 创建测试 `__brick__/test/{{name}}_cubit_test.dart`**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_{{name}}/feature_{{name}}.dart';

void main() {
  group('{{name.pascalCase()}}Cubit', () {
    test('initial state is correct', () {
      final cubit = {{name.pascalCase()}}Cubit(const _FakeRepository());
      expect(cubit.state, const {{name.pascalCase()}}State.initial());
    });

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'load emits loading then loaded',
      build: () => {{name.pascalCase()}}Cubit(const _FakeRepository()),
      act: (c) => c.load(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(items: ['test']),
      ],
    );
  });
}

class _FakeRepository implements {{name.pascalCase()}}Repository {
  const _FakeRepository();
  @override
  Future<List<String>> fetch() async => ['test'];
}
```

- [ ] **Step 12: 注册 brick 并验证**

```bash
mason add feature --path bricks/feature
mason make feature --name test
# 应生成 feature_test/ 包
flutter analyze feature_test/
# 零 error
```

---

### Task 6: 全量验证

- [ ] **Step 1: 运行全量测试**

```bash
melos test
# 全部 41 个测试通过
```

- [ ] **Step 2: 运行分析**

```bash
melos analyze
# 零 error
```

- [ ] **Step 3: 验证 Makefile 命令**

```bash
make get    # melos bs
make test   # melos test
```

---

### Task 7: 提交

```bash
git add melos.yaml mason.yaml bricks/ Makefile .github/workflows/ .githooks/
git commit -m "feat: add Melos monorepo management and Mason feature brick

- melos.yaml: auto-detect all 14 packages, unified test/analyze
- Makefile: get/test/lint delegate to melos
- CI: test job now covers all packages (was root-only)
- Pre-commit: only test affected packages via melos test:affected
- mason: feature brick generates complete package scaffold"
```
