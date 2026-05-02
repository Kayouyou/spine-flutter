# Feature Package 拆分任务

## Phase 0.1: 整理目录结构（基础设施层 + 服务层）

### Task 0.1.1: 创建 infrastructure 目录
- [ ] 创建 `packages/infrastructure/` 目录
- [ ] 移动 `packages/api/` → `packages/infrastructure/api/`
- [ ] 移动 `packages/routing/` → `packages/infrastructure/routing/`
- [ ] 移动 `packages/key_value_storage/` → `packages/infrastructure/key_value_storage/`
- [ ] 移动 `packages/component_library/` → `packages/infrastructure/component_library/`
- [ ] 创建 `packages/infrastructure/README.md`（目录说明：组织说明，无 pubspec.yaml）
- [ ] 创建 `packages/infrastructure/api/README.md`（包说明）
- [ ] 创建 `packages/infrastructure/routing/README.md`（包说明）
- [ ] 创建 `packages/infrastructure/key_value_storage/README.md`（包说明）
- [ ] 创建 `packages/infrastructure/component_library/README.md`（包说明）
- [ ] 更新所有 pubspec.yaml 的依赖路径
- [ ] 更新所有 import 路径
- [ ] 运行 `flutter pub get`

### Task 0.1.2: 创建 services 目录
- [ ] 创建 `packages/services/` 目录
- [ ] 创建 `packages/services/README.md`（目录说明：组织说明，每个子项是独立 package）
- [ ] 移动 auth 和 data_sync 到 services（Phase 0.4 执行）

### Task 0.1.3: 创建 features 目录 README
- [ ] 创建 `packages/features/README.md`（目录说明：组织说明，每个子项是独立 package）

## Phase 0.2: 扩展 component_library（在 infrastructure 内）

### Task 0.2.1: 合并 AppConstants 到 component_library
- [ ] 移动 `lib/core/constants/` → `packages/infrastructure/component_library/lib/src/constants/`
- [ ] 更新 `packages/infrastructure/component_library/lib/component_library.dart` 添加 constants export
- [ ] 更新所有文件的 import 路径为 `package:component_library/...`
- [ ] 删除 `lib/core/constants/` 目录
- [ ] 创建 `packages/infrastructure/component_library/lib/src/constants/README.md`

### Task 0.2.2: AppLogger 处理（保留在 core）
- [ ] AppLogger 留在 `lib/core/utils/logger.dart`（不迁移）
- [ ] 原因：AppLogger 实现 api 包的 AppLoggerInterface，component_library 不应依赖 api
- [ ] 确保 DI 注册时正确注入到 api 包的拦截器

## Phase 0.3: domain 改名与扩展

### Task 0.3.1: domain_models 改名为 domain
- [ ] 重命名 `packages/domain_models/` → `packages/domain/`
- [ ] 更新 `packages/domain/pubspec.yaml` 的 name 为 `domain`
- [ ] 更新 `packages/domain/lib/domain.dart`（原 domain_models.dart）
- [ ] 更新所有 pubspec.yaml 中的依赖声明：`domain_models` → `domain`
- [ ] 更新所有文件的 import：`package:domain_models/` → `package:domain/`
- [ ] 运行 `flutter pub get`

### Task 0.3.2: domain 包 README 创建
- [ ] 创建 `packages/domain/README.md`（包整体说明）
- [ ] 创建 `packages/domain/lib/src/models/README.md`（判断标准）
- [ ] 创建 `packages/domain/lib/src/enums/README.md`（判断标准）
- [ ] 创建 `packages/domain/lib/src/exceptions/README.md`（判断标准）
- [ ] 创建 `packages/domain/lib/src/state/README.md`（判断标准）
- [ ] 创建 `packages/domain/lib/src/usecase/README.md`（判断标准）
- [ ] 创建 `packages/domain/lib/src/repository/README.md`（判断标准）
- [ ] 创建 `packages/domain/lib/src/adapters/README.md`（判断标准）

## Phase 0.4: 提取业务服务包（放入 services）

### Task 0.4.1: 提取 AuthManager
- [ ] 创建 `packages/services/auth/` 目录结构
- [ ] 创建 `packages/services/auth/pubspec.yaml`
- [ ] 移动 `lib/core/auth/manager.dart` → `packages/services/auth/lib/src/manager.dart`
- [ ] 创建 `packages/services/auth/lib/auth.dart`（barrel file）
- [ ] 创建 `packages/services/auth/README.md`（服务职责说明）
- [ ] 更新 `lib/core/di/setup.dart` import 为 `package:auth/`
- [ ] 更新 packages/infrastructure/api 对 AuthManager 的引用（如有）

### Task 0.4.2: 提取 DataSyncManager
- [ ] 创建 `packages/services/data_sync/` 目录结构
- [ ] 创建 `packages/services/data_sync/pubspec.yaml`
- [ ] 移动 `lib/core/sync/manager.dart` → `packages/services/data_sync/lib/src/manager.dart`
- [ ] 创建 `packages/services/data_sync/lib/data_sync.dart`（barrel file）
- [ ] 创建 `packages/services/data_sync/README.md`

### Task 0.4.3: 更新主 app 依赖
- [ ] 主 app pubspec.yaml 添加 `auth`、`data_sync` 依赖（路径为 packages/services/auth 等）
- [ ] 运行 `flutter pub get`
- [ ] 更新 packages/infrastructure/api 对 AppLogger 的引用

### Task 0.4.4: 验证
- [ ] `flutter analyze` 通过（无 import 错误）
- [ ] `flutter analyze` 通过（无 import 错误）
- [ ] `flutter test` 通过

## Phase 1: feature_home

### Task 1.1: 创建 feature_home 包骨架
- [ ] 创建 `packages/features/feature_home/` 目录
- [ ] 创建 `packages/features/feature_home/pubspec.yaml`（依赖 infrastructure下的包 + domain + services/auth）
- [ ] 创建 `packages/features/feature_home/lib/feature_home.dart`（barrel file）
- [ ] 创建 `packages/features/feature_home/lib/src/` 目录结构（models/, usecase/, repository/, cubit/, ui/, di/）
- [ ] 创建 `packages/features/feature_home/lib/src/models/README.md`（判断标准）
- [ ] 创建 `packages/features/feature_home/lib/src/usecase/README.md`（判断标准）

### Task 1.2: 迁移 home 代码
- [ ] 移动 `lib/features/home/models/` → `packages/features/feature_home/lib/src/models/`（如有）
- [ ] 移动 `lib/features/home/usecase/` → `packages/features/feature_home/lib/src/usecase/`（如有）
- [ ] 移动 `lib/features/home/repository/` → `packages/features/feature_home/lib/src/repository/`
- [ ] 移动 `lib/features/home/cubit/` → `packages/features/feature_home/lib/src/cubit/`
- [ ] 移动 `lib/features/home/ui/` → `packages/features/feature_home/lib/src/ui/`
- [ ] 移动 `lib/features/home/README.md` → `packages/features/feature_home/README.md`

### Task 3: 更新 home 内部 import
- [ ] 更新 cubit 中 repository 的 import 路径为 `package:feature_home/src/...`
- [ ] 更新 ui 中 cubit 的 import 路径为 `package:feature_home/src/...`
- [ ] 更新 barrel file export 声明

### Task 4: 主 app 适配
- [ ] 主 app pubspec.yaml 添加 `feature_home` 依赖
- [ ] 运行 `flutter pub get`
- [ ] 更新 `lib/core/di/setup.dart` import 路径
- [ ] 更新 routing 包中 home 相关 import

### Task 5: 迁移 home 测试
- [ ] 创建 `packages/features/feature_home/test/` 目录
- [ ] 迁移相关测试文件
- [ ] 更新测试 import 路径
- [ ] 验证 `cd packages/features/feature_home && flutter test` 通过

## Phase 2: feature_detail

### Task 6: 创建 feature_detail 包骨架
- [ ] 创建 `packages/features/feature_detail/` 目录
- [ ] 创建 `packages/features/feature_detail/pubspec.yaml`
- [ ] 创建 `packages/features/feature_detail/lib/feature_detail.dart`（barrel file）
- [ ] 创建 `packages/features/feature_detail/lib/src/` 目录结构（models/, usecase/, repository/, cubit/, ui/, di/）
- [ ] 创建 `packages/features/feature_detail/lib/src/models/README.md`
- [ ] 创建 `packages/features/feature_detail/lib/src/usecase/README.md`

### Task 7: 迁移 detail 代码
- [ ] 移动 `lib/features/detail/models/` → `packages/features/feature_detail/lib/src/models/`（如有）
- [ ] 移动 `lib/features/detail/usecase/` → `packages/features/feature_detail/lib/src/usecase/`（如有）
- [ ] 移动 `lib/features/detail/repository/` → `packages/features/feature_detail/lib/src/repository/`
- [ ] 移动 `lib/features/detail/cubit/` → `packages/features/feature_detail/lib/src/cubit/`
- [ ] 移动 `lib/features/detail/ui/` → `packages/features/feature_detail/lib/src/ui/`
- [ ] 移动 `lib/features/detail/README.md` → `packages/features/feature_detail/README.md`

### Task 8: 更新 detail 内部 import
- [ ] 更新 cubit 中 repository 的 import 路径
- [ ] 更新 ui 中 cubit 的 import 路径
- [ ] 更新 barrel file export 声明

### Task 9: 主 app 适配
- [ ] 主 app pubspec.yaml 添加 `feature_detail` 依赖
- [ ] 运行 `flutter pub get`
- [ ] 更新 `lib/core/di/setup.dart` import 路径
- [ ] 更新 routing 包中 detail 相关 import

### Task 10: 迁移 detail 测试
- [ ] 创建 `packages/features/feature_detail/test/` 目录
- [ ] 迁移相关测试文件
- [ ] 验证 `cd packages/features/feature_detail && flutter test` 通过

## Phase 3: 清理与验证

### Task 3.1: 删除旧目录与空目录
- [ ] 删除 `lib/features/` 目录（代码已迁移到 packages/features/）
- [ ] 删除 `lib/features/order/`、`lib/features/user/`（空目录）
- [ ] 删除 `lib/core/auth/`（已迁移到 packages/services/auth）
- [ ] 删除 `lib/core/sync/`（已迁移到 packages/services/data_sync）
- [ ] 删除 `lib/core/constants/`（已迁移到 infrastructure/component_library）
- [ ] 确认 `lib/core/utils/logger.dart` 保留（AppLogger 不迁移）
- [ ] 确认无残留引用

### Task 3.2: 全量验证
- [ ] `flutter analyze` 通过
- [ ] `flutter test` 全量通过
- [ ] `flutter build apk --debug` 编译通过
- [ ] 运行 app，验证 home 和 detail 页面功能正常
- [ ] 验证 NetworkCubit、LocaleCubit 功能正常

### Task 3.3: README 最终检查
- [ ] 检查 `packages/infrastructure/README.md` 已创建
- [ ] 检查 `packages/services/README.md` 已创建
- [ ] 检查 `packages/domain/README.md` 已创建
- [ ] 检查 `packages/features/README.md` 已创建
- [ ] 检查各子目录 README 已创建

---

## 附录

### 命名约定速查表

| 类型 | 命名规则 | 示例 |
|-----|---------|-----|
| **infrastructure package** | 技术功能名（无前缀） | api、routing |
| **services package** | 业务功能名（无前缀） | auth、data_sync |
| **features package** | feature_ 前缀 | feature_home |
| **Cubit** | XXXCubit | HomeCubit |
| **State** | XXXState | HomeState |
| **Repository 接口** | XXXRepository | HomeRepository |
| **Repository 实现** | XXXRepositoryImpl | HomeRepositoryImpl |
| **UseCase** | XXXUseCase | GetUserInfoUseCase |
| **Manager** | XXXManager | AuthManager |
| **Model** | XXX 或 XXXModel | UserProfile |
| **Page Widget** | XXXPage | HomePage |
| **barrel file** | package名.dart | auth.dart |

### 回滚步骤速查

**回滚单阶段**：
```bash
git log --oneline  # 查看 commit
git reset --soft HEAD~1  # 回滚，保留工作区
```

**完全回滚**：
```bash
git checkout main
git branch -D feature-package-split
```

**备份策略**：
```bash
git checkout -b backup-before-split
git checkout main
git checkout -b feature-package-split
```

### 新增 feature 速查

```bash
# 1. 创建目录
mkdir -p packages/features/feature_XXX/lib/src/{models,usecase,repository,cubit,ui,di}
mkdir -p packages/features/feature_XXX/test

# 2. 创建 pubspec.yaml（复制 feature_home）

# 3. 创建 barrel file
# packages/features/feature_XXX/lib/feature_XXX.dart

# 4. 创建 README（复制 feature_home）

# 5. 创建 DI setup
# packages/features/feature_XXX/lib/src/di/setup.dart

# 6. 更新主 app
# pubspec.yaml + lib/core/di/setup.dart

# 7. 验证
flutter pub get
flutter analyze packages/features/feature_XXX/
cd packages/features/feature_XXX && flutter test
```

### 新增 service 速查

```bash
# 1. 创建目录
mkdir -p packages/services/XXX/lib/src
mkdir -p packages/services/XXX/test

# 2. 创建 pubspec.yaml（依赖 infrastructure + domain）

# 3. 创建 Manager
# packages/services/XXX/lib/src/manager.dart

# 4. 创建 README（说明：业务服务职责）

# 5. 创建 DI setup
# packages/services/XXX/lib/src/di/setup.dart

# 6. 更新主 app
# pubspec.yaml + lib/core/di/setup.dart

# 7. 验证
flutter pub get
flutter analyze packages/services/XXX/
```

### 验证命令速查

```bash
# 单 package 验证
flutter analyze packages/<path>/
flutter test packages/<path>/test/

# 全量验证
flutter pub get
flutter analyze
flutter test
flutter build apk --debug

# 检查残留
grep -r "lib/features/" lib/
grep -r "lib/core/auth/" lib/
grep -r "package:domain_models" packages/

# 检查循环依赖
flutter analyze（会报循环依赖错误）
```
