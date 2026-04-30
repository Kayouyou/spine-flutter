# 常量模块 (Constants)

## 职责
定义应用全局常量和配置值：
- API端点配置
- 应用配置常量
- 资源路径常量
- 枚举定义

## 使用示例
```dart
// 使用API端点
final url = ApiConstants.baseUrl + ApiEndpoints.login;

// 使用应用配置
final appName = AppConstants.appName;
final version = AppConstants.version;

// 使用资源路径
final iconPath = AssetPaths.icons.home;
```

## 依赖关系
- 无外部模块依赖，作为基础配置模块

## 性能警告
- 常量在编译时确定，无性能问题
- 避免在常量类中存储大量数据