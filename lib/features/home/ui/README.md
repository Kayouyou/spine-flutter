# Home功能模块

## 职责
负责应用首页功能的实现：
- 首页布局和UI
- 首页数据展示
- 首页交互逻辑
- 首页状态管理

## 使用示例
```dart
// 首页视图
HomeScreen();

// 首页ViewModel
final homeViewModel = context.read<HomeViewModel>();

// 刷新首页数据
await homeViewModel.refresh();
```

## 依赖关系
- `lib/core/widgets` - 通用组件
- `lib/core/utils` - 工具函数
- `lib/core/di` - 依赖注入

## 性能警告
- 列表数据应实现分页加载
- 图片资源应使用缓存
- 避免首页初始化时加载过多数据
