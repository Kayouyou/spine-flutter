# 认证模块 (Auth)

## 职责
负责用户认证和授权相关的核心功能，包括：
- 用户登录/登出流程
- Token管理和刷新
- 权限验证
- 会话状态管理

## 使用示例
```dart
// 登录示例
final authResult = await authService.login(
  username: 'user@example.com',
  password: 'password123',
);

// 检查认证状态
if (authService.isAuthenticated) {
  // 用户已登录
}

// 登出
await authService.logout();
```

## 依赖关系
- `lib/core/di` - 依赖注入
- `lib/core/utils` - 工具类
- `lib/core/constants` - 常量定义

## 性能警告
- Token刷新操作应避免频繁调用，建议使用缓存策略
- 权限验证应在后台线程执行，避免阻塞UI
