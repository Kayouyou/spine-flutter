# 用户API模块

## 概述

本模块提供用户相关的API接口方法，通过Mixin模式混入到主Api类。

## 核心组件

### UserApiMixin

用户API混合类，提供以下方法：

| 方法 | 说明 | 需要登录 |
|------|------|---------|
| login | 用户登录 | 否 |
| getUserInfo | 获取用户信息 | 是 |
| logout | 用户登出 | 是 |
| updateUser | 更新用户信息 | 是 |

## 使用方法

```dart
// 在Api类中混入
class Api extends ApiBase with UserApiMixin, HomeApiMixin, OrderApiMixin {
  // ...
}

// 调用API方法
final api = Api(userTokenSupplier: ...);

// 登录
final loginResult = await api.login(username: 'user', password: 'pass');

// 获取用户信息
final userInfo = await api.getUserInfo();

// 更新用户信息
await api.updateUser({'nickname': '新昵称'});

// 登出
await api.logout();
```

## 设计原则

1. **Mixin模式**：灵活组合，按需混入
2. **统一错误处理**：fireInternal自动转换为DomainException
3. **参数自动过滤**：null和空字符串自动过滤

## 错误处理

所有方法通过fireInternal执行，异常自动转换为DomainException：
- 网络错误 → ErrorCode.networkError
- 业务错误 → ErrorCode.serverError
- 未登录错误 → ErrorCode.tokenExpired