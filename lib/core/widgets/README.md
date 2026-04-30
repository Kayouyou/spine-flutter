# 通用组件模块

## 职责
提供跨Feature共享的通用UI组件。

## 组件列表

### RequestScope
请求范围管理Widget，自动取消页面退出后的请求。

```dart
RequestScope(
  tag: 'detail_page',
  child: DetailContent(),
)
```

### NetworkBanner（Phase 3.3）
网络状态提示Banner。

## 使用示例
```dart
// 在页面顶层包装
RequestScope(
  tag: 'home_page',
  child: BlocProvider(
    create: (context) => HomeCubit()..loadData(),
    child: HomePageContent(),
  ),
)
```

## 依赖关系
- api: CancelTokenManager
- flutter_bloc（部分组件）

## 性能警告
- RequestScope仅管理请求取消，不影响UI渲染性能
- 避免过度嵌套Stack层叠