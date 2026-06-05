# Alice 调试面板端内可见入口 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 app 端内添加一个可见的调试面板入口按钮，点击后打开 Alice HTTP Inspector 界面。

**Architecture:** 在首页 AppBar 的 actions 区域添加一个 debug 图标按钮（仅 kDebugMode 可见），点击调用 `Alice.showInspector()` 打开 inspector 页面。Alice 实例通过已注册的 GetIt singleton 获取。

**Tech Stack:** Flutter, Alice, GetIt (Service Locator), feature_home

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `packages/features/feature_home/lib/src/ui/home_page.dart:24-29` | 在 AppBar actions 中添加 debug 入口按钮（仅 debug 模式）|

这就是全部。只需修改一个文件一个位置。Alice 已经:
- ✅ 在 `setup.dart:32-37` 注册为 GetIt singleton
- ✅ 在 `dio_factory.dart:85-87` 作为 interceptor 接入 Dio
- ✅ 在 `app.dart:58-61` 设置了 navigatorKey

只需添加入口按钮即可。

---

### Task 1: 在首页添加调试面板入口按钮

**Files:**
- Modify: `packages/features/feature_home/lib/src/ui/home_page.dart:24-29`

当前 actions 区域只有一个刷新按钮：

```dart
actions: [
  // 刷新按钮
  IconButton(
    icon: const Icon(Icons.refresh),
    onPressed: () => context.read<HomeCubit>().refreshData(),
  ),
],
```

**目标：** 在刷新按钮后方添加一个调试面板按钮，仅 debug 模式可见。

**修改后的 actions 区域：**

```dart
actions: [
  // 刷新按钮
  IconButton(
    icon: const Icon(Icons.refresh),
    onPressed: () => context.read<HomeCubit>().refreshData(),
    tooltip: '刷新',
  ),
  // 调试面板按钮（仅 Debug 模式）
  if (kDebugMode)
    IconButton(
      icon: const Icon(Icons.bug_report),
      onPressed: () {
        final alice = GetIt.instance<Alice>();
        alice.showInspector();
      },
      tooltip: '调试面板',
    ),
],
```

- [ ] **Step 1: 确认当前 actions 区域代码**

读取 `packages/features/feature_home/lib/src/ui/home_page.dart` 确认 actions 区域在 `AppScaffold` 的构建中（约 lines 24-29）。该文件已有 `import 'package:get_it/get_it.dart';`，无需再添加 import。只需要添加 `import 'package:flutter/foundation.dart';` 以获取 `kDebugMode`。

- [ ] **Step 2: 添加 kDebugMode import**

在 `home_page.dart` 文件头部的 imports 中添加：

```dart
import 'package:flutter/foundation.dart';
```

放在 `import 'package:flutter/material.dart';` 之后即可。

- [ ] **Step 3: 修改 actions 区域**

将 actions 从：

```dart
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HomeCubit>().refreshData(),
          ),
        ],
```

改为：

```dart
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HomeCubit>().refreshData(),
            tooltip: '刷新',
          ),
          // 调试面板按钮（仅 Debug 模式）
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                final alice = GetIt.instance<Alice>();
                alice.showInspector();
              },
              tooltip: '调试面板',
            ),
        ],
```

**注意：** Alice import 不需要添加 — `home_page.dart` 不直接 import `package:alice/alice.dart`。GetIt 通过类型查找已注册的实例，运行时 `Alice` 类型已在 setup.dart 中注册。但为了让 `GetIt.instance<Alice>()` 的类型引用有效，**需要**添加：

```dart
import 'package:alice/alice.dart';
```

在 imports 区域添加此 import。

- [ ] **Step 4: 验证编译**

运行：
```bash
cd /Users/yeyangyang/Desktop/spine_flutter && make lint
```

预期：无 error，通过静态分析。

- [ ] **Step 5: 运行应用验证**

运行：
```bash
make debug-simulator
```

验证：
1. 首页 AppBar 右侧出现 🐛 (bug_report) 图标（仅 debug 模式）
2. 点击图标，打开 Alice Inspector 页面
3. Inspector 中能看到 HTTP 请求记录
4. Release 模式（不验证，理论上 kDebugMode 条件保证不显示）

- [ ] **Step 6: 提交**

```bash
git add packages/features/feature_home/lib/src/ui/home_page.dart
git commit -m "feat: add Alice debug inspector entry button on home page"
```

---

## Definition of Done

- [ ] `home_page.dart` actions 区域包含 debug 按钮（`if (kDebugMode)` 条件包裹）
- [ ] debug 按钮点击调用 `GetIt.instance<Alice>().showInspector()`
- [ ] `make lint` 通过（无 error）
- [ ] 应用运行后首页可见调试按钮
- [ ] 点击按钮能打开 Alice Inspector
