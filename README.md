# Flutter 项目骨架

一行简介：一个基于 Clean Architecture 的 Flutter 多包项目骨架，提供分层架构、最佳实践和开发工具。

---

## 目录

- [项目简介](#项目简介)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
- [我要加一个页面](#我要加一个页面)
- [分层决策树](#分层决策树)
- [测试命令](#测试命令)
- [Make 命令参考](#make-命令参考)
- [环境配置](#环境配置)
- [列表缓存](#列表缓存)
- [架构评分](#架构评分)

---

## 项目简介

本项目是 **Flutter 移动应用骨架**，采用 **Clean Architecture + Feature-First** 架构：
- **domain**：纯 Dart 业务领域（无 Flutter 依赖）
- **features**：功能模块（cubit + repository + ui）
- **infrastructure**：基础设施（API、路由、本地存储）
- **services**：共享服务（认证、网络状态、多语言）

---

## 目录结构

```
my_app/
├── lib/                          # 主应用
│   ├── main.dart                 # 入口文件
│   ├── app.dart                  # 主应用 Widget
│   ├── config.dart               # 全局配置
│   ├── core/                     # 核心模块
│   │   ├── di/                    # 依赖注入（locator.dart, setup.dart）
│   │   ├── startup/               # 启动流程（launcher, profiler, initializer）
│   │   ├── l10n/                  # 国际化生成文件
│   │   ├── utils/                 # 工具类（logger）
│   │   └── widgets/               # 全局组件（网络状态 banner 等）
│   └── theme/                    # 主题配置
│
├── packages/                     # 本地包（Monorepo）
│   ├── domain/                   # ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│   │   └── lib/
│   │       └── src/
│   │           ├── models/       # 领域模型（User, Todo 等）
│   │           ├── repositories/ # 仓储接口（抽象类）
│   │           ├── usecases/     # 用例（业务编排）
│   │           ├── enums/        # 枚举定义
│   │           └── exceptions/   # 领域异常（sealed class）
│   │
│   ├── infrastructure/            # ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│   │   ├── api/                  # Dio HTTP 封装
│   │   ├── routing/              # GoRouter 路由模块
│   │   ├── key_value_storage/    # Hive 本地存储
│   │   └── component_library/    # 共享 UI 组件
│   │
│   ├── services/                 # ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│   │   ├── auth/                 # 认证服务
│   │   ├── network/              # 网络状态（NetworkCubit）
│   │   ├── locale/               # 多语言服务（LocaleCubit）
│   │   ├── data_sync/            # 数据同步
│   │   └── error/                # 错误处理
│   │
│   └── features/                 # ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│       ├── feature_home/        # 示例功能：首页
│       │   ├── lib/
│       │   │   ├── feature_home.dart       # 导出入口
│       │   │   ├── di/                      # DI 注册（setupFeatureXxx）
│       │   │   ├── cubit/                   # 状态管理
│       │   │   ├── repository/              # Repository 实现
│       │   │   ├── ui/                      # 页面 Widget
│       │   │   └── models/                  # Feature 本地模型
│       │   └── test/
│       └── feature_detail/      # 示例功能：详情页
│
├── makefile                     # 开发命令
├── pubspec.yaml                 # 主应用依赖
└── l10n.yaml                    # 国际化配置
```

### 各层职责速查

| 目录 | 职责 | 依赖 Flutter？ |
|------|------|--------------|
| `packages/domain/` | 纯业务：模型、仓储接口、用例、枚举、异常 | ❌ 否 |
| `packages/infrastructure/` | 技术：API、路由、存储 | ⚠️ 仅技术栈 |
| `packages/services/` | 共享状态：AuthCubit、NetworkCubit、LocaleCubit | ✅ 是 |
| `packages/features/` | 功能模块：一个功能一个包 | ✅ 是 |
| `lib/` | 组装：main.dart、DI 编排、路由绑定 | ✅ 是 |

---

## 快速开始

```bash
# 1. 安装依赖
make get

# 2. 运行调试（自动选择设备）
make debug

# 2.1 运行到模拟器（推荐）
make debug-simulator

# 3. 分析代码
make lint

# 4. 运行测试
make test
```

---

## 我要加一个页面

完整示例：假设我们要添加「设置页面」。

### 步骤 1：创建 Feature 包

在 `packages/features/` 下创建 `feature_settings/`：

```
feature_settings/
├── pubspec.yaml
├── lib/
│   ├── feature_settings.dart          # 导出入口
│   ├── di/
│   │   └── setup.dart                  # DI 注册
│   ├── cubit/
│   │   ├── settings_cubit.dart         # 状态管理
│   │   └── settings_state.dart
│   ├── repository/
│   │   └── settings_repository.dart    # 数据访问
│   ├── ui/
│   │   └── settings_page.dart          # 页面
│   └── models/                         # 本页面专用模型
│       └── settings_data.dart
└── test/
    └── settings_cubit_test.dart
```

### 步骤 2：定义 Model（domain 层）

如果需要共享模型，放在 `packages/domain/lib/src/models/`：

```dart
// packages/domain/lib/src/models/settings_data.dart
class SettingsData {
  final bool darkMode;
  final String language;

  const SettingsData({this.darkMode = false, this.language = 'zh'});
}
```

### 步骤 3：定义 Repository 接口（domain 层）

```dart
// packages/domain/lib/src/repositories/settings_repository.dart
abstract class SettingsRepository {
  Future<SettingsData> getSettings();
  Future<void> saveSettings(SettingsData data);
}
```

### 步骤 4：实现 Repository（feature 层）

```dart
// packages/features/feature_settings/lib/repository/settings_repository_impl.dart
class SettingsRepositoryImpl implements SettingsRepository {
  final KeyValueStorage _storage;
  
  SettingsRepositoryImpl(this._storage);

  @override
  Future<SettingsData> getSettings() async {
    // 从本地存储读取
  }

  @override
  Future<void> saveSettings(SettingsData data) async {
    // 保存到本地存储
  }
}
```

### 步骤 5：实现 Cubit（feature 层）

```dart
// packages/features/feature_settings/lib/cubit/settings_cubit.dart
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  
  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> loadSettings() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final data = await _repository.getSettings();
      emit(state.copyWith(data: data, status: SettingsStatus.loaded));
    } catch (e) {
      emit(state.copyWith(error: e, status: SettingsStatus.error));
    }
  }
}
```

### 步骤 6：DI 注册（feature 层）

```dart
// packages/features/feature_settings/lib/di/setup.dart
void setupFeatureSettings(ServiceLocator sl) {
  // 注册仓储实现
  sl.registerFactory<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<KeyValueStorage>()),
  );
  
  // 注册 Cubit
  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(sl<SettingsRepository>()),
  );
}
```

### 步骤 7：添加路由（infrastructure 层）

```dart
// packages/infrastructure/routing/lib/app_router.dart
GoRouter getRouter(RouteContext ctx) {
  return GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => BlocProvider(
          create: (context) => sl<SettingsCubit>()..loadSettings(),
          child: const SettingsPage(),
        ),
      ),
    ],
  );
}
```

### 步骤 8：根项目注册（lib 层）

```dart
// lib/core/di/setup.dart
import 'package:feature_settings/feature_settings.dart';

void setupDependencies() {
  // ... 其他注册
  
  // 注册新功能
  setupFeatureSettings(sl);
}
```

```dart
// pubspec.yaml（添加本地包依赖）
dependencies:
  feature_settings:
    path: packages/features/feature_settings
```

### 步骤 9：运行

```bash
make get
make debug-simulator
```

---

## 分层决策树

### Q1: 这个模型放哪里？

```
这个数据是跨功能共享的吗？
  ├─ 是 → domain/models/
  │
  └─ 否 → 这个功能专用吗？
           ├─ 是 → features/feature_xxx/models/
           └─ 仅一个页面内 → 直接放在页面文件里
```

**记忆口诀**：「共享放 domain，专用放 feature」

---

### Q2: 这个逻辑放哪里？（Cubit vs UseCase）

```
业务逻辑需要协调多个 Repository 吗？
  ├─ 是 → UseCase（domain/usecases/）
  │
  └─ 否 → 直接放在 Cubit 里

业务逻辑需要复用吗？
  ├─ 是 → UseCase
  │
  └─ 否 → 放在对应功能的 Cubit 里
```

**记忆口诀**：「多 Repository 找 UseCase，单 Repository 放 Cubit」

---

### Q3: 这个状态放哪里？

```
这个状态需要跨功能共享吗？
  ├─ 是 → services/（AuthCubit, NetworkCubit, LocaleCubit）
  │
  └─ 否 → 功能内部 Cubit（features/feature_xxx/cubit/）
```

---

## 测试命令

```bash
# 运行所有测试
make test

# 或直接使用 flutter
fvm flutter test

# 运行特定文件
fvm flutter test packages/domain/test/

# 生成覆盖率报告
fvm flutter test --coverage
```

---

## Make 命令参考

| 命令 | 说明 |
|------|------|
| `make get` | 安装所有包依赖（主应用 + 所有本地包） |
| `make clean` | 清理构建缓存 |
| `make debug` | 运行调试版本 |
| `make debug-simulator` | 运行到 iOS 模拟器（推荐） |
| `make release` | 构建 iOS 发布版本 |
| `make lint` | 代码分析（flutter analyze） |
| `make test` | 运行测试 |
| `make create-repo` | 查看创建 Repository 步骤 |
| `make create-feature` | 查看创建 Feature 步骤 |
| `make add-api` | 查看添加 API 端点步骤 |
| `make dev` | Flavor 开发环境运行 |
| `make staging` | Flavor 预发布环境运行 |
| `make prod` | Flavor 生产环境运行 |
| `make build-prod` | 生产环境构建 APK |

---

## 环境配置

项目支持 dev / staging / prod 三套环境，通过 `--dart-define` 切换。

```bash
make dev           # 开发环境（默认）
make staging       # 预发布环境
make prod          # 生产环境
make build-prod    # 生产环境构建 APK
```

每个环境的 API 地址、日志开关、网络超时自动切换：

```dart
import 'package:my_app/config.dart';

// 当前环境
if (EnvironmentConfig.isDev) { ... }

// API 地址（自动根据环境切换）
final url = EnvironmentConfig.apiBaseUrl;
```

默认 API 地址在 `lib/config.dart` 的 `EnvironmentConfig` 中配置，接入真实项目时替换为实际地址。

---

## 列表缓存

`packages/infrastructure/list_cache/` 提供通用列表缓存策略，任意模块可复用。

### 四种策略

| 策略 | 工厂方法 | 行为 | 适用 |
|------|----------|------|------|
| **先缓存后网络** | `CacheConfig.staleWhileRevalidate()` | 立刻显示缓存 → 后台静默刷新 | 社交动态、商品列表 |
| **先网络后缓存** | `CacheConfig.networkFirst()` | 请求网络 → 成功则缓存 → 失败用缓存兜底 | 关键数据、交易记录 |
| **仅缓存** | `CacheConfig(cacheOnly)` | 只读缓存，永不请求网络 | 静态配置、说明页 |
| **仅网络** | `CacheConfig.networkOnly()` | 只请求网络，永不缓存 | 敏感数据、一次性内容 |

### 使用示例

```dart
import 'package:list_cache/list_cache.dart';

// 1. 在 RepositoryImpl 中注入
class FeedRepositoryImpl implements FeedRepository {
  final Dio _dio;
  final ListCacheManager<FeedItem> _cacheManager;

  FeedRepositoryImpl(this._dio)
      : _cacheManager = ListCacheManager<FeedItem>(
          config: CacheConfig.staleWhileRevalidate(pageSize: 20),
        );

  @override
  Future<CacheResult<FeedItem>> getFeedList({required int page}) async {
    // 2. 一行搞定缓存逻辑
    return _cacheManager.fetch(
      cacheKey: 'home_feed',           // 不同列表用不同 key
      page: page,
      networkFetcher: () async {      // 网络请求函数
        final res = await _dio.get('/api/feed', queryParameters: {'page': page});
        return (res.data as List).map((e) => FeedItem.fromJson(e)).toList();
      },
    );
  }
}

// 3. Cubit 中根据结果决定 UI
final result = await _repo.getFeedList(page: 1);
if (result.isFromCache) {
  // 数据来自缓存，可显示"加载中"指示器
} else {
  // 数据来自网络，最新数据
}
emit(FeedLoaded(items: result.data, hasMore: result.hasMore));
```

### 分页行为

- **page=1**：自动清空该 key 的旧缓存，防止新旧数据混合
- **page>1**：追加到已有缓存
- **下拉刷新**：重新请求 page=1（自动清空）

### 缓存 key 规范

不同列表用不同 key，建议格式：`'模块名_列表名_参数'`

```dart
cacheKey: 'home_feed'                 // 首页动态
cacheKey: 'user_posts_${userId}'      // 用户帖子（按 userId 隔离）
cacheKey: 'search_${keyword}'         // 搜索结果（按关键词隔离）
```

---

## 架构评分

当前架构评分：9.0+/10（2026-05 最佳实践升级后）

| 维度 | 评分 | 说明 |
|------|------|------|
| 分层隔离 | 9/10 | 纯 Dart domain + 物理包强制 |
| Repository 模式 | 9/10 | 接口在 domain，组合注入 |
| 可测性 | 8/10 | 三层测试体系（单测/bloc/widget） |
| 依赖约束 | 8/10 | 物理隔离 + lint + CI |
| 错误处理 | 8/10 | sealed 异常体系 + 全局边界 |
| 启动可靠性 | 9/10 | 分阶段 await + 性能分析 |
| 环境配置 | 9/10 | dev/staging/prod flavor 系统 |
| 缓存基础设施 | 8/10 | 通用 ListCacheManager，四种策略，分页感知 |

---

## 常见问题

**Q: 为什么 domain 必须是纯 Dart？**  
A: domain 层不依赖 Flutter，可以在任何 Dart 项目中复用，也方便编写纯 Dart 单元测试。

**Q: 什么时候用 services/，什么时候用 features/？**  
A: services/ 是全局共享的状态（如登录状态、网络状态、语言），features/ 是具体业务功能。

**Q: 如何决定是 Feature 还是 Page？**  
A: Feature 是一个完整的功能模块，包含状态、仓储、UI。Page 只是 UI 页面。一个 Feature 可以包含多个 Page。

---

## 了解更多

- domain 包结构：`packages/domain/README.md`
- core 模块说明：`lib/core/README.md`
- 依赖注入说明：`lib/core/di/README.md`
