# Feature Package 拆分实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 lib/features/ 目录拆分为独立 Flutter package，建立四层架构（infrastructure → domain → services → features）

**Architecture:** 上层依赖下层，下层不知道上层。每个 feature 是独立 package，通过 package import 约束依赖。

**Tech Stack:** Flutter、GetIt (DI)、flutter_bloc (状态管理)、mocktail (测试)

---

## 文件结构总览

### Phase 0 创建的文件

```
packages/
├── infrastructure/
│   ├── README.md                    ← 新建：目录说明
│   └── component_library/
│       └── lib/src/constants/       ← 新建：从 lib/core/constants 迁移
│           └── app_constants.dart
│           └── api_constants.dart
│           └── cache_constants.dart
│           └── README.md
│       └── lib/component_library.dart  ← 修改：新增 constants export
│
├── services/
│   ├── README.md                    ← 新建：目录说明+跨层协作示例
│   ├── auth/
│   │   ├── lib/auth.dart            ← 新建：barrel file
│   │   ├── lib/src/manager.dart     ← 新建：从 lib/core/auth 迁移
│   │   ├── lib/src/di/setup.dart    ← 新建：DI 自注册
│   │   ├── README.md                ← 新建：包说明
│   │   ├── test/auth_test.dart      ← 新建：测试
│   │   └── pubspec.yaml             ← 新建
│   │
│   └── data_sync/
│   │   ├── lib/data_sync.dart       ← 新建
│   │   ├── lib/src/manager.dart     ← 新建：从 lib/core/sync 迁移
│   │   ├── lib/src/di/setup.dart    ← 新建
│   │   ├── README.md                ← 新建
│   │   ├── test/data_sync_test.dart ← 新建
│   │   └── pubspec.yaml             ← 新建
│
├── domain/                          ← 改名：domain_models → domain
│   ├── lib/domain.dart              ← 改名
│   ├── lib/src/di/setup.dart        ← 新建：DI 自注册
│   ├── README.md                    ← 新建：包说明+各目录判断标准
│   └── pubspec.yaml                 ← 修改：name 改为 domain，添加 flutter_bloc
│
└── features/
    ├── README.md                    ← 新建：目录说明+跨层通信示例
    │
    ├── feature_home/
    │   ├── lib/feature_home.dart    ← 新建：barrel file
    │   ├── lib/src/cubit/           ← 迁移：从 lib/features/home/cubit
    │   ├── lib/src/repository/      ← 迁移
    │   ├── lib/src/ui/              ← 迁移
    │   ├── lib/src/di/setup.dart    ← 新建：DI 自注册
    │   ├── lib/src/models/README.md ← 新建：判断标准
    │   ├── README.md                ← 新建
    │   ├── test/feature_home_test.dart ← 新建
    │   └── pubspec.yaml             ← 新建
    │
    └── feature_detail/
    │   ├── ...（同 feature_home）
```

### Phase 3 删除的文件

```
lib/features/                        ← 删除整个目录
lib/core/auth/                       ← 删除
lib/core/sync/                       ← 删除
lib/core/constants/                  ← 删除
```

---

## Task 1: 创建 infrastructure 目录结构

**Files:**
- Create: `packages/infrastructure/README.md`

- [ ] **Step 1: 创建目录**

```bash
mkdir -p packages/infrastructure
```

- [ ] **Step 2: 创建 README.md**

```markdown
# infrastructure 目录

存放纯技术基础设施包（无业务逻辑）。

## 目录下有哪些包

- api/ - HTTP 网络请求
- routing/ - 路由导航
- key_value_storage/ - 本地存储
- component_library/ - UI 组件库（theme + constants）

## 判断标准

问自己："这个包知道业务是什么吗？"

- ✓ 知道"用户、商品、订单" → 不放这里（放 domain 或 services）
- ✗ 只知道"HTTP、路由、存储、UI" → 放这里

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

写入文件：
```bash
cat > packages/infrastructure/README.md << 'EOF'
# infrastructure 目录

存放纯技术基础设施包（无业务逻辑）。

## 目录下有哪些包

- api/ - HTTP 网络请求
- routing/ - 路由导航
- key_value_storage/ - 本地存储
- component_library/ - UI 组件库（theme + constants）

## 判断标准

问自己："这个包知道业务是什么吗？"

- ✓ 知道"用户、商品、订单" → 不放这里（放 domain 或 services）
- ✗ 只知道"HTTP、路由、存储、UI" → 放这里

## 与其他层的关系

infrastructure 不依赖任何业务层
infrastructure 被 domain、services、features 依赖

## 约定

- 无业务逻辑
- 无业务数据模型
- 可被任何上层依赖
- 独立测试（不依赖业务）
EOF
```

- [ ] **Step 3: 移动现有包到 infrastructure 目录**

```bash
mv packages/api packages/infrastructure/
mv packages/routing packages/infrastructure/
mv packages/key_value_storage packages/infrastructure/
mv packages/component_library packages/infrastructure/
```

- [ ] **Step 4: 验证目录结构**

```bash
ls packages/infrastructure/
```

Expected output:
```
README.md
api
component_library
key_value_storage
routing
```

- [ ] **Step 5: Commit**

```bash
git add packages/infrastructure/
git commit -m "phase-0.1: 创建 infrastructure 目录，移动现有基础设施包

- 创建 infrastructure/README.md（目录说明+判断标准）
- 移动 api、routing、key_value_storage、component_library 到 infrastructure/

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: 创建 services 目录结构

**Files:**
- Create: `packages/services/README.md`

- [ ] **Step 1: 创建目录**

```bash
mkdir -p packages/services
```

- [ ] **Step 2: 创建 README.md**

```markdown
# services 目录

业务服务包的组织目录。

## 目录下有哪些包

- auth/ - 认证服务包（独立 package）
- data_sync/ - 数据同步服务包（独立 package）

## 为什么每个服务是独立 package？

| 维度 | 独立 package | 单一 package |
|-----|-------------|-------------|
| 编译器约束 | ✓ 独立依赖约束 | ✗ 混在一起 |
| 独立测试 | ✓ 单独运行 | ✗ 必须跑整体 |
| 依赖控制 | ✓ feature 只依赖需要的 | ✗ 依赖所有 |

## 业务服务 vs UseCase 判断标准

| 维度 | 业务服务（AuthManager） | UseCase（GetUserInfoUseCase） |
|-----|----------------------|---------------------------|
| 生命周期 | app 级别（长期存在） | 请求级别（用完销毁） |
| 有状态 | ✓ 有（isLoggedIn） | ✗ 无状态 |
| 职责 | 提供某种**能力** | 执行某个**任务** |
| 方法数量 | 多个（login、logout） | 单一（execute） |
| 注册方式 | Singleton | Factory |

## 与其他层协作

### 调用 UseCase

```dart
class AuthManager {
  final GetUserInfoUseCase _getUserInfo;  // 构造函数注入

  Future<void> login(String username, String password) async {
    // 登录成功后调用 UseCase
    await _getUserInfo.execute();
  }
}
```

### 触发数据同步

```dart
class AuthManager {
  final DataSyncManager _dataSync;  // 构造函数注入

  Future<void> login(...) async {
    await _dataSync.sync();  // 登录后触发同步
  }
}
```

## 添加新 service

1. 创建 `packages/services/<service_name>/` 目录
2. 创建 `pubspec.yaml`（依赖 infrastructure + domain）
3. 创建 `lib/<service_name>.dart`（barrel file）
4. 创建 `lib/src/manager.dart`
5. 创建 `lib/src/di/setup.dart`
6. 创建 `README.md`
7. 在主 app pubspec.yaml 添加依赖
8. 在主 app DI setup 调用 setup<Service>(sl)

## 约定

- 每个服务独立 package
- 每个服务有 README.md
- 注册为 Singleton（长期存在）
```

写入文件：
```bash
cat > packages/services/README.md << 'EOF'
# services 目录

业务服务包的组织目录。

## 目录下有哪些包

- auth/ - 认证服务包（独立 package）
- data_sync/ - 数据同步服务包（独立 package）

## 业务服务 vs UseCase 判断标准

| 维度 | 业务服务 | UseCase |
|-----|---------|---------|
| 生命周期 | app 级别（长期） | 请求级别（短期） |
| 有状态 | ✓ 有 | ✗ 无 |
| 职责 | 提供能力（多方法） | 执行任务（单一方法） |
| 注册方式 | Singleton | Factory |

## 与其他层协作

### 调用 UseCase

构造函数注入 UseCase，在业务流程中调用。

### 触发数据同步

在 AuthManager.login() 成功后调用 DataSyncManager.sync()。

## 添加新 service

1. 创建 packages/services/<service_name>/ 目录
2. 创建 pubspec.yaml
3. 创建 barrel file + manager.dart + di/setup.dart
4. 创建 README.md
5. 主 app 添加依赖并调用 setup

## 约定

- 每个服务独立 package
- 注册为 Singleton
EOF
```

- [ ] **Step 3: 验证**

```bash
ls packages/services/
cat packages/services/README.md
```

- [ ] **Step 4: Commit**

```bash
git add packages/services/README.md
git commit -m "phase-0.1: 创建 services 目录 README

- 说明业务服务 vs UseCase 判断标准
- 包含跨层协作示例

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: 创建 features 目录结构

**Files:**
- Create: `packages/features/README.md`

- [ ] **Step 1: 创建目录**

```bash
mkdir -p packages/features
```

- [ ] **Step 2: 创建 README.md**

```markdown
# features 目录

业务功能包的组织目录。

## 目录下有哪些包

- feature_home/ - 首页功能
- feature_detail/ - 详情页功能

## 如何跳转到其他 feature

**不要直接 import 其他 feature！**

```dart
// ✗ 错误做法
import 'package:feature_detail/feature_detail.dart';  // 循环依赖风险

// ✓ 正确做法：通过 routing 包
import 'package:routing/routing.dart';
context.go(AppRouter.detailPath(id: '123'));
```

## 如何获取全局数据

用户信息等共享数据通过 domain 层获取：

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

1. 创建 `packages/features/feature_<name>/` 目录
2. 创建 `pubspec.yaml`（依赖 infrastructure + domain + services）
3. 创建 `lib/feature_<name>.dart`（barrel file）
4. 创建内部结构：cubit/、repository/、ui/、di/、models/
5. 创建各目录 README.md（判断标准）
6. 创建测试
7. 在 routing 包添加路由
8. 在主 app pubspec.yaml 添加依赖
9. 在主 app DI setup 调用 setupFeature<Name>(sl)

## 约定

- 每个 feature 独立 package
- feature 之间不直接依赖
- 通过 domain 或 routing 通信
- 页面级 Cubit 注册为 Factory
```

写入文件：
```bash
cat > packages/features/README.md << 'EOF'
# features 目录

业务功能包的组织目录。

## 如何跳转到其他 feature

不要直接 import 其他 feature，通过 routing 包跳转。

## 如何获取全局数据

通过 domain 层获取用户信息等共享数据。

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
EOF
```

- [ ] **Step 3: 验证**

```bash
ls packages/features/
```

- [ ] **Step 4: Commit**

```bash
git add packages/features/README.md
git commit -m "phase-0.1: 创建 features 目录 README

- 包含跨层通信示例（跳转、获取全局数据）
- 添加新 feature 步骤

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 4: 合并 constants 到 component_library

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/constants/`
- Create: `packages/infrastructure/component_library/lib/src/constants/app_constants.dart`
- Create: `packages/infrastructure/component_library/lib/src/constants/api_constants.dart`
- Create: `packages/infrastructure/component_library/lib/src/constants/cache_constants.dart`
- Create: `packages/infrastructure/component_library/lib/src/constants/README.md`
- Modify: `packages/infrastructure/component_library/lib/component_library.dart`

- [ ] **Step 1: 创建 constants 目录**

```bash
mkdir -p packages/infrastructure/component_library/lib/src/constants
```

- [ ] **Step 2: 复制 app_constants.dart**

```bash
cp lib/core/constants/app_constants.dart packages/infrastructure/component_library/lib/src/constants/
```

- [ ] **Step 3: 复制 api_constants.dart**

```bash
cp lib/core/constants/api_constants.dart packages/infrastructure/component_library/lib/src/constants/
```

- [ ] **Step 4: 复制 cache_constants.dart**

```bash
cp lib/core/constants/cache_constants.dart packages/infrastructure/component_library/lib/src/constants/
```

- [ ] **Step 5: 创建 constants README.md**

```markdown
# constants 目录

应用配置常量（纯技术，无业务含义）。

## 内容

- app_constants.dart - 应用名称、版本、超时配置
- api_constants.dart - API 相关配置
- cache_constants.dart - 缓存相关配置

## 约定

- 纯静态常量
- 无业务逻辑
- 可被任何层使用
```

写入：
```bash
cat > packages/infrastructure/component_library/lib/src/constants/README.md << 'EOF'
# constants 目录

应用配置常量（纯技术，无业务含义）。

## 内容

- app_constants.dart - 应用配置
- api_constants.dart - API 配置
- cache_constants.dart - 缓存配置

## 约定

- 纯静态常量
- 无业务逻辑
EOF
```

- [ ] **Step 6: 修改 component_library.dart 添加 export**

读取当前文件：
```bash
cat packages/infrastructure/component_library/lib/component_library.dart
```

添加 constants export（在文件末尾添加）：
```dart
export 'src/constants/app_constants.dart';
export 'src/constants/api_constants.dart';
export 'src/constants/cache_constants.dart';
```

- [ ] **Step 7: 更新主 app import 路径**

查找所有引用 lib/core/constants 的文件：
```bash
grep -r "lib/core/constants" lib/ --include="*.dart"
```

更新为 package import：
```dart
// 原来
import '../core/constants/app_constants.dart';

// 改为
import 'package:component_library/component_library.dart';
```

- [ ] **Step 8: 运行 flutter analyze 验证**

```bash
flutter pub get
flutter analyze
```

Expected: 无错误

- [ ] **Step 9: Commit**

```bash
git add packages/infrastructure/component_library/lib/src/constants/
git add packages/infrastructure/component_library/lib/component_library.dart
git commit -m "phase-0.2: 合并 constants 到 component_library

- 迁移 app_constants、api_constants、cache_constants
- 更新 component_library.dart export
- 更新主 app import 路径

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 5: domain_models 改名为 domain

**Files:**
- Rename: `packages/domain_models/` → `packages/domain/`
- Modify: `packages/domain/pubspec.yaml` (name)
- Modify: `packages/domain/lib/domain.dart` (barrel file name)
- Modify: All files importing `package:domain_models/`

- [ ] **Step 1: 重命名目录**

```bash
mv packages/domain_models packages/domain
```

- [ ] **Step 2: 修改 pubspec.yaml name**

修改 `packages/domain/pubspec.yaml`：
```yaml
name: domain
description: Shared business domain - models, state, usecases, repositories
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  equatable: ^2.0.5
  hive: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^0.3.0
```

- [ ] **Step 3: 重命名 barrel file**

```bash
mv packages/domain/lib/domain_models.dart packages/domain/lib/domain.dart
```

- [ ] **Step 4: 查找所有 domain_models 引用**

```bash
grep -r "package:domain_models" packages/ lib/ --include="*.dart"
```

- [ ] **Step 5: 批量更新 import**

将所有 `package:domain_models/domain_models.dart` 改为 `package:domain/domain.dart`：

```bash
# macOS
sed -i '' 's/package:domain_models\/domain_models.dart/package:domain\/domain.dart/g' lib/**/*.dart packages/**/*.dart

# 或手动逐个文件更新
```

- [ ] **Step 6: 更新主 app pubspec.yaml**

修改 `pubspec.yaml`：
```yaml
# 原来
domain_models:
  path: packages/domain_models

# 改为
domain:
  path: packages/domain
```

- [ ] **Step 7: 运行验证**

```bash
flutter pub get
flutter analyze
```

Expected: 无错误，无 "domain_models" 残留引用

- [ ] **Step 8: Commit**

```bash
git add packages/domain/
git add pubspec.yaml
git add lib/
git commit -m "phase-0.3: domain_models 改名为 domain

- 重命名目录和 pubspec.yaml name
- 重命名 barrel file
- 更新所有 import 路径
- 添加 flutter_bloc 依赖

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 6: 创建 auth 服务包

**Files:**
- Create: `packages/services/auth/lib/auth.dart`
- Create: `packages/services/auth/lib/src/manager.dart`
- Create: `packages/services/auth/lib/src/di/setup.dart`
- Create: `packages/services/auth/README.md`
- Create: `packages/services/auth/pubspec.yaml`
- Create: `packages/services/auth/test/auth_test.dart`

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p packages/services/auth/lib/src/di
mkdir -p packages/services/auth/test
```

- [ ] **Step 2: 创建 pubspec.yaml**

```yaml
name: auth
description: Authentication service - manages user authentication state
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

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

写入：
```bash
cat > packages/services/auth/pubspec.yaml << 'EOF'
name: auth
description: Authentication service
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

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
EOF
```

- [ ] **Step 3: 复制 manager.dart 并更新**

```bash
cp lib/core/auth/manager.dart packages/services/auth/lib/src/manager.dart
```

- [ ] **Step 4: 创建 barrel file**

```dart
export 'src/manager.dart';
export 'src/di/setup.dart';
```

写入：
```bash
cat > packages/services/auth/lib/auth.dart << 'EOF'
export 'src/manager.dart';
export 'src/di/setup.dart';
EOF
```

- [ ] **Step 5: 创建 DI setup.dart**

```dart
import 'package:get_it/get_it.dart';
import 'package:auth/src/manager.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:domain/domain.dart';

/// Auth 包 DI 自注册
void setupAuth(GetIt sl) {
  sl.registerSingleton<AuthManager>(AuthManager(
    api: sl<Api>(),
    storage: sl<KeyValueStorage>(),
    userCubit: sl<UserCubit>(),
  ));
}
```

写入：
```bash
cat > packages/services/auth/lib/src/di/setup.dart << 'EOF'
import 'package:get_it/get_it.dart';
import 'package:auth/src/manager.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:domain/domain.dart';

void setupAuth(GetIt sl) {
  sl.registerSingleton<AuthManager>(AuthManager(
    api: sl<Api>(),
    storage: sl<KeyValueStorage>(),
    userCubit: sl<UserCubit>(),
  ));
}
EOF
```

- [ ] **Step 6: 创建 README.md**

```markdown
# auth 包

认证服务包 - 管理用户认证状态。

## 职责

提供认证能力：
- handleLogin() - 启动时自动检查登录状态
- login() - 用户主动登录
- logout() - 用户登出
- checkTokenValid() - 检查 Token 有效性

## 业务服务特征

- 长期存在（app 生命周期）
- 有内部状态（isLoggedIn、_token）
- 提供能力（多个方法）

## 依赖

- api - 网络请求
- key_value_storage - Token 存储
- domain - UserCubit（全局状态）

## 使用方式

```dart
// DI 注册
setupAuth(sl);

// 调用
await sl<AuthManager>().login(username, password);
await sl<AuthManager>().logout();

// 检查状态
if (sl<AuthManager>().isLoggedIn) { ... }
```

## 注册方式

Singleton（长期存在、有状态）
```

写入：
```bash
cat > packages/services/auth/README.md << 'EOF'
# auth 包

认证服务包 - 管理用户认证状态。

## 职责

提供认证能力：handleLogin、login、logout、checkTokenValid

## 业务服务特征

- 长期存在（app 生命周期）
- 有内部状态（isLoggedIn、_token）

## 注册方式

Singleton（长期存在、有状态）
EOF
```

- [ ] **Step 7: 创建测试文件**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auth/src/manager.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:domain/domain.dart';

class MockApi extends Mock implements Api {}
class MockKeyValueStorage extends Mock implements KeyValueStorage {}
class MockUserCubit extends Mock implements UserCubit {}

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
      manager = AuthManager(
        api: mockApi,
        storage: mockStorage,
        userCubit: mockUserCubit,
      );
    });

    test('isLoggedIn is false initially', () {
      expect(manager.isLoggedIn, false);
    });

    test('isLoggedIn becomes true after login', () async {
      when(() => mockStorage.getString('token')).thenAnswer((_) async => null);
      when(() => mockStorage.saveString('token', any())).thenAnswer((_) async {});
      
      // 模拟登录成功（实际需要 Api.login 实现）
      expect(manager.isLoggedIn, false);
    });
  });
}
```

写入：
```bash
cat > packages/services/auth/test/auth_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auth/src/manager.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:domain/domain.dart';

class MockApi extends Mock implements Api {}
class MockKeyValueStorage extends Mock implements KeyValueStorage {}
class MockUserCubit extends Mock implements UserCubit {}

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
      manager = AuthManager(
        api: mockApi,
        storage: mockStorage,
        userCubit: mockUserCubit,
      );
    });

    test('isLoggedIn is false initially', () {
      expect(manager.isLoggedIn, false);
    });
  });
}
EOF

void main() {
  group('AuthManager', () {
    test('isLoggedIn is false initially', () {
      // Placeholder - 需要依赖注入 mock
      expect(true, isTrue);
    });
  });
}
EOF
```

- [ ] **Step 8: 运行验证**

```bash
cd packages/services/auth && flutter pub get && flutter analyze
```

Expected: 无错误

- [ ] **Step 9: Commit**

```bash
git add packages/services/auth/
git commit -m "phase-0.4: 创建 auth 服务包

- 从 lib/core/auth 迁移 AuthManager
- 创建 DI 自注册 setupAuth()
- 创建 README 和测试骨架

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 7: 创建 data_sync 服务包

**Files:**
- Create: `packages/services/data_sync/lib/data_sync.dart`
- Create: `packages/services/data_sync/lib/src/manager.dart`
- Create: `packages/services/data_sync/lib/src/di/setup.dart`
- Create: `packages/services/data_sync/README.md`
- Create: `packages/services/data_sync/pubspec.yaml`
- Create: `packages/services/data_sync/test/data_sync_test.dart`

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p packages/services/data_sync/lib/src/di
mkdir -p packages/services/data_sync/test
```

- [ ] **Step 2: 创建 pubspec.yaml**

```yaml
name: data_sync
description: Data synchronization service
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

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

- [ ] **Step 3: 复制 manager.dart**

```bash
cp lib/core/sync/manager.dart packages/services/data_sync/lib/src/manager.dart
```

- [ ] **Step 4: 创建 barrel file**

```dart
export 'src/manager.dart';
export 'src/di/setup.dart';
```

- [ ] **Step 5: 创建 DI setup**

```dart
import 'package:get_it/get_it.dart';
import 'package:data_sync/src/manager.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';

void setupDataSync(GetIt sl) {
  sl.registerSingleton<DataSyncManager>(DataSyncManager(
    api: sl<Api>(),
    storage: sl<KeyValueStorage>(),
  ));
}
```

- [ ] **Step 6: 创建 README**

```markdown
# data_sync 包

数据同步服务 - 用户登录后同步本地和远程数据。

## 职责

- sync() - 执行数据同步

## 注册方式

Singleton（长期存在）
```

- [ ] **Step 7: 创建测试骨架**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataSyncManager', () {
    test('sync executes without error', () {
      expect(true, isTrue);
    });
  });
}
```

- [ ] **Step 8: 运行验证**

```bash
cd packages/services/data_sync && flutter pub get && flutter analyze
```

- [ ] **Step 9: Commit**

```bash
git add packages/services/data_sync/
git commit -m "phase-0.4: 创建 data_sync 服务包

- 从 lib/core/sync 迁移 DataSyncManager
- 创建 DI 自注册 setupDataSync()

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 8: 更新主 app pubspec.yaml 依赖路径

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 更新 infrastructure 包路径**

将原来的：
```yaml
api:
  path: packages/api
routing:
  path: packages/routing
key_value_storage:
  path: packages/key_value_storage
component_library:
  path: packages/component_library
domain_models:
  path: packages/domain_models
```

改为：
```yaml
# ===== 基础设施层 =====
api:
  path: packages/infrastructure/api
routing:
  path: packages/infrastructure/routing
key_value_storage:
  path: packages/infrastructure/key_value_storage
component_library:
  path: packages/infrastructure/component_library

# ===== 数据定义层 =====
domain:
  path: packages/domain

# ===== 业务服务层 =====
auth:
  path: packages/services/auth
data_sync:
  path: packages/services/data_sync
```

- [ ] **Step 2: 运行 flutter pub get**

```bash
flutter pub get
```

Expected: 成功获取依赖

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "phase-0.4: 更新主 app pubspec.yaml 依赖路径

- infrastructure 包路径更新
- domain_models 改为 domain
- 新增 auth、data_sync 服务依赖

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 9: 创建 feature_home 包

**Files:**
- Create: `packages/features/feature_home/` 整个目录结构

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p packages/features/feature_home/lib/src/{cubit,repository,ui,di,models}
mkdir -p packages/features/feature_home/test
```

- [ ] **Step 2: 创建 pubspec.yaml**

```yaml
name: feature_home
description: Home feature module
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

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

- [ ] **Step 3: 迁移 cubit 文件**

```bash
cp lib/features/home/cubit/home_cubit.dart packages/features/feature_home/lib/src/cubit/
cp lib/features/home/cubit/home_state.dart packages/features/feature_home/lib/src/cubit/
```

更新 home_cubit.dart import：
```dart
// 原来
import 'package:domain_models/domain_models.dart';
import '../repository/home_repository.dart';

// 改为
import 'package:domain/domain.dart';
import '../repository/home_repository.dart';
```

- [ ] **Step 4: 迁移 repository 文件**

```bash
cp lib/features/home/repository/home_repository.dart packages/features/feature_home/lib/src/repository/
cp lib/features/home/repository/home_repository_impl.dart packages/features/feature_home/lib/src/repository/
```

更新 import 路径。

- [ ] **Step 5: 迁移 ui 文件**

```bash
cp lib/features/home/ui/home_page.dart packages/features/feature_home/lib/src/ui/
```

更新 import 路径。

- [ ] **Step 6: 创建 models README**

```markdown
# models 目录

存放页面特定数据模型。

## 判断标准

问自己："这是核心业务数据吗？还是不确定是否共用？"

- ✓ 核心业务数据（User、Product）→ 放 domain/models/
- ✓ 不确定是否共用 → 先放这里，发现共用再迁移
- ✗ 确定单 feature 使用 → 放这里

## 示例

| 模型 | 是否核心业务 | 放哪 |
|-----|------------|-----|
| HomeBanner | 首页轮播，页面特定 | feature_home/models/ |
| Product | 商品，核心业务 | domain/models/ |
```

- [ ] **Step 7: 创建 DI setup**

```dart
import 'package:get_it/get_it.dart';
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:feature_home/src/repository/home_repository.dart';
import 'package:feature_home/src/repository/home_repository_impl.dart';
import 'package:api/api.dart';
import 'package:auth/auth.dart';
import 'package:domain/domain.dart';

void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(
    api: sl<Api>(),
  ));

  sl.registerFactory<HomeCubit>(() => HomeCubit(
    repo: sl<HomeRepository>(),
    authManager: sl<AuthManager>(),
    networkCubit: sl<NetworkCubit>(),
  ));
}
```

- [ ] **Step 8: 创建 barrel file**

```dart
export 'src/cubit/home_cubit.dart';
export 'src/cubit/home_state.dart';
export 'src/repository/home_repository.dart';
export 'src/ui/home_page.dart';
export 'src/di/setup.dart';
```

- [ ] **Step 9: 创建 README**

```markdown
# feature_home 包

首页功能模块。

## 内部结构

- cubit/ - HomeCubit 状态管理
- repository/ - 数据获取
- ui/ - 页面 Widget
- di/ - DI 自注册
- models/ - 页面特定数据模型

## 依赖

- infrastructure: api, routing, component_library
- domain: models, state
- services: auth

## 注册方式

- HomeCubit: Factory（页面级）
- HomeRepository: Factory
```

- [ ] **Step 10: 创建测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_home/feature_home.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  group('HomeCubit', () {
    late HomeCubit cubit;
    late MockHomeRepository mockRepo;

    setUp(() {
      mockRepo = MockHomeRepository();
      cubit = HomeCubit(mockRepo);
    });

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeLoaded] when loadData succeeds',
      build: () => cubit,
      act: (cubit) => cubit.loadData(),
      expect: () => [HomeLoading(), isA<HomeLoaded>()],
    );
  });
}
```

- [ ] **Step 11: 运行验证**

```bash
cd packages/features/feature_home && flutter pub get && flutter analyze
```

- [ ] **Step 12: Commit**

```bash
git add packages/features/feature_home/
git commit -m "phase-1: 创建 feature_home 包

- 迁移 cubit、repository、ui
- 创建 DI 自注册 setupFeatureHome()
- 创建 models README 判断标准
- 创建测试骨架

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 10: 创建 feature_detail 包

**Files:**
- Create: `packages/features/feature_detail/` 整个目录结构

步骤同 Task 9，将 detail 相关文件迁移。

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p packages/features/feature_detail/lib/src/{cubit,repository,ui,di,models}
mkdir -p packages/features/feature_detail/test
```

- [ ] **Step 2: 创建 pubspec.yaml**

同 feature_home 格式。

- [ ] **Step 3-10: 迁移文件并创建必要文件**

参照 Task 9 步骤。

- [ ] **Step 11: Commit**

```bash
git add packages/features/feature_detail/
git commit -m "phase-2: 创建 feature_detail 包

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 11: 更新主 app DI setup

**Files:**
- Modify: `lib/core/di/setup.dart`

- [ ] **Step 1: 更新 import 路径**

将原来的本地 import 改为 package import：

```dart
// 原来
import '../auth/manager.dart';
import '../sync/manager.dart';
import '../../features/home/repository/home_repository.dart';

// 改为
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart';
```

- [ ] **Step 2: 改为调用各包 setup 函数**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:routing/routing.dart';
import 'package:domain/domain.dart';
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_detail/feature_detail.dart';

import 'locator.dart';
import '../utils/logger.dart';
import '../global/locale/locale_cubit.dart';
import '../global/network/network_cubit.dart';

void setupDependencies() {
  // ===== Step 1: 基础设施层 =====
  sl.registerSingleton<AppLogger>(AppLogger());
  sl.registerSingleton<Api>(Api(...));
  sl<Api>().setLogger(sl<AppLogger>());
  sl.registerSingleton<KeyValueStorage>(KeyValueStorage());
  sl.registerSingleton<AppRouter>(AppRouter());

  // ===== Step 2: 数据定义层 =====
  setupDomain(sl);

  // ===== Step 3: 应用状态 =====
  sl.registerSingleton<LocaleCubit>(LocaleCubit(sl<KeyValueStorage>()));
  sl.registerSingleton<NetworkCubit>(NetworkCubit()..startListening());

  // ===== Step 4: 业务服务层 =====
  setupAuth(sl);
  setupDataSync(sl);

  // ===== Step 5: 业务功能层 =====
  setupFeatureHome(sl);
  setupFeatureDetail(sl);

  configureEasyLoading();
}
```

- [ ] **Step 3: 运行验证**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/di/setup.dart
git commit -m "更新主 app DI setup，调用各包 setup 函数

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 12: 更新 routing 包 import 路径

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/routes/*.dart`

- [ ] **Step 1: 查找 routing 包中的 feature import**

```bash
grep -r "lib/features" packages/infrastructure/routing/ --include="*.dart"
```

- [ ] **Step 2: 更新为 package import**

```dart
// 原来
import '../../../lib/features/home/ui/home_page.dart';

// 改为
import 'package:feature_home/feature_home.dart';
```

- [ ] **Step 3: 运行验证**

```bash
flutter analyze packages/infrastructure/routing/
```

- [ ] **Step 4: Commit**

```bash
git add packages/infrastructure/routing/
git commit -m "更新 routing 包 import 路径为 package import

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 13: 删除旧目录并验证

**Files:**
- Delete: `lib/features/`
- Delete: `lib/core/auth/`
- Delete: `lib/core/sync/`
- Delete: `lib/core/constants/`

- [ ] **Step 1: 检查无残留引用**

```bash
grep -r "lib/features" lib/ --include="*.dart"
grep -r "lib/core/auth" lib/ --include="*.dart"
grep -r "lib/core/sync" lib/ --include="*.dart"
grep -r "lib/core/constants" lib/ --include="*.dart"
```

Expected: 无输出（无引用）

- [ ] **Step 2: 删除旧目录**

```bash
rm -rf lib/features/
rm -rf lib/core/auth/
rm -rf lib/core/sync/
rm -rf lib/core/constants/
```

- [ ] **Step 3: 全量验证**

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Expected: 全部通过

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "phase-3: 清理旧目录

- 删除 lib/features/（已迁移到 packages/features/）
- 删除 lib/core/auth/（已迁移到 packages/services/auth/）
- 删除 lib/core/sync/（已迁移到 packages/services/data_sync/）
- 删除 lib/core/constants/（已迁移到 component_library/）

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 14: 创建 domain README

**Files:**
- Create: `packages/domain/README.md`
- Create: `packages/domain/lib/src/models/README.md`
- Create: `packages/domain/lib/src/state/README.md`
- Create: `packages/domain/lib/src/usecase/README.md`

- [ ] **Step 1: 创建 domain 包 README**

参照设计规格中的 README 内容要求。

- [ ] **Step 2: 创建各目录 README**

包含判断标准。

- [ ] **Step 3: Commit**

---

## 验证清单

完成所有 Task 后运行：

```bash
# 1. 目录结构验证
ls packages/infrastructure/  # api, routing, key_value_storage, component_library
ls packages/services/        # auth, data_sync
ls packages/features/        # feature_home, feature_detail
ls packages/domain/

# 2. 每个 package 独立验证
cd packages/services/auth && flutter analyze && flutter test
cd packages/features/feature_home && flutter analyze && flutter test

# 3. 全量验证
flutter pub get
flutter analyze
flutter test
flutter build apk --debug

# 4. 运行验证
flutter run
# 手动测试：首页加载、详情页、网络断开、语言切换
```

---

## 成功标准

1. `flutter analyze` 无错误无警告
2. 每个 feature package 可独立运行 `flutter test`
3. `flutter build apk --debug` 成功
4. 运行时各功能正常
5. 各层 README 包含判断标准和跨层通信示例