# Feature Package 拆分方案

## 为什么

当前 features 放在 `lib/features/` 下是目录组织约定，没有编译器级别的依赖约束。团队已有 5 个基础设施包（api、domain、key_value_storage、component_library、routing），feature 用包是同一个模式的自然延伸。

### 当前问题

```
lib/features/home/cubit/home_cubit.dart
  └─ import '../../detail/cubit/detail_cubit.dart';  // 可以随意引用
lib/features/detail/cubit/detail_cubit.dart
  └─ import '../../home/cubit/home_cubit.dart';      // 循环依赖编译器不拦截
```

- **无依赖约束**：feature 之间可随意 import，循环依赖只能靠 code review 发现
- **无法独立测试**：必须跑整个项目测试，feature 多了会慢
- **主 app lib/ 职责不清**：既包含组装逻辑（core/），又包含业务逻辑（features/）

## 改什么

### 核心变更
1. **整理基础设施层**：api、routing、key_value_storage、component_library 放入 `packages/infrastructure/` 统一管理
2. **domain 改名**：domain_models → domain，扩展职责（models + state + usecase + repository接口）
3. **创建 services 目录**：auth、data_sync 放入 `packages/services/` 统一管理业务服务
4. **拆分 feature 为独立包**：将 `lib/features/` 下每个 feature 迁移为 `packages/features/` 下的独立 Flutter package
5. **constants 迁移**：AppConstants 移入 component_library
6. **AppLogger 保留**：留在 lib/core/utils/（实现 api 包接口）
7. 主 app `lib/core/` 只保留组装层（DI、启动、全局状态）

---

## 四层架构设计

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

| 层 | 目录 | 职责 | 特征 | 内容 |
|---|-----|-----|-----|-----|
| **基础设施层** | infrastructure/ | 纯技术能力 | 无业务含义 | api、routing、storage、component_library |
| **数据定义层** | domain/ | 业务数据定义 | 有业务含义 | models、state、usecase、repository接口 |
| **业务服务层** | services/ | 业务能力服务 | 长期存在、有状态 | auth、data_sync、payment |
| **业务功能层** | features/ | 用户可见功能 | 页面级 | feature_home、feature_detail |

---

## 业务服务层设计

### 业务服务 vs UseCase 区别

| 维度 | 业务服务（AuthManager） | UseCase（GetUserInfoUseCase） |
|-----|----------------------|---------------------------|
| **生命周期** | app 级别（长期存在） | 请求级别（用完销毁） |
| **有状态** | ✓ 有（isLoggedIn、isSyncing） | ✗ 无状态 |
| **职责** | 提供某种**能力** | 执行某个**任务** |
| **方法数量** | 多个（login、logout、check...） | 单一（execute） |
| **依赖注入** | Singleton（单例） | Factory（每次创建） |
| **类比** | 服务员、门卫 | 点菜流程、查信息流程 |

### 业务服务示例

```dart
// packages/services/auth/lib/src/manager.dart
class AuthManager {
  // ===== 有状态 =====
  String? _token;
  bool get isLoggedIn => _token != null;
  DateTime? _tokenExpiry;
  
  // ===== 长期存在（app 生命周期）=====
  
  // ===== 提供认证"能力" =====
  
  /// 启动时自动检查登录状态
  Future<void> handleLogin() async {
    final savedToken = await _storage.getString('token');
    if (savedToken != null) {
      _token = savedToken;
      // 自动登录成功
    }
  }
  
  /// 用户主动登录
  Future<void> login(String username, String password) async {
    final response = await _api.login(username, password);
    _token = response.token;
    await _storage.saveToken(_token!);
    
    // 触发后续操作（调用 UseCase 或其他服务）
    await _sl<GetUserInfoUseCase>().execute();
    await _sl<DataSyncManager>().sync();
  }
  
  /// 用户登出
  Future<void> logout() async {
    _token = null;
    await _storage.removeToken();
    _sl<UserCubit>().emit(UserUnauthenticated());
  }
  
  /// 检查 Token 是否有效
  Future<bool> checkTokenValid() async {
    if (_token == null) return false;
    return DateTime.now().before(_tokenExpiry!);
  }
}
```

### UseCase 示例

```dart
// packages/domain/lib/src/usecase/get_user_info_usecase.dart
class GetUserInfoUseCase {
  // ===== 无状态 =====
  
  // ===== 用完就销毁 =====
  
  // ===== 执行"获取用户信息"任务 =====
  
  Future<UserProfile> execute() async {
    // 步骤1：检查缓存
    final cached = await _cacheRepo.get<UserProfile>('user');
    if (cached != null && !cached.isExpired) return cached;
    
    // 步骤2：从网络获取
    final fresh = await _userRepo.fetchProfile();
    
    // 步骤3：更新缓存
    await _cacheRepo.set('user', fresh);
    
    return fresh;  // 任务完成，返回结果
  }
}
```

### 判断标准

```
业务逻辑需要处理

↓

问：需要长期存在（app 生命周期）？
  ├─ 否 → UseCase 或 Cubit 方法
  └─ 是 ↓

问：有内部状态？
  ├─ 否 → UseCase
  └─ 是 ↓

问：提供某种能力（多个方法）？
  ├─ 否 → UseCase
  └─ 是 → 业务服务（services/）
```

### 业务服务放哪里

| 内容 | 放哪 | 原因 |
|-----|-----|-----|
| AuthManager | services/auth/ | 长期存在 + 有状态 + 提供认证能力 |
| DataSyncManager | services/data_sync/ | 长期存在 + 有状态 + 提供同步能力 |
| PaymentManager | services/payment/ | 长期存在 + 有状态 + 提供支付能力 |
| GetUserInfoUseCase | domain/usecase/ | 无状态 + 执行一次性任务 |

---

## services/ 目录设计

```
packages/services/
│
├── auth/                    ← 认证服务
│   ├── lib/
│   │   ├── auth.dart        ← barrel file
│   │   └── src/
│   │       └── manager.dart ← AuthManager
│   ├── README.md            ← 服务职责说明
│   └── pubspec.yaml
│
├── data_sync/               ← 数据同步服务
│   ├── lib/
│   │   ├── data_sync.dart
│   │   └── src/
│   │       └── manager.dart ← DataSyncManager
│   ├── README.md
│   └── pubspec.yaml
│
├── payment/                 ← 支付服务（未来）
├── notification/            ← 推送服务（未来）
│
└── README.md                ← services 目录整体说明
```

---

## 目录 vs Package 定义

| 术语 | 定义 | 有 pubspec.yaml | 示例 |
|-----|-----|----------------|-----|
| **package** | 可独立编译、发布 | ✓ 有 | api、auth、feature_home |
| **目录** | 组织分组（无编译意义） | ✗ 无 | infrastructure、services、features |

```
packages/
│
├── infrastructure/      ← 目录（组织）
│   ├── api/            ← package（有 pubspec.yaml）
│   ├── routing/        ← package
│   ├── key_value_storage/ ← package
│   ├── component_library/ ← package
│   └── README.md       ← 目录说明
│
├── services/           ← 目录（组织）
│   ├── auth/           ← package（有 pubspec.yaml）
│   ├── data_sync/      ← package
│   ├── payment/        ← package
│   └── README.md       ← 目录说明
│
├── domain/             ← package（有 pubspec.yaml）
│   ├── README.md       ← 包说明
│   └── lib/src/
│       ├── models/     ← 目录（lib 内部组织）
│       ├── state/      ← 目录
│       └── ...
│
└── features/           ← 目录（组织）
    ├── feature_home/   ← package（有 pubspec.yaml）
    ├── feature_detail/ ← package
    └── README.md       ← 目录说明
```

### 为什么 services 下每个服务是独立 package？

| 维度 | 独立 package | 单一 package |
|-----|-------------|-------------|
| **编译器约束** | ✓ 每个 service 有独立依赖约束 | ✗ 所有服务混在一起 |
| **独立测试** | ✓ 可单独运行测试 | ✗ 必须跑整个 services 测试 |
| **依赖控制** | ✓ feature 可只依赖需要的 service | ✗ 依赖 services 就依赖所有 |
| **职责清晰** | ✓ 每个 service 有自己的 pubspec | ✗ 混在一起 |
| **import 路径** | package:auth | package:services |

**类比**：
```
services/ 的角色 = features/ 的角色
  ├─ 都是"组织目录"（无 pubspec.yaml）
  ├─ 目录下每个子项是独立 package
  └─ README.md 说明目录职责
```

---

## README 结构总览

每个层级都需要 README：

```
packages/
│
├── infrastructure/
│   ├── api/
│   │   └── README.md      ← api 包说明
│   ├── routing/
│   │   └── README.md      ← routing 包说明
│   ├── key_value_storage/
│   │   └── README.md
│   ├── component_library/
│   │   ├── README.md      ← component_library 包说明
│   │   └── lib/src/
│   │       ├── theme/
│   │       │   └── README.md
│   │       └── constants/
│   │           └── README.md
│   └── README.md          ← infrastructure 目录说明（组织说明）
│
├── domain/
│   ├── README.md          ← domain 包说明（domain 本身是 package）
│   └── lib/src/
│       ├── models/
│       │   └── README.md  ← models 目录说明（判断标准）
│       ├── state/
│       │   ├── README.md
│       │   └── user/
│       │       └── README.md
│       ├── usecase/
│       │   └── README.md
│       ├── repository/
│       │   └── README.md
│       └── adapters/
│           └── README.md
│
├── services/
│   ├── auth/
│   │   ├── README.md      ← auth 包说明
│   │   └── lib/src/
│   │       └── README.md  ← auth 内部说明（如有）
│   ├── data_sync/
│   │   └── README.md
│   ├── payment/
│   │   └── README.md
│   └── README.md          ← services 目录说明（组织说明）
│
└── features/
    ├── feature_home/
    │   ├── README.md      ← feature_home 包说明
    │   └── lib/src/
    │       ├── models/
    │       │   └── README.md
    │       ├── usecase/
    │       │   └── README.md
    │       └── ...
    ├── feature_detail/
    │   └── README.md
    └── README.md          ← features 目录说明（组织说明）
```

---

## 目录 README vs 包 README

| 类型 | 位置 | 职责 | 内容 |
|-----|-----|-----|-----|
| **目录 README** | infrastructure/、services/、features/ | 组织说明 | 此目录下有哪些 package、为什么这样组织 |
| **包 README** | api/、auth/、feature_home/ 等 | 包职责 | 这个包做什么、依赖什么、如何使用 |
| **内部目录 README** | models/、state/、usecase/ 等 | 判断标准 | 什么放这里、什么放别处 |

### 目录 README 示例（services/）

```markdown
# services 目录

业务服务包的组织目录。

## 说明

此目录下的每个子目录是一个独立的 Flutter package：
- auth/ - 认证服务包（独立 package，有 pubspec.yaml）
- data_sync/ - 数据同步服务包（独立 package）
- payment/ - 支付服务包（独立 package）

## 为什么每个服务是独立 package？

| 维度 | 独立 package | 单一 package |
|-----|-------------|-------------|
| 编译器约束 | ✓ 独立依赖约束 | ✗ 混在一起 |
| 独立测试 | ✓ 单独运行 | ✗ 必须跑整体 |
| 依赖控制 | ✓ feature 只依赖需要的 | ✗ 依赖所有 |

## 与 features/ 目录的关系

services/ 和 features/ 都是"组织目录"：
- 目录本身无 pubspec.yaml
- 目录下每个子项是独立 package
- README.md 仅作为组织说明

## 添加新服务

创建新服务包：
1. 创建 `packages/services/<service_name>/` 目录
2. 创建 `pubspec.yaml`
3. 创建 `lib/<service_name>.dart`（barrel file）
4. 创建 `lib/src/manager.dart`
5. 创建 `README.md`

## 约定

- 每个服务独立 package
- 每个服务有 README.md
- 此 README.md 仅作为组织说明（无 pubspec.yaml）
```

### 包 README 示例（auth/）

```markdown
# auth 包

认证服务包 - 管理用户认证状态。

## 职责

提供认证能力：
- login() - 用户登录
- logout() - 用户登出
- checkTokenValid() - 检查 Token 有效性
- handleLogin() - 启动时自动检查登录状态

## 业务服务特征

- 长期存在（app 生命周期）
- 有内部状态（isLoggedIn、_token）
- 提供能力（多个方法）

## 与 UseCase 的区别

| 维度 | AuthManager（业务服务） | GetUserInfoUseCase |
|-----|----------------------|------------------|
| 生命周期 | app 级别（长期） | 请求级别（短期） |
| 有状态 | ✓ 有（isLoggedIn） | ✗ 无 |
| 职责 | 提供认证能力 | 执行获取信息任务 |
| 方法数量 | 多个 | 单一 |

## 依赖

```yaml
dependencies:
  api:
    path: ../infrastructure/api
  key_value_storage:
    path: ../infrastructure/key_value_storage
  domain:
    path: ../domain
```

## 使用方式

```dart
// DI 注册（Singleton）
sl.registerSingleton<AuthManager>(AuthManager(
  sl<Api>(),
  sl<KeyValueStorage>(),
));

// 调用
await sl<AuthManager>().login(username, password);
await sl<AuthManager>().logout();

// 检查状态
if (sl<AuthManager>().isLoggedIn) {
  // 已登录
}
```

## 内部结构

```
lib/
├── auth.dart              ← barrel file
└── src/
    └── manager.dart       ← AuthManager
```
```

---

## infrastructure/ 目录设计

```
packages/infrastructure/
│
├── api/                     ← 网络请求（已有）
│   ├── lib/
│   ├── README.md
│   └── pubspec.yaml
│
├── routing/                 ← 路由导航（已有）
│   ├── lib/
│   ├── README.md
│   └── pubspec.yaml
│
├── key_value_storage/       ← 本地存储（已有）
│   ├── lib/
│   ├── README.md
│   └── pubspec.yaml
│
├── component_library/       ← UI组件库（扩展）
│   ├── lib/
│   │   ├── theme/           ← 已有
│   │   └── constants/       ← 新增（AppConstants）
│   ├── README.md
│   └── pubspec.yaml
│
└── README.md                ← infrastructure 目录整体说明
```

### infrastructure/ README.md

```markdown
# infrastructure 目录

存放纯技术基础设施包（无业务逻辑）。

## 职责

提供纯技术能力，不关心具体业务：
- 网络请求（api）：只关心 HTTP，不知道"用户、商品"
- 路由导航（routing）：只关心导航，不知道"首页、详情"
- 本地存储（key_value_storage）：只关心存取，不知道"Token、配置"
- UI组件库（component_library）：只关心 UI，不知道"业务含义"

## 判断标准

问自己："这个包知道业务是什么吗？"

- ✓ 知道"用户、商品、订单" → 不放这里（放 domain 或 services）
- ✗ 只知道"HTTP、路由、存储、UI" → 放这里

## 示例

| 包 | 是否纯技术 | 知道业务吗 | 放哪 |
|---|----------|----------|-----|
| api | ✓ | ✗（只知道 HTTP） | infrastructure/ |
| routing | ✓ | ✗（只知道路由） | infrastructure/ |
| key_value_storage | ✓ | ✗（只知道存储） | infrastructure/ |
| component_library | ✓ | ✗（只知道 UI） | infrastructure/ |
| domain | ✗ | ✓（知道用户、商品） | packages/domain/ |
| auth | ✗ | ✓（知道认证业务） | services/auth/ |

## 与其他层的关系

```
infrastructure 不依赖任何业务层
infrastructure 被 domain、services、features 依赖
```

## 约定

- 无业务逻辑
- 无业务数据模型
- 可被任何上层依赖
- 独立测试（不依赖业务）
```

---

### 目录变化

**改造前：**
```
my_app/
├── lib/
│   ├── core/                    ← 混合：组装逻辑 + 业务实现
│   │   ├── auth/                ← 业务服务，需提取
│   │   ├── di/
│   │   ├── startup/
│   │   ├── global/
│   │   ├── sync/                ← 业务服务，需提取
│   │   ├── utils/               ← 工具，移入 component_library
│   │   └── constants/           ← 配置，移入 component_library
│   └── features/                ← 业务层（目录）
│       ├── home/
│       └── detail/
└── packages/                    ← 基础设施包
    ├── api/
    ├── domain
    ├── component_library/       ← 只有 theme
    └── ...
```

**改造后：**
```
my_app/
├── lib/
│   └── core/                    ← 只剩组装层
│       ├── di/                  ← 依赖注入配置
│       ├── startup/             ← 启动流程
│       ├── global/              ← 全局状态（NetworkCubit, LocaleCubit）
│       └── utils/               ← AppLogger（实现 api 接口）
│
├── packages/
│   │
│   ├── infrastructure/          ← 纯技术基础设施层
│   │   ├── api/                 ← 网络请求（已有）
│   │   ├── routing/             ← 路由导航（已有）
│   │   ├── key_value_storage/   ← 本地存储（已有）
│   │   ├── component_library/   ← UI组件库（扩展：theme + constants）
│   │   └── README.md            ← 说明：纯技术，无业务逻辑
│   │
│   ├── domain/                  ← 业务数据定义层（改名）
│   │   ├── lib/
│   │   │   ├── models/          ← 共用数据模型
│   │   │   ├── state/           ← 全局业务状态（UserCubit）
│   │   │   ├── usecase/         ← 共用业务逻辑编排
│   │   │   ├── repository/      ← 共用 Repository 接口
│   │   │   └── adapters/        ← Hive 适配器
│   │   └── README.md
│   │
│   ├── services/                ← 业务服务层（新增统一目录）
│   │   ├── auth/                ← 认证服务（从 lib/core/auth 提取）
│   │   ├── data_sync/           ← 同步服务（从 lib/core/sync 提取）
│   │   ├── payment/             ← 支付服务（未来）
│   │   ├── notification/        ← 推送服务（未来）
│   │   └── README.md            ← 说明：业务服务职责、判断标准
│   │
│   └── features/                ← 业务功能层
│       ├── feature_home/
│       ├── feature_detail/
│       └── README.md
│
└── pubspec.yaml
```

### 每个 feature package 的标准结构

```
packages/features/feature_home/
├── lib/
│   ├── feature_home.dart        ← 公开出口（barrel file）
│   └── src/
│       ├── models/              ← 页面特定数据模型（新增）
│       │   ├── home_banner.dart
│       │   ├── home_section.dart
│       │   └── README.md        ← 说明：什么放这里 vs domain
│       │
│       ├── usecase/             ← 单 feature 复杂逻辑（新增）
│       │   ├── validate_order_usecase.dart
│       │   └── README.md        ← 说明：何时用 UseCase vs Cubit 方法
│       │
│       ├── repository/
│       │   ├── home_repository.dart
│       │   └── home_repository_impl.dart
│       ├── cubit/
│       │   ├── home_cubit.dart
│       │   └── home_state.dart
│       └── ui/
│           └── home_page.dart
├── test/
│   └── feature_home_test.dart
└── pubspec.yaml
```

### feature/models/ README.md 示例

```markdown
# models 目录

存放页面特定数据模型（纯 Dart 类，无 Flutter 依赖）。

## 判断标准

问自己："这是核心业务数据吗？还是不确定是否共用？"

- ✓ 核心业务数据（User、Product、Order）→ 放 domain/models/
- ✓ 不确定是否共用 → 先放这里，发现共用再迁移
- ✗ 确定单 feature 使用 → 放这里

## 示例

| 模型 | 是否核心业务 | 放哪 |
|-----|------------|-----|
| HomeBanner | 首页轮播，页面特定 | feature_home/models/ |
| FilterOption | 搜索筛选，页面特定 | feature_search/models/ |
| Product | 商品，核心业务 | domain/models/ |
| User | 用户，核心业务 | domain/models/ |

## 迁移流程

当发现其他 feature 也需要：
1. 移动文件到 domain/models/
2. 更新 import（2+ feature）
3. 迁移成本约 45 秒

## 约定

- 纯 Dart 类，无 Flutter 依赖
- 提供 fromJson/toJson（如有网络需求）
```

---

## Model 放置策略

### 判断标准（两个问题）

**问题1**："这是核心业务数据吗？"

核心业务数据 = 业务领域的基础实体，即使暂时单 feature 使用，其他地方迟早会用到。

| Model | 是否核心业务 | 放哪 |
|-------|------------|-----|
| User（用户） | ✓ 核心 | domain/models/ |
| Product（商品） | ✓ 核心 | domain/models/ |
| Order（订单） | ✓ 核心 | domain/models/ |
| Review（评价） | ✓ 核心 | domain/models/ |
| HomeBanner（首页轮播） | ✗ 页面特定 | feature_home/models/ |
| SearchResult（搜索结果） | ✗ 页面特定 | feature_search/models/ |
| FilterOption（筛选条件） | ✗ 页面特定 | feature_search/models/ |

**问题2**："不确定时怎么处理？"

- 不确定 → 先放 feature/models/
- 发现 2+ feature 使用 → 迁移到 domain/models/
- 迁移成本低（约 45 秒）

### 迁移成本分析

| 步骤 | 操作 | 时间 |
|-----|-----|-----|
| 1 | 移动文件 | 10秒 |
| 2 | 更新 import | 30秒 |
| 3 | flutter analyze | 5秒 |
| **总计** | | **45秒** |

**结论**：迁移成本低，不必过度设计。

### 开发策略

```
开发初期：
  ├─ 核心业务数据 → 直接放 domain（即使暂时单 feature）
  │   ├─ User
  │   ├─ Product
  │   ├─ Order
  │   └─ Review
  │
  ├─ 不确定的数据 → 先放 feature，发现共用再迁移
  │
  └─ 页面特定数据 → 放 feature
  │   ├─ HomeBanner
  │   ├─ FilterOption
  │   └─ DetailMeta
```

**原则**：宁可先放 feature 后迁移，不要过早放 domain 导致臃肿。

---

## UseCase 放置策略

### UseCase 存在的意义

**问题**：复杂业务逻辑放哪？

| 位置 | 适合放什么 | 不适合放什么 |
|-----|----------|-------------|
| Cubit | 状态管理 + 简单逻辑 | 多 Repository 协调、复杂业务流程 |
| Repository | 数据获取 | 业务编排、多 Repo 协调 |
| UseCase | 业务逻辑编排 | 状态管理、纯数据获取 |

### 判断标准（三个问题）

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

| 问题 | 回答 | 结论 |
|-----|-----|-----|
| 1. 需要协调多个 Repository？ | ✓ 需要 → UseCase | ✗ 单 Repository → Cubit 直接调用 |
| 2. 业务逻辑复杂（多步骤）？ | ✓ 复杂 → UseCase | ✗ 简单 → Cubit 内方法 |
| 3. 多 feature 共用？ | ✓ 共用 → domain/usecase/ | ✗ 单 feature → feature/usecase/ |

### 示例对比

**不需要 UseCase**（Cubit 直接调用 Repository）：

```dart
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repo;

  Future<void> loadData() async {
    emit(HomeLoading());
    final data = await _repo.getHomeData();  // ← 直接调用
    emit(HomeLoaded(data));
  }
}
```

**需要 UseCase（domain）**（多 Repository 协调 + 多 feature 共用）：

```dart
// domain/lib/src/usecase/get_user_info_usecase.dart
class GetUserInfoUseCase {
  final UserRepository _userRepo;
  final CacheRepository _cacheRepo;
  final KeyValueStorage _storage;

  Future<UserProfile> execute() async {
    // 步骤1：检查本地缓存
    final cached = await _cacheRepo.get<UserProfile>('user');
    if (cached != null && !cached.isExpired) return cached;

    // 步骤2：从网络获取
    final token = await _storage.getString('token');
    final fresh = await _userRepo.fetchProfile(token);

    // 步骤3：更新缓存
    await _cacheRepo.set('user', fresh);
    return fresh;
  }
}

// 使用：首页、个人中心、评价页都调用这个 UseCase
```

**需要 UseCase（feature）**（复杂逻辑但单 feature 使用）：

```dart
// feature_order/lib/src/usecase/place_order_usecase.dart
class PlaceOrderUseCase {
  final OrderRepository _orderRepo;
  final CartRepository _cartRepo;
  final InventoryRepository _inventoryRepo;

  Future<OrderResult> execute(List<CartItem> items) async {
    // 步骤1：验证库存
    for (final item in items) {
      final available = await _inventoryRepo.checkStock(item.productId);
      if (available < item.quantity) {
        throw InsufficientStockException(item.productId);
      }
    }

    // 步骤2：计算总价
    final total = items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

    // 步骤3：创建订单
    final order = await _orderRepo.create(items, total);

    // 步骤4：清空购物车
    await _cartRepo.clear();

    return OrderResult(order: order, total: total);
  }
}

// 使用：只有订单页用，放 feature_order/usecase/
```

### 各层职责总结

| 层 | 职责 | 示例 |
|---|-----|-----|
| **Cubit** | 状态管理 + 简单逻辑 | loadData() → emit() |
| **Cubit 内方法** | 单 Repository + 简单步骤 | validateForm() |
| **feature/usecase** | 复杂逻辑 + 单 feature | PlaceOrderUseCase |
| **domain/usecase** | 复杂逻辑 + 多 feature 共用 | GetUserInfoUseCase |

### 开发建议

| 场景 | 建议 |
|-----|-----|
| **初期** | 先用 Cubit 内方法，发现复杂再抽 UseCase |
| **重构** | Cubit 方法 > 20 行 → 抽 UseCase |
| **共用** | 发现 2+ feature 调用 → 从 feature 迁移到 domain |

---

### feature/usecase/ README.md 示例

```markdown
# usecase 目录

存放单 feature 的复杂业务逻辑编排。

## 判断标准

问自己三个问题：

1. 需要多 Repository 协调？
   - ✓ 需要 → UseCase
   - ✗ 单 Repository → Cubit 直接调用

2. 逻辑复杂（多步骤）？
   - ✓ 复杂 → UseCase
   - ✗ 简单 → Cubit 内方法

3. 多 feature 共用？
   - ✓ 共用 → domain/usecase/
   - ✗ 单 feature → 放这里

## 示例

| UseCase | 多 Repo 协调 | 复杂逻辑 | 多 feature 共用 | 放哪 |
|---------|------------|---------|---------------|-----|
| PlaceOrderUseCase | ✓（订单、购物车、库存） | ✓（4 步） | ✗（只订单页） | feature_order/usecase/ |
| ValidatePaymentUseCase | ✓（支付、订单） | ✓（3 步） | ✗ | feature_order/usecase/ |
| GetUserInfoUseCase | ✓（用户、缓存、存储） | ✓（3 步） | ✓（首页、个人中心） | domain/usecase/ |

## 约定

- 纯 Dart 类，无 Flutter 依赖
- 单一 execute() 方法
- 构造函数注入所需 Repository
- 返回业务结果或抛出异常

## 迁移流程

当发现其他 feature 也需要：
1. 移动到 domain/usecase/
2. 更新 import（2+ feature）
3. 迁移成本约 1 分钟
```

---

### feature package pubspec.yaml 模板

```yaml
name: feature_home
description: 首页功能模块
publish_to: 'none'

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  get_it: ^7.6.0

  # 基础设施包
  api:
    path: ../../api
  domain:
    path: ../../domain
  component_library:    ← 包含 theme + logger + constants
    path: ../../component_library
  routing:
    path: ../../routing
  auth:
    path: ../../auth

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.0
  mocktail: ^0.3.0
```

## Capabilities

### New Capabilities
- `feature-packaging`: Feature 作为独立 Flutter package 的规范，包括目录结构、pubspec 模板、导出约定
- `package-boundary`: 编译器级别的 feature 依赖约束，防止循环依赖和未声明引用
- `component-library-expansion`: 将 theme、AppLogger、AppConstants 合并到 component_library 的规范

### Modified Capabilities
- `feature-structure`: 从 lib/features/ 目录结构改为 packages/features/feature_X/ 包结构
- `dependency-injection`: DI 注册从本地 import 改为 package import，支持 feature 自注册
- `testing-templates`: 每个 feature package 有独立测试目录

---

## pubspec.yaml 配置示例

### 主 app pubspec.yaml

```yaml
# my_app/pubspec.yaml
name: my_app
description: 主应用
publish_to: 'none'

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # ===== 基础设施层（infrastructure）=====
  api:
    path: packages/infrastructure/api
  routing:
    path: packages/infrastructure/routing
  key_value_storage:
    path: packages/infrastructure/key_value_storage
  component_library:
    path: packages/infrastructure/component_library

  # ===== 数据定义层（domain）=====
  domain:
    path: packages/domain

  # ===== 业务服务层（services）=====
  auth:
    path: packages/services/auth
  data_sync:
    path: packages/services/data_sync

  # ===== 业务功能层（features）=====
  feature_home:
    path: packages/features/feature_home
  feature_detail:
    path: packages/features/feature_detail

  # ===== 通用依赖 =====
  flutter_bloc: ^8.1.0
  get_it: ^7.6.0
  go_router: ^14.2.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.0
  mocktail: ^0.3.0
```

### infrastructure/api pubspec.yaml

```yaml
# packages/infrastructure/api/pubspec.yaml
name: api
description: HTTP client based on Dio
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.2.0+1
  rxdart: ^0.27.1
  key_value_storage:
    path: ../key_value_storage
  domain:
    path: ../../domain
  crypto: ^3.0.3
  uuid: ^4.5.0
  connectivity_plus: ^6.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^0.3.0
```

### infrastructure/component_library pubspec.yaml

```yaml
# packages/infrastructure/component_library/pubspec.yaml
name: component_library
description: Shared widgets, theme, and utilities
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

### domain pubspec.yaml

```yaml
# packages/domain/pubspec.yaml
name: domain
description: Shared business domain - models, state, usecases
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0    # Cubit 需要
  equatable: ^2.0.5       # State/Model 值比较
  hive: ^2.2.3            # 适配器需要

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^0.3.0
```

### services/auth pubspec.yaml

```yaml
# packages/services/auth/pubspec.yaml
name: auth
description: Authentication service
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  api:
    path: ../../infrastructure/api
  key_value_storage:
    path: ../../infrastructure/key_value_storage
  domain:
    path: ../../domain

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^0.3.0
```

### services/data_sync pubspec.yaml

```yaml
# packages/services/data_sync/pubspec.yaml
name: data_sync
description: Data synchronization service
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  api:
    path: ../../infrastructure/api
  key_value_storage:
    path: ../../infrastructure/key_value_storage
  domain:
    path: ../../domain

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

### features/feature_home pubspec.yaml

```yaml
# packages/features/feature_home/pubspec.yaml
name: feature_home
description: Home feature module
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  get_it: ^7.6.0

  # ===== 基础设施层 =====
  api:
    path: ../../infrastructure/api
  routing:
    path: ../../infrastructure/routing
  component_library:
    path: ../../infrastructure/component_library

  # ===== 数据定义层 =====
  domain:
    path: ../../domain

  # ===== 业务服务层 =====
  auth:
    path: ../../services/auth

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.0
  mocktail: ^0.3.0
```

### features/feature_detail pubspec.yaml

```yaml
# packages/features/feature_detail/pubspec.yaml
name: feature_detail
description: Detail feature module
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  get_it: ^7.6.0

  # ===== 基础设施层 =====
  api:
    path: ../../infrastructure/api
  routing:
    path: ../../infrastructure/routing
  component_library:
    path: ../../infrastructure/component_library

  # ===== 数据定义层 =====
  domain:
    path: ../../domain

  # ===== 业务服务层 =====
  auth:
    path: ../../services/auth

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.0
  mocktail: ^0.3.0
```

---

## DI 注册示例

### 各 package 的 DI setup 函数

**auth 包 setup**：

```dart
// packages/services/auth/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'package:auth/src/manager.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:domain/domain.dart';

void setupAuth(GetIt sl) {
  // AuthManager 是 Singleton（长期存在）
  sl.registerSingleton<AuthManager>(
    AuthManager(
      api: sl<Api>(),
      storage: sl<KeyValueStorage>(),
      userCubit: sl<UserCubit>(),
    ),
  );
}
```

**data_sync 包 setup**：

```dart
// packages/services/data_sync/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'package:data_sync/src/manager.dart';

void setupDataSync(GetIt sl) {
  // DataSyncManager 是 Singleton
  sl.registerSingleton<DataSyncManager>(DataSyncManager(
    api: sl<Api>(),
    storage: sl<KeyValueStorage>(),
  ));
}
```

**domain 包 setup**：

```dart
// packages/domain/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'package:domain/domain.dart';

void setupDomain(GetIt sl) {
  // 全局业务状态 Cubit（Singleton）
  sl.registerSingleton<UserCubit>(UserCubit(
    storage: sl<KeyValueStorage>(),
    api: sl<Api>(),
  ));

  // UseCase（Factory - 每次创建新实例）
  sl.registerFactory<GetUserInfoUseCase>(() => GetUserInfoUseCase(
    userRepo: sl<UserRepository>(),
    cacheRepo: sl<CacheRepository>(),
  ));
}
```

**feature_home 包 setup**：

```dart
// packages/features/feature_home/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'package:feature_home/feature_home.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:auth/auth.dart';

void setupFeatureHome(GetIt sl) {
  // Repository（Factory）
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(
    api: sl<Api>(),
  ));

  // Cubit（Factory - 页面级状态）
  sl.registerFactory<HomeCubit>(() => HomeCubit(
    repo: sl<HomeRepository>(),
    authManager: sl<AuthManager>(),
    networkCubit: sl<NetworkCubit>(),  // 从主 app 获取
  ));
}
```

**feature_detail 包 setup**：

```dart
// packages/features/feature_detail/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:api/api.dart';
import 'package:auth/auth.dart';

void setupFeatureDetail(GetIt sl) {
  sl.registerFactory<DetailRepository>(() => DetailRepositoryImpl(
    api: sl<Api>(),
  ));

  sl.registerFactory<DetailCubit>(() => DetailCubit(
    repo: sl<DetailRepository>(),
    authManager: sl<AuthManager>(),
  ));
}
```

### 主 app DI setup（调用各包 setup）

```dart
// lib/core/di/setup.dart
import 'package:get_it/get_it.dart';

// ===== 基础设施层 =====
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:routing/routing.dart';

// ===== 数据定义层 =====
import 'package:domain/domain.dart';

// ===== 业务服务层 =====
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';

// ===== 业务功能层 =====
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart';

// ===== 主 app 内部 =====
import 'lib/core/utils/logger.dart';
import 'lib/core/global/network/network_cubit.dart';
import 'lib/core/global/locale/locale_cubit.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ===== 1. 基础设施层注册 =====
  // KeyValueStorage（最底层）
  sl.registerSingleton<KeyValueStorage>(KeyValueStorageImpl());

  // Api（依赖 KeyValueStorage）
  sl.registerSingleton<Api>(Api(
    storage: sl<KeyValueStorage>(),
    logger: AppLogger(),  // AppLogger 在主 app 实现
  ));

  // Routing
  sl.registerSingleton<AppRouter>(AppRouter());

  // ===== 2. 数据定义层注册 =====
  setupDomain(sl);

  // ===== 3. 应用状态注册（主 app core/global）=====
  // NetworkCubit（不依赖登录，应用级状态）
  sl.registerSingleton<NetworkCubit>(NetworkCubit());

  // LocaleCubit（不依赖登录，应用级状态）
  sl.registerSingleton<LocaleCubit>(LocaleCubit(
    storage: sl<KeyValueStorage>(),
  ));

  // ===== 4. 业务服务层注册 =====
  setupAuth(sl);
  setupDataSync(sl);

  // ===== 5. 业务功能层注册 =====
  setupFeatureHome(sl);
  setupFeatureDetail(sl);
}
```

### main.dart（注入全局状态到 Widget 树）

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'package:routing/routing.dart';
import 'core/di/setup.dart';
import 'core/global/network/network_cubit.dart';
import 'core/global/locale/locale_cubit.dart';
import 'core/widgets/network/network_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DI 注册
  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ===== 应用状态（不依赖登录）=====
        BlocProvider<NetworkCubit>(
          create: (_) => sl<NetworkCubit>(),
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => sl<LocaleCubit>(),
        ),

        // ===== 全局业务状态（登录后才有）=====
        BlocProvider<UserCubit>(
          create: (_) => sl<UserCubit>(),
        ),
      ],
      child: NetworkBanner(  // 网络状态 Banner 包裹整个 app
        child: BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            return MaterialApp.router(
              routerConfig: sl<AppRouter>().config,
              locale: localeState.locale,
              supportedLocales: const [Locale('zh'), Locale('en')],
            );
          },
        ),
      ),
    );
  }
}
```

### Singleton vs Factory 选择标准

| 类型 | 注册方式 | 原因 |
|-----|---------|-----|
| **业务服务（AuthManager）** | Singleton | 长期存在、有状态 |
| **全局业务状态（UserCubit）** | Singleton | 多 feature 共用 |
| **应用状态（NetworkCubit）** | Singleton | app 级别 |
| **UseCase** | Factory | 无状态、每次新建 |
| **Repository** | Factory | 页面级使用 |
| **页面 Cubit** | Factory | 页面级状态、页面销毁时释放 |

---

## 验证检查清单

### Phase 0.x 完成后验证

**Phase 0.1（目录结构）**：

```bash
# 验证命令
cd packages/infrastructure
ls -la api/ routing/ key_value_storage/ component_library/
# 确认每个 package 有 pubspec.yaml

cd packages/services
ls -la auth/ data_sync/
# 确认每个 package 有 pubspec.yaml

cd packages/features
ls -la feature_home/ feature_detail/
# 确认每个 package 有 pubspec.yaml

# 检查 README
cat packages/infrastructure/README.md
cat packages/services/README.md
cat packages/features/README.md

# 验证依赖
flutter pub get
```

**Phase 0.2（component_library 扩展）**：

```bash
# 验证 constants 迁移
ls packages/infrastructure/component_library/lib/src/constants/
cat packages/infrastructure/component_library/lib/component_library.dart
# 确认 export 'src/constants/...';

# 检查 import 路径更新
grep -r "lib/core/constants" lib/
# 应返回空（无残留引用）

flutter analyze
flutter test
```

**Phase 0.3（domain 改名）**：

```bash
# 验证改名
ls packages/domain/
cat packages/domain/pubspec.yaml
# name: domain

# 检查 import 更新
grep -r "package:domain_models" packages/
grep -r "package:domain_models" lib/
# 应返回空

flutter pub get
flutter analyze
```

**Phase 0.4（业务服务包提取）**：

```bash
# 验证 auth 包
ls packages/services/auth/lib/src/
cat packages/services/auth/lib/auth.dart
flutter analyze packages/services/auth/

# 验证 data_sync 包
ls packages/services/data_sync/lib/src/
flutter analyze packages/services/data_sync/

# 检查残留
ls lib/core/auth/
ls lib/core/sync/
# 应不存在或为空

flutter test packages/services/auth/
flutter test packages/services/data_sync/
```

### Phase 1.x 完成后验证

**Phase 1（feature_home）**：

```bash
# 验证结构
ls packages/features/feature_home/lib/src/
ls packages/features/feature_home/lib/src/models/
ls packages/features/feature_home/lib/src/usecase/

# 检查 barrel file
cat packages/features/feature_home/lib/feature_home.dart

# 检查 README
cat packages/features/feature_home/README.md
cat packages/features/feature_home/lib/src/models/README.md
cat packages/features/feature_home/lib/src/usecase/README.md

# 独立测试
cd packages/features/feature_home
flutter test

# 检查 import 路径
grep -r "package:feature_home/src" packages/features/feature_home/
flutter analyze packages/features/feature_home/
```

**Phase 2（feature_detail）**：

```bash
# 同 feature_home 验证流程
ls packages/features/feature_detail/lib/src/
cd packages/features/feature_detail && flutter test
flutter analyze packages/features/feature_detail/
```

### Phase 3（清理与最终验证）

```bash
# ===== 清理验证 =====
# 检查旧目录删除
ls lib/features/
ls lib/core/auth/
ls lib/core/sync/
ls lib/core/constants/
# 应不存在或为空

# 检查残留引用
grep -r "lib/features/" lib/
grep -r "lib/core/auth/" lib/
grep -r "lib/core/sync/" lib/
# 应返回空

# ===== 全量验证 =====
flutter pub get
flutter analyze
flutter test

# 编译验证
flutter build apk --debug
flutter build ios --debug

# ===== 运行验证 =====
flutter run
# 手动验证：
# - 首页加载正常
# - 详情页加载正常
# - 网络断开时 Banner 显示
# - 语言切换正常
# - 登录/登出流程正常
```

### 每个 package 独立验证标准

| Package | 验证命令 | 验证内容 |
|---------|---------|---------|
| infrastructure/api | `flutter analyze packages/infrastructure/api/` | 无 import 错误 |
| infrastructure/routing | `flutter analyze packages/infrastructure/routing/` | 无 import 错误 |
| infrastructure/component_library | `flutter analyze packages/infrastructure/component_library/` | 无 import 错误 |
| domain | `flutter analyze packages/domain/` | 无 import 错误 |
| services/auth | `flutter analyze packages/services/auth/` + `flutter test` | 无错误 + 测试通过 |
| services/data_sync | `flutter analyze packages/services/data_sync/` | 无 import 错误 |
| features/feature_home | `cd packages/features/feature_home && flutter test` | 独立测试通过 |
| features/feature_detail | `cd packages/features/feature_detail && flutter test` | 独立测试通过 |
| 主 app | `flutter analyze` + `flutter test` + `flutter build apk --debug` | 全量通过 |

---

## 测试策略

### 每个 package 独立测试

| Package | 测试目录 | 测试内容 | 运行命令 |
|---------|---------|---------|---------|
| infrastructure/api | test/ | HTTP 拦截器、错误处理 | `cd packages/infrastructure/api && flutter test` |
| infrastructure/routing | test/ | 路由配置 | `cd packages/infrastructure/routing && flutter test` |
| domain | test/ | Models、UseCase | `cd packages/domain && flutter test` |
| services/auth | test/ | AuthManager、登录流程 | `cd packages/services/auth && flutter test` |
| features/feature_home | test/ | HomeCubit、Repository | `cd packages/features/feature_home && flutter test` |
| features/feature_detail | test/ | DetailCubit | `cd packages/features/feature_detail && flutter test` |

### Mock 依赖策略

**原则**：测试时 mock 外部依赖，不依赖真实实现。

| 测试对象 | 需 mock 的依赖 | mock 方式 |
|---------|--------------|----------|
| **Cubit** | Repository、Service | Mocktail.mock() |
| **UseCase** | Repository | Mocktail.mock() |
| **Repository** | Api | Mocktail.mock() |
| **AuthManager** | Api、Storage | Mocktail.mock() |

### Cubit 测试示例

```dart
// packages/features/feature_home/test/home_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_home/feature_home.dart';
import 'package:api/api.dart';
import 'package:auth/auth.dart';
import 'package:domain/domain.dart';

class MockHomeRepository extends Mock implements HomeRepository {}
class MockAuthManager extends Mock implements AuthManager {}
class MockNetworkCubit extends MockCubit<NetworkState> implements NetworkCubit {}

void main() {
  group('HomeCubit', () {
    late HomeCubit cubit;
    late MockHomeRepository mockRepo;
    late MockAuthManager mockAuth;
    late MockNetworkCubit mockNetwork;

    setUp(() {
      mockRepo = MockHomeRepository();
      mockAuth = MockAuthManager();
      mockNetwork = MockNetworkCubit();

      // 设置 mock 行为
      when(() => mockAuth.isLoggedIn).thenReturn(true);
      when(() => mockNetwork.state).thenReturn(NetworkState.connected());

      cubit = HomeCubit(
        repo: mockRepo,
        authManager: mockAuth,
        networkCubit: mockNetwork,
      );
    });

    blocTest<HomeCubit, HomeState>(
      'emit [HomeLoading, HomeLoaded] when loadData success',
      build: () => cubit,
      act: (cubit) => cubit.loadData(),
      setUp: () {
        when(() => mockRepo.getHomeData()).thenAnswer(
          (_) async => {'title': 'Test'},
        );
      },
      expect: () => [HomeLoading(), HomeLoaded(data: {'title': 'Test'})],
    );

    blocTest<HomeCubit, HomeState>(
      'emit [HomeOffline] when network disconnected',
      build: () => cubit,
      setUp: () {
        when(() => mockNetwork.state).thenReturn(NetworkState.disconnected());
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [HomeOffline()],
    );
  });
}
```

### UseCase 测试示例

```dart
// packages/domain/test/usecase/get_user_info_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockCacheRepository extends Mock implements CacheRepository {}

void main() {
  group('GetUserInfoUseCase', () {
    late GetUserInfoUseCase usecase;
    late MockUserRepository mockUserRepo;
    late MockCacheRepository mockCacheRepo;

    setUp(() {
      mockUserRepo = MockUserRepository();
      mockCacheRepo = MockCacheRepository();
      usecase = GetUserInfoUseCase(mockUserRepo, mockCacheRepo);
    });

    test('return cached user when cache valid', () async {
      final cachedUser = UserProfile(id: '1', name: 'Cached');
      when(() => mockCacheRepo.get<UserProfile>('user'))
          .thenAnswer((_) async => cachedUser);

      final result = await usecase.execute();

      expect(result, cachedUser);
      verifyNever(() => mockUserRepo.fetchProfile());
    });

    test('fetch from api when cache expired', () async {
      when(() => mockCacheRepo.get<UserProfile>('user'))
          .thenAnswer((_) async => null);

      final freshUser = UserProfile(id: '2', name: 'Fresh');
      when(() => mockUserRepo.fetchProfile())
          .thenAnswer((_) async => freshUser);

      final result = await usecase.execute();

      expect(result, freshUser);
      verify(() => mockCacheRepo.set('user', freshUser)).called(1);
    });
  });
}
```

### AuthManager 测试示例

```dart
// packages/services/auth/test/auth_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auth/auth.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:domain/domain.dart';

class MockApi extends Mock implements Api {}
class MockKeyValueStorage extends Mock implements KeyValueStorage {}
class MockUserCubit extends MockCubit<UserState> implements UserCubit {}

void main() {
  group('AuthManager', () {
    late AuthManager manager;
    late MockApi mockApi;
    late MockKeyValueStorage mockStorage;
    late MockUserCubit mockUserCubit;

    setUp(() {
      mockApi = MockApi();
      mockStorage = MockKeyValueStorage();
      mockUserCubit = MockUserCubit();
      manager = AuthManager(mockApi, mockStorage, mockUserCubit);
    });

    test('isLoggedIn is false initially', () {
      expect(manager.isLoggedIn, false);
    });

    test('login success updates state', () async {
      when(() => mockApi.login('user', 'pass'))
          .thenAnswer((_) async => LoginResponse(token: 'test_token'));
      when(() => mockStorage.saveToken('test_token'))
          .thenAnswer((_) async {});

      await manager.login('user', 'pass');

      expect(manager.isLoggedIn, true);
      verify(() => mockStorage.saveToken('test_token')).called(1);
    });

    test('logout clears state', () async {
      // 先登录
      when(() => mockApi.login('user', 'pass'))
          .thenAnswer((_) async => LoginResponse(token: 'test_token'));
      when(() => mockStorage.saveToken('test_token'))
          .thenAnswer((_) async {});
      await manager.login('user', 'pass');

      // 再登出
      when(() => mockStorage.removeToken()).thenAnswer((_) async {});
      when(() => mockUserCubit.emit(any())).thenReturn(null);

      await manager.logout();

      expect(manager.isLoggedIn, false);
      verify(() => mockStorage.removeToken()).called(1);
    });
  });
}
```

### 测试覆盖率要求

| Package | 覆盖率目标 | 重点覆盖 |
|---------|----------|---------|
| infrastructure/api | > 80% | 拦截器、错误处理 |
| domain | > 90% | UseCase 逻辑 |
| services/auth | > 85% | login/logout 流程 |
| features | > 80% | Cubit 状态变化 |

---

## 命名约定

### Package 命名

| 层级 | 命名规则 | 示例 |
|-----|---------|-----|
| **infrastructure** | 技术功能名（无前缀） | api、routing、key_value_storage |
| **domain** | 固定名 | domain |
| **services** | 业务功能名（无前缀） | auth、data_sync、payment |
| **features** | feature_ 前缀 | feature_home、feature_detail、feature_profile |

**判断**：
- infrastructure/services：直接用功能名（api、auth）
- features：加 feature_ 前缀（区分目录名和 package 名）

### 文件命名

| 类型 | 命名规则 | 示例 |
|-----|---------|-----|
| **barrel file** | package 名.dart | auth.dart、feature_home.dart |
| **Cubit** | XXX_cubit.dart | home_cubit.dart、auth_manager.dart |
| **State** | XXX_state.dart | home_state.dart |
| **Repository 接口** | XXX_repository.dart | home_repository.dart |
| **Repository 实现** | XXX_repository_impl.dart | home_repository_impl.dart |
| **UseCase** | XXX_usecase.dart | get_user_info_usecase.dart |
| **Model** | XXX.dart（无后缀） | user_profile.dart、product.dart |
| **页面 Widget** | XXX_page.dart | home_page.dart、detail_page.dart |
| **setup 函数** | setup.dart | setup.dart（在 di 目录） |

### 类命名

| 类型 | 命名规则 | 示例 |
|-----|---------|-----|
| **Cubit** | XXXCubit | HomeCubit、UserCubit |
| **State** | XXXState 或细分 | HomeState、HomeInitial、HomeLoaded |
| **Repository** | XXXRepository | HomeRepository（接口）、HomeRepositoryImpl（实现） |
| **UseCase** | XXXUseCase | GetUserInfoUseCase、PlaceOrderUseCase |
| **Manager** | XXXManager | AuthManager、DataSyncManager |
| **Model** | XXXModel 或 XXX | UserProfile、Product、Order |
| **Page Widget** | XXXPage | HomePage、DetailPage |

### import 别名约定

**避免冲突时使用别名**：

```dart
// 如果两个包有同名类
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart' as detail;

// 使用
final homePage = HomePage();
final detailPage = detail.DetailPage();
```

**常见别名**：
- `detail`：feature_detail
- `profile`：feature_profile
- `home`：feature_home（如有冲突）

---

## 新增 Package 流程

### 新增 feature package

```
场景：需要添加 "feature_profile" 个人中心功能

步骤：

1. 创建目录结构
   mkdir -p packages/features/feature_profile/lib/src/{models,usecase,repository,cubit,ui,di}
   mkdir -p packages/features/feature_profile/test

2. 创建 pubspec.yaml
   参考 feature_home 的配置
   依赖：infrastructure下的包 + domain + services/auth

3. 创建 barrel file
   packages/features/feature_profile/lib/feature_profile.dart
   export 'src/ui/profile_page.dart';
   export 'src/cubit/profile_cubit.dart';
   export 'src/di/setup.dart';

4. 创建 README
   packages/features/feature_profile/README.md（包说明）
   packages/features/feature_profile/lib/src/models/README.md
   packages/features/feature_profile/lib/src/usecase/README.md

5. 创建 DI setup
   packages/features/feature_profile/lib/src/di/setup.dart
   void setupFeatureProfile(GetIt sl) {
     sl.registerFactory<ProfileRepository>(...);
     sl.registerFactory<ProfileCubit>(...);
   }

6. 更新主 app
   - pubspec.yaml 添加依赖：
     feature_profile:
       path: packages/features/feature_profile
   - lib/core/di/setup.dart 添加：
     setupFeatureProfile(sl);
   - routing 包添加路由

7. 验证
   flutter pub get
   flutter analyze packages/features/feature_profile/
   cd packages/features/feature_profile && flutter test
```

### 新增 service package

```
场景：需要添加 "payment" 支付服务

步骤：

1. 创建目录结构
   mkdir -p packages/services/payment/lib/src
   mkdir -p packages/services/payment/test

2. 创建 pubspec.yaml
   name: payment
   dependencies:
     api:
       path: ../../infrastructure/api
     key_value_storage:
       path: ../../infrastructure/key_value_storage
     domain:
       path: ../../domain

3. 创建 barrel file
   packages/services/payment/lib/payment.dart
   export 'src/manager.dart';

4. 创建 Manager
   packages/services/payment/lib/src/manager.dart
   class PaymentManager {
     bool _isProcessing = false;
     Future<PaymentResult> pay(...) async { ... }
   }

5. 创建 README
   packages/services/payment/README.md（服务职责、与 UseCase 区别）

6. 创建 DI setup
   packages/services/payment/lib/src/di/setup.dart
   void setupPayment(GetIt sl) {
     sl.registerSingleton<PaymentManager>(PaymentManager(
       api: sl<Api>(),
       storage: sl<KeyValueStorage>(),
     ));
   }

7. 更新主 app
   - pubspec.yaml 添加依赖
   - lib/core/di/setup.dart 调用 setupPayment(sl)

8. 验证
   flutter pub get
   flutter analyze packages/services/payment/
   cd packages/services/payment && flutter test
```

### 新增 infrastructure package

```
场景：需要添加 "analytics" 数据统计基础设施

步骤：

1. 创建目录结构
   mkdir -p packages/infrastructure/analytics/lib/src
   mkdir -p packages/infrastructure/analytics/test

2. 创建 pubspec.yaml
   name: analytics
   dependencies:
     flutter:
       sdk: flutter
     # 纯技术依赖，不依赖 domain

3. 创建 barrel file
   packages/infrastructure/analytics/lib/analytics.dart
   export 'src/tracker.dart';

4. 创建 Tracker
   packages/infrastructure/analytics/lib/src/tracker.dart
   class AnalyticsTracker {
     void trackEvent(String name, Map<String, dynamic> params) { ... }
   }

5. 创建 README
   packages/infrastructure/analytics/README.md
   说明：纯技术基础设施，无业务逻辑

6. 更新主 app
   - pubspec.yaml 添加：
     analytics:
       path: packages/infrastructure/analytics
   - DI 注册（Singleton）

7. 验证
   flutter pub get
   flutter analyze packages/infrastructure/analytics/
```

---

## 回滚方案

### Git 分支策略

```
main（稳定）
  │
  ├── feature-package-split（迁移分支）
  │     │
  │     ├── phase-0.1（目录结构）
  │     ├── phase-0.2（component_library）
  │     ├── phase-0.3（domain改名）
  │     ├── phase-0.4（services提取）
  │     ├── phase-1（feature_home）
  │     ├── phase-2（feature_detail）
  │     └─ phase-3（清理验证）
  │
  └── 其他 feature 分支...
```

### 每阶段提交

```bash
# Phase 0.1 完成后
git add packages/infrastructure/ packages/services/ packages/features/
git commit -m "phase-0.1: 创建 infrastructure/services/features 目录结构"

# Phase 0.2 完成后
git add packages/infrastructure/component_library/
git commit -m "phase-0.2: 合并 constants 到 component_library"

# Phase 0.3 完成后
git add packages/domain/
git commit -m "phase-0.3: domain_models 改名为 domain"

# ...以此类推
```

### 回滚操作

**回滚单个阶段**：

```bash
# 查看 commit 历史
git log --oneline

# 回滚到上一阶段（保留工作区）
git reset --soft HEAD~1

# 回滚到上一阶段（丢弃工作区）
git reset --hard HEAD~1
```

**完全回滚到迁移前**：

```bash
# 回到主分支
git checkout main

# 删除迁移分支
git branch -D feature-package-split
```

### 迁移前备份

```bash
# 创建备份分支
git checkout -b backup-before-split

# 回到主分支继续迁移
git checkout main
git checkout -b feature-package-split

# 如果迁移失败，回到备份
git checkout backup-before-split
```

---

## 风险提示

### Phase 0 风险

| Phase | 风险点 | 防范措施 |
|-------|-------|---------|
| 0.1 | pubspec.yaml 路径更新遗漏 | grep 检查所有 import |
| 0.2 | constants import 残留 | grep 搜索 "lib/core/constants" |
| 0.3 | domain_models 引用残留 | grep 搜索 "package:domain_models" |
| 0.4 | AuthManager 依赖未更新 | 检查 DI setup 中的 import |

### Phase 1-2 风险

| Phase | 风险点 | 防范措施 |
|-------|-------|---------|
| 1-2 | feature 间循环依赖 | flutter analyze 检查 |
| 1-2 | barrel file export 遗漏 | 检查公开 API 是否完整 |
| 1-2 | 测试 import 错误 | cd package && flutter test |
| 1-2 | routing 包未更新 import | 检查路由配置文件 |

### Phase 3 风险

| Phase | 风险点 | 防范措施 |
|-------|-------|---------|
| 3 | 删除未迁移文件 | 先 flutter analyze 确认无引用 |
| 3 | 编译失败 | flutter build apk --debug |
| 3 | 运行时崩溃 | flutter run 手动验证 |

### 常见问题处理

| 问题 | 表现 | 解决 |
|-----|-----|-----|
| **循环依赖** | flutter analyze 报错 | 检查 feature 间是否有直接 import，改为通过 domain/routing |
| **import 找不到** | 编译错误 | grep 检查所有 import 路径，更新为 package:XXX |
| **测试失败** | flutter test 报错 | 检查测试 import 是否更新，mock 是否正确 |
| **路由失效** | 页面跳转失败 | 检查 routing 包的 import 路径更新 |

---

## FAQ

### Q1: feature 之间如何共享数据？

**A**: 通过 domain 层：

```dart
// feature_home 需要用户头像
// 不直接 import feature_profile

// 正确做法：通过 domain
import 'package:domain/domain.dart';

final user = sl<UserCubit>().state;
if (user is UserLoaded) {
  return Avatar(user.profile.avatar);
}
```

### Q2: feature 之间如何跳转页面？

**A**: 通过 routing 包：

```dart
// feature_home 跳转到 detail
// 不直接 import feature_detail

// 正确做法：通过 routing
import 'package:routing/routing.dart';

context.go(AppRouter.detailPath(id: '123'));
```

### Q3: 什么时候用 UseCase vs Cubit 内方法？

**A**: 判断标准：

| 场景 | 用什么 |
|-----|-----|
| 单 Repository + 简单步骤 | Cubit 内方法 |
| 多 Repository 协调 | UseCase |
| 逻辑 > 20 行 | UseCase |
| 多 feature 共用 | UseCase（domain） |

### Q4: 什么时候用 services vs domain/usecase？

**A**: 判断标准：

| 场景 | 用什么 |
|-----|-----|
| 长期存在 + 有状态 + 提供能力 | services |
| 无状态 + 执行一次性任务 | domain/usecase |

### Q5: domain 为什么是 package 而不是目录？

**A**: domain 需要被多个层依赖：
- services 依赖 domain（获取状态）
- features 依赖 domain（获取数据）

作为 package 可以有独立的 pubspec.yaml，明确依赖关系。

### Q6: AppLogger 为什么不迁移到 component_library？

**A**: AppLogger 实现 api 包的 AppLoggerInterface。如果放在 component_library，会导致：
- component_library 需依赖 api
- 违反"基础设施不依赖业务层"原则

留在 lib/core/utils/ 是正确做法。

### Q7: 如何确保不引入循环依赖？

**A**: 三层防护：

1. **架构设计**：明确依赖方向（features → services → domain → infrastructure）
2. **flutter analyze**：编译器检测循环依赖
3. **Code Review**：review 时检查 import 是否跨层反向引用

### Q8: 测试时如何 mock DI？

**A**: 构造函数注入 + 直接传 mock：

```dart
// 生产环境：DI
final cubit = sl<HomeCubit>();

// 测试环境：直接注入 mock
final mockRepo = MockHomeRepository();
final cubit = HomeCubit(mockRepo, mockAuth);
```

---

## 影响

### 新增文件
- `packages/auth/`（从 lib/core/auth 提取）
- `packages/data_sync/`（从 lib/core/sync 提取）
- `packages/features/feature_home/pubspec.yaml`
- `packages/features/feature_home/lib/feature_home.dart`
- `packages/features/feature_detail/pubspec.yaml`
- `packages/features/feature_detail/lib/feature_detail.dart`
- `packages/component_library/lib/src/logger/`（移入）
- `packages/component_library/lib/src/constants/`（移入）

### 修改文件
- `packages/component_library/lib/component_library.dart`（新增 logger、constants 的 export）
- `lib/core/di/setup.dart`（import 路径变更，改为调用 feature 自注册函数）
- `lib/core/di/locator.dart`（import 路径变更）
- `packages/routing/lib/routing.dart`（import 路径变更）
- `lib/features/` 目录删除（代码已迁移到 packages/）

### 破坏性变更
- `lib/features/` 路径不再存在
- `lib/core/auth/`、`lib/core/sync/` 路径不再存在
- `lib/core/utils/`、`lib/core/constants/` 路径不再存在
- 所有引用这些路径的代码需改为对应 package import

---

## 跨层状态传递方案

### 各层推荐方式

| 层级 | 方式 | 原因 |
|-----|-----|-----|
| **Widget** | BlocBuilder + context.watch | 自动响应状态变化，无需手动监听 |
| **Cubit** | 构造函数注入 | 显式依赖，测试可直接 mock |
| **纯 Dart (UseCase/Repository)** | DI (`sl<T>()`) | 无 context，只能用 DI |

### Widget 层：多层状态处理

当页面需要监听多个状态（本页面 + 全局）：

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

        if (homeState.isLoading) {
          return LoadingIndicator();
        }

        return HomeContent(data: homeState.data, locale: locale.locale);
      },
    );
  }
}
```

**避免嵌套地狱**：一个 BlocBuilder（本页面）+ 多个 context.watch（全局）。

### Cubit 层：构造函数注入

```dart
// packages/features/feature_home/lib/src/cubit/home_cubit.dart
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repo;
  final NetworkCubit _network;  // ← 注入全局状态

  HomeCubit(this._repo, this._network) : super(HomeInitial());

  Future<void> loadData() async {
    if (!_network.state.isConnected) {
      emit(HomeOffline());
      return;
    }
    // 正常加载...
  }
}

// packages/features/feature_home/lib/src/di/setup.dart
void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeCubit>(() => HomeCubit(
    sl<HomeRepository>(),
    sl<NetworkCubit>(),  // ← 从 DI 获取全局状态并注入
  ));
}
```

**测试友好**：

```dart
void main() {
  test('离线时返回 HomeOffline', () async {
    final mockNetwork = MockNetworkCubit();
    final mockRepo = MockRepo();

    final cubit = HomeCubit(mockRepo, mockNetwork);  // ← 直接注入，不依赖 DI

    await cubit.loadData();
    expect(cubit.state, isA<HomeOffline>());
  });
}
```

### 主 app 负责注入全局状态到 Widget 树

```dart
// lib/main.dart
void main() {
  setupDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<NetworkCubit>(create: (_) => sl<NetworkCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
        // 其他全局 Cubit...
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 全局状态归属设计

### 判断标准

| 类型 | 特征 | 示例 | 放哪 |
|-----|-----|-----|-----|
| **应用状态** | 不依赖登录，启动即有 | Network、Locale、Theme | `lib/core/global/` |
| **业务全局数据** | 登录后才有，依赖认证 | User、Token、权限 | `packages/domain` |

### 用户信息设计

```dart
// packages/domain/lib/src/user/user_cubit.dart
class UserCubit extends Cubit<UserState> {
  final KeyValueStorage _storage;

  UserCubit(this._storage) : super(UserInitial());

  Future<void> loadUser() async {
    final token = await _storage.getString('token');
    if (token == null) {
      emit(UserUnauthenticated());
      return;
    }
    // 加载用户信息...
  }

  Future<void> logout() async {
    await _storage.remove('token');
    emit(UserUnauthenticated());
  }
}
```

**为什么放 domain**：
- 多 feature 都需要 → 不放单个 feature
- 纯数据模型 + 状态容器 → 符合 domain 层职责
- 不涉及具体业务逻辑 → 不放 core

---

## core/widgets/ 归属说明

`lib/core/widgets/` 保留在 core，不迁移到 package。

| Widget | 依赖 | 说明 |
|--------|-----|-----|
| `RequestScope` | `api.CancelTokenManager` | 跨层 UI 基础设施 |
| `NetworkBanner` | `NetworkCubit` | 依赖全局状态 |

**原因**：`core/widgets/` 是"组装层的 UI 部分"，依赖 package 合理（组装层本身就要组装各包）。

---

## AppLogger 处理方案

当前 `AppLogger` 实现 `api` 包的 `AppLoggerInterface`。

**问题**：搬入 `component_library` → `component_library` 需依赖 `api`，但组件库依赖网络层不合常理。

**方案**：AppLogger 留在 `lib/core/utils/`，不迁移到 package。

- `AppLoggerInterface` 定义在 `api` 包（已存在）
- `AppLogger` 实现留在 `lib/core/utils/logger.dart`
- DI 注册时注入到 `api` 包的拦截器

**依赖链**：
```
api (定义接口 AppLoggerInterface)
  ↓
lib/core/utils/logger.dart (实现 AppLogger)
  ↓
主 app DI 注册
```

---

## 多 Feature 共用逻辑设计

### Repository vs UseCase

| 场景 | 用什么 | 放哪 |
|-----|-----|-----|
| 纯数据获取 | Repository | `packages/domain` 或相关 feature |
| 多 Repository 协调 | UseCase | `packages/domain` |
| 单 feature 内部逻辑 | Cubit 内方法 | feature 包内 |

### UseCase 示例

```dart
// packages/domain/lib/src/usecase/get_user_info_usecase.dart
class GetUserInfoUseCase {
  final UserProfileRepository _userRepo;
  final CacheRepository _cacheRepo;

  GetUserInfoUseCase(this._userRepo, this._cacheRepo);

  Future<UserProfile> execute() async {
    // 先查缓存
    final cached = await _cacheRepo.get<UserProfile>('user');
    if (cached != null && !cached.isExpired) return cached;

    // 缓存失效，从网络获取
    final fresh = await _userRepo.fetch();
    await _cacheRepo.set('user', fresh);
    return fresh;
  }
}
```

---

## domain 包规划（原 domain_models 改名）

### 改名原因

`domain_models` 名字暗示只放模型，但实际需要放：Cubit（全局状态）、UseCase（共用逻辑）、Repository 接口。改名 `domain` 更准确，涵盖"业务域"相关的一切。

### 目录结构

```
packages/domain/
├── lib/
│   ├── domain.dart                    ← barrel file
│   └── src/
│       │
│       ├── models/                    ← 共用数据模型（纯 Dart，无 Flutter 依赖）
│       │   ├── user_profile.dart      ← 用户详情（头像、昵称、手机号）
│       │   ├── README.md              ← 说明：什么放 models、判断标准
│       │   └── response.dart          ← 通用响应结构
│       │
│       ├── enums/                     ← 业务枚举（纯 Dart）
│       │   ├── application_types.dart ← 已有（ApplicationTypes）
│       │   ├── README.md              ← 说明：业务级别枚举 vs 页面级枚举
│       │   └── error_code.dart        ← 已有（ErrorCode）
│       │
│       ├── exceptions/                ← 业务异常（纯 Dart）
│       │   ├── domain_exception.dart  ← 已有
│       │   └── README.md              ← 说明：全局异常 vs feature 内部异常
│       │
│       ├── state/                     ← 全局业务状态（依赖 flutter_bloc）
│       │   ├── README.md              ← 说明：全局状态 vs 页面级状态
│       │   ├── user/                  ← 用户状态
│       │   │   ├── user_cubit.dart
│       │   │   ├── user_state.dart
│       │   │   └── README.md          ← 说明：UserCubit 职责、使用方式
│       │   │
│       │   └── cart/                  ← 购物车状态（如有，示例）
│       │       ├── cart_cubit.dart
│       │       ├── cart_state.dart
│       │       └ README.md
│       │
│       ├── usecase/                   ← 共用业务逻辑
│       │   ├── README.md              ← 说明：UseCase vs Cubit 内方法
│       │   ├── get_user_info_usecase.dart
│       │   └ sync_data_usecase.dart
│       │
│       ├── repository/                ← 共用 Repository 接口（可选）
│       │   ├── README.md              ← 说明：什么放 domain/repository、什么放 feature
│       │   ├── user_repository.dart   ← 用户相关接口
│       │   └ product_repository.dart ← 商品相关接口
│       │
│       └── adapters/                  ← Hive/其他存储适配器
│           ├── README.md              ← 说明：适配器职责、注册流程
│           ├── user_adapter.dart      ← 已有
│           └ registrar.dart         ← 已有
│
├── test/
│   └── domain_test.dart
├── README.md                          ← domain 包整体说明
└── pubspec.yaml                       ← 依赖 flutter_bloc、equatable、hive
```

### 各目录职责与判断标准

| 目录 | 内容 | 依赖 Flutter | 判断标准 |
|-----|-----|-------------|---------|
| **models/** | 共用数据模型 | 否 | 2+ feature 共用 → domain；单 feature → feature |
| **enums/** | 业务枚举 | 否 | 业务级别 → domain；页面级 → feature |
| **exceptions/** | 全局异常 | 否 | 全局通用 → domain；feature 内部 → feature |
| **state/** | 全局业务状态 Cubit | 是（flutter_bloc） | 多 feature 需 → domain；页面级 → feature |
| **usecase/** | 共用业务逻辑 | 否 | 多 feature 共用 → domain；单 feature → feature |
| **repository/** | 共用 Repository 接口 | 否 | 多 feature 共用 → domain；单 feature → feature |
| **adapters/** | Hive 适配器 | 否（hive） | 共用模型的适配器 |

### domain 包 README.md 示例

```markdown
# domain 包

共享业务域 - 模型、状态、用例、仓库接口。

## 职责

存放多 feature 共用的业务相关内容：
- 数据模型（UserProfile、Product、Order 等）
- 全局业务状态（UserCubit、CartCubit 等）
- 共用业务逻辑（UseCase）
- 共用 Repository 接口

## 不放什么

- 页面级状态 → 放对应 feature 的 cubit/
- 单 feature 专用模型 → 放对应 feature 的 models/
- Repository 实现 → 放对应 feature 的 repository/
- 应用级状态（Network、Locale） → 放 lib/core/global/

## 依赖关系

```
domain
  ↓
api、key_value_storage（数据来源）
  ↓
被 features、auth、data_sync 依赖
```

## 目录说明

- models/ - 共用数据模型，README 有判断标准
- enums/ - 业务枚举，README 有判断标准
- exceptions/ - 全局异常，README 有判断标准
- state/ - 全局业务状态，README 有判断标准
- usecase/ - 共用业务逻辑，README 有判断标准
- repository/ - 共用接口，README 有判断标准
- adapters/ - Hive 适配器，README 有判断标准
```

### domain/models/ README.md 示例

```markdown
# models 目录

存放共用数据模型（纯 Dart 类，无 Flutter 依赖）。

## 判断标准

问自己："这个模型有 2+ feature 要用吗？"

- ✓ 多 feature 共用 → 放这里
- ✗ 单 feature 专用 → 放对应 feature 的 models/

## 示例

| 模型 | 用途 | 是否共用 | 放哪 |
|-----|-----|---------|-----|
| UserProfile | 首页头像、个人中心、评价、订单 | ✓ | domain/models/ |
| Product | 首页列表、详情、订单 | ✓ | domain/models/ |
| Order | 订单页、评价页 | ✓ | domain/models/ |
| HomeData | 只首页 | ✗ | feature_home/models/ |
| DetailData | 只详情页 | ✗ | feature_detail/models/ |

## 约定

- 所有模型必须是纯 Dart 类
- 不可依赖 Flutter SDK
- 提供 fromJson/toJson 方法（如有网络传输需求）
- 使用 equatable 进行值比较（可选）
```

### domain/state/ README.md 示例

```markdown
# state 目录

存放全局业务状态 Cubit（依赖 flutter_bloc）。

## 判断标准

问自己："这个状态有 2+ feature 要访问吗？"

- ✓ 多 feature 需 → 放这里
- ✗ 单 feature 页面级 → 放对应 feature 的 cubit/

## 示例

| Cubit | 用途 | 是否全局 | 放哪 |
|-----|-----|---------|-----|
| UserCubit | 首页头像、个人中心、评价、订单 | ✓ | domain/state/user/ |
| CartCubit | 首页数量、详情加购、订单结算 | ✓ | domain/state/cart/ |
| HomeCubit | 只首页数据加载 | ✗ | feature_home/cubit/ |
| DetailCubit | 只详情页数据 | ✗ | feature_detail/cubit/ |

## 使用方式

Widget 层：BlocBuilder + context.watch
Cubit 层：构造函数注入全局状态

```dart
// Widget
BlocBuilder<UserCubit, UserState>(...)

// Cubit
class HomeCubit {
  final UserCubit _user;  // 构造函数注入
}
```
```

### domain/usecase/ README.md 示例

```markdown
# usecase 目录

存放多 feature 共用的复杂业务逻辑编排。

## 判断标准

问自己三个问题：

1. 需要多 Repository 协调？
   - ✓ 需要 → UseCase
   - ✗ 单 Repository → Cubit 直接调用

2. 逻辑复杂（多步骤）？
   - ✓ 复杂 → UseCase
   - ✗ 简单 → Cubit 内方法

3. 多 feature 共用？
   - ✓ 共用 → 放这里（domain/usecase/）
   - ✗ 单 feature → 放 feature/usecase/

## 示例

| UseCase | 多 Repo 协调 | 复杂逻辑 | 多 feature 共用 | 放哪 |
|---------|------------|---------|---------------|-----|
| GetUserInfoUseCase | ✓（用户、缓存、存储） | ✓（3 步） | ✓（首页、个人中心、评价） | domain/usecase/ |
| SyncDataUseCase | ✓（API、缓存、存储） | ✓（4 步） | ✓（多处触发） | domain/usecase/ |
| PlaceOrderUseCase | ✓（订单、购物车、库存） | ✓（4 步） | ✗（只订单页） | feature_order/usecase/ |
| LoadHomeDataUseCase | ✗（单 Repository） | ✗（简单） | - | Cubit 内方法 |

## 约定

- 纯 Dart 类，无 Flutter 依赖
- 单一 execute() 方法
- 构造函数注入所需 Repository
- 返回业务结果或抛出 DomainException

## 使用方式

```dart
// DI 注册
sl.registerFactory<GetUserInfoUseCase>(() => GetUserInfoUseCase(
  sl<UserRepository>(),
  sl<CacheRepository>(),
  sl<KeyValueStorage>(),
));

// Cubit 调用
class ProfileCubit extends Cubit<ProfileState> {
  final GetUserInfoUseCase _getUserInfo;

  Future<void> loadProfile() async {
    final user = await _getUserInfo.execute();
    emit(ProfileLoaded(user));
  }
}
```

## 与 feature/usecase 的区别

- domain/usecase：多 feature 共用，迁移时移到这里
- feature/usecase：单 feature 使用，发现共用再迁移到 domain
```

### pubspec.yaml

```yaml
name: domain
description: Shared business domain - models, state, usecases, repositories
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0    # Cubit 需要
  equatable: ^2.0.5       # State/Model 值比较
  hive: ^2.2.3            # 适配器需要

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^0.3.0        # 测试 mock
```

---

## 依赖图

```
┌──────────────────────────────────────────────────────────────┐
│                         main.dart                            │
│                            ↓                                 │
│                      lib/core/                               │
│                    (组装层 + 应用状态)                         │
│                            ↓                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    packages/                          │   │
│  │                                                      │   │
│  │  ┌─────────────────────────────────────────────┐     │   │
│  │  │  features/          业务功能层               │     │   │
│  │  │  ├─ feature_home/                           │     │   │
│  │  │  ├─ feature_detail/                         │     │   │
│  │  │  └─ README.md                               │     │   │
│  │  └─────────────────────────────────────────────┘     │   │
│  │                        ↓                             │   │
│  │  ┌─────────────────────────────────────────────┐     │   │
│  │  │  services/          业务服务层               │     │   │
│  │  │  ├─ auth/                                   │     │   │
│  │  │  ├─ data_sync/                              │     │   │
│  │  │  ├─ payment/                                │     │   │
│  │  │  └─ README.md                               │     │   │
│  │  └─────────────────────────────────────────────┘     │   │
│  │                        ↓                             │   │
│  │  ┌─────────────────────────────────────────────┐     │   │
│  │  │  domain/           业务数据定义层            │     │   │
│  │  │  ├─ models/                                 │     │   │
│  │  │  ├─ state/                                  │     │   │
│  │  │  ├─ usecase/                                │     │   │
│  │  │  ├─ repository/                             │     │   │
│  │  │  └─ README.md                               │     │   │
│  │  └─────────────────────────────────────────────┘     │   │
│  │                        ↓                             │   │
│  │  ┌─────────────────────────────────────────────┐     │   │
│  │  │  infrastructure/   纯技术基础设施层          │     │   │
│  │  │  ├─ api/                                    │     │   │
│  │  │  ├─ routing/                                │     │   │
│  │  │  ├─ key_value_storage/                      │     │   │
│  │  │  ├─ component_library/                      │     │   │
│  │  │  └─ README.md                               │     │   │
│  │  └─────────────────────────────────────────────┘     │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                            ↓                                 │
│              单向依赖，下层不知上层                           │
└──────────────────────────────────────────────────────────────┘
```

**依赖原则**：
- features → services → domain → infrastructure
- 上层依赖下层，下层不知道上层存在
- feature 之间不直接依赖（通过 domain 或 routing 通信）
- services 可以调用 domain 的 UseCase
- infrastructure 不依赖任何业务层
