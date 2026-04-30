# GoRouter 防抖拦截器使用指南

## 📊 问题背景

快速点击路由跳转按钮时，会触发多次路由跳转，导致：
- 页面被推入多次
- 导航栈混乱
- 用户看到多次页面跳转

## ✅ 解决方案：DebouncedGoRouter

### 🎯 核心优势

| 特性 | 说明 |
|------|------|
| **零修改** | ✅ 无需修改现有的路由调用代码 |
| **全局生效** | ✅ 自动拦截所有 `context.go()` / `context.push()` |
| **智能防抖** | ✅ 只对相同路径防抖，不同路径正常跳转 |
| **可配置** | ✅ 可调整防抖时间间隔 |
| **无侵入** | ✅ 不影响现有业务逻辑 |
| **稳定可靠** | ✅ 基于 GoRouter 子类实现，兼容性好 |

---

## 🚀 工作原理

```
用户点击按钮
   ↓
调用 context.go('/home')
   ↓
DebouncedGoRouter.go() 拦截
   ↓
检查是否与上次路径相同
   ↓
路径不同 → ✅ 直接执行跳转
   ↓
路径相同 → 检查时间间隔
   ↓
间隔 < 300ms → 🚫 拦截，不执行
间隔 >= 300ms → ✅ 执行跳转
```

---

## 📝 使用方法

### 方法一：直接使用 DebouncedGoRouter（推荐）

在 `packages/routing/lib/src/routes/router.dart` 中：

```dart
import 'package:component_library/component_library.dart';

static GoRouter getRouter({...}) {
  // 使用 DebouncedGoRouter 替代普通 GoRouter
  router = DebouncedGoRouter(
    debounceMs: 300,  // 防抖时间，默认 300ms
    initialLocation: '/mine',
    observers: [AnalyticsObserver(userRepository: userRepository)],
    redirect: (context, state) async {
      // ... 原有重定向逻辑不变
    },
    routes: [
      // ... 原有路由配置不变
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
  );
  return router;
}
```

### 方法二：使用 GoRouterDebounceInterceptor 静态方法

```dart
// 在任何地方手动检查是否允许导航
if (GoRouterDebounceInterceptor.shouldAllowNavigation('/home')) {
  // 执行导航
}

// 重置防抖状态（强制允许下次导航）
GoRouterDebounceInterceptor.reset();

// 运行时调整防抖时间
GoRouterDebounceInterceptor.setDebounceMs(500);
```

---

## ⚙️ 配置选项

### DebouncedGoRouter 构造函数参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `debounceMs` | int | 300 | 防抖时间（毫秒） |
| `debugLog` | bool? | kDebugMode | 是否启用调试日志 |
| 其他参数 | - | - | 与 GoRouter 完全相同 |

### 调整防抖时间

```dart
// 创建时设置
router = DebouncedGoRouter(
  debounceMs: 500,  // 500ms 防抖
  routes: [...],
);

// 运行时调整
GoRouterDebounceInterceptor.setDebounceMs(500);
```

---

## 📊 防抖行为详解

### 同路径防抖

```dart
// 第一次点击：允许
context.go('/home');  // ✅ 执行

// 100ms 后再次点击同一路径：拦截
context.go('/home');  // 🚫 拦截（间隔 < 300ms）

// 400ms 后再次点击同一路径：允许
context.go('/home');  // ✅ 执行（间隔 >= 300ms）
```

### 不同路径不防抖

```dart
// 连续跳转不同路径：全部允许
context.go('/home');     // ✅ 执行
context.go('/profile');  // ✅ 执行（路径不同）
context.go('/settings'); // ✅ 执行（路径不同）
```

### 命名路由同样生效

```dart
// 命名路由也会防抖
context.goNamed('home');        // ✅ 执行
context.goNamed('home');        // 🚫 拦截（300ms 内）
context.pushNamed('profile');   // ✅ 执行（路径不同）
```

---

## 📊 性能影响

| 指标 | 数值 |
|------|------|
| 内存开销 | < 1KB（静态变量） |
| CPU 开销 | 可忽略（一次时间比较） |
| 延迟增加 | 0ms（防抖是阻止跳转，不增加延迟） |
| 对不同路径的影响 | 无（直接执行） |

---

## 🐛 调试日志

开发模式下会自动输出防抖日志：

```
🛡️ GoRouterDebounceInterceptor 已初始化，防抖时间：300ms
✅ 允许路由跳转：/home
🚫 拦截重复路由：/home (间隔：100ms < 300ms)
✅ 允许路由跳转（不同路径）：/profile
```

生产模式下默认关闭日志，可通过 `debugLog: false` 强制关闭。

---

## 🔧 扩展方法（可选）

```dart
// 使用扩展方法手动防抖
context.debouncedGo('/home');
context.debouncedPush('/detail');

// 强制导航（忽略防抖）
context.forceGo('/home');
context.forcePush('/detail');
```

---

## ⚠️ 注意事项

### 1. 防抖时间选择

- **推荐**：300ms（适合大多数场景）
- **保守**：500ms（更严格防抖）
- **激进**：200ms（更灵敏）

### 2. 特殊场景处理

```dart
// 如果某个操作需要强制导航（不受防抖限制）
context.forceGo('/important-page');

// 或者在导航前重置
GoRouterDebounceInterceptor.reset();
context.go('/important-page');
```

### 3. 与原有代码兼容

所有原有的路由调用代码无需修改，自动获得防抖功能：
- `context.go('/path')` ✅
- `context.push('/path')` ✅
- `context.goNamed('name')` ✅
- `context.pushNamed('name')` ✅
- `router.go('/path')` ✅
- `router.push('/path')` ✅

---

## 🆚 与其他方案对比

| 方案 | 修改量 | 全局生效 | 智能防抖 | 稳定性 | 推荐度 |
|------|--------|----------|----------|--------|--------|
| **DebouncedGoRouter** | ⭐ 0 处 | ✅ 是 | ✅ 是 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 防抖按钮组件 | ⚠️ 需替换按钮 | ❌ 否 | ❌ 否 | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 手动检查 location | ⚠️ 300+ 处 | ❌ 否 | ❌ 否 | ⭐⭐⭐⭐⭐ | ⭐⭐ |

---

## 📚 技术实现

### 核心类

1. **GoRouterDebounceInterceptor** - 静态工具类
   - 管理防抖状态
   - 提供防抖检查方法
   - 可运行时调整参数

2. **DebouncedGoRouter** - GoRouter 子类
   - 重写 `go()`, `push()`, `goNamed()`, `pushNamed()` 等方法
   - 在调用前检查防抖状态
   - 其他方法透传给父类

3. **DebouncedNavigationExtension** - BuildContext 扩展
   - 提供手动防抖导航方法
   - 提供强制导航方法

---

**版本**: v2.0.0 | **更新时间**: 2025-03-03 | **作者**: Sisyphus