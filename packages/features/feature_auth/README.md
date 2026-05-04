# feature_auth 包

Login/Register 脚手架模块 - 演示认证页面流程。

## 职责

提供登录和注册示例页面，展示路由守卫 + redirect 跳转流程。**无真实 API，仅用于开发调试。**

## 内部结构

```
feature_auth/
├── pubspec.yaml
├── lib/
│   ├── feature_auth.dart           # 导出入口
│   └── src/
│       ├── cubit/
│       │   ├── login_cubit.dart    # LoginCubit（login/reset）
│       │   └── login_state.dart    # LoginState（initial/loading/success/error）
│       ├── repository/
│       │   ├── auth_repository.dart       # AuthRepository 抽象接口
│       │   └── mock_auth_repository.dart  # Mock 实现（延迟模拟）
│       ├── ui/
│       │   ├── login_page.dart     # 登录页面（支持 redirect）
│       │   └── register_page.dart  # 注册页面（支持 redirect）
│       └── di/
│           └── setup.dart          # DI 注册（Factory）
└── test/
    └── login_cubit_test.dart       # LoginCubit 单元测试
```

## 使用

```dart
import 'package:feature_auth/feature_auth.dart';

// 路由已自动注册，直接访问
// /login?redirect=/settings
// /register?redirect=/home
```

## 注册方式

- LoginCubit: **Factory**（页面级，每次创建新实例）
- MockAuthRepository: Factory

## 依赖

- `component_library` - UI 组件
- `routing` - 路由导航（GoRouter）
- `flutter_bloc` - 状态管理
- `equatable` - 值比较
