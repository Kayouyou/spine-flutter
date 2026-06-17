# UI 层生命周期模式指南

本项目建立了一套 UI 层统一模式，统一页面结构、导航栏样式和生命周期管理。

## 架构层次

```
┌─────────────────────────────────────────────────────┐
│                    UI 层                            │
│    CustomAppBar / AppScaffold（页面结构 + 导航栏）   │
├─────────────────────────────────────────────────────┤
│                  Logic 层                           │
│     LifecycleMixin（页面级） / AppLifecycleMixin（App 级）│
├─────────────────────────────────────────────────────┤
│               Infrastructure 层                     │
│            AppRouteObserver（路由观察者）             │
└─────────────────────────────────────────────────────┘
```

- **UI 层**：CustomAppBar、AppScaffold 负责页面结构和导航栏
- **Logic 层**：LifecycleMixin 系列负责生命周期回调
- **Infrastructure 层**：AppRouteObserver 单例管理路由订阅

---

## CustomAppBar 使用说明

统一导航栏 Widget，所有页面复用。实现 `PreferredSizeWidget` 接口。

```dart
import 'package:component_library/component_library.dart';

CustomAppBar(
  title: '首页',
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () {},
    ),
  ],
  showBackButton: true,
  leading: const BackButton(),
  elevation: 0,
  backgroundColor: Theme.of(context).colorScheme.surface,
)
```

### 参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `title` | `String` | 是 | - | 导航栏标题 |
| `actions` | `List<Widget>` | 否 | `null` | 右侧按钮列表 |
| `showBackButton` | `bool` | 否 | `true` | 是否显示返回按钮 |
| `leading` | `Widget` | 否 | `null` | 自定义左侧 widget（优先级高于 showBackButton） |
| `elevation` | `double` | 否 | `0` | 阴影高度 |
| `backgroundColor` | `Color` | 否 | `null` | 背景色（默认跟随主题） |

---

## AppScaffold 使用说明

统一页面结构 Widget，封装 Scaffold + CustomAppBar，提供两种使用模式。

### 简单模式（80% 页面）

传 `title` 参数，自动生成标准 AppBar。

```dart
import 'package:component_library/component_library.dart';

AppScaffold(
  title: '首页',
  body: Center(
    child: Text('页面内容'),
  ),
  actions: [
    IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
  ],
)
```

### 高级模式（20% 页面）

传 `appBar` 参数，完全自定义 AppBar。

```dart
import 'package:component_library/component_library.dart';

AppScaffold(
  appBar: CustomAppBar(
    title: '自定义标题',
    actions: [...],
  ),
  body: BlocBuilder<SomeCubit, SomeState>(
    builder: (context, state) {
      return Text('内容：${state.value}');
    },
  ),
)
```

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `title` | `String` | 二选一 | 标题（简单模式） |
| `appBar` | `PreferredSizeWidget` | 二选一 | 自定义 AppBar（高级模式） |
| `body` | `Widget` | 是 | 页面内容 |
| `actions` | `List<Widget>` | 否 | 右侧按钮（仅简单模式生效） |
| `showBackButton` | `bool` | 否 | 是否显示返回按钮（默认 true） |
| `floatingActionButton` | `Widget` | 否 | 悬浮按钮 |
| `backgroundColor` | `Color` | 否 | 页面背景色 |
| `bottomNavigationBar` | `Widget` | 否 | 底部导航栏 |
| `resizeToAvoidBottomInset` | `bool` | 否 | 键盘弹出时是否调整布局 |

### 重要注意

**BlocBuilder 不能直接传给 appBar 参数**（类型不匹配）。应在 body 中使用 BlocBuilder：

```dart
// 错误
AppScaffold(
  appBar: BlocBuilder<SomeCubit, SomeState>(
    builder: (context, state) => CustomAppBar(title: state.title),
  ),  // ❌ 类型不匹配
)

// 正确
AppScaffold(
  title: '标题',  // 静态标题
  body: BlocBuilder<SomeCubit, SomeState>(
    builder: (context, state) {
      return Column(
        children: [
          // 动态内容
          Text(state.title),
        ],
      );
    },
  ),
)
```

---

## LifecycleMixin 使用说明

页面级生命周期 mixin（实现 `RouteAware`），监听路由事件。

```dart
import 'package:flutter/material.dart';
import 'package:routing/routing.dart';

class EditPageState extends State<EditPage> with LifecycleMixin<EditPage> {
  
  @override
  void onPageEnter() {
    // 页面进入时调用
    context.read<EditCubit>().loadData();
  }
  
  @override
  void onPageLeave() {
    // 页面离开时调用
    context.read<EditCubit>().saveData();
  }
  
  @override
  void onPageCovered() {
    // 被下一个页面覆盖时调用
  }
  
  @override
  void onPageRevealed() {
    // 下一个页面 pop，重新显示时调用
  }
  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '编辑',
      body: ...,
    );
  }
}
```

### 回调说明

| 回调 | 触发时机 | 适用场景 |
|------|----------|----------|
| `onPageEnter()` | 页面首次显示（didPush） | 加载数据、初始化 |
| `onPageLeave()` | 页面离开（didPop） | 保存数据、清理资源 |
| `onPageCovered()` | 被新页面覆盖（didPushNext） | 暂停播放、停止轮询 |
| `onPageRevealed()` | 重新显示（didPopNext） | 恢复状态、刷新数据 |

### Cubit 响应方式

Cubit 保持纯净（无 Flutter 依赖），通过 UI 层间接响应：

```dart
class EditPageState extends State<EditPage> with LifecycleMixin<EditPage> {
  
  @override
  void onPageEnter() {
    // UI 层监听页面进入，调用 Cubit
    context.read<EditCubit>().loadData();
  }
  
  @override
  Widget build(BuildContext context) {
    // BlocBuilder 响应 Cubit 状态变化
    return BlocBuilder<EditCubit, EditState>(
      builder: (context, state) {
        return AppScaffold(
          title: '编辑',
          body: ...,
        );
      },
    );
  }
}
```

---

## AppLifecycleMixin 使用说明

App 级生命周期 mixin（实现 `WidgetsBindingObserver`），监听 App 前后台切换。

```dart
import 'package:flutter/material.dart';
import 'package:routing/routing.dart';

class VideoPlayerPageState extends State<VideoPlayerPage> 
    with AppLifecycleMixin<VideoPlayerPage> {
  
  @override
  void onAppPaused() {
    // App 进入后台时调用
    _controller.pause();
  }
  
  @override
  void onAppResumed() {
    // App 从后台返回时调用
    _controller.play();
  }
  
  @override
  void onAppInactive() {
    // App 进入非活跃状态时调用（如来电、切换 App）
  }
  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '视频播放',
      body: ...,
    );
  }
}
```

### 回调说明

| 回调 | 触发时机 | 适用场景 |
|------|----------|----------|
| `onAppPaused()` | App 进入后台 | 暂停视频、停止计时器、保存状态 |
| `onAppResumed()` | App 从后台返回 | 恢复播放、重新连接 |
| `onAppInactive()` | App 进入非活跃状态 | 暂停实时更新 |

---

## FullLifecycleMixin 使用说明

完整生命周期 mixin（组合 `LifecycleMixin` + `AppLifecycleMixin`），同时监听路由事件和 App 前后台切换。

适用于：视频播放器、计时器、实时数据监控等需要完整生命周期管理的场景。

```dart
import 'package:flutter/material.dart';
import 'package:routing/routing.dart';

class VideoPageState extends State<VideoPage> with FullLifecycleMixin<VideoPage> {
  
  // 页面级生命周期
  @override
  void onPageEnter() {
    _controller.play();
  }
  
  @override
  void onPageLeave() {
    _controller.pause();
  }
  
  @override
  void onPageCovered() {
    _controller.pause();
  }
  
  @override
  void onPageRevealed() {
    _controller.play();
  }
  
  // App 级生命周期
  @override
  void onAppPaused() {
    _controller.pause();
  }
  
  @override
  void onAppResumed() {
    _controller.play();
  }
  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '视频',
      body: ...,
    );
  }
}
```

---

## Mixin 选择指南

| 页面类型 | 推荐模式 | 说明 |
|----------|----------|------|
| 普通展示页 | `AppScaffold` | 只需统一结构和导航栏，无需生命周期 |
| 需要加载/保存的编辑页 | `AppScaffold` + `LifecycleMixin` | 监听页面进入/离开 |
| 视频播放器 | `AppScaffold` + `FullLifecycleMixin` | 监听页面 + App 前后台 |
| 实时数据页面 | `AppScaffold` + `FullLifecycleMixin` | 页面覆盖时暂停，后台时断开 |
| 计时器页面 | `AppScaffold` + `FullLifecycleMixin` | 离开页面/进入后台时暂停 |

### 快速选择流程

```
需要监听生命周期？
  │
  ├─ 否 → AppScaffold（简单/高级模式）
  │
  └─ 是 → 需要监听 App 前后台？
            │
            ├─ 否 → LifecycleMixin（页面级）
            │
            └─ 是 → FullLifecycleMixin（完整版）
```

---

## 对比 iOS BaseView

| Flutter 组件 | iOS BaseView | 说明 |
|--------------|--------------|------|
| `CustomAppBar` | `BaseView.configureNavBar()` | 统一导航栏样式 |
| `LifecycleMixin` | `BaseView.viewDidLoad()` | 页面加载时调用 |
| `LifecycleMixin` | `BaseView.viewWillAppear()` | 页面进入 |
| `LifecycleMixin` | `BaseView.viewDidDisappear()` | 页面离开 |
| `AppLifecycleMixin` | `AppDelegate.applicationDidBecomeActive()` | App 进入前台 |
| `AppLifecycleMixin` | `AppDelegate.applicationWillResignActive()` | App 进入后台 |

---

## 最佳实践

### 1. Cubit 保持纯净

Cubit 应该是纯 Dart 类，不依赖 Flutter。业务逻辑放在 Cubit 中，UI 响应通过 BlocBuilder。

```dart
// ✅ 正确：Cubit 是纯 Dart
class EditCubit extends Cubit<EditState> {
  final EditRepository _repository;
  
  EditCubit(this._repository) : super(const EditState());
  
  Future<void> loadData() async { ... }
  Future<void> saveData() async { ... }
}

// ❌ 错误：Cubit 依赖 Flutter（不要这样做）
class EditCubit extends Cubit<EditState> {
  Future<void> loadData(BuildContext context) async { 
    // 不要传 BuildContext
  }
}
```

### 2. BlocBuilder 响应状态

所有 UI 状态变化通过 BlocBuilder 响应，保持单向数据流。

```dart
// ✅ 正确
BlocBuilder<SomeCubit, SomeState>(
  builder: (context, state) {
    if (state.isLoading) return CircularProgressIndicator();
    return Text(state.data);
  },
)
```

### 3. 组合优于继承

使用 Mixin 组合而非继承，保持类层次扁平。

```dart
// ✅ 正确：组合模式
class VideoPageState extends State<VideoPage> 
    with FullLifecycleMixin<VideoPage> { ... }

// ❌ 避免：深层继承
class VideoPageState extends BaseVideoState with VideoLifecycle { ... }
```

### 4. 职责分离

- **AppScaffold**：处理 UI 结构（标题、导航栏、背景）
- **LifecycleMixin**：处理生命周期（加载、清理）
- 各自独立，互不干扰

---

## 常见问题 Q&A

### Q: LifecycleMixin 为什么必须放在 UI 层？

A: `RouteAware` 需要 `BuildContext` 来订阅 `RouteObserver`。UI 层的 `State` 类才有 `BuildContext`，因此 LifecycleMixin 必须 mixin 到 `State` 类上。

```dart
// ✅ 正确：mixin 到 State
class _PageState extends State<Page> with LifecycleMixin<Page> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 需要 BuildContext 订阅 RouteObserver
    AppRouteObserver.instance.subscribe(this, ModalRoute.of(context)!);
  }
}

// ❌ 错误：无法获取 BuildContext
mixin LifecycleMixin on Cubit { ... }
```

### Q: AppScaffold 和 LifecycleMixin 如何一起用？

A: AppScaffold 处理 UI 结构，LifecycleMixin 处理生命周期，职责分离。

```dart
class EditPageState extends State<EditPage> with LifecycleMixin<EditPage> {
  
  @override
  void onPageEnter() {
    context.read<EditCubit>().loadData();  // 页面进入加载
  }
  
  @override
  void onPageLeave() {
    context.read<EditCubit>().saveData();  // 页面离开保存
  }
  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '编辑',
      body: BlocBuilder<EditCubit, EditState>(
        builder: (context, state) => ...,
      ),
    );
  }
}
```

### Q: 什么时候用 LifecycleMixin vs AppLifecycleMixin？

A: 
- `LifecycleMixin`：监听页面路由变化（进入、离开、被覆盖、重新显示）
- `AppLifecycleMixin`：监听 App 前后台切换

场景：
- 页面数据加载 → `LifecycleMixin.onPageEnter()`
- App 切换到后台 → `AppLifecycleMixin.onAppPaused()`

### Q: 可以同时使用 LifecycleMixin 和 AppLifecycleMixin 吗？

A: 可以，但更推荐直接使用 `FullLifecycleMixin`（组合版），避免重复代码。

```dart
// 两种方式等效
class PageState extends State<Page> 
    with LifecycleMixin<Page>, AppLifecycleMixin<Page> { ... }

// 推荐：使用组合版
class PageState extends State<Page> with FullLifecycleMixin<Page> { ... }
```

### Q: BlocBuilder 不能传给 appBar 参数怎么办？

A: 如需动态 AppBar，使用简单模式 + body 中的 BlocBuilder，或在 body 中构建包含 AppBar 的复杂结构。

```dart
// 方案 1：简单模式 + body
AppScaffold(
  title: '标题',
  body: BlocBuilder<...>(builder: (context, state) {
    return Column(
      children: [
        // 动态内容区域
      ],
    );
  }),
)

// 方案 2：高级模式 + 静态 AppBar
AppScaffold(
  appBar: CustomAppBar(title: '静态标题'),
  body: BlocBuilder<...>(...),
)
```

---

## 相关文档

- [component_library 组件库](../infrastructure/component_library/README.md)
- [routing 路由模块](../infrastructure/routing/README.md)
- [路由守卫文档](./auth-route-guard.md)
