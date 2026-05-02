# 启动模块 (Startup)

## 职责
负责应用启动流程的初始化和配置：
- 应用初始化序列
- 启动画面管理
- 配置加载
- 启动依赖检查

## 使用示例
```dart
// 初始化启动流程
await StartupManager.initialize();

// 检查启动状态
if (StartupManager.isReady) {
  // 启动完成，显示主界面
}

// 获取启动配置
final config = StartupManager.config;
```

## 依赖关系
- `lib/core/di` - 服务初始化
- `lib/core/utils` - 配置工具
- `packages/infrastructure/` - 配置常量（已迁移至独立 package）

## 性能警告
- 启动任务应按优先级排序
- 避免在启动流程中进行网络请求
- 使用延迟加载优化启动时间
