# Routing 开发指南

> 本文档说明如何在项目中新增路由。路由系统基于 GoRouter + RouteModule 模式。

## 快速参考

### 方式一：使用 Skill 自动生成（推荐）

```bash
# 在项目根目录下，与 Claude 对话时输入：
/ovsx-add-route

# 或提供参数：
{
  "route_path": "/car_detail",
  "feature_name": "car_detail",
  "needs_auth": true
}
```

Skill 会自动生成：
- GoRoute 配置
- BlocProvider 注入
- 路由守卫配置
- 提供集成指导

### 方式二：手动添加

按照以下步骤手动添加：

## Step 1：定义路由路径常量

**文件位置**：`packages/routing/lib/src/routes/app_routes.dart`

**模板**：

```dart
class XxxRoutes {
  static const base = '/xxx';
  static const detail = '$base/detail';
}
```

**命名规范**：
- 路由路径：`snake_case`（如 `/car_detail`）
- 路径参数：`:camelCase`（如 `:carId`）
- 常量名：`camelCase`（如 `detail`）

## Step 2：创建 RouteModule

**文件位置**：`packages/routing/lib/src/routes/<domain>_routes.dart`

**模板**：

```dart
import 'package:go_router/go_router.dart';
import 'package:routing/src/routes/route_module.dart';
import 'package:routing/src/routes/route_context.dart';

class XxxRouteModule extends RouteModule {
  const XxxRouteModule(super.ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: XxxRoutes.base,
        builder: (context, state) => XxxScreen(
          userRepository: ctx.userRepository,
          carRepository: ctx.carRepository,
        ),
      ),
    ];
  }
}
```

**RouteModule 抽象基类**：

```dart
abstract class RouteModule {
  final RouteContext ctx;
  const RouteModule(this.ctx);
  List<RouteBase> build();
}
```

**RouteContext**封装 7 个 Repository：
- `userRepository`
- `carRepository`
- `mapRepository`
- `ossRepository`
- `storyRepository`
- `storeRepository`
- `payRepository`

## Step 3：在 router.dart 中注册

**文件位置**：`packages/routing/lib/src/routes/router.dart`

**在 routes 数组中展开**：

```dart
...XxxRouteModule(ctx).build(),
```

**注册位置**：
- Shell 内的子路由：放在 `StatefulShellBranch.routes` 中
- 不需要底部导航的路由：放在顶级 `routes` 数组中

## Step 4：在 routes.dart 中导出

**文件位置**：`packages/routing/lib/src/routes/routes.dart`

**添加导出**：

```dart
export '<domain>_routes.dart';
```

## 路由类型

### Simple GoRoute（无参数）

```dart
GoRoute(
  path: '/xxx',
  builder: (context, state) => XxxScreen(
    repository: ctx.xxxRepository,
  ),
)
```

### GoRoute（有路径参数）

```dart
GoRoute(
  path: '/xxx/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return XxxDetailScreen(id: id);
  },
)
```

### GoRoute（有 extra 数据）

```dart
GoRoute(
  path: '/xxx',
  builder: (context, state) {
    final extra = state.extra as XxxData?;
    return XxxScreen(data: extra);
  },
)
```

### 路由守卫（需要登录）

```dart
GoRoute(
  path: '/xxx',
  redirect: (context, state) {
    final isLoggedIn = ctx.userRepository.isLoggedIn;
    if (!isLoggedIn) {
      return '/wechatSignIn';
    }
    return null; // 允许访问
  },
  builder: (context, state) => XxxScreen(),
)
```

### StatefulShellRoute（底部 Tab）

在 `router.dart` 中，4 个 Tab 分支：

```dart
StatefulShellRoute.indexedStack(
  branches: [
    StatefulShellBranch(routes: [...CarShellRouteModule(ctx).build()]),
    StatefulShellBranch(routes: [...StoryRouteModule(ctx).build()]),
    StatefulShellBranch(routes: [GoRoute(path: '/tripInfo', ...)]),
    StatefulShellBranch(routes: [...MineShellRouteModule(ctx).build()]),
  ],
)
```

## 功能域推断

从 feature_name 推断路由文件位置：

| feature_name 关键词 | domain | 路由文件 |
|---------------------|--------|---------|
| `car_` / `vehicle_` | car | `car_shell_routes.dart` |
| `story_` | story | `story_routes.dart` |
| `mine_` / `user_` | mine | `mine_shell_routes.dart` |
| `event_` | event | `event_routes_module.dart` |
| `order_` | order | `order_routes_module.dart` |
| `store_` | store | `store_routes_module.dart` |
| `fence_` | fence | `mine_detail_fence.dart` |

## 目录结构

```
packages/routing/lib/
  routing.dart                           # 包入口
  src/routes/
    routes.dart                          # 统一导出
    router.dart                          # GoRouter 配置入口
    app_routes.dart                      # 路由路径常量
    route_context.dart                   # Repository 依赖封装
    route_module.dart                    # RouteModule 抽象基类

    # Shell
    splash_screen2.dart
    tab_container_screen.dart

    # Auth
    auth_routes.dart

    # Car module
    car_shell_routes.dart
    car_add_routes.dart
    car_detail_base.dart
    car_detail_location.dart
    car_detail_settings.dart
    car_detail_fence.dart
    car_detail_share.dart

    # Event module
    event_routes_module.dart

    # Mine module
    mine_shell_routes.dart
    mine_detail_routes.dart

    # Order/Store/Station
    order_routes_module.dart
    store_routes_module.dart
    station_routes_module.dart

    # Story
    story_routes.dart
```

## 导航方法

```dart
// 跳转到指定页面
context.go('/car/detail');

// 推入新页面（可返回）
context.push('/car/detail/123');

// 带参数跳转
context.go('/car/detail/123');
context.push('/story/detail', extra: storyData);

// 返回上一页
context.pop();
```

## 相关 Skill

| Skill | 说明 |
|------|------|
| `/ovsx-add-route` | 路由配置生成器（推荐） |
| `/ovsx-create-feature` | Feature 结构创建（Cubit/State/Screen） |
| `/ovsx-add-l10n` | 国际化资源添加 |
| `/ovsx-add-test` | 测试文件生成 |
| `/ovsx-review` | 合规审查 |

**典型工作流**：

```
ovsx-create-feature → Feature 结构
    ↓
ovsx-add-route → 路由配置
    ↓
ovsx-add-l10n → 国际化资源
    ↓
ovsx-add-test → 测试文件
    ↓
ovsx-review → 合规审查
```

## 常见问题

### Q1: 页面跳转没反应？
检查：
1. 路径是否以 `/` 开头
2. 路径是否在路由配置中存在
3. 是否有拼写错误

### Q2: 如何不显示底部 Tab？
使用 `context.push()` 而不是 `context.go()`。

### Q3: 如何获取路由参数？
```dart
final carId = state.pathParameters['carId']!;
final query = state.uri.queryParameters['query'];
final extra = state.extra as XxxData?;
```

### Q4: 如何添加路由守卫？
在 GoRoute 中添加 `redirect` 函数：

```dart
GoRoute(
  path: '/xxx',
  redirect: (context, state) {
    if (!isLoggedIn) return '/wechatSignIn';
    return null;
  },
  builder: ...
)
```