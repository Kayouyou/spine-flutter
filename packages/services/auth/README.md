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
│       │   ├── auth_cubit.dart   # AuthCubit（login/logout/isLoggedIn/setAuthState）
│       │   └── auth_state.dart   # AuthState（initial/loading/loggedIn/error）
│       ├── repository/
│       │   ├── mock_auth_repository.dart  # Mock 实现（脚手架用，release 必删）
│       │   └── auth_repository_impl.dart  # 真实实现（Dio）
│       └── di/
│           └── setup.dart        # setupAuth(GetIt, {useMock = kDebugMode})
└── test/
    ├── auth_cubit_test.dart          # AuthCubit 业务流单元测试
    ├── auth_test.dart                # AuthManager 集成测试
    ├── auth_cubit_singleton_test.dart  # AuthCubit lazySingleton 验证
    └── auth_repository_factory_test.dart  # setupAuth useMock flag + fail-fast
```

## 业务服务特征

- 长期存在（app 生命周期）
- 有内部状态（isLoggedIn、AuthState）
- AuthCubit 注册为 **lazySingleton**（与 AuthManager 共享生命周期，懒构造避免启动期副作用）

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

- AuthManager: lazySingleton（长期存在、有状态）
- AuthCubit: lazySingleton（与 AuthManager 共享生命周期，懒构造）
- MockAuthRepository: Factory（仅 debug 模式自动注册）
- UserRepository: lazySingleton（Dio 实现）

## 使用

```dart
import 'package:auth/auth.dart';

// 在主 DI 设置中调用
setupAuth(sl);                          // debug 默认 useMock = kDebugMode
setupAuth(sl, useMock: false);          // release 模式, 必须先注册真 AuthRepository
//   sl.registerSingleton<AuthRepository>(RestAuthRepository(sl()));

// 使用
final authManager = sl<AuthManager>();
await authManager.handleLogin();
```

## AuthCubit 写入权威

`AuthCubit.setAuthState(AuthState)` 是**唯一**外部写入入口（仅 `AuthManager` 可调）。
`loggedIn(userId)` public mutator 已删除 — 它允许任意模块直接 emit，制造 AuthCubit/AuthManager 双真相源。
所有状态变化必须经 `AuthManager` 流过来。