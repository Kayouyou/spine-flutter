# 通用组件模块 (Widgets)

## 职责
提供应用通用的UI组件：
- 按钮组件
- 输入组件
- 加载指示器
- 错误提示组件
- 网络状态组件

## 使用示例
```dart
// 使用通用按钮
PrimaryButton(
  text: '提交',
  onPressed: () => handleSubmit(),
);

// 使用加载指示器
LoadingIndicator(size: 24);

// 使用错误提示
ErrorWidget(
  message: '加载失败',
  onRetry: () => retry(),
);
```

## 依赖关系
- `lib/core/constants` - 样式常量
- `lib/core/utils` - 工具函数

## 性能警告
- 列表项组件应使用const构造函数
- 避免频繁重建复杂组件
- 使用RepaintBoundary优化重绘范围