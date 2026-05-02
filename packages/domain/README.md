# domain

业务数据定义层 - 存放核心业务数据模型、状态、UseCase。

## 职责

| 目录 | 内容 | 依赖 Flutter |
|-----|------|-------------|
| models/ | 共用数据模型 | 否（纯 Dart） |
| state/ | 全局业务状态 Cubit | 是（flutter_bloc） |
| usecase/ | 共用业务逻辑编排 | 否 |
| repository/ | 共用 Repository 接口 | 否 |

## 依赖方向

```
     domain（纯 Dart，不依赖 infrastructure）
       ↓
services, features, infrastructure
```

- **依赖**: equatable 仅此而已
- **被依赖**: features、services、infrastructure 依赖 domain 获取类型和接口
- **核心原则**: domain 是最内层，只定义接口，不依赖任何 infrastructure 实现

## DI 注册方式

| 类型 | 注册方式 | 原因 |
|-----|---------|-----|
| 全局状态（UserCubit） | Singleton | 长期存在、多 feature 共用 |
| UseCase | Factory | 无状态、用完即弃 |

## 当前内容

```
lib/
├── domain.dart           ← barrel file
└── src/
    ├── demo/             ← 示例模型
    ├── enum.dart         ← 共用枚举
    └── exceptions.dart   ← 域异常定义
```

## 判断标准

### models/ 判断

问自己："这是核心业务数据吗？是否多个 feature 共用？"

- ✓ 核心业务数据（User、Product、Order）→ 放这里
- ✓ 多 feature 共用 → 放这里
- ✗ 单 feature 使用 → 放 feature/models/

| 模型 | 是否核心业务 | 放哪 |
|-----|------------|-----|
| User | 用户，核心业务 | domain/models/ |
| Product | 商品，核心业务 | domain/models/ |
| HomeBanner | 首页轮播，页面特定 | feature_home/models/ |

### state/ 判断

问自己："这个状态是全局的（多 feature 共用）还是页面级的？"

- ✓ 全局状态（UserCubit、NetworkCubit）→ 放这里
- ✗ 页面级状态（HomeCubit）→ 放 feature/cubit/

#### Widget 层使用方式

```dart
// 本页面状态 + 多个全局状态
BlocBuilder<HomeCubit, HomeState>(
  builder: (context, homeState) {
    final user = context.watch<UserCubit>().state;      // 全局状态
    final network = context.watch<NetworkCubit>().state; // 全局状态
    // ...
  },
)
```

### usecase/ 判断

三步判断：

1. 需要多 Repository 协调？ → UseCase
2. 逻辑复杂（多步骤）？ → UseCase
3. 多 feature 共用？ → 放 domain/usecase/

如果单 feature 使用 → 放 feature/usecase/

#### 约定

- UseCase 不访问 Cubit 状态
- UseCase 只处理数据获取逻辑
- 注册为 Factory（无状态）

| 层 | 职责 | 示例 |
|---|-----|-----|
| **Cubit** | 状态管理 + 简单逻辑 | loadData() → emit() |
| **Cubit 内方法** | 单 Repository + 简单步骤 | validateForm() |
| **feature/usecase** | 复杂逻辑 + 单 feature | PlaceOrderUseCase |
| **domain/usecase** | 复杂逻辑 + 多 feature 共用 | GetUserInfoUseCase |

## 业务服务 vs UseCase 区别

| 维度 | 业务服务（AuthManager） | UseCase（GetUserInfoUseCase） |
|-----|----------------------|---------------------------|
| **生命周期** | app 级别（长期存在） | 请求级别（用完销毁） |
| **有状态** | ✓ 有（isLoggedIn、isSyncing） | ✗ 无状态 |
| **职责** | 提供某种**能力** | 执行某个**任务** |
| **方法数量** | 多个（login、logout、check...） | 单一（execute） |
| **依赖注入** | Singleton（单例） | Factory（每次创建） |
| **归属** | packages/services/ | domain/usecase/ 或 feature/usecase/ |

## 全局状态归属

| 类型 | 特征 | 示例 | 放哪 |
|-----|-----|-----|-----|
| **应用状态** | 不依赖登录，启动即有 | Network、Locale | `lib/core/global/` |
| **业务全局数据** | 登录后才有 | User、Token | `packages/domain/state/` |