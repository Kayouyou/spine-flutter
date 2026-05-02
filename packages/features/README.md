# features 目录

业务功能包的组织目录。

## 目录下有哪些包

- feature_home/ - 首页功能
- feature_detail/ - 详情页功能

## 如何跳转到其他 feature

不要直接 import 其他 feature，通过 routing 包跳转：

```dart
// ✗ 错误做法
import 'package:feature_detail/feature_detail.dart';

// ✓ 正确做法：通过 routing 包
import 'package:routing/routing.dart';
context.go(AppRouter.detailPath(id: '123'));
```

## 如何获取全局数据

通过 domain 层获取用户信息等共享数据：

```dart
import 'package:domain/domain.dart';

// Widget 层
final user = context.watch<UserCubit>().state;
if (user is UserLoaded) {
  return Avatar(user.profile.avatar);
}

// Cubit 层（构造函数注入）
class HomeCubit {
  final UserCubit _user;  // 注入全局状态
}
```

## 添加新 feature

1. 创建 packages/features/feature_<name>/ 目录
2. 创建 pubspec.yaml + barrel file + 内部结构
3. 创建 README.md
4. routing 包添加路由
5. 主 app 添加依赖并调用 setup

## 约定

- 每个 feature 独立 package
- feature 之间不直接依赖
- 页面级 Cubit 注册为 Factory