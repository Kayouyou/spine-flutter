# Solo + AI Scaffold Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把当前 monorepo 从“优秀工程底座”提升为“更适合 1 人 + AI 持续开发的开箱脚手架”，先收口规则，再补护栏，最后做产品化打磨。

**Architecture:** 保留现有 `domain / infrastructure / services / features / app` 分层，不做大重构。P0 只解决“唯一真相”与“依赖纪律”，P1 增加脚手架守门和版本漂移检查，P2 将高级能力可选化并补齐 AI 交接文档。

**Tech Stack:** Flutter 3 stable, Dart 3, Melos, Mason, GetIt, GoRouter, flutter_test, GitHub Actions

---

## Phase Overview

- **P0 必做**：统一 feature 接入规则，移除 feature 内部直接取 DI 的模式
- **P1 应做**：补脚手架守门命令、契约测试、依赖版本漂移检查
- **P2 可做**：把调试/监控/同步能力改成可选模块，补 Solo + AI 最短指南

---

### Task 1: P0 统一 Feature 接入唯一真相

**Files:**
- Create: `test/unit/scaffold/feature_template_contract_test.dart`
- Modify: `bricks/feature/__brick__/lib/feature_{{name}}.dart`
- Modify: `makefile`
- Modify: `README.md`
- Modify: `docs/di-discipline.md`

**Why:** 当前模板里仍保留 import 副作用注册，但根应用真实策略是 composition root 显式 `register + runAll`。这会让人和 AI 都误以为“生成 feature 后自动接入已完成”。

- [ ] **Step 1: 写一个会失败的脚手架契约测试**

```dart
// test/unit/scaffold/feature_template_contract_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature scaffold contract', () {
    test('feature barrel does not use import side-effect registration', () {
      final file = File(
        'bricks/feature/__brick__/lib/feature_{{name}}.dart',
      );
      final content = file.readAsStringSync();

      expect(
        content.contains('FeatureRegistry.instance.register'),
        isFalse,
        reason: 'Feature 接入必须只在 root composition root 显式注册',
      );
    });

    test('make create-feature output reminds root explicit registration', () {
      final file = File('makefile');
      final content = file.readAsStringSync();

      expect(
        content.contains('lib/core/di/setup.dart'),
        isTrue,
        reason: '创建 feature 后必须提示开发者去 root setup 显式注册',
      );
    });
  });
}
```

- [ ] **Step 2: 先运行测试确认它失败**

Run: `flutter test test/unit/scaffold/feature_template_contract_test.dart -r expanded`
Expected: FAIL，错误里出现 `FeatureRegistry.instance.register` 仍存在于模板 barrel。

- [ ] **Step 3: 修改 Mason feature 模板，删除副作用注册**

```dart
// bricks/feature/__brick__/lib/feature_{{name}}.dart
export 'src/cubit/{{name}}_cubit.dart';
export 'src/cubit/{{name}}_state.dart';
export 'src/ui/{{name}}_page.dart';
export 'src/di/setup.dart';
export 'src/routes/{{name}}_route_module.dart';
```

- [ ] **Step 4: 修改 `make create-feature` 的完成提示，明确 root 手工接入**

```makefile
# makefile
	@echo ""
	@echo "=== ✅ 完成！下一步请在 lib/core/di/setup.dart 中显式注册 ==="
	@echo "1. 添加 feature_$(name) 的 import"
	@echo "2. 添加 FeatureRegistry.instance.register('feature_$(name)', setupFeatureXxx);"
	@echo "然后运行: make lint && make test"
```

- [ ] **Step 5: 更新 README 的 feature 接入说明，只保留一种接法**

```md
<!-- README.md -->
### 步骤 8：添加根依赖 + 显式注册

当前项目的唯一推荐做法：

1. 在根 `pubspec.yaml` 添加 path 依赖
2. 在 `lib/core/di/setup.dart` 添加 import
3. 调用 `FeatureRegistry.instance.register('feature_settings', setupFeatureSettings);`
4. 保持 `FeatureRegistry.instance.runAll(sl);` 作为统一执行入口

> 不再依赖 import 副作用自动注册。
```

- [ ] **Step 6: 更新 DI 规范文档，声明 FeatureRegistry 只允许在根 composition root 调用**

```md
<!-- docs/di-discipline.md -->
## FeatureRegistry 规则

- `FeatureRegistry.instance.register(...)` 只允许出现在 `lib/core/di/setup.dart`
- Feature 包可以暴露 `setupFeatureXxx`，但不负责自行接入根应用
- Mason 模板生成的代码不得依赖 import 副作用完成注册
```

- [ ] **Step 7: 运行验证**

Run: `flutter test test/unit/scaffold/feature_template_contract_test.dart && melos run analyze`
Expected: PASS，模板契约测试通过，静态分析无 error。

- [ ] **Step 8: Commit**

```bash
git add test/unit/scaffold/feature_template_contract_test.dart
git add bricks/feature/__brick__/lib/feature_{{name}}.dart
git add makefile README.md docs/di-discipline.md
git commit -m "refactor(scaffold): unify explicit feature registration"
```

---

### Task 2: P0 清理 Feature 内部直接取 DI 的模式

**Files:**
- Modify: `packages/features/feature_home/lib/src/routes/home_route_module.dart`
- Modify: `packages/features/feature_auth/lib/src/routes/auth_route_module.dart`
- Modify: `packages/features/feature_detail/lib/src/routes/detail_route_module.dart`
- Modify: `packages/features/feature_home/lib/src/ui/home_page.dart`
- Modify: `packages/features/feature_home/lib/src/di/setup.dart`
- Modify: `packages/features/feature_auth/lib/src/di/setup.dart`
- Modify: `packages/features/feature_detail/lib/src/di/setup.dart`
- Create: `packages/features/feature_home/test/home_page_test.dart`
- Modify: `packages/features/feature_home/test/home_route_module_test.dart`
- Modify: `packages/features/feature_auth/test/auth_route_module_test.dart`
- Modify: `packages/features/feature_detail/test/detail_route_module_test.dart`

**Why:** 当前 feature route module 和页面里还有 `GetIt.instance`、`Alice` 这类 app 级依赖，和现有 DI 规范冲突。

- [ ] **Step 1: 先写一个 HomePage 调试入口注入测试**

```dart
// packages/features/feature_home/test/home_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:feature_home/feature_home.dart';
import 'package:domain/domain.dart';

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<Result<HomeData, DomainException>> getHomeData() async {
    return Result.failure(DomainException.unknown());
  }
}

class _FakeHomeCubit extends HomeCubit {
  _FakeHomeCubit() : super(_FakeHomeRepository());
}

void main() {
  testWidgets('shows debug action only when callback is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeCubit>.value(
          value: _FakeHomeCubit(),
          child: HomePage(onOpenDebugInspector: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.bug_report), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试，确认当前构造函数不支持 callback 注入**

Run: `cd packages/features/feature_home && flutter test test/home_page_test.dart`
Expected: FAIL，错误提示 `HomePage` 没有 `onOpenDebugInspector` 参数。

- [ ] **Step 3: 修改 `HomePage`，移除 Alice 依赖，改成接收可选回调**

```dart
// packages/features/feature_home/lib/src/ui/home_page.dart
class HomePage extends StatelessWidget {
  final VoidCallback? onOpenDebugInspector;

  const HomePage({
    super.key,
    this.onOpenDebugInspector,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '首页',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<HomeCubit>().refreshData(),
        ),
        if (onOpenDebugInspector != null)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: onOpenDebugInspector,
            tooltip: '调试面板',
          ),
      ],
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeInitial() => _buildInitial(context),
            HomeLoading() => _buildLoading(context),
            HomeLoaded(data: final data) => _buildLoaded(context, data),
            HomeError(errorCode: final errorCode) => _buildError(context, errorCode),
          };
        },
      ),
    );
  }
}
```

- [ ] **Step 4: 修改三个 RouteModule，改为使用 setup.dart 传入的工厂，而不是 `GetIt.instance`**

```dart
// packages/features/feature_home/lib/src/routes/home_route_module.dart
class HomeRouteModule extends RouteModule {
  final HomeCubit Function() createCubit;
  final VoidCallback? onOpenDebugInspector;

  const HomeRouteModule(
    super.ctx, {
    required this.createCubit,
    this.onOpenDebugInspector,
  });

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          Widget page = BlocProvider(
            create: (_) => createCubit(),
            child: HomePage(
              onOpenDebugInspector: onOpenDebugInspector,
            ),
          );
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return MaterialPage(child: page);
        },
      ),
    ];
  }
}
```

```dart
// packages/features/feature_auth/lib/src/routes/auth_route_module.dart
class AuthRouteModule extends RouteModule {
  final LoginCubit Function() createCubit;

  const AuthRouteModule(
    super.ctx, {
    required this.createCubit,
  });

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final page = BlocProvider(
            create: (_) => createCubit(),
            child: LoginPage(redirect: redirect),
          );
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final page = BlocProvider(
            create: (_) => createCubit(),
            child: RegisterPage(redirect: redirect),
          );
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
    ];
  }
}
```

```dart
// packages/features/feature_detail/lib/src/routes/detail_route_module.dart
class DetailRouteModule extends RouteModule {
  final DetailCubit Function() createCubit;

  const DetailRouteModule(
    super.ctx, {
    required this.createCubit,
  });

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/detail',
        pageBuilder: (context, state) {
          final page = BlocProvider(
            create: (_) => createCubit(),
            child: const DetailPage(),
          );
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
      GoRoute(
        path: '/detail/:id',
        pageBuilder: (context, state) {
          final page = BlocProvider(
            create: (_) => createCubit(),
            child: DetailPage(id: state.pathParameters['id']),
          );
          final wrapped = ctx.routeWrapper?.call(page) ?? page;
          return MaterialPage(child: wrapped);
        },
      ),
    ];
  }
}
```

- [ ] **Step 5: 在各自 `setup.dart` 里通过闭包把依赖注入给 RouteModule**

```dart
// packages/features/feature_home/lib/src/di/setup.dart
import 'package:flutter/foundation.dart';
import 'package:alice/alice.dart';

void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(sl<Dio>()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl<HomeRepository>()));

  RouteModuleRegistry.instance.register(
    'feature_home',
    (ctx) => HomeRouteModule(
      ctx,
      createCubit: () => sl<HomeCubit>(),
      onOpenDebugInspector: kDebugMode && sl.isRegistered<Alice>()
          ? () => sl<Alice>().showInspector()
          : null,
    ),
  );
}
```

- [ ] **Step 6: 更新 route module 测试，按新构造函数传入假工厂**

```dart
// packages/features/feature_home/test/home_route_module_test.dart
test('build returns one route for /home', () {
  final module = HomeRouteModule(
    ctx,
    createCubit: () => throw UnimplementedError('not used in this test'),
  );
  final routes = module.build();
  expect(routes.length, 1);
});
```

- [ ] **Step 7: 运行 feature 相关测试**

Run: `melos exec --scope="feature_*" -- flutter test`
Expected: PASS，三个 feature 的 route module 测试与 `home_page_test.dart` 通过。

- [ ] **Step 8: Commit**

```bash
git add packages/features/feature_home/lib/src/ui/home_page.dart
git add packages/features/feature_home/lib/src/routes/home_route_module.dart
git add packages/features/feature_auth/lib/src/routes/auth_route_module.dart
git add packages/features/feature_detail/lib/src/routes/detail_route_module.dart
git add packages/features/feature_home/lib/src/di/setup.dart
git add packages/features/feature_auth/lib/src/di/setup.dart
git add packages/features/feature_detail/lib/src/di/setup.dart
git add packages/features/feature_home/test/home_page_test.dart
git add packages/features/feature_home/test/home_route_module_test.dart
git add packages/features/feature_auth/test/auth_route_module_test.dart
git add packages/features/feature_detail/test/detail_route_module_test.dart
git commit -m "refactor(features): inject dependencies without direct GetIt access"
```

---

### Task 3: P1 增加脚手架契约测试和一键体检命令

**Files:**
- Create: `test/unit/scaffold/root_contract_test.dart`
- Create: `scripts/scaffold_check.sh`
- Modify: `makefile`
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`

**Why:** 现在 `validate` 更偏业务工程健康，缺少“脚手架产品本身有没有走偏”的检测。

- [ ] **Step 1: 写 root contract 测试，约束 composition root 行为**

```dart
// test/unit/scaffold/root_contract_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('root scaffold contract', () {
    test('root setup keeps explicit feature registration', () {
      final content = File('lib/core/di/setup.dart').readAsStringSync();

      expect(
        content.contains("FeatureRegistry.instance.register('feature_home'"),
        isTrue,
      );
      expect(
        content.contains("FeatureRegistry.instance.runAll(sl);"),
        isTrue,
      );
    });

    test('README documents scaffold-check command', () {
      final content = File('README.md').readAsStringSync();
      expect(content.contains('make scaffold-check'), isTrue);
    });
  });
}
```

- [ ] **Step 2: 先运行测试，确认 README 尚未包含 `make scaffold-check`**

Run: `flutter test test/unit/scaffold/root_contract_test.dart -r expanded`
Expected: FAIL，README 中还没有 `make scaffold-check`。

- [ ] **Step 3: 创建脚手架体检脚本**

```bash
# scripts/scaffold_check.sh
#!/bin/bash
set -euo pipefail

echo "▸ scaffold contract tests"
flutter test test/unit/scaffold/feature_template_contract_test.dart
flutter test test/unit/scaffold/root_contract_test.dart

echo "▸ workspace validate"
melos run validate

echo "✅ scaffold health check passed"
```

- [ ] **Step 4: 在 Makefile 增加统一入口**

```makefile
# makefile
.PHONY: scaffold-check

scaffold-check:
	@chmod +x scripts/scaffold_check.sh
	@./scripts/scaffold_check.sh
```

- [ ] **Step 5: 在 CI 中补一条脚手架体检步骤**

```yaml
# .github/workflows/ci.yml
  analyze:
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.3'
          channel: 'stable'
      - run: dart pub global activate melos
      - run: melos bs
      - name: Scaffold health check
        run: make scaffold-check
```

- [ ] **Step 6: README 增加新入口**

```md
<!-- README.md -->
### 一键体检

```bash
make scaffold-check
```

该命令专门检查脚手架契约是否仍然成立：
- Feature 模板不再使用副作用注册
- 根 composition root 仍保留显式注册
- workspace 级 analyze / test / l10n / deps 校验通过
```

- [ ] **Step 7: 运行验证**

Run: `make scaffold-check`
Expected: PASS，显示 `scaffold health check passed`。

- [ ] **Step 8: Commit**

```bash
git add test/unit/scaffold/root_contract_test.dart
git add scripts/scaffold_check.sh makefile README.md .github/workflows/ci.yml
git commit -m "chore(scaffold): add scaffold contract checks"
```

---

### Task 4: P1 对齐 workspace 依赖版本并阻止漂移

**Files:**
- Create: `scripts/check_workspace_versions.dart`
- Modify: `melos.yaml`
- Modify: `README.md`
- Modify: `pubspec.yaml`
- Modify: `packages/domain/pubspec.yaml`
- Modify: `packages/features/feature_home/pubspec.yaml`
- Modify: `packages/features/feature_detail/pubspec.yaml`
- Modify: `packages/features/feature_auth/pubspec.yaml`
- Modify: `packages/infrastructure/api/pubspec.yaml`
- Modify: `packages/infrastructure/routing/pubspec.yaml`
- Modify: `packages/services/auth/pubspec.yaml`

**Why:** 目前 `get_it`、`go_router`、`freezed`、`build_runner` 等版本有轻微漂移，短期能跑，长期会制造 AI 和人工维护噪音。

- [ ] **Step 1: 先写版本漂移检查脚本**

```dart
// scripts/check_workspace_versions.dart
import 'dart:io';

const trackedPackages = [
  'get_it',
  'go_router',
  'flutter_bloc',
  'freezed_annotation',
  'freezed',
  'build_runner',
];

void main() {
  final pubspecs = Directory('.')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('pubspec.yaml'))
      .where((file) => !file.path.contains('/bricks/'))
      .toList();

  final versions = <String, Map<String, String>>{};

  for (final file in pubspecs) {
    final content = file.readAsStringSync();
    for (final pkg in trackedPackages) {
      final match = RegExp('^\\s{2}$pkg:\\s*(.+)\$', multiLine: true)
          .firstMatch(content);
      if (match != null) {
        versions.putIfAbsent(pkg, () => {});
        versions[pkg]![file.path] = match.group(1)!.trim();
      }
    }
  }

  var hasDrift = false;
  versions.forEach((pkg, entries) {
    final unique = entries.values.toSet();
    if (unique.length > 1) {
      hasDrift = true;
      stderr.writeln('Version drift for $pkg:');
      entries.forEach((path, version) => stderr.writeln('  $path -> $version'));
    }
  });

  if (hasDrift) exitCode = 1;
}
```

- [ ] **Step 2: 先运行脚本，确认当前版本确实不一致**

Run: `dart run scripts/check_workspace_versions.dart`
Expected: FAIL，输出 `get_it`、`go_router`、`freezed` 或 `build_runner` 的版本差异。

- [ ] **Step 3: 统一关键依赖版本**

```yaml
# 推荐统一到以下版本，所有 workspace package 对齐
get_it: ^7.7.0
go_router: ^14.2.7
flutter_bloc: ^9.1.1
freezed_annotation: ^2.4.0
freezed: ^2.5.2
build_runner: ^2.4.9
```

- [ ] **Step 4: 在 Melos 加一个显式检查命令**

```yaml
# melos.yaml
  check:versions:
    run: dart run scripts/check_workspace_versions.dart
    description: 检查 workspace 关键依赖版本是否漂移
```

- [ ] **Step 5: README 增加版本一致性说明**

```md
<!-- README.md -->
### 依赖版本一致性

```bash
melos run check:versions
```

用于检查 workspace 中关键依赖是否发生版本漂移。
```

- [ ] **Step 6: 运行验证**

Run: `melos run check:versions && melos bs`
Expected: PASS，脚本无输出或只输出成功结束，bootstrap 正常。

- [ ] **Step 7: Commit**

```bash
git add scripts/check_workspace_versions.dart
git add melos.yaml README.md pubspec.yaml
git add packages/domain/pubspec.yaml
git add packages/features/feature_home/pubspec.yaml
git add packages/features/feature_detail/pubspec.yaml
git add packages/features/feature_auth/pubspec.yaml
git add packages/infrastructure/api/pubspec.yaml
git add packages/infrastructure/routing/pubspec.yaml
git add packages/services/auth/pubspec.yaml
git commit -m "chore(workspace): align package versions and add drift guard"
```

---

### Task 5: P2 把高级能力改为可选模块

**Files:**
- Create: `lib/core/bootstrap/bootstrap_options.dart`
- Create: `lib/core/widgets/debug/debug_tools_wrapper.dart`
- Create: `lib/core/widgets/upgrade/upgrade_wrapper.dart`
- Modify: `lib/app.dart`
- Modify: `lib/core/di/setup.dart`
- Modify: `packages/services/data_sync/lib/src/di/setup.dart`
- Modify: `README.md`
- Create: `test/unit/bootstrap/bootstrap_options_test.dart`

**Why:** 现在监控、调试、同步、更新能力都已经在骨架中出现，但其中一部分仍是“示例能力”。对 solo 项目来说，更好的默认行为是“默认最小化，可按需打开”。

- [ ] **Step 1: 先写配置对象测试**

```dart
// test/unit/bootstrap/bootstrap_options_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/bootstrap/bootstrap_options.dart';

void main() {
  test('defaults keep optional integrations disabled', () {
    const options = BootstrapOptions();

    expect(options.enableDebugTools, isFalse);
    expect(options.enableDataSync, isFalse);
    expect(options.enableUpgradePrompt, isFalse);
  });
}
```

- [ ] **Step 2: 创建 `BootstrapOptions`**

```dart
// lib/core/bootstrap/bootstrap_options.dart
class BootstrapOptions {
  final bool enableDebugTools;
  final bool enableDataSync;
  final bool enableUpgradePrompt;

  const BootstrapOptions({
    this.enableDebugTools = false,
    this.enableDataSync = false,
    this.enableUpgradePrompt = false,
  });
}
```

- [ ] **Step 3: 在 `setup.dart` 和 `app.dart` 中按 options 组装可选能力**

```dart
// lib/core/di/setup.dart
void setupDependencies({BootstrapOptions options = const BootstrapOptions()}) {
  sl.registerSingleton<BootstrapOptions>(options);

  setupAuth(sl);
  if (options.enableDataSync) {
    setupDataSync(sl);
  }
}
```

```dart
// lib/app.dart
Widget build(BuildContext context) {
  final options = sl<BootstrapOptions>();

  Widget child = MaterialApp.router(
    title: '骨架演示',
    routerConfig: _router,
    theme: appLightTheme,
    darkTheme: appDarkTheme,
  );

  if (options.enableDebugTools) {
    child = DebugToolsWrapper(child: child);
  }
  if (options.enableUpgradePrompt) {
    child = UpgradeWrapper(child: child);
  }

  return child;
}
```

- [ ] **Step 4: 把 README 中相关能力改成“可选集成”而非默认生产就绪**

```md
<!-- README.md -->
## 可选模块

- Debug Tools: 默认关闭，适合本地调试时打开
- Data Sync: 默认关闭，接入真实同步任务后再启用
- Upgrade Prompt: 默认关闭，配置商店信息后启用
```

- [ ] **Step 5: 运行验证**

Run: `flutter test test/unit/bootstrap/bootstrap_options_test.dart && melos run analyze`
Expected: PASS，默认 options 测试通过，静态分析无 error。

- [ ] **Step 6: Commit**

```bash
git add lib/core/bootstrap/bootstrap_options.dart
git add lib/core/widgets/debug/debug_tools_wrapper.dart
git add lib/core/widgets/upgrade/upgrade_wrapper.dart
git add lib/app.dart lib/core/di/setup.dart
git add packages/services/data_sync/lib/src/di/setup.dart
git add README.md test/unit/bootstrap/bootstrap_options_test.dart
git commit -m "feat(scaffold): optionalize advanced integrations"
```

---

### Task 6: P2 补最短 Solo + AI 开发指南

**Files:**
- Create: `docs/solo-ai-scaffold-guide.md`
- Modify: `README.md`

**Why:** README 现在信息很全，但对 AI 和未来的自己来说，最需要的是 1 页“怎么加功能、怎么接路由、怎么接 DI、哪些模块只是示例”。

- [ ] **Step 1: 创建最短指南**

```md
<!-- docs/solo-ai-scaffold-guide.md -->
# Solo + AI Scaffold Guide

## 先看这 6 条

1. 新增 feature 后，必须去 `lib/core/di/setup.dart` 显式注册
2. Feature 不允许直接调用 `GetIt.instance`
3. App 级能力只能放在 `lib/`，不要放进 feature 包
4. 共享模型放 `packages/domain/`
5. `make scaffold-check` 是改完脚手架后的第一条验收命令
6. `services/data_sync`、调试面板、升级提醒默认都按可选模块理解
```

- [ ] **Step 2: README 首页增加入口链接**

```md
<!-- README.md -->
- [Solo + AI 开发指南](docs/solo-ai-scaffold-guide.md)
```

- [ ] **Step 3: 运行最小验证**

Run: `grep -n "Solo + AI 开发指南" README.md && test -f docs/solo-ai-scaffold-guide.md`
Expected: PASS，README 有入口，指南文件存在。

- [ ] **Step 4: Commit**

```bash
git add docs/solo-ai-scaffold-guide.md README.md
git commit -m "docs(scaffold): add solo and ai quick-start guide"
```

---

## Delivery Order

1. 先做 **Task 1**，把“唯一真相”收口
2. 再做 **Task 2**，把 Feature DI 纪律落到代码
3. 然后做 **Task 3** 和 **Task 4**，补脚手架护栏
4. 最后做 **Task 5** 和 **Task 6**，提升产品化和 AI 友好度

## Done Criteria

- `make create-feature` 不再让人误以为自动接入已完成
- `packages/features/` 中不再出现直接 `GetIt.instance` 读取依赖的代码
- `make scaffold-check` 能作为脚手架层的一键验收命令
- workspace 关键依赖版本一致，并有漂移检查
- 高级能力改为可选模块，README 不再默认暗示“全都生产可用”
- AI 和新接手的人可以先看 `docs/solo-ai-scaffold-guide.md` 再开始开发
