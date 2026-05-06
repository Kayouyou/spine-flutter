# Flutter UI 层统一模式（Lifecycle Patterns）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 Flutter UI 层的统一模式，包括统一导航栏、统一页面结构、统一生命周期管理，减少模板代码，提升开发效率。

**Architecture:** 采用组合优于继承的策略。AppScaffold widget 封装页面结构（UI 层），LifecycleMixin 系列处理生命周期回调（Logic 层），RouteObserver 作为路由监听基础设施（Infrastructure 层）。分层清晰，按需叠加。

**Tech Stack:** Flutter 3.x, GoRouter, RouteAware, WidgetsBindingObserver, Bloc/Cubit 状态管理

---

## File Structure Map

### UI 层（component_library）
```
packages/infrastructure/component_library/
├── lib/
│   ├── component_library.dart        ← 修改：导出 widgets
│   └── src/
│       ├── widgets/                  ← 新建目录
│       │   ├── custom_app_bar.dart   ← 新建：统一导航栏 widget
│       │   └── app_scaffold.dart     ← 新建：统一页面结构 widget
│       └── theme/                    ← 已存在
│       └── constants/                ← 已存在
└── test/
    └── widgets/                      ← 新建目录
        ├── custom_app_bar_test.dart  ← 新建：widget 测试
        └── app_scaffold_test.dart    ← 新建：widget 测试
```

### Infrastructure 层（routing）
```
packages/infrastructure/routing/
├── lib/
│   ├── routing.dart                  ← 修改：导出 route_observer
│   └── src/
│       ├── route_observer.dart       ← 新建：RouteObserver 单例
│       └── routes/
│           └── router.dart           ← 修改：注册 observers
└── test/
    └── route_observer_test.dart      ← 新建：集成测试
```

### Logic 层 mixin（routing 包）

**为什么放 routing 包？**
- LifecycleMixin 依赖 `AppRouteObserver`（在 routing 包）
- feature packages 都已依赖 `routing`，可直接 import
- `lib/core/mixins/` 是主 app 私有目录，feature packages 无法访问

```
packages/infrastructure/routing/
├── lib/
│   ├── routing.dart                  ← 修改：导出 route_observer + mixins
│   └── src/
│       ├── route_observer.dart       ← 新建：RouteObserver 单例
│       ├── mixins/                   ← 新建目录
│       │   ├── lifecycle_mixin.dart          ← 新建：RouteAware mixin
│       │   ├── app_lifecycle_mixin.dart      ← 新建：WidgetsBindingObserver mixin
│       │   └── full_lifecycle_mixin.dart     ← 新建：组合版 mixin
│       └── routes/
│           └── router.dart           ← 修改：注册 observers
└── test/
    ├── route_observer_test.dart      ← 新建：集成测试
    └── mixins/                       ← 新建目录
        ├── lifecycle_mixin_test.dart ← 新建：mixin 测试
        ├── app_lifecycle_mixin_test.dart ← 新建
        └── full_lifecycle_mixin_test.dart ← 新建
```

### Feature 页面迁移
```
packages/features/feature_home/lib/src/ui/home_page.dart         ← 修改
packages/features/feature_detail/lib/src/ui/detail_page.dart     ← 修改
lib/src/ui/tab_b_page.dart                                         ← 修改
```

### 文档更新
```
packages/infrastructure/component_library/README.md     ← 修改
packages/infrastructure/routing/README.md               ← 修改：mixins 章节
README.md                                               ← 修改
docs/ui-lifecycle-patterns-guide.md                    ← 新建：最佳实践指南
```

---

## Phase 1: UI 组件（立即见效）

### Task 1: CustomAppBar Widget

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/widgets/custom_app_bar.dart`
- Create: `packages/infrastructure/component_library/lib/src/widgets/` directory
- Create: `packages/infrastructure/component_library/test/widgets/custom_app_bar_test.dart`
- Modify: `packages/infrastructure/component_library/lib/component_library.dart` (exports)

- [ ] **Step 1: Create widgets directory**

```bash
mkdir -p packages/infrastructure/component_library/lib/src/widgets
mkdir -p packages/infrastructure/component_library/test/widgets
```

- [ ] **Step 2: Write CustomAppBar widget（实现 PreferredSizeWidget）**

Create file: `packages/infrastructure/component_library/lib/src/widgets/custom_app_bar.dart`

```dart
import 'package:flutter/material.dart';

/// 统一导航栏 widget
///
/// 职责：提供统一的 AppBar 样式，所有页面复用
/// 实现 PreferredSizeWidget（AppBar 必需接口）
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;

  const CustomAppBar({
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.leading,
    this.elevation = 0,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      leading: leading ?? (showBackButton ? const BackButton() : null),
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

- [ ] **Step 3: Write widget test（验证渲染）**

Create file: `packages/infrastructure/component_library/test/widgets/custom_app_bar_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('CustomAppBar', () {
    testWidgets('renders title correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CustomAppBar(title: '测试标题'),
          ),
        ),
      );

      expect(find.text('测试标题'), findsOneWidget);
    });

    testWidgets('shows back button when showBackButton is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CustomAppBar(title: '标题', showBackButton: true),
          ),
        ),
      );

      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('hides back button when showBackButton is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CustomAppBar(title: '标题', showBackButton: false),
          ),
        ),
      );

      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('renders actions correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CustomAppBar(
              title: '标题',
              actions: [
                IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('implements PreferredSizeWidget with correct height', (tester) async {
      final appBar = CustomAppBar(title: '标题');
      
      expect(appBar.preferredSize.height, equals(kToolbarHeight));
    });
  });
}
```

- [ ] **Step 4: Run test**

```bash
cd packages/infrastructure/component_library
fvm flutter test test/widgets/custom_app_bar_test.dart
```

Expected: PASS (5 tests)

- [ ] **Step 5: Update component_library exports**

Modify file: `packages/infrastructure/component_library/lib/component_library.dart`

```dart
// Component Library
export 'src/theme/ovs_theme.dart';
export 'src/theme/ovs_theme_data.dart';
export 'src/theme/font_size.dart';
export 'src/theme/spacing.dart';

// Constants
export 'src/constants/app_constants.dart';
export 'src/constants/api_constants.dart';
export 'src/constants/cache_constants.dart';

// Widgets
export 'src/widgets/custom_app_bar.dart';
```

- [ ] **Step 6: Commit**

```bash
git add packages/infrastructure/component_library/lib/src/widgets/
git add packages/infrastructure/component_library/test/widgets/
git add packages/infrastructure/component_library/lib/component_library.dart
git commit -m "feat(component_library): add CustomAppBar widget for unified navigation bar"
```

---

### Task 2: AppScaffold Widget

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/widgets/app_scaffold.dart`
- Create: `packages/infrastructure/component_library/test/widgets/app_scaffold_test.dart`

- [ ] **Step 1: Write AppScaffold widget（封装 Scaffold + CustomAppBar）**

Create file: `packages/infrastructure/component_library/lib/src/widgets/app_scaffold.dart`

```dart
import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

/// 统一页面结构 widget
///
/// 职责：封装 Scaffold + CustomAppBar，减少模板代码
/// 提供两种模式：
/// - 简单模式：传 title（默认 appBar）
/// - 高级模式：传 appBar（完全自定义 appBar）
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  /// showBackButton — 是否显示返回按钮（默认 true，仅在简单模式即 title 模式下生效，传自定义 appBar 时忽略此参数）
  final bool showBackButton;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  const AppScaffold({
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.appBar,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    super.key,
  }) : assert(
         title != null || appBar != null,
         'Either title or appBar must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar = appBar ?? CustomAppBar(
      title: title!,
      actions: actions,
      showBackButton: showBackButton,
    );

    return Scaffold(
      appBar: effectiveAppBar,
      body: body,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
```

- [ ] **Step 2: Write widget test（验证两种模式）**

Create file: `packages/infrastructure/component_library/test/widgets/app_scaffold_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppScaffold', () {
    testWidgets('renders with title (simple mode)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            title: '首页',
            body: const Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('内容'), findsOneWidget);
      expect(find.byType(CustomAppBar), findsOneWidget);
    });

    testWidgets('renders with custom appBar (advanced mode)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            appBar: CustomAppBar(title: '自定义标题'),
            body: const Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.text('自定义标题'), findsOneWidget);
      expect(find.byType(CustomAppBar), findsOneWidget);
    });

    testWidgets('renders actions correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            title: '首页',
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
            ],
            body: const Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renders floatingActionButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            title: '首页',
            body: const Center(child: Text('内容')),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('asserts title or appBar is provided', (tester) async {
      expect(
        () => AppScaffold(body: const Center(child: Text('内容'))),
        throwsAssertionError,
      );
    });

    testWidgets('hides back button when showBackButton is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            title: '首页',
            showBackButton: false,
            body: const Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.byType(BackButton), findsNothing);
    });
  });
}
```

- [ ] **Step 3: Run test**

```bash
cd packages/infrastructure/component_library
fvm flutter test test/widgets/app_scaffold_test.dart
```

Expected: PASS (6 tests)

- [ ] **Step 4: Update component_library exports**

Modify file: `packages/infrastructure/component_library/lib/component_library.dart`

```dart
// Component Library
export 'src/theme/ovs_theme.dart';
export 'src/theme/ovs_theme_data.dart';
export 'src/theme/font_size.dart';
export 'src/theme/spacing.dart';

// Constants
export 'src/constants/app_constants.dart';
export 'src/constants/api_constants.dart';
export 'src/constants/cache_constants.dart';

// Widgets
export 'src/widgets/custom_app_bar.dart';
export 'src/widgets/app_scaffold.dart';
```

- [ ] **Step 5: Commit**

```bash
git add packages/infrastructure/component_library/lib/src/widgets/app_scaffold.dart
git add packages/infrastructure/component_library/test/widgets/app_scaffold_test.dart
git add packages/infrastructure/component_library/lib/component_library.dart
git commit -m "feat(component_library): add AppScaffold widget for unified page structure"
```

---

### Task 3: 迁移 HomePage 到 AppScaffold

**Files:**
- Modify: `packages/features/feature_home/lib/src/ui/home_page.dart`

- [ ] **Step 1: Read current HomePage implementation**

Current file location: `packages/features/feature_home/lib/src/ui/home_page.dart`

Current pattern: Scaffold + AppBar(title: '首页', actions: [IconButton])

- [ ] **Step 2: Replace Scaffold with AppScaffold**

Modify file: `packages/features/feature_home/lib/src/ui/home_page.dart`

在文件顶部添加 import：
```dart
import 'package:component_library/component_library.dart';  // 新增
```

修改 build 方法，替换 Scaffold 为 AppScaffold：
```dart
@override
Widget build(BuildContext context) {
  return AppScaffold(  // 替换 Scaffold
    title: '首页',
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => context.read<HomeCubit>().refreshData(),
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
```

（_buildInitial、_buildLoading、_buildLoaded、_buildError 方法内容保持不变）

- [ ] **Step 3: Run app to verify**

```bash
fvm flutter run -d macos
```

Expected: HomePage 正常显示，AppBar 标题"首页"，刷新按钮可用

- [ ] **Step 4: Commit**

```bash
git add packages/features/feature_home/lib/src/ui/home_page.dart
git commit -m "refactor(feature_home): migrate HomePage to AppScaffold widget"
```

---

### Task 4: 迁移 DetailPage 到 AppScaffold

**Files:**
- Modify: `packages/features/feature_detail/lib/src/ui/detail_page.dart`

- [ ] **Step 1: Replace Scaffold with AppScaffold**

Modify file: `packages/features/feature_detail/lib/src/ui/detail_page.dart`

添加 import：
```dart
import 'package:component_library/component_library.dart';  // 新增
```

修改 build 方法：
```dart
@override
Widget build(BuildContext context) {
  return AppScaffold(  // 替换 Scaffold
    title: '详情页',
    body: BlocBuilder<DetailCubit, DetailState>(
      builder: (context, state) {
        return switch (state) {
          DetailInitial() => _buildInitial(context),
          DetailLoading() => _buildLoading(context),
          DetailLoaded(data: final data) => _buildLoaded(context, data),
          DetailError(errorCode: final errorCode) => _buildError(context, errorCode),
        };
      },
    ),
  );
}
```

（_buildInitial、_buildLoading、_buildLoaded、_buildError 保持不变）

- [ ] **Step 2: Run app to verify**

```bash
fvm flutter run -d macos
# 导航到 DetailPage 验证
```

Expected: DetailPage 正常显示

- [ ] **Step 3: Commit**

```bash
git add packages/features/feature_detail/lib/src/ui/detail_page.dart
git commit -m "refactor(feature_detail): migrate DetailPage to AppScaffold widget"
```

---

### Task 5: 迁移 TabBPage 到 AppScaffold

**Files:**
- Modify: `lib/src/ui/tab_b_page.dart`

- [ ] **Step 1: Replace Scaffold with AppScaffold**

Modify file: `lib/src/ui/tab_b_page.dart`

添加 import：
```dart
import 'package:component_library/component_library.dart';  // 新增
```

修改 build 方法：
```dart
@override
Widget build(BuildContext context) {
  return AppScaffold(  // 替换 Scaffold
    title: 'Settings',
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _InfoTile(label: 'Framework', value: 'Flutter'),
        _InfoTile(label: 'Architecture', value: 'Repository Pattern + GoRouter'),
        _InfoTile(label: 'Storage', value: 'Hive + SharedPreferences'),
        _InfoTile(label: 'HTTP', value: 'Dio'),
        _InfoTile(label: 'State', value: 'RxDart'),
        _InfoTile(label: 'UI Scale', value: 'flutter_screenutil'),
        SizedBox(height: 24),
        Text(
          'Start building your app by creating repositories and features:',
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 8),
        Text('make create-repo name=my_repository'),
        SizedBox(height: 4),
        Text('make create-feature name=my_feature'),
      ],
    ),
  );
}
```

（_InfoTile 类保持不变）

- [ ] **Step 2: Run app to verify**

```bash
fvm flutter run -d macos
# 导航到 Settings tab 验证
```

Expected: Settings tab 正常显示

- [ ] **Step 3: Commit**

```bash
git add lib/src/ui/tab_b_page.dart
git commit -m "refactor(ui): migrate TabBPage to AppScaffold widget"
```

---

## Phase 2: 路由基础设施（RouteObserver）

### Task 6: RouteObserver 单例

**Files:**
- Create: `packages/infrastructure/routing/lib/src/route_observer.dart`
- Modify: `packages/infrastructure/routing/lib/routing.dart` (exports)

- [ ] **Step 1: Create RouteObserver singleton**

Create file: `packages/infrastructure/routing/lib/src/route_observer.dart`

```dart
import 'package:flutter/material.dart';

/// 全局 RouteObserver 单例
///
/// 职责：为 RouteAware 提供订阅源，监听路由事件
/// 使用：GoRouter.observers 参数注册
/// 使用 `ModalRoute` 泛型以兼容 GoRouter 内部路由机制。
/// RouteAware 实现类通过 `AppRouteObserver.instance.subscribe(this, ModalRoute.of(context)!)` 订阅。
class AppRouteObserver extends RouteObserver<ModalRoute> {
  static final AppRouteObserver _instance = AppRouteObserver._internal();
  
  AppRouteObserver._internal();
  
  /// 全局单例访问
  static AppRouteObserver get instance => _instance;
}
```

- [ ] **Step 2: Update routing package exports**

Modify file: `packages/infrastructure/routing/lib/routing.dart`

```dart
export 'src/routes/routes.dart';
export 'src/guards/auth_guard.dart';
export 'src/guards/public_routes.dart';
export 'src/route_observer.dart';  // 新增
export 'src/mixins/lifecycle_mixin.dart';  // 新增
export 'src/mixins/app_lifecycle_mixin.dart';  // 新增
export 'src/mixins/full_lifecycle_mixin.dart';  // 新增
```

- [ ] **Step 3: Commit**

```bash
git add packages/infrastructure/routing/lib/src/route_observer.dart
git add packages/infrastructure/routing/lib/routing.dart
git commit -m "feat(routing): add AppRouteObserver singleton for RouteAware support"
```

---

### Task 7: GoRouter 注册 RouteObserver

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/routes/router.dart`

- [ ] **Step 1: Add observers parameter to GoRouter**

Modify file: `packages/infrastructure/routing/lib/src/routes/router.dart`

在文件顶部添加 import：
```dart
import 'package:routing/routing.dart';  // 新增：导入 AppRouteObserver
```

在 GoRouter 构造函数中添加 observers 参数：
```dart
static GoRouter getRouter({required RouteContext ctx}) {
  router = GoRouter(
    initialLocation: '/home',
    observers: [AppRouteObserver.instance],  // 新增：注册 RouteObserver
    redirect: ctx.enableAuthGuard && ctx.authManager != null
        ? (context, state) {
            final location = state.matchedLocation;
            return AuthGuard.check(location, ctx.authManager!);
          }
        : null,
    routes: [
      // ... 路由配置保持不变
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found')),
    ),
  );
  return router;
}
```

- [ ] **Step 2: Run app to verify RouteObserver registration**

```bash
fvm flutter run -d macos
```

Expected: App 正常启动，无路由错误

- [ ] **Step 3: Commit**

```bash
git add packages/infrastructure/routing/lib/src/routes/router.dart
git commit -m "feat(routing): register AppRouteObserver in GoRouter observers"
```

---

## Phase 3: 生命周期 Mixin

### Task 8: LifecycleMixin（RouteAware）

**Files:**
- Create: `packages/infrastructure/routing/lib/src/mixins/lifecycle_mixin.dart`
- Create: `packages/infrastructure/routing/lib/src/mixins/` directory
- Create: `packages/infrastructure/routing/test/mixins/lifecycle_mixin_test.dart`
- Create: `packages/infrastructure/routing/test/mixins/` directory

- [ ] **Step 1: Create mixins directory**

```bash
mkdir -p packages/infrastructure/routing/lib/src/mixins
mkdir -p packages/infrastructure/routing/test/mixins
```

- [ ] **Step 2: Write LifecycleMixin**

Create file: `packages/infrastructure/routing/lib/src/mixins/lifecycle_mixin.dart`

```dart
import 'package:flutter/material.dart';

/// 页面生命周期 mixin（RouteAware）
///
/// 职责：监听路由事件（页面进入/离开）
/// 使用：State 类 mixin LifecycleMixin<T>
/// 回调：onPageEnter、onPageLeave、onPageCovered、onPageRevealed
mixin LifecycleMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  /// 进入页面（didPush）
  void onPageEnter() {}
  
  /// 离开页面（didPop）
  void onPageLeave() {}
  
  /// 被下一个页面覆盖（didPushNext）
  void onPageCovered() {}
  
  /// 下一个页面 pop，重新显示当前页面（didPopNext）
  void onPageRevealed() {}

  @override
  void didPush() => onPageEnter();

  @override
  void didPop() => onPageLeave();

  @override
  void didPushNext() => onPageCovered();

  @override
  void didPopNext() => onPageRevealed();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 订阅 RouteObserver
    AppRouteObserver.instance.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // 取消订阅
    AppRouteObserver.instance.unsubscribe(this);
    super.dispose();
  }
}
```

- [ ] **Step 3: Write mixin test**

Create file: `packages/infrastructure/routing/test/mixins/lifecycle_mixin_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

void main() {
  group('LifecycleMixin', () {
    testWidgets('calls onPageEnter when page is pushed', (tester) async {
      int enterCount = 0;
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestPage(
                  onEnter: () => enterCount++,
                ),
              ),
            ],
          ),
        ),
      );

      // Wait for route to settle
      await tester.pumpAndSettle();
      
      expect(enterCount, equals(1));
    });

    testWidgets('subscribes and unsubscribes RouteObserver correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestPage(),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify no exception during dispose
      await tester.pumpWidget(const SizedBox());  // Remove widget tree
      await tester.pumpAndSettle();
    });
  });
}

class _TestPage extends StatefulWidget {
  final VoidCallback? onEnter;

  const _TestPage({this.onEnter});

  @override
  State<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<_TestPage> with LifecycleMixin<_TestPage> {
  @override
  void onPageEnter() {
    widget.onEnter?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Page')),
      body: const Center(child: Text('Test')),
    );
  }
}
```

- [ ] **Step 4: Run test**

```bash
cd packages/infrastructure/routing
fvm flutter test test/mixins/lifecycle_mixin_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add packages/infrastructure/routing/lib/src/mixins/lifecycle_mixin.dart
git add packages/infrastructure/routing/test/mixins/lifecycle_mixin_test.dart
git commit -m "feat(routing): add LifecycleMixin for RouteAware lifecycle callbacks"
```

---

### Task 9: AppLifecycleMixin（WidgetsBindingObserver）

**Files:**
- Create: `packages/infrastructure/routing/lib/src/mixins/app_lifecycle_mixin.dart`
- Create: `packages/infrastructure/routing/test/mixins/app_lifecycle_mixin_test.dart`

- [ ] **Step 1: Write AppLifecycleMixin**

Create file: `packages/infrastructure/routing/lib/src/mixins/app_lifecycle_mixin.dart`

```dart
import 'package:flutter/material.dart';

/// App 生命周期 mixin（WidgetsBindingObserver）
///
/// 职责：监听 App 前后台切换
/// 使用：State 类 mixin AppLifecycleMixin<T>
/// 回调：onAppPaused、onAppResumed、onAppInactive
mixin AppLifecycleMixin<T extends StatefulWidget> on State<T> implements WidgetsBindingObserver {
  /// App 进入后台（paused）
  void onAppPaused() {}
  
  /// App 恢复前台（resumed）
  void onAppResumed() {}
  
  /// App 不活跃状态（inactive，如弹出系统对话框）
  void onAppInactive() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        onAppPaused();
        break;
      case AppLifecycleState.resumed:
        onAppResumed();
        break;
      case AppLifecycleState.inactive:
        onAppInactive();
        break;
      case AppLifecycleState.hidden:
        // 可忽略（较少触发）
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

- [ ] **Step 2: Write mixin test**

Create file: `packages/infrastructure/routing/test/mixins/app_lifecycle_mixin_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

void main() {
  group('AppLifecycleMixin', () {
    testWidgets('registers WidgetsBindingObserver in initState', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestAppLifecyclePage(),
        ),
      );

      await tester.pumpAndSettle();
      
      expect(find.byType(_TestAppLifecyclePage), findsOneWidget);
    });

    testWidgets('calls onAppPaused when app lifecycle changes', (tester) async {
      int pausedCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: _TestAppLifecyclePage(
            onPaused: () => pausedCount++,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      final state = tester.state(find.byType(_TestAppLifecyclePage)) as _TestAppLifecyclePageState;
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      
      expect(pausedCount, equals(1));
    });

    testWidgets('calls onAppResumed when app returns to foreground', (tester) async {
      int resumedCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: _TestAppLifecyclePage(
            onResumed: () => resumedCount++,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      final state = tester.state(find.byType(_TestAppLifecyclePage)) as _TestAppLifecyclePageState;
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      
      expect(resumedCount, equals(1));
    });

    testWidgets('removes observer in dispose', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestAppLifecyclePage(),
        ),
      );

      await tester.pumpAndSettle();
      
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}

class _TestAppLifecyclePage extends StatefulWidget {
  final VoidCallback? onPaused;
  final VoidCallback? onResumed;

  const _TestAppLifecyclePage({
    this.onPaused,
    this.onResumed,
  });

  @override
  State<_TestAppLifecyclePage> createState() => _TestAppLifecyclePageState();
}

class _TestAppLifecyclePageState extends State<_TestAppLifecyclePage> with AppLifecycleMixin<_TestAppLifecyclePage> {
  @override
  void onAppPaused() {
    widget.onPaused?.call();
  }

  @override
  void onAppResumed() {
    widget.onResumed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: const Center(child: Text('Test')),
    );
  }
}
```

- [ ] **Step 3: Run test**

```bash
cd packages/infrastructure/routing
fvm flutter test test/mixins/app_lifecycle_mixin_test.dart
```

Expected: PASS (4 tests)

- [ ] **Step 4: Commit**

```bash
git add packages/infrastructure/routing/lib/src/mixins/app_lifecycle_mixin.dart
git add packages/infrastructure/routing/test/mixins/app_lifecycle_mixin_test.dart
git commit -m "feat(routing): add AppLifecycleMixin for WidgetsBindingObserver callbacks"
```

---

### Task 10: FullLifecycleMixin（组合版）

**Files:**
- Create: `packages/infrastructure/routing/lib/src/mixins/full_lifecycle_mixin.dart`
- Create: `packages/infrastructure/routing/test/mixins/full_lifecycle_mixin_test.dart`

- [ ] **Step 1: Write FullLifecycleMixin**

Create file: `packages/infrastructure/routing/lib/src/mixins/full_lifecycle_mixin.dart`

```dart
import 'package:flutter/material.dart';
import '../route_observer.dart';

/// 完整生命周期 mixin（RouteAware + WidgetsBindingObserver）
///
/// 职责：监听路由事件 + App 前后台切换
/// 使用：State 类 mixin FullLifecycleMixin<T>
/// 适用：视频播放器、计时器、实时数据等需要完整监听的页面
mixin FullLifecycleMixin<T extends StatefulWidget> on State<T> 
    implements RouteAware, WidgetsBindingObserver {
  
  // RouteAware 回调（路由事件）
  void onPageEnter() {}
  void onPageLeave() {}
  void onPageCovered() {}
  void onPageRevealed() {}
  
  // WidgetsBindingObserver 回调（前后台切换）
  void onAppPaused() {}
  void onAppResumed() {}
  void onAppInactive() {}

  // RouteAware 实现
  @override
  void didPush() => onPageEnter();

  @override
  void didPop() => onPageLeave();

  @override
  void didPushNext() => onPageCovered();

  @override
  void didPopNext() => onPageRevealed();

  // WidgetsBindingObserver 实现
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        onAppPaused();
        break;
      case AppLifecycleState.resumed:
        onAppResumed();
        break;
      case AppLifecycleState.inactive:
        onAppInactive();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // 注册双重监听
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouteObserver.instance.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    AppRouteObserver.instance.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

- [ ] **Step 2: Write mixin test**

Create file: `packages/infrastructure/routing/test/mixins/full_lifecycle_mixin_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

void main() {
  group('FullLifecycleMixin', () {
    testWidgets('calls both onPageEnter and registers WidgetsBindingObserver', (tester) async {
      int enterCount = 0;
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestFullLifecyclePage(
                  onEnter: () => enterCount++,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      expect(enterCount, equals(1));
    });

    testWidgets('calls onAppPaused when app lifecycle changes', (tester) async {
      int pausedCount = 0;
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestFullLifecyclePage(
                  onAppPaused: () => pausedCount++,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      final state = tester.state(find.byType(_TestFullLifecyclePage)) as _TestFullLifecyclePageState;
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      
      expect(pausedCount, equals(1));
    });

    testWidgets('removes both observers in dispose', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestFullLifecyclePage(),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}

class _TestFullLifecyclePage extends StatefulWidget {
  final VoidCallback? onEnter;
  final VoidCallback? onAppPaused;

  const _TestFullLifecyclePage({
    this.onEnter,
    this.onAppPaused,
  });

  @override
  State<_TestFullLifecyclePage> createState() => _TestFullLifecyclePageState();
}

class _TestFullLifecyclePageState extends State<_TestFullLifecyclePage> with FullLifecycleMixin<_TestFullLifecyclePage> {
  @override
  void onPageEnter() {
    widget.onEnter?.call();
  }

  @override
  void onAppPaused() {
    widget.onAppPaused?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: const Center(child: Text('Test')),
    );
  }
}
```

- [ ] **Step 3: Run test**

```bash
cd packages/infrastructure/routing
fvm flutter test test/mixins/full_lifecycle_mixin_test.dart
```

Expected: PASS (3 tests)

- [ ] **Step 4: Commit**

```bash
git add packages/infrastructure/routing/lib/src/mixins/full_lifecycle_mixin.dart
git add packages/infrastructure/routing/test/mixins/full_lifecycle_mixin_test.dart
git commit -m "feat(routing): add FullLifecycleMixin combining RouteAware and WidgetsBindingObserver"
```

---

## Phase 4: 文档更新

### Task 11: 更新 component_library README

**Files:**
- Modify: `packages/infrastructure/component_library/README.md`

- [ ] **Step 1: Add widgets section to README**

Modify file: `packages/infrastructure/component_library/README.md`

在 `## 内部结构` section 的目录树中添加 widgets 目录：

```
└── widgets/
    ├── custom_app_bar.dart   # 统一导航栏 widget
    └── app_scaffold.dart      # 统一页面结构 widget
```

在文件末尾添加 widgets 章节：

```markdown
## Widgets

### CustomAppBar

统一导航栏 widget，所有页面复用。

```dart
import 'package:component_library/component_library.dart';

CustomAppBar(
  title: '首页',
  actions: [IconButton(icon: Icon(Icons.refresh), onPressed: () {})],
  showBackButton: true,
)
```

参数：
- `title` — 标题文本（必需）
- `actions` — AppBar 右侧按钮列表（可选）
- `showBackButton` — 是否显示返回按钮（默认 true）
- `leading` — 自定义 leading widget（可选，覆盖 showBackButton）
- `elevation` — 阴影高度（默认 0）
- `backgroundColor` — AppBar 背景色（可选）

---

### AppScaffold

统一页面结构 widget，封装 Scaffold + CustomAppBar。

```dart
// 简单模式（传 title）
AppScaffold(
  title: '首页',
  body: Center(child: Text('内容')),
  actions: [IconButton(...)],
)

// 高级模式（传自定义 appBar）
AppScaffold(
  appBar: CustomAppBar(title: '自定义标题', ...),
  body: Center(child: Text('内容')),
)
```

参数：
- `title` — 标题（简单模式，与 appBar 二选一）
- `appBar` — 自定义 AppBar widget（高级模式）
- `body` — 页面内容（必需）
- `actions` — AppBar 右侧按钮（仅在简单模式生效）
- `showBackButton` — 是否显示返回按钮（默认 true）
- `floatingActionButton` — FAB（可选）
- `backgroundColor` — Scaffold 背景色（可选）
- `bottomNavigationBar` — 底部导航栏（可选）
- `resizeToAvoidBottomInset` — 键盘弹出时是否调整布局（可选，默认由 Scaffold 决定）

**使用场景**：
- 简单页面：传 title（80% 页面）
- 复杂页面：传 appBar + BlocBuilder（动态 AppBar）
- 需生命周期：叠加 LifecycleMixin（单独 mixin）
```

- [ ] **Step 2: Commit**

```bash
git add packages/infrastructure/component_library/README.md
git commit -m "docs(component_library): add CustomAppBar and AppScaffold documentation"
```

---

### Task 12: 更新 routing 包 README

**Files:**
- Modify: `packages/infrastructure/routing/README.md`

- [ ] **Step 1: Add mixins section to README**

Modify file: `packages/infrastructure/routing/README.md`

在目录结构中添加 mixins：

```
packages/infrastructure/routing/
├── lib/
│   ├── routing.dart                  ← 导出
│   └── src/
│       ├── route_observer.dart       # RouteObserver 单例
│       ├── mixins/                   ← 新增
│       │   ├── lifecycle_mixin.dart          # RouteAware（页面级）
│       │   ├── app_lifecycle_mixin.dart      # WidgetsBindingObserver（App级）
│       │   └── full_lifecycle_mixin.dart     # 组合版
│       └── routes/
│           └── router.dart
└── test/
    └── mixins/                       ← 新增
        ├── lifecycle_mixin_test.dart
        ├── app_lifecycle_mixin_test.dart
        └── full_lifecycle_mixin_test.dart
```

在文件末尾添加 mixins 章节：

```markdown
## Mixins

### LifecycleMixin

页面生命周期 mixin（RouteAware），监听路由事件。

```dart
import 'package:routing/routing.dart';

class _EditPageState extends State<EditPage> with LifecycleMixin<EditPage> {
  @override
  void onPageEnter() {
    context.read<EditCubit>().loadData();  // 进入页面加载
  }
  
  @override
  void onPageLeave() {
    context.read<EditCubit>().saveData();  // 离开页面保存
  }
  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(title: '编辑', body: ...);
  }
}
```

回调：
- `onPageEnter()` — 进入页面（didPush）
- `onPageLeave()` — 离开页面（didPop）
- `onPageCovered()` — 被下一个页面覆盖（didPushNext）
- `onPageRevealed()` — 下一个页面 pop，重新显示（didPopNext）

---

### AppLifecycleMixin

App 级生命周期 mixin（WidgetsBindingObserver），监听前后台切换。

```dart
import 'package:routing/routing.dart';

class _VideoPlayerPageState extends State<VideoPlayerPage> 
    with AppLifecycleMixin<VideoPlayerPage> {
  
  @override
  void onAppPaused() {
    _controller.pause();  // App 后台暂停播放
  }
  
  @override
  void onAppResumed() {
    _controller.play();   // App 前台恢复播放
  }
}
```

---

### FullLifecycleMixin

完整生命周期 mixin（组合版）。

```dart
import 'package:routing/routing.dart';

class _VideoPageState extends State<VideoPage> with FullLifecycleMixin<VideoPage> {
  @override
  void onPageEnter() { _controller.play(); }
  @override
  void onPageLeave() { _controller.pause(); }
  @override
  void onAppPaused() { _controller.pause(); }
  @override
  void onAppResumed() { _controller.play(); }
}
```

适用：视频播放器、计时器、实时数据等需要完整监听的页面。
```

- [ ] **Step 2: Commit**

```bash
git add packages/infrastructure/routing/README.md
git commit -m "docs(routing): add LifecycleMixin, AppLifecycleMixin, and FullLifecycleMixin documentation"
```

---

### Task 13: 创建 UI 层最佳实践指南文档

**Files:**
- Create: `docs/ui-lifecycle-patterns-guide.md`

- [ ] **Step 1: Create comprehensive guide**

Create file: `docs/ui-lifecycle-patterns-guide.md` with complete content covering:
- 概述
- 架构层次图
- CustomAppBar 使用说明
- AppScaffold 使用说明（简单模式 + 高级模式）
- LifecycleMixin 使用说明
- AppLifecycleMixin 使用说明
- FullLifecycleMixin 使用说明
- Mixin 选择指南表格
- 对比 iOS BaseView
- 最佳实践（Cubit 保持纯净、BlocBuilder 响应状态、组合优于继承）
- 常见问题 Q&A

```markdown
## 概述
本项目建立了一套 UI 层统一模式...

## 架构层次
UI 层（CustomAppBar / AppScaffold）→ Logic 层（LifecycleMixin）→ Infrastructure 层（AppRouteObserver）

## CustomAppBar 使用说明
...（引用头脑风暴总结中的描述）

## AppScaffold 使用说明
简单模式（80% 页面）：传 title + body
高级模式（20% 页面）：传自定义 appBar
注意：BlocBuilder 不能直接传给 appBar 参数（类型不匹配），应在 body 中使用 BlocBuilder

## LifecycleMixin 使用说明
onPageEnter / onPageLeave / onPageCovered / onPageRevealed
Cubit 通过 UI 层间接响应（UI 监听 → 调用 Cubit）

## AppLifecycleMixin 使用说明
onAppPaused / onAppResumed / onAppInactive

## FullLifecycleMixin 使用说明
组合版，适用于视频播放器、计时器等

## Mixin 选择指南
普通展示页 → AppScaffold
编辑页 → AppScaffold + LifecycleMixin
视频播放器 → AppScaffold + FullLifecycleMixin

## 对比 iOS BaseView
CustomAppBar ↔ BaseView.configureNavBar
LifecycleMixin ↔ BaseView.viewDidLoad/viewWillAppear

## 最佳实践
- Cubit 保持纯净（无 Flutter 依赖）
- BlocBuilder 管理所有 UI 状态
- 组合优于继承

## 常见问题
Q: LifecycleMixin 为什么必须放在 UI 层？
A: RouteAware 需要 BuildContext 订阅 RouteObserver

Q: AppScaffold 和 LifecycleMixin 如何一起用？
A: AppScaffold 处理 UI 结构，LifecycleMixin 处理生命周期
```

- [ ] **Step 2: Commit**

```bash
git add docs/ui-lifecycle-patterns-guide.md
git commit -m "docs: add UI layer lifecycle patterns guide"
```

---

### Task 14: 更新主 README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add UI patterns section**

在 `## 常见问题` section 前添加：

```markdown
## UI 层统一模式

本项目建立了 UI 层的统一模式，减少模板代码，提升开发效率。

### 统一导航栏（CustomAppBar）

所有页面使用 CustomAppBar widget，统一 AppBar 样式。

```dart
AppScaffold(title: '首页', body: ...)
```

### 统一页面结构（AppScaffold）

AppScaffold widget 封装 Scaffold + CustomAppBar。

**简单模式**：
```dart
AppScaffold(title: '首页', body: BlocBuilder<...>(...))
```

**高级模式**：
```dart
// ✅ 正确的动态 AppBar 用法
// 方案 A：在 body 内使用 BlocBuilder 整体控制
AppScaffold(
  title: state.isLoading ? '登录中...' : '登录',
  body: BlocBuilder<LoginCubit, LoginState>(
    builder: (context, state) {
      return switch (state) {
        LoginLoading() => const Center(child: CircularProgressIndicator()),
        LoginLoaded() => LoginContent(data: state.data),
        LoginError() => ErrorWidget(state.error),
      };
    },
  ),
)

// 方案 B（复杂场景）：使用 LifecycleMixin 更新状态变量
// 适用于需要根据 Cubit state 改变 appBar 标题的页面
```

### 统一生命周期（LifecycleMixin）

```dart
class _EditPageState extends State<EditPage> with LifecycleMixin<EditPage> {
  @override
  void onPageEnter() { context.read<EditCubit>().loadData(); }
  @override
  void onPageLeave() { context.read<EditCubit>().saveData(); }
}
```

**详细指南**：[docs/ui-lifecycle-patterns-guide.md](docs/ui-lifecycle-patterns-guide.md)
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add UI layer unified patterns section to main README"
```

---

## Final Verification Wave

### F1: Oracle Review（Goal/Constraint Verification）

- [ ] **Verify CustomAppBar/AppScaffold widgets exist**
- [ ] **Verify RouteObserver registered in GoRouter**
- [ ] **Verify LifecycleMixin works with RouteAware**
- [ ] **Verify HomePage/DetailPage/TabBPage migrated to AppScaffold**

### F2: Oracle Review（Code Quality）

- [ ] **Check no placeholders in widgets/mixins**
- [ ] **Check proper error handling in mixin dispose**
- [ ] **Check consistent naming conventions**

### F3: Oracle Review（Security）

- [ ] **Check no sensitive data in widgets**
- [ ] **Check proper lifecycle cleanup in dispose**

### F4: Hands-On QA

- [ ] **Run app and verify HomePage AppBar title**
- [ ] **Run app and verify DetailPage back button**
- [ ] **Run all widget tests**
- [ ] **Run all mixin tests**

---

## Success Criteria

✅ CustomAppBar 和 AppScaffold widget 测试通过（11 tests）
✅ HomePage、DetailPage、TabBPage 成功迁移到 AppScaffold
✅ RouteObserver 注册到 GoRouter，LifecycleMixin 可订阅
✅ LifecycleMixin、AppLifecycleMixin、FullLifecycleMixin 测试通过（9 tests）
✅ 文档更新完成（component_library README、routing README、主 README、UI patterns guide）
✅ App 正常运行，无路由错误
✅ 所有 tests pass

---

## Estimated Effort

- Phase 1（UI 组件）：2-3 hours
- Phase 2（路由基础设施）：30 minutes
- Phase 3（生命周期 Mixin）：2 hours
- Phase 4（文档更新）：1 hour

Total：5-6 hours

---

## Commit Strategy

- Phase 1: 5 commits
- Phase 2: 2 commits
- Phase 3: 3 commits
- Phase 4: 4 commits
- Total: 14 atomic commits