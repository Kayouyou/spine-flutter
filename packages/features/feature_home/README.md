# feature_home 包

首页功能模块 — 展示应用首页内容和导航。

## 内部结构

```
feature_home/
├── pubspec.yaml
├── lib/
│   ├── feature_home.dart           # 导出入口
│   └── src/
│       ├── cubit/
│       │   ├── home_cubit.dart     # HomeCubit（状态管理）
│       │   └── home_state.dart     # HomeState
│       ├── repository/
│       │   └── home_repository.dart # HomeRepository（数据访问）
│       ├── ui/
│       │   └── home_page.dart      # HomePage（首页 UI）
│       ├── models/                 # 页面专用模型
│       └── di/
│           └── setup.dart          # DI 注册
└── test/
    ├── home_cubit_test.dart        # HomeCubit 测试
    └── home_page_test.dart         # HomePage Widget 测试
```

## 依赖

| 依赖 | 用途 |
|------|------|
| `api` | Dio HTTP 请求 |
| `routing` | GoRouter 导航 |
| `component_library` | 共享 UI 组件 |
| `domain` | 领域模型 |
| `auth` | 认证状态 |

## 使用

```dart
import 'package:feature_home/feature_home.dart';

// 路由已自动注册，直接访问 /
// HomePage 自动加载首页数据
```

## 注册方式

- HomeCubit: **Factory**（页面级，每次创建新实例）
- HomeRepository: Factory