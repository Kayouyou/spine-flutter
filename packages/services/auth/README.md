# auth 包

认证服务包 - 管理用户认证状态。

## 职责

提供认证能力：AuthCubit 状态管理、AuthManager 业务编排、MockAuthRepository 脚手架

## 内部结构

```
auth/
├── lib/
│   ├── auth.dart                 # 导出入口
│   └── src/
│       ├── manager.dart          # AuthManager（isLoggedIn、handleLogin）
│       ├── cubit/
│       │   ├── auth_cubit.dart   # AuthCubit（login/logout/isLoggedIn）
│       │   └── auth_state.dart   # AuthState（initial/loading/loggedIn/error）
│       ├── repository/
│       │   ├── mock_auth_repository.dart  # Mock 实现（脚手架用）
│       │   └── auth_repository_impl.dart  # 真实实现（Dio）
│       └── di/
│           └── setup.dart        # DI 注册（Singleton）
└── test/
    └── auth_cubit_test.dart      # AuthCubit 单元测试
```

## 业务服务特征

- 长期存在（app 生命周期）
- 有内部状态（isLoggedIn、AuthState）
- AuthCubit 注册为 **Singleton**（与 AuthManager 共享生命周期）

## AuthCubit

```dart
import 'package:auth/auth.dart';

final cubit = sl<AuthCubit>();
await cubit.login('user', 'pass');

// 获取登录状态
if (cubit.isLoggedIn) { ... }

// 退出
await cubit.logout();
```

## 注册方式

- AuthManager: Singleton（长期存在、有状态）
- AuthCubit: Singleton（与 AuthManager 共享生命周期）
- MockAuthRepository: Factory

## 使用

```dart
import 'package:auth/auth.dart';

// 在主 DI 设置中调用
setupAuth(sl);

// 使用
final authManager = sl<AuthManager>();
await authManager.handleLogin();
```