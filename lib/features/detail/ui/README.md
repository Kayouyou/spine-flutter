# Detail功能模块

## 职责
负责详情页功能的实现：
- 详情页布局和UI
- 详情数据展示
- 详情交互逻辑
- 详情状态管理

## 使用示例
```dart
// 详情页视图
DetailScreen(itemId: '123');

// 详情页ViewModel
final detailViewModel = context.read<DetailViewModel>();

// 加载详情数据
await detailViewModel.loadDetail('123');
```

## 依赖关系
- `lib/core/widgets` - 通用组件
- `lib/core/utils` - 工具函数
- `lib/core/di` - 依赖注入

## 性能警告
- 详情页应实现懒加载
- 大图片应使用缩略图预览
- 复杂布局应使用VirtualScrollView优化