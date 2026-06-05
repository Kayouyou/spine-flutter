# Feature Package 拆分设计规格

## 概述

将 `lib/features/` 目录下的业务功能拆分为独立 Flutter package，建立四层架构，实现编译器级别的依赖约束。

## 问题陈述

当前 `lib/features/` 是目录组织约定，没有编译器级别的依赖约束：

```dart
// 问题示例：循环依赖编译器不拦截
lib/features/home/cubit/home_cubit.dart
  └─ import '../../detail/cubit/detail_cubit.dart';  // 可以随意引用
lib/features/detail/cubit/detail_cubit.dart
  └─ import '../../home/cubit/home_cubit.dart';      // 循环依赖
```

核心问题：
- **无依赖约束**：feature 之间可随意 import，循环依赖只能靠 code review 发现
- **无法独立测试**：必须跑整个项目测试，feature 多了会慢
- **主 app lib/ 职责不清**：既包含组装逻辑（core/），又包含业务逻辑（features/）

---

## 四层架构设计

### 架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                    features/                                │
│                  业务功能层                                  │
│         用户可见的页面级功能                                 │
│              feature_home、feature_detail                   │
└─────────────────────────────────────────────────────────────┘
                           ↓ 依赖
┌─────────────────────────────────────────────────────────────┐
│                    services/                                │
│                  业务服务层                                  │
│         长期存在、有状态、提供业务能力                       │
│              auth、data_sync、payment                       │
└─────────────────────────────────────────────────────────────┘
                           ↓ 依赖
┌─────────────────────────────────────────────────────────────┐
│                    domain/                                  │
│                  业务数据定义层                              │
│         models、state、usecase、repository接口               │
│             UserProfile、UserCubit、GetUserInfoUseCase      │
└─────────────────────────────────────────────────────────────┘
                           ↓ 依赖
┌─────────────────────────────────────────────────────────────┐
│                  infrastructure/                            │
│                  纯技术基础设施层                            │
│         无业务逻辑的纯技术能力                               │
│        api、routing、key_value_storage、component_library   │
└─────────────────────────────────────────────────────────────┘

依赖原则：上层依赖下层，下层不知道上层存在
```

### 各层职责

| 层 | 目录 | 职责 | 特征 | 内容示例 |
|---|-----|-----|-----|-----|
| **基础设施层** | infrastructure/ | 纯技术能力 | 无业务含义 | api、routing、storage |
| **数据定义层** | domain/ | 业务数据定义 | 有业务含义 | models、state、usecase |
| **业务服务层** | services/ | 业务能力服务 | 长期存在、有状态 | auth、data_sync |
| **业务功能层** | features/ | 用户可见功能 | 页面级 | feature_home、feature_detail |

---

## services vs domain 边界

### 核心区分

| 维度 | AuthManager (services) | UserCubit (domain) |
|-----|----------------------|-------------------|
| **职责** | 执行认证**动作** | 存储用户**数据** |
| **类比** | 门卫（检查证件、放行） | 档案柜（存放用户信息） |
| **生命周期** | app 级别（长期存在） | app 级别（长期存在） |
| **有状态** | ✓ 有（isLoggedIn、_token） | ✓ 有（UserState） |
| **调用时机** | 用户主动触发（登录按钮） | 被动读取（展示头像） |

### 判断标准

```
业务逻辑需要处理

↓

问：需要长期存在（app 生命周期）？
  ├─ 否 → UseCase 或 Cubit 方法
  └─ 是 ↓

问：提供某种能力（动作/多个方法）？
  ├─ 是 → 业务服务（services/）
  └─ 否 ↓

问：是数据容器（被动读取）？
  ├─ 是 → domain/state/
  └─ 否 → UseCase
```

### 代码示例

**AuthManager (services/auth/)**：
```dart
class AuthManager {
  String? _token;
  bool get isLoggedIn => _token != null;

  // 提供认证能力（多个方法）
  Future<void> handleLogin() async { ... }
  Future<void> login(String username, String password) async { ... }
  Future<void> logout() async { ... }
  Future<bool> checkTokenValid() async { ... }
}
```

**UserCubit (domain/state/user/)**：
```dart
class UserCubit extends Cubit<UserState> {
  // 存储用户数据（被动读取）
  Future<void> loadUser() async { ... }
  Future<void> logout() async { ... }
}

// 其他 feature 通过 domain 获取用户信息
final user = context.watch<UserCubit>().state;
```

---

## Feature Package 内部结构

### 标准目录结构

```
packages/features/feature_home/
├── lib/
│   ├── feature_home.dart        ← barrel file（公开API）
│   └── src/
│       ├── models/              ← 页面特定数据模型
│       │   ├── home_banner.dart
│       │   ├── home_section.dart
│       │   └── README.md        ← 判断标准
│       │
│       ├── usecase/             ← 单feature复杂逻辑
│       │   ├── validate_order_usecase.dart
│       │   └── README.md        ← 何时用UseCase
│       │
│       ├── repository/
│       │   ├── home_repository.dart      ← 接口
│       │   └── home_repository_impl.dart ← 实现
│       │
│       ├── cubit/
│       │   ├── home_cubit.dart
│       │   └── home_state.dart
│       │
│       ├── ui/
│       │   └── home_page.dart
│       │
│       └── di/
│       │   └── setup.dart       ← DI自注册函数
│       │
├── test/
│   └── home_cubit_test.dart
│
├── README.md                    ← 包说明
└── pubspec.yaml
```

### Model 放置策略

**判断标准**：

| Model | 是否核心业务 | 放哪 |
|-----|------------|-----|
| User、Product、Order | ✓ 核心（多feature共用） | domain/models/ |
| HomeBanner | ✗ 页面特定 | feature_home/models/ |
| FilterOption | ✗ 页面特定 | feature_search/models/ |

**开发策略**：
- 不确定是否共用 → 先放 feature/models/
- 发现 2+ feature 使用 → 迁移到 domain/models/
- 迁移成本约 45 秒

### UseCase 放置策略

**三步判断**：

1. 需要多 Repository 协调？
   - ✓ 需要 → UseCase
   - ✗ 单 Repository → Cubit 直接调用

2. 逻辑复杂（多步骤）？
   - ✓ 复杂 → UseCase
   - ✗ 简单 → Cubit 内方法

3. 多 feature 共用？
   - ✓ 共用 → domain/usecase/
   - ✗ 单feature → feature/usecase/

---

## 依赖注入流程

### Singleton vs Factory 选择标准

| 类型 | 注册方式 | 原因 |
|-----|---------|-----|
| **业务服务（AuthManager）** | Singleton | 长期存在、有状态 |
| **全局业务状态（UserCubit）** | Singleton | 多feature共用 |
| **应用状态（NetworkCubit）** | Singleton | app级别 |
| **UseCase** | Factory | 无状态、每次新建 |
| **Repository** | Factory | 页面级使用 |
| **页面 Cubit** | Factory | 页面级状态、页面销毁时释放 |

### 注册流程

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const SpineFlutter());
}

// lib/core/di/setup.dart
Future<void> setupDependencies() async {
  // Step 1: 基础设施层
  sl.registerSingleton<Api>(Api(...));
  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());

  // Step 2: 数据定义层
  setupDomain(sl);  // 调用 domain 包的 setup

  // Step 3: 应用状态（主 app core/global）
  sl.registerSingleton<NetworkCubit>(NetworkCubit());
  sl.registerSingleton<LocaleCubit>(LocaleCubit());

  // Step 4: 业务服务层
  setupAuth(sl);
  setupDataSync(sl);

  // Step 5: 业务功能层
  setupFeatureHome(sl);
  setupFeatureDetail(sl);
}
```

### 各包 setup 函数示例

**domain/lib/src/di/setup.dart**：
```dart
void setupDomain(GetIt sl) {
  // 全局业务状态（Singleton）
  sl.registerSingleton<UserCubit>(UserCubit(
    storage: sl<KeyValueStorage>(),
    api: sl<Api>(),
  ));

  // UseCase（Factory）
  sl.registerFactory<GetUserInfoUseCase>(() => GetUserInfoUseCase(
    userRepo: sl<UserRepository>(),
    cacheRepo: sl<CacheRepository>(),
  ));
}
```

**feature_home/lib/src/di/setup.dart**：
```dart
void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(
    api: sl<Api>(),
  ));

  sl.registerFactory<HomeCubit>(() => HomeCubit(
    repo: sl<HomeRepository>(),
    authManager: sl<AuthManager>(),
    networkCubit: sl<NetworkCubit>(),  // 注入全局状态
  ));
}
```

---

## 跨层状态传递

### 三层传递方式

| 层级 | 方式 | 原因 |
|-----|-----|-----|
| **Widget 层** | BlocBuilder + context.watch | 自动响应状态变化 |
| **Cubit 层** | 构造函数注入 | 显式依赖，测试可mock |
| **纯 Dart (UseCase)** | DI `sl<T>()` | 无context，只能用DI |

### 场景 1: Cubit 获取全局状态

```dart
// feature_home/lib/src/cubit/home_cubit.dart
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repo;
  final NetworkCubit _network;  // 构造函数注入
  final UserCubit _user;        // 构造函数注入

  HomeCubit(this._repo, this._network, this._user) : super(HomeInitial());

  Future<void> loadData() async {
    if (!_network.state.isConnected) {
      emit(HomeOffline());
      return;
    }
    // 正常加载...
  }
}

// feature_home/lib/src/di/setup.dart
void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeCubit>(() => HomeCubit(
    sl<HomeRepository>(),
    sl<NetworkCubit>(),  // 从 DI 获取并注入
    sl<UserCubit>(),
  ));
}
```

### 场景 2: Widget 多层状态

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(  // 本页面状态
      builder: (context, homeState) {
        final network = context.watch<NetworkCubit>().state;  // 全局状态
        final user = context.watch<UserCubit>().state;        // 全局状态

        if (!network.isConnected) return OfflineIndicator();
        if (homeState.isLoading) return LoadingIndicator();

        return HomeContent(user: user, data: homeState.data);
      },
    );
  }
}
```

**避免嵌套地狱**：一个 BlocBuilder（本页面）+ 多个 context.watch（全局）

### 场景 3: Feature 间跳转

```dart
// ✓ 正确做法：通过 routing 包
import 'package:routing/routing.dart';
context.go(AppRouter.detailPath(id: '123'));

// ✗ 错误做法：直接 import 其他 feature
import 'package:feature_detail/feature_detail.dart';  // 导致循环依赖风险
```

### 场景 4: Feature 间共享数据

```dart
// ✓ 正确做法：通过 domain 层
import 'package:domain/domain.dart';

final user = context.watch<UserCubit>().state;
if (user is UserLoaded) {
  return Avatar(user.profile.avatar);
}
```

### 场景 5: Services 调用 UseCase

```dart
class AuthManager {
  final GetUserInfoUseCase _getUserInfo;  // 构造函数注入

  Future<void> login(String username, String password) async {
    // 登录成功后调用 UseCase
    await _getUserInfo.execute();
  }
}
```

### 场景 6: UseCase 不访问 Cubit

```dart
// UseCase 只处理数据获取逻辑
class GetUserInfoUseCase {
  Future<UserProfile> execute() async {
    // 不访问 UserCubit
    // 只负责数据获取和缓存
    final cached = await _cacheRepo.get<UserProfile>('user');
    if (cached != null) return cached;
    return await _userRepo.fetchProfile();
  }
}
```

---

## 目录结构总览

```
spine_flutter/
├── lib/
│   └── core/                    ← 只剩组装层
│       ├── di/                  ← 依赖注入配置
│       ├── startup/             ← 启动流程
│       ├── global/              ← 全局状态（NetworkCubit, LocaleCubit）
│       └── widgets/             ← 跨层 UI 基础设施
│       └── utils/               ← AppLogger（实现 api 接口）
│
├── packages/
│   ├── infrastructure/          ← 纯技术基础设施层
│   │   ├── api/
│   │   ├── routing/
│   │   ├── key_value_storage/
│   │   ├── component_library/
│   │   └── README.md            ← 目录说明
│   │
│   ├── domain/                  ← 业务数据定义层
│   │   ├── lib/src/
│   │   │   ├── models/
│   │   │   ├── state/
│   │   │   ├── usecase/
│   │   │   ├── repository/
│   │   │   └── adapters/
│   │   └── README.md
│   │
│   ├── services/                ← 业务服务层
│   │   ├── auth/
│   │   ├── data_sync/
│   │   └── README.md            ← 目录说明 + 跨层协作示例
│   │
│   └── features/                ← 业务功能层
│       ├── feature_home/
│       ├── feature_detail/
│       └── README.md            ← 目录说明 + 跨层通信示例
│
└── pubspec.yaml
```

---

## README 文档要求

### 目录 README vs 包 README

| 类型 | 位置 | 职责 | 内容 |
|-----|-----|-----|-----|
| **目录 README** | infrastructure/、services/、features/ | 组织说明 | 此目录下有哪些包、为什么这样组织、跨层通信示例 |
| **包 README** | api/、auth/、feature_home/ 等 | 包职责 | 这个包做什么、依赖什么、如何使用 |
| **内部目录 README** | models/、state/、usecase/ 等 | 判断标准 | 什么放这里、什么放别处 |

### features/README.md 内容要求

必须包含：
- 目录下有哪些 feature 包
- **如何跳转到其他 feature**（通过 routing 包）
- **如何获取全局数据**（通过 domain/state/）
- 添加新 feature 的步骤

### services/README.md 内容要求

必须包含：
- 业务服务 vs UseCase 判断标准
- **与其他层协作**章节：
  - 调用 UseCase 示例
  - 触发数据同步示例
- 添加新 service 的步骤

### domain/state/README.md 内容要求

必须包含：
- 全局状态 vs 页面级状态判断标准
- **Widget 层使用方式**（BlocBuilder + context.watch）
- 各 feature 如何读取全局状态

---

## 迁移阶段

### Phase 0: 基础设施准备

| Phase | 内容 | 验证 |
|-------|-----|-----|
| 0.1 | 创建 infrastructure/services/features 目录结构 | ls 检查每个目录有 pubspec.yaml |
| 0.2 | component_library 扩展（合并 constants） | flutter analyze 无错误 |
| 0.3 | domain_models 改名为 domain | grep 检查无残留引用 |
| 0.4 | auth、data_sync 包提取 | flutter analyze + flutter test |

### Phase 1-2: Feature 拆分

| Phase | 内容 | 验证 |
|-------|-----|-----|
| 1 | feature_home 拆分 | cd feature_home && flutter test |
| 2 | feature_detail 拆分 | cd feature_detail && flutter test |

### Phase 3: 清理验证

- 删除旧目录（lib/features/、lib/core/auth/、lib/core/sync/）
- 全量验证：flutter analyze + flutter test + flutter build apk --debug
- 运行验证：手动测试各功能

---

## 测试策略

### 每个 package 独立测试

| Package | 测试内容 | 运行命令 |
|---------|---------|---------|
| infrastructure/api | HTTP 拦截器、错误处理 | cd packages/infrastructure/api && flutter test |
| domain | Models、UseCase | cd packages/domain && flutter test |
| services/auth | AuthManager、登录流程 | cd packages/services/auth && flutter test |
| features/feature_home | HomeCubit、Repository | cd packages/features/feature_home && flutter test |

### Cubit 测试示例（构造函数注入便于 mock）

```dart
class MockHomeRepository extends Mock implements HomeRepository {}
class MockNetworkCubit extends MockCubit<NetworkState> implements NetworkCubit {}

void main() {
  test('离线时返回 HomeOffline', () async {
    final mockRepo = MockHomeRepository();
    final mockNetwork = MockNetworkCubit();
    when(() => mockNetwork.state).thenReturn(NetworkState.disconnected());

    final cubit = HomeCubit(mockRepo, mockNetwork);  // 直接注入，不依赖 DI
    await cubit.loadData();
    expect(cubit.state, isA<HomeOffline>());
  });
}
```

---

## 成功标准

1. **编译器约束生效**：feature 间直接 import 会报编译错误
2. **独立测试**：每个 feature package 可单独运行 flutter test
3. **依赖方向正确**：flutter analyze 无循环依赖警告
4. **功能完整**：flutter build apk --debug 成功，运行无异常
5. **文档完善**：各层 README 包含判断标准和跨层通信示例

---

## 风险与缓解

| 风险 | 缓解措施 |
|-----|---------|
| import 路径遗漏更新 | grep 检查所有 import |
| 循环依赖 | flutter analyze 检查 + Code Review |
| 测试失败 | 每个 phase 完成后立即运行 flutter test |
| 删除未迁移文件 | 先 flutter analyze 确认无引用再删除 |

---

## 补充文档位置

建议创建专门的跨层通信文档：
`docs/architecture/cross-layer-communication.md`

内容：
- 所有通信场景汇总（本规格第5节）
- 依赖方向图解
- 常见错误示例（不要怎么做）
- FAQ：常见问题解答