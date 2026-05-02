# Feature Package 拆分设计

## 四层架构目标

```
┌────────────────────────────────────────────────────────────────┐
│                       依赖方向（单向）                          │
│                                                                │
│  main.dart ──▶ core/ ──▶ features/ ──▶ services/ ──▶ domain/ ──▶ infrastructure/ │
│   (入口)     (组装层)   (业务功能)    (业务服务)      (数据定义)      (基础设施)    │
│                                                                │
│  核心原则：上层依赖下层，下层不知道上层存在                     │
│  feature_home 不依赖 feature_detail（除非明确声明）             │
│  infrastructure 不依赖任何业务层                               │
└────────────────────────────────────────────────────────────────┘
```

### 各层职责

| 层 | 目录 | 职责 | 特征 | 内容 |
|---|-----|-----|-----|-----|
| **基础设施层** | infrastructure/ | 纯技术能力 | 无业务含义 | api、routing、storage、component_library |
| **数据定义层** | domain/ | 业务数据定义 | 有业务含义 | models、state、usecase、repository接口 |
| **业务服务层** | services/ | 业务能力服务 | 长期存在、有状态 | auth、data_sync、payment |
| **业务功能层** | features/ | 用户可见功能 | 页面级 | feature_home、feature_detail |

---

## 目录结构设计

```
packages/
│
├── infrastructure/          ← 纯技术基础设施层
│   ├── api/                 ← 网络请求（已有）
│   ├── routing/             ← 路由导航（已有）
│   ├── key_value_storage/   ← 本地存储（已有）
│   ├── component_library/   ← UI组件库（扩展：theme + constants）
│   └── README.md
│
├── domain/                  ← 业务数据定义层
│   ├── models/              ← 共用数据模型
│   ├── state/               ← 全局业务状态（UserCubit）
│   ├── usecase/             ← 共用业务逻辑编排
│   ├── repository/          ← 共用 Repository 接口
│   ├── adapters/            ← Hive 适配器
│   └── README.md
│
├── services/                ← 业务服务层
│   ├── auth/                ← 认证服务（AuthManager）
│   ├── data_sync/           ← 同步服务（DataSyncManager）
│   ├── payment/             ← 支付服务（未来）
│   └── README.md
│
└── features/                ← 业务功能层
    ├── feature_home/
    ├── feature_detail/
    └── README.md
```

---

## 业务服务 vs UseCase 区别

| 维度 | 业务服务（AuthManager） | UseCase（GetUserInfoUseCase） |
|-----|----------------------|---------------------------|
| **生命周期** | app 级别（长期存在） | 请求级别（用完销毁） |
| **有状态** | ✓ 有（isLoggedIn、isSyncing） | ✗ 无状态 |
| **职责** | 提供某种**能力** | 执行某个**任务** |
| **方法数量** | 多个（login、logout、check...） | 单一（execute） |
| **依赖注入** | Singleton（单例） | Factory（每次创建） |
| **类比** | 服务员、门卫 | 点菜流程、查信息流程 |

---

## infrastructure 层设计

**职责**：提供纯技术能力，不关心具体业务。

| 包 | 是否纯技术 | 知道业务吗 | 说明 |
|---|----------|----------|-----|
| api | ✓ | ✗ | 只知道 HTTP，不知道"用户、商品" |
| routing | ✓ | ✗ | 只知道路由，不知道"首页、详情" |
| key_value_storage | ✓ | ✗ | 只知道存储，不知道"Token、配置" |
| component_library | ✓ | ✗ | 只知道 UI，不知道"业务含义" |

**判断标准**：
- ✓ 知道"用户、商品、订单" → 不放 infrastructure（放 domain 或 services）
- ✗ 只知道"HTTP、路由、存储、UI" → 放 infrastructure

---

## services 层设计

**职责**：提供跨 feature 共用的业务能力（长期存在、有状态）。

**判断标准**：
```
问：需要长期存在（app 生命周期）？
  ├─ 否 → UseCase 或 Cubit 方法
  └─ 是 ↓

问：有内部状态？
  ├─ 否 → UseCase
  └─ 是 ↓

问：提供某种能力（多个方法）？
  ├─ 否 → UseCase
  └─ 是 → 业务服务
```

---

## domain 层设计

**职责**：业务数据定义（models + state + usecase + repository接口）。

| 目录 | 内容 | 依赖 Flutter |
|---|-----|-------------|
| models/ | 共用数据模型 | 否（纯 Dart） |
| state/ | 全局业务状态 Cubit | 是（flutter_bloc） |
| usecase/ | 共用业务逻辑编排 | 否 |
| repository/ | 共用 Repository 接口 | 否 |
| adapters/ | Hive 适配器 | 否（hive） |

---

## AppLogger 不迁移

AppLogger 实现 `api` 包的 `AppLoggerInterface`。留在 `lib/core/utils/logger.dart`。

```
依赖链：
  api (定义接口 AppLoggerInterface)
    ↓
  lib/core/utils/logger.dart (实现 AppLogger)
    ↓
  主 app DI 注册
```

---

## feature 包依赖声明

```yaml
# packages/features/feature_home/pubspec.yaml
dependencies:
  # 基础设施
  api:
    path: ../../infrastructure/api
  routing:
    path: ../../infrastructure/routing
  component_library:
    path: ../../infrastructure/component_library

  # 数据定义
  domain:
    path: ../../domain

  # 业务服务
  auth:
    path: ../../services/auth
```

**什么样的东西不该单独成包？**

```
┌──────────────────────────┬──────────────────────┬─────────────┐
│  类型                    │  示例                │  放哪       │
├──────────────────────────┼──────────────────────┼─────────────┤
│ 工具型（轻量、纯函数）    │ AppConstants         │ component_ │
│                          │ FontSize、Spacing    │ library    │
│                          │ 格式化工具、验证器   │            │
├──────────────────────────┼──────────────────────┼─────────────┤
│ 工具型（有接口实现）      │ AppLogger            │ lib/core/  │
│                          │（实现api包接口）      │ utils/     │
├──────────────────────────┼──────────────────────┼─────────────┤
│ 业务服务（有状态/逻辑）   │ AuthManager          │ 独立包     │
│                          │ DataSyncManager      │ packages/  │
├──────────────────────────┼──────────────────────┼─────────────┤
│ 组装逻辑                  │ DI setup             │ lib/core/  │
│                          │ AppLauncher          │            │
│ 全局状态                  │ NetworkCubit         │ lib/core/  │
│                          │ LocaleCubit          │ global/    │
│ 业务全局数据              │ UserCubit            │ packages/  │
│                          │（登录后才存在）       │ domain_    │
│                          │                      │ models/    │
└──────────────────────────┴──────────────────────┴─────────────┘
```

**判断标准**：轻量工具 → component_library；有接口实现的工具 → core/utils；业务服务 → 独立包；业务全局数据 → domain。

## lib/core/ 留什么？

```
lib/core/
├── di/                    ← "这个app怎么组装所有零件"
│   ├── locator.dart       │
│   └── setup.dart         │
│                          │
├── startup/               ← "这个app怎么启动"
│   ├── launcher.dart      │
│   ├── initializer.dart   │
│   └── profiler.dart      │
│                          │
└── global/                ← "这个app的全局状态"
    ├── network/           │   NetworkCubit + NetworkBanner
    └── locale/            │   LocaleCubit
```

**判断标准**：如果某个模块放的是"具体业务实现"或"纯工具"，就该移到包里。只有"组装逻辑"留 core。

## package 边界设计

### 公开出口 vs 内部实现

```
packages/features/feature_home/
├── lib/
│   ├── feature_home.dart        ← 唯一的公开出口（barrel file）
│   │   export 'src/ui/home_page.dart';
│   │   export 'src/cubit/home_cubit.dart';
│   │   export 'src/cubit/home_state.dart';
│   │   export 'src/repository/home_repository.dart';
│   │   export 'src/di/setup.dart';    ← DI 注册函数
│   │
│   └── src/                     ← 内部实现，外部不可见
│       ├── repository/
│       ├── cubit/
│       ├── ui/
│       └── di/
│           └── setup.dart       ← 负责注册自己的服务
├── test/
│   └── feature_home_test.dart
└── pubspec.yaml
```

**设计决策：公开哪些 API？**

```
对外可见（通过 feature_home.dart export）：
  - HomePage          ← 页面 Widget，主 app 路由需要
  - HomeCubit         ← 状态管理，主 app DI 注册需要
  - HomeState         ← 状态类型，UI 层使用
  - HomeRepository    ← 接口，DI 注册需要
  - setupFeatureHome  ← DI 自注册函数

对外隐藏（不 export）：
  - HomeRepositoryImpl ← 实现细节，DI 容器决定用哪个
  - 其他内部辅助类
```

## DI 集成方式

### 改造后（packages/）— feature 自注册

```dart
// packages/features/feature_home/lib/src/di/setup.dart
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:feature_home/src/repository/home_repository_impl.dart';
import 'package:get_it/get_it.dart';

void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(sl<Api>()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl<HomeRepository>()));
}
```

```dart
// lib/core/di/setup.dart（主 app 变得很干净）
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart';

void setupDependencies() {
  // ... 基础设施注册 ...

  // 业务模块注册（每个 feature 负责自己的）
  setupFeatureHome(sl);
  setupFeatureDetail(sl);
}
```

## feature 包结构（含 models）

```
packages/features/feature_home/
├── lib/
│   ├── feature_home.dart        ← barrel file
│   └── src/
│       ├── models/              ← 页面特定数据模型
│       │   ├── home_banner.dart
│       │   └── README.md        ← 判断标准
│       ├── repository/
│       ├── cubit/
│       ├── ui/
│       └── di/
```

**models/ 判断**：
- 核心业务数据（User、Product、Order）→ domain/models/
- 页面特定数据（HomeBanner、FilterOption）→ feature/models/
- 不确定 → 先放 feature，发现共用再迁移（成本约 45秒）

**models/ 判断**：
- 核心业务数据（User、Product、Order）→ domain/models/
- 页面特定数据（HomeBanner、FilterOption）→ feature/models/
- 不确定 → 先放 feature，发现共用再迁移（成本约 45秒）

## UseCase 判断标准

```
业务逻辑需要处理

↓

问：需要多 Repository 协调？
  ├─ 否 → Cubit 内方法
  └─ 是 ↓

问：逻辑复杂（多步骤）？
  ├─ 否 → Cubit 内方法
  └─ 是 ↓

问：多 feature 共用？
  ├─ 否 → feature/usecase/
  └─ 是 → domain/usecase/
```

**usecase/ 判断**：
- 简单逻辑 → Cubit 内方法
- 复杂逻辑 + 单 feature → feature/usecase/
- 复杂逻辑 + 多 feature 共用 → domain/usecase/

| 层 | 职责 | 示例 |
|---|-----|-----|
| **Cubit** | 状态管理 + 简单逻辑 | loadData() → emit() |
| **Cubit 内方法** | 单 Repository + 简单步骤 | validateForm() |
| **feature/usecase** | 复杂逻辑 + 单 feature | PlaceOrderUseCase |
| **domain/usecase** | 复杂逻辑 + 多 feature 共用 | GetUserInfoUseCase |

## 跨 feature 通信

```
┌──────────────────┐          ┌──────────────────┐
│  feature_home    │          │  feature_detail  │
│                  │          │                  │
│  HomePage ───────┼─────────▶│  DetailPage      │
│  (导航到)        │  routing │                  │
│                  │          │                  │
│  HomeCubit ──────┼────X─────│  (不能直接依赖)  │
│  (不能直接引用)  │          │                  │
└──────────────────┘          └──────────────────┘
         │                              │
         │                              │
         ▼                              ▼
┌─────────────────────────────────────────────┐
│           core/global/ (共享层)              │
│                                             │
│  • NetworkCubit（全局网络状态）              │
│  • LocaleCubit（全局语言设置）               │
│                                             │
│  跨 feature 的共享状态放这里，不是互相引用   │
└─────────────────────────────────────────────┘
```

**规则**：
- **页面导航**：用 routing 包（已存在），不直接 import 另一个 feature 的 page
- **状态共享**：放到 core/global/ 或 domain，不直接 import 另一个 feature 的 cubit
- **数据依赖**：通过 api 和 domain 包，不直接 import 另一个 feature 的 repository

## 主 app pubspec.yaml 变更

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 基础设施包
  api:
    path: packages/api
  key_value_storage:
    path: packages/key_value_storage
  domain:
    path: packages/domain
  component_library:    ← 扩展后：theme + logger + constants + utils
    path: packages/component_library
  routing:
    path: packages/routing

  # 业务服务包
  auth:
    path: packages/auth
  data_sync:
    path: packages/data_sync

  # Feature 包
  feature_home:
    path: packages/features/feature_home
  feature_detail:
    path: packages/features/feature_detail

  # 通用依赖
  flutter_bloc: ^8.1.0
  get_it: ^7.6.0
  flutter_easyloading: ^3.0.5
  go_router: ^14.2.7
```

## component_library 内部结构变更

```
packages/component_library/lib/
├── component_library.dart    ← 更新 barrel file
│   ├── export 'src/theme/ovs_theme.dart';
│   ├── export 'src/theme/ovs_theme_data.dart';
│   ├── export 'src/theme/font_size.dart';
│   ├── export 'src/theme/spacing.dart';
│   ├── export 'src/constants/app_constants.dart'; ← 新增
│   ├── export 'src/constants/api_constants.dart';  ← 新增
│   └── export 'src/constants/cache_constants.dart'; ← 新增

├── src/
│   ├── theme/        ← 不变
│   │   ├── font_size.dart
│   │   ├── spacing.dart
│   │   ├── ovs_theme.dart
│   │   └── ovs_theme_data.dart
│   │
│   └── constants/    ← 移入（从 lib/core/constants/）
│       ├── app_constants.dart
│       ├── api_constants.dart
│       └── cache_constants.dart
```

**注意**：AppLogger 不迁移，留在 `lib/core/utils/logger.dart`。

## 路由适配

```dart
// packages/routing/lib/routing.dart（需要更新 import）
// 之前：
import 'package:my_app/features/home/ui/home_page.dart';

// 之后：
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart';
```

## 测试隔离

```
# 改造前：只能跑全量测试
flutter test                              # 跑所有测试，慢

# 改造后：可以按 feature 独立测试
cd packages/features/feature_home && flutter test  # 只跑 home 测试
cd packages/features/feature_detail && flutter test # 只跑 detail 测试
```

---

## 跨层状态传递设计

### 各层推荐方式

| 层级 | 方式 | 原因 |
|-----|-----|-----|
| **Widget** | BlocBuilder + context.watch | 自动响应状态变化，无需手动监听 |
| **Cubit** | 构造函数注入 | 显式依赖，测试可直接 mock |
| **纯 Dart (UseCase/Repository)** | DI (`sl<T>()`) | 无 context，只能用 DI |

### Widget 层：多层状态处理

当页面需监听多个状态（本页面 + 全局）：

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(  // ← 本页面状态
      builder: (context, homeState) {
        final network = context.watch<NetworkCubit>().state;  // ← 全局状态
        final locale = context.watch<LocaleCubit>().state;

        if (!network.isConnected) {
          return OfflineIndicator(locale: locale.locale);
        }

        return HomeContent(data: homeState.data);
      },
    );
  }
}
```

**避免嵌套地狱**：一个 BlocBuilder + 多个 context.watch。

### Cubit 层：构造函数注入

```dart
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repo;
  final NetworkCubit _network;  // ← 构造函数注入

  HomeCubit(this._repo, this._network) : super(HomeInitial());
}

// DI setup
void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeCubit>(() => HomeCubit(
    sl<HomeRepository>(),
    sl<NetworkCubit>(),  // ← 依赖来自 DI
  ));
}

// 测试
void main() {
  test('离线时返回 HomeOffline', () async {
    final cubit = HomeCubit(MockRepo(), MockNetworkCubit());  // ← 直接注入 mock
  });
}
```

### 主 app 注入全局状态到 Widget 树

```dart
void main() {
  setupDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<NetworkCubit>(create: (_) => sl<NetworkCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 全局状态归属

| 类型 | 特征 | 示例 | 放哪 |
|-----|-----|-----|-----|
| **应用状态** | 不依赖登录，启动即有 | Network、Locale | `lib/core/global/` |
| **业务全局数据** | 登录后才有 | User、Token | `packages/domain/` |

**UserCubit 放 domain**：多 feature 共需，纯数据模型 + 状态容器。

---

## core/widgets/ 归属

`lib/core/widgets/` 保留在 core，不迁移到 package：

| Widget | 依赖 | 说明 |
|--------|-----|-----|
| `RequestScope` | api.CancelTokenManager | 跨层 UI 基础设施 |
| `NetworkBanner` | NetworkCubit | 依赖全局状态 |

**原因**：core/widgets/ 是"组装层的 UI 部分"，依赖 package 合理。

---

## 多 Feature 共用逻辑

| 场景 | 用什么 | 放哪 |
|-----|-----|-----|
| 纯数据获取 | Repository | domain 或相关 feature |
| 多 Repository 协调 | UseCase | domain |
| 单 feature 内部逻辑 | Cubit 内方法 | feature 包内 |

```dart
// UseCase 示例
class GetUserInfoUseCase {
  final UserProfileRepository _userRepo;
  final CacheRepository _cacheRepo;

  Future<UserProfile> execute() async {
    final cached = await _cacheRepo.get<UserProfile>('user');
    if (cached != null && !cached.isExpired) return cached;

    final fresh = await _userRepo.fetch();
    await _cacheRepo.set('user', fresh);
    return fresh;
  }
}
```
