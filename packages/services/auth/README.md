# auth 包

认证服务包 - 管理用户认证状态。

## 职责

提供认证能力：handleLogin、login、logout、checkTokenValid

## 业务服务特征

- 长期存在（app 生命周期）
- 有内部状态（isLoggedIn、_token）

## 注册方式

Singleton（长期存在、有状态）

## 使用

```dart
import 'package:auth/auth.dart';

// 在主 DI 设置中调用
setupAuth(sl);

// 使用
final authManager = sl<AuthManager>();
await authManager.handleLogin();
```