# 依赖注入模块 (DI)

## 职责
负责应用的依赖注入管理，提供统一的服务注册和获取机制：
- 服务注册和绑定
- 单例管理
- 工厂模式支持
- 生命周期管理

## 使用示例
```dart
// 注册单例服务
di.registerSingleton<ApiService>(ApiService());

// 注册工厂服务
di.registerFactory<Repository>(() => RepositoryImpl());

// 获取服务实例
final apiService = di.get<ApiService>();
```

## 依赖关系
- 无外部模块依赖，作为基础设施模块

## 性能警告
- 避免在循环中频繁获取实例，建议缓存引用
- 懒加载服务应在合适的时机预初始化