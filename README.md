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
- [开发工具](#开发工具)
- [环境配置](#环境配置)
- [资源管理（flutter_gen）](#资源管理flutter_gen)
- [主题系统（Theme）](#主题系统theme)
- [列表缓存](#列表缓存)
- [架构评分](#架构评分)
- [Melos 多包管理](#melos-多包管理)
- [Mason 代码模板](#mason-代码模板)
- [监控与更新](#监控与更新)
- [路由守卫](#路由守卫)
- [Domain 测试](#domain-测试)
- [Login/Register 示例](#loginregister-示例)
- [测试覆盖率](#测试覆盖率)

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
│   │   ├── list_cache/           # 列表缓存策略
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
├── melos.yaml                   # Melos 多包管理配置
├── mason.yaml                   # Mason 代码模板配置
├── pubspec.yaml                 # 主应用依赖
├── l10n.yaml                    # 国际化配置
│
├── env/                         # 环境变量文件
│   ├── .env.dev                 # 开发环境
│   ├── .env.staging             # 预发布环境
│   └── .env.prod                # 生产环境
│
├── assets/                      # 静态资源
│   ├── icon.png                 # 应用图标
│   ├── splash.png               # 启动页图片
│   ├── images/                  # 图片资源
│   └── fonts/                   # 字体资源
│
├── bricks/                      # Mason 代码模板
│   └── feature/                 # Feature 模板
│
└── docs/                        # 文档
```

### 各层职责速查

| 目录 | 职责 | 依赖 Flutter？ |
|------|------|--------------|
| `packages/domain/` | 纯业务：模型、仓储接口、用例、枚举、异常、**IAppConfig** | ❌ 否 |
| `packages/infrastructure/` | 技术：API、路由、存储 | ⚠️ 仅技术栈 |
| `packages/services/` | 共享状态：AuthCubit、NetworkCubit、LocaleCubit | ✅ 是 |
| `packages/features/` | 功能模块：一个功能一个包 | ✅ 是 |
| `lib/` | 组装：main.dart、DI 编排、路由绑定、**EnvAppConfig** | ✅ 是 |

---

## 快速开始

```bash
# 0. 安装 Melos（首次）
dart pub global activate melos

# 1. 安装依赖（Melos 自动扫描所有包）
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

### 快速方式：一行命令

```bash
make create-feature name=settings
```

自动执行三步：生成文件 → `melos bs` 安装依赖 → `build_runner` 生成 freezed 代码。

完成后 RouteModule 自动注册，DI 需在 `lib/core/di/setup.dart` 中显式注册一行（见手动方式步骤 8）。

> 详细用法见 [Mason 代码模板](#mason-代码模板) 章节。

### 手动方式（传统步骤）

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

### 步骤 7：添加路由模块（infrastructure 层）

```dart
// packages/features/feature_settings/lib/src/routes/settings_route_module.dart
class SettingsRouteModule extends RouteModule {
  SettingsRouteModule(super.ctx);
  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/settings',
        builder: (context, state) => BlocProvider(
          create: (context) => sl<SettingsCubit>()..loadSettings(),
          child: const SettingsPage(),
        ),
      ),
    ];
  }
}

// packages/features/feature_settings/lib/src/di/setup.dart
void setupFeatureSettings(GetIt sl) {
  // 注册 DI
  sl.registerFactory<SettingsRepository>(() => SettingsRepositoryImpl(sl<KeyValueStorage>()));
  sl.registerFactory<SettingsCubit>(() => SettingsCubit(sl<SettingsRepository>()));
  
  // 路由自动注册（FeatureRegistry + RouteModuleRegistry 自动接入）
  RouteModuleRegistry.instance.register('feature_settings', (ctx) => SettingsRouteModule(ctx));
}
```

### 步骤 8：添加根依赖 + 显式注册

```yaml
# pubspec.yaml（添加本地包依赖）
dependencies:
  feature_settings:
    path: packages/features/feature_settings
```

```dart
// lib/core/di/setup.dart（添加一行 import + 一行 register）
import 'package:feature_settings/feature_settings.dart';

void setupDependencies() {
  // ... 其他注册
  FeatureRegistry.instance.register('feature_settings', setupFeatureSettings);
  FeatureRegistry.instance.runAll(sl);
}
```

> **设计说明**：FeatureRegistry 采用"显式注册 + 统一执行"模式。
> Barrel 文件不依赖 import 副作用注册，避免热重载/冷启动时序问题。
> 新增 feature 只需在 setup.dart 加一行 `register` + 一行 `import`。

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
# 运行所有包测试（Melos）
make test

# 只跑变更相关包的测试（快）
melos test:affected

# 运行特定包测试
cd packages/domain && flutter test

# 生成覆盖率报告
melos test:coverage
```

---

## Make 命令参考

| 命令 | 说明 |
|------|------|
| `make get` | 安装所有包依赖（通过 Melos 自动扫描） |
| `make clean` | 清理构建缓存 |
| `make debug` | 运行调试版本 |
| `make debug-simulator` | 运行到 iOS 模拟器（推荐） |
| `make release` | 构建 iOS 发布版本 |
| `make lint` | 代码分析（Melos 全量，内部调用 `melos run analyze`） |
| `make test` | 运行所有包测试（Melos） |
| `make create-repo` | 查看创建 Repository 步骤 |
| `make create-feature name=xxx` | 创建新 Feature 包（生成 + 装依赖 + 生成 freezed） |
| `make create-model name=xxx` | 创建 @freezed 数据模型（domain 包） |
| `make create-api name=xxx baseUrl=/api/v1 [modelName=xxx]` | 创建 Retrofit API 模块（指定 modelName=dynamic 可不传模型） |
| `make scaffold-api name=xxx baseUrl=/api/v1` | 一键创建 Model + API（create-model + create-api） |
| `make create-hive-model name=xxx typeId=N` | 创建 @HiveType 本地存储模型 |
| `make add-api` | 查看添加 API 端点步骤 |
| `make dev` | 开发环境运行（env/.env.dev） |
| `make staging` | 预发布环境运行（env/.env.staging） |
| `make prod` | 生产环境运行（env/.env.prod） |
| `make build-prod` | 生产环境构建 APK（env/.env.prod） |
| `make bs` | 仅安装依赖（= melos bs） |
| `make gen-api-mason spec=xxx` | 从 JSON spec 生成 API 代码（Mason ✨） |
| `make gen-all-apis-mason` | 批量生成所有 spec 代码（Mason ✨） |
| `make refresh-api-mason` | 完整刷新：生成 + 依赖 + build_runner + 校验（内部调用 `melos run analyze`） |
| `make gen-api spec=xxx` | 从 JSON spec 生成 API 代码（Dart 脚本备用） |

> 📌 2026-05-10 修复：domain 包已添加 build_runner/freezed/json_serializable，create-model 现已可用；create-api 支持 `--modelName dynamic` 跳过交互式输入；lint/refresh-api-mason 已改用 `melos run analyze`。

---

## 开发工具

项目内置自动化检查，pre-commit 本地把关 + CI 远端兜底。

| 工具 | 触发时机 | 检查内容 | 跳过方式 |
|------|----------|----------|----------|
| **check_deps.sh** | hook / CI / 手动 | Feature 包不得反向依赖 my_app | — |
| **pre-commit hook** | `git commit` 时 | check_deps → l10n → analyze(仅 error) → 增量测试 | `git commit --no-verify` |
| **check_l10n.sh** | hook / CI / 手动 | ARB 文件 key 数量一致（模板: `app_zh.arb`） | — |
| **CI (GitHub Actions)** | push 到 main | check_deps → l10n → analyze(仅 error) → test → build | — |
| **Melos validate** | 手动一键验收 | deps → l10n → analyze → test 全跑 | — |
| **Melos** | 日常开发 | 多包管理：统一依赖安装、测试、分析 | — |
| **Mason** | 新建 Feature | 代码模板：mason make feature --name xxx | — |

**一键验收**（新同学跑这条就知道是否健康）：
```bash
melos run validate
```

**手动运行**：
```bash
./scripts/check_deps.sh        # 检查依赖方向
./scripts/check_l10n.sh        # 检查翻译一致性
.githooks/pre-commit            # 执行完整 hook（模拟提交前检查）
```

**修改 hook**：编辑 `.githooks/pre-commit`，下次 commit 自动生效。  
**修改 CI**：编辑 `.github/workflows/ci.yml`，push 后 GitHub Actions 自动加载。

---

## 环境配置

### 快速使用

通过 `--dart-define-from-file` 读取 `env/` 目录下的环境文件。

```bash
make dev           # 开发环境（env/.env.dev）
make staging       # 预发布环境（env/.env.staging）
make prod          # 生产环境（env/.env.prod）
```

### 环境变量

定义在 `env/.env.*`：

| 变量 | 说明 |
|------|------|
| ENV | 环境名称 |
| API_BASE_URL | API 地址 |
| SENTRY_DSN | Sentry DSN（空=不启用） |
| APP_STORE_ID | App Store ID（空=不启用更新检查） |

> `.env.prod` 和 `.env.staging` 已加入 .gitignore。

### 配置架构（三层设计）

```
┌─────────────────────────────────────────────────────────────┐
│                    环境变量（.env.* 文件）                       │
│   --dart-define-from-file=env/.env.dev                       │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ 编译时注入
┌──────────────────────┴──────────────────────────────────────┐
│  EnvironmentConfig（lib/config.dart）                         │
│  职责：读取原始环境变量，提供静态属性                              │
│  警告：这是 ONLY 被 EnvAppConfig 引用的文件，其他任何地方不要直接 import │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ 包装为接口
┌──────────────────────┴──────────────────────────────────────┐
│  EnvAppConfig（lib/core/config/app_config.dart）              │
│  职责：实现 IAppConfig 接口，唯一读取 EnvironmentConfig 的地方      │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ 注册为 DI Singleton
┌──────────────────────┴──────────────────────────────────────┐
│  IAppConfig（packages/domain/lib/src/config/app_config.dart）  │
│  职责：纯 Dart 接口契约，定义 feature 层需要的所有配置              │
│  使用：通过 sl<IAppConfig>() 全局获取                           │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ 注入到各层
┌──────────────────────┬──────────────────────┬───────────────┐
│  app 层               │  feature 层            │  infra 层     │
│  sl<IAppConfig>()     │  GetIt.instance       │  参数传参      │
│  .enableAuthGuard     │  .<IAppConfig>()      │  (已解耦)      │
│  .sentryDsn          │  .enableDebugLog      │               │
│                      │  .apiBaseUrl          │               │
└──────────────────────┴──────────────────────┴───────────────┘
```

### 为什么这么设计

| 问题 | 方案 |
|------|------|
| feature 不能反向依赖 app | `IAppConfig` 放在 domain（纯 Dart，无 Flutter 依赖） |
| 各处直接读静态变量，改实现要改 N 处 | DI 注入，换实现只需改 `EnvAppConfig` |
| 传参层层透传，新增配置改所有中间层 | 需要处直接 `GetIt.instance<IAppConfig>()` |
| 区分"app 专用配置"和"feature 共享配置" | `IAppConfig` 只放 feature 真正需要的 |

### 原则

1. **`EnvironmentConfig` 只被 `EnvAppConfig` 引用**，其他地方不得 import `config.dart`
2. **`IAppConfig` 包含所有配置**，不分 app/feature。统一入口比"区分边界"更重要——避免出现"这个配置走 DI，那个配置直接读"的混乱
3. **单个 UI 行为配置继续传参**（如某个按钮的颜色），不要为了"统一"硬塞进 IAppConfig
4. **新增配置时先问**：这个配置 feature 层需要读吗？→ 是则加接口，否则留在 `EnvAppConfig` 私有

### 使用示例

```dart
// ===== app 层（setup.dart）=====
final config = sl<IAppConfig>();
dio.options.baseUrl = config.apiBaseUrl;

// ===== feature 层（widget 中）=====
import 'package:get_it/get_it.dart';
import 'package:domain/domain.dart';

final debugLogging = GetIt.instance<IAppConfig>().enableDebugLog;

// ===== feature 层（Cubit 中）=====
class HomeCubit extends Cubit<HomeState> {
  final IAppConfig _config;
  HomeCubit(this._config, ...);
}
```

### 新增配置的流程

1. 在 `env/.env.dev` 加变量（如 `NEW_FEATURE_FLAG=true`）
2. 在 `lib/config.dart` 加 `EnvironmentConfig` 静态属性
3. 在 `packages/domain/lib/src/config/app_config.dart` 加 `IAppConfig` 接口
4. 在 `lib/core/config/app_config.dart` 加 `EnvAppConfig` 实现
5. 业务代码通过 `sl<IAppConfig>()` 读取

---

## 资源管理（flutter_gen）

项目使用 flutter_gen 提供强类型的资源访问，避免手写字符串路径。

### 添加新资源

将图片放入 `assets/images/` 目录，然后运行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 使用方式

```dart
// 之前（手写字符串，容易出错）
Image.asset('assets/images/logo.png')

// 之后（强类型，有代码补全）
Image.asset(Assets.images.logo.path)
```

生成的代码在 `lib/gen/assets.gen.dart`，无需手动编辑。

### 配置

`pubspec.yaml` 中 `flutter_gen` 节点控制生成行为：

```yaml
flutter_gen:
  output: lib/gen/
  assets:
    enabled: true
    outputs:
      class_name: Assets
```

> 注意：添加或删除资源后需要重新运行 `build_runner`，生成的 `assets.gen.dart` 已纳入版本控制。

---

## 主题系统（Theme）

本项目使用 Flutter 内置 **ThemeExtension** 方案管理主题颜色，支持亮色/暗色自动切换。

### 快速使用

```dart
// 在任意 Widget 中通过 context 访问颜色
Container(
  color: context.colors.primary,
  child: Text('标题', style: TextStyle(color: context.colors.textPrimaryLight)),
)
```

### 可用颜色

| 属性 | 亮光模式 | 深色模式 | 用途 |
|------|---------|---------|------|
| `primary` | #1976D2 | #42A5F5 | 主色调 |
| `secondary` | #26A69A | #4DB6AC | 次色调 |
| `success` / `warning` / `error` / `info` | ✅ | ✅ | 状态色 |
| `backgroundLight` / `backgroundDark` | ✅ | ✅ | 背景色 |
| `textPrimaryLight` / `textPrimaryDark` | ✅ | ✅ | 文字色 |
| `border` / `divider` | ✅ | ✅ | 边框/分割线 |

### 如何新增颜色

1. 在 `lib/src/theme/app_colors.dart` 的 `AppColors` 类中添加属性
2. 在 `light` 和 `dark` 静态常量添加对应值
3. 更新 `copyWith()` 和 `lerp()` 方法
4. 通过 `context.colors.newColor` 使用

详见：[lib/src/theme/README.md](lib/src/theme/README.md)

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

## 最近架构演进

### FeatureRegistry 收口为显式注册模式（2026-05-11）
- 移除 barrel 文件中的 `FeatureRegistry.register`（import 副作用不稳定，冷启动/热重载时序问题）
- `lib/core/di/setup.dart` 显式 `register` + `runAll` 统一执行
- 新增 `test/unit/di/feature_registry_test.dart`（5 个守门测试）
- 新增 `test/unit/routing/route_module_registry_test.dart`（6 个守门测试）
- README 文档对齐显式注册行为

### Result<T, E> 模式（2026-05-09）
- domain 层引入 `Result<T, E>` 密封类替代 try-catch 错误处理
- 所有仓储接口/实现返回 `Result<T, DomainException>`
- Cubit 通过 `result.when()` 穷尽匹配成功/失败
- 创建 `Future.toResult()` 扩展自动转换 DioException
- Mason 模板已更新包含 Result 模式

### Retrofit API 集成（2026-05-09）
- api 包添加 Retrofit 代码生成（5个业务域接口）
- 仓库实现改用 Retrofit API 替代直接 Dio 调用
- `ApiEndpoints` 标记为 @Deprecated

### Hive 迁移框架（2026-05-09）
- key_value_storage 包支持 schema 版本管理和数据迁移
- 支持链式迁移（保留数据）和版本不匹配清除策略
- 创建 `register.yaml` 集中管理 Hive TypeId

### Mason 砖块扩展（2026-05-09）
- 新增 `api` 砖：一键创建 Retrofit API 模块
- 新增 `model` 砖：一键创建 @freezed 数据模型
- 新增 `hive_model` 砖：一键创建 @HiveType 本地存储模型
- 新增 `create-api` / `create-model` / `create-hive-model` make 命令

### API 生成 Mason 化（2026-05-10）
- 新增 `api_gen_spec` 砖：从 JSON spec 自动生成完整 API 代码（替代 `gen_api.dart` 入口）
- `post_gen.dart` 钩子读取 JSON spec → 生成 Freezed DTO + Retrofit API + Hive CM → 更新 barrel
- 新增 `make gen-api-mason` / `gen-all-apis-mason` / `refresh-api-mason` 目标
- 输出与 `gen_api.dart` **完全一致**，Dart 脚本保留为备用

---

## 架构评分

当前架构评分：**8.8/10**（2026-05-10 审计后为 7.8，经 P0-P3 修复后升至 8.8，目标 9.2/10）

> 📌 2026-05 审计发现：原 9.0/10 评分偏高，部分设计意图未完全落地。详见 [审计发现摘要](#审计发现摘要)。

### 审计发现摘要

| 维度 | 设计意图 | 实际现状 | 差距 | 状态 |
|------|---------|---------|------|------|
| Auth DI | 依赖注入 | 页面直接 bypass | 严重 | 已修复 |
| Repository 模式 | 接口在 domain | 模板生成在 feature | 中等 | 已修复 |
| 类型安全 | 全类型化 | Map\<String,dynamic\> 在 domain 层 | 中等 | P4 待处理 |
| DataSync | 按 spec 需实现 | 空实现 | 中等 | 已标注 |
| 路由自动注册 | 全链路自动 | import 副作用不稳定 | 中等 | **收口为显式注册** |
| 测试守门 | 自动接入有测试 | 无 | 中等 | **已修复** |

| 维度 | 评分 | 说明 |
|------|------|------|
| 分层隔离 | 9.5/10 | 纯 Dart domain + 物理包强制 + Repository 接口统一归位 |
| State 管理 | 9/10 | 全部 @freezed 统一，auto copyWith/==/toString |
| Repository 模式 | 9.5/10 | 接口在 domain，组合注入，HomeRepo 已接入缓存 |
| 路由架构 | 9/10 | GoRouter + RouteModule + Deep Link + Auth Guard |
| 缓存体系 | 9/10 | ListCacheManager 4 策略 + 分页感知 + 已接入使用 |
| 存储安全 | 9/10 | PreferenceKey enum 类型化，48 key 无魔法字符串 |
| 组件库 | 8.5/10 | AppScaffold/CustomAppBar + LoadingButton/EmptyState/ErrorCard |
| 可测性 | 8.5/10 | 三层测试 + bloc_test + RTL 测试 |
| 错误处理 | 9/10 | sealed 异常 + Dio 映射 + ErrorReporter 接口（Sentry 就绪） |
| 网络监控 | 9/10 | connectivity_plus + NetworkQualityMonitor（弱网检测） |
| 启动可靠性 | 9/10 | 分阶段 await + 性能分析 |
| 环境配置 | 9/10 | dev/staging/prod flavor 系统 |
| 开发工具链 | 9.5/10 | Melos 多包管理 + Mason 代码模板 + validate 一键验收 |
| 资源管理 | 9/10 | 一键图标/启动页 |
| 监控体系 | 9/10 | Sentry 崩溃监控（DSN 空时自动禁用） |
| 版本管理 | 9/10 | upgrader 强制更新检查 |

## 标准脚手架通过条件

本项目定位为**团队中型项目起步骨架**。以下检查全部通过即视为"健康"：

```bash
melos run validate
```

包含 4 项检查：
| # | 检查 | 说明 |
|---|------|------|
| 1 | `check_deps.sh` | Feature 包不得反向依赖 my_app |
| 2 | `check_l10n.sh` | ARB 翻译 key 数量一致 |
| 3 | `melos analyze` | 静态分析（--no-fatal-infos --no-fatal-warnings） |
| 4 | `melos test` | 全量测试通过 |

**文档一致性**：melos.yaml / pre-commit / CI 四处 analyze 标准已统一为 `--no-fatal-infos --no-fatal-warnings`。

---

## Melos 多包管理

项目使用 Melos 管理 Monorepo 多包依赖。

### 核心命令

```bash
melos bootstrap   # 安装所有包依赖（= make get）
melos validate    # ✅ 一键验收：deps → l10n → analyze → test
melos analyze     # 全量代码分析（= make lint）
melos test        # 运行所有包测试（= make test）
melos test:affected  # 仅变更包测试（CI 增量）
melos check:deps  # 检查依赖方向
melos clean       # 清理所有包构建缓存
```

### 配置文件

`melos.yaml` 定义包路径、脚本命令和 bootstrapping 行为。

---

## Mason 代码模板

Mason 提供标准化 Feature 包生成模板，减少重复工作。

### 使用方式

```bash
# 一行命令：生成 + 装依赖 + 生成 freezed 代码
make create-feature name=settings
```

单步生成（如需手动控制）：
```bash
# 仅生成模板文件
mason make feature --name settings --output-dir packages/features/feature_settings
# 然后手动安装依赖 + 生成代码
make get
cd packages/features/feature_settings && dart run build_runner build --delete-conflicting-outputs
```

### 模板内容

生成的 Feature 包包含完整结构：`lib/`（di/cubit/repository/ui/models）、`pubspec.yaml`、`test/`。

### 自定义模板

模板位于 `bricks/feature/`，可根据团队规范修改。

### Mason 砖块一览

项目现有 6 个 Mason 砖块：

| 砖块 | 用途 | 入口命令 |
|------|------|----------|
| `feature` | 一键创建完整的 Flutter Feature 包（含 cubit、repository、UI、DI） | `make create-feature name=xxx` |
| `api` | 一键创建 Retrofit API 模块（含 RepositoryImpl、DI 注册） | `make create-api name=xxx baseUrl=/api/v1` |
| `model` | 一键创建 @freezed 数据模型 | `make create-model name=xxx` |
| `hive_model` | 一键创建 @HiveType 本地存储模型 | `make create-hive-model name=xxx typeId=N` |
| `api_gen` | 从砖块 vars 生成单个 Retrofit API 文件（模板级） | `mason make api_gen --domain xxx ...` |
| `api_gen_spec` ⭐ | 从 JSON spec 文件自动生成全部 API 代码（推荐） | `make gen-api-mason spec=auth.json` |

### API 代码生成（推荐 Mason 方式）

JSON spec 文件位于 `packages/infrastructure/api/spec/`（如 `auth.json`、`user.json` 等）。

**一键生成（Mason ✨）**：
```bash
# 单个 spec
make gen-api-mason spec=auth.json

# 批量所有 spec
make gen-all-apis-mason

# 完整刷新（生成 + 依赖 + build_runner + 校验）
make refresh-api-mason
```

**备用方式（Dart 脚本）**：
```bash
# 单文件
make gen-api spec=auth.json

# 批量
make gen-all-apis

# 完整刷新
make refresh-api
```

两种方式输出**完全一致**，`scripts/gen_api.dart` 保留为备用。

---

## 监控与更新

### Sentry 崩溃监控

- 通过 `SENTRY_DSN` 环境变量启用
- DSN 为空时自动禁用，不影响开发
- `SentryReporter` 实现 `ErrorReporter` 接口

### Upgrader 强制更新

- 通过 `APP_STORE_ID` 环境变量启用
- 首页集成 `UpgradeAlert` widget
- 检测 App Store 版本，弹窗提示更新

### 环境控制

| 环境 | SENTRY_DSN | APP_STORE_ID |
|------|------------|--------------|
| dev | 空（禁用） | 空（禁用） |
| staging | 可配置 | 可配置 |
| prod | 必填 | 必填 |

---

## 路由守卫

环境自动启用（debug/staging）。白名单：`/`, `/home`, `/login`, `/register`。

详细指南：[docs/auth-route-guard.md](docs/auth-route-guard.md)

---

## Domain 测试

按风险优先覆盖。Phase 1：usecases 100%。

详细指南：[docs/domain-testing-guide.md](docs/domain-testing-guide.md)

---

## Login/Register 示例

脚手架示例页面，位于 `packages/features/feature_auth/`。

### 认证流程

```mermaid
%%{init: {'theme':'dark', 'themeVariables': {'primaryColor':'#4fc3f7','primaryTextColor':'#fff','primaryBorderColor':'#4fc3f7','lineColor':'#ffa726','sectionBkgColor':'#1e1e1e','altSectionBkgColor':'#2d2d2d','gridColor':'#404040','secondaryColor':'#ff6b6b','tertiaryColor':'#81c784'}}}%%
sequenceDiagram
    participant App as App启动
    participant AM as AuthManager
    participant TS as TokenStorage
    participant KVS as KeyValueStorage(Hive)
    participant Dio as Dio拦截器
    participant API as 后端API
    participant RI as TokenRenewalInterceptor

    App->>AM: handleLogin()
    AM->>TS: getToken()
    TS->>KVS: getString(auth_token)
    KVS-->>TS: token (可能为null)
    TS-->>AM: token

    alt token存在
        AM->>API: getCurrentUser() 验证
        API-->>AM: user对象
        AM->>TS: setUserId(user.id)
        TS->>KVS: putString(auth_user_id, user.id)
        AM->>AM: AuthCubit.loggedIn(userId)
    else token不存在
        AM-->>App: 返回，等待用户主动登录
    end

    User->>Dio: 发起API请求
    Dio->>TS: getToken()
    TS->>KVS: getString(auth_token)
    KVS-->>TS: token
    TS-->>Dio: token
    alt token存在
        Dio->>API: 请求带上token
    else token不存在
        Dio->>API: 请求不带token
    end

    alt API返回code=1000102需要续期
        RI->>TS: setToken(newToken)
        TS->>KVS: putString(auth_token, newToken)
        KVS-->>TS: 写入成功
        RI->>TS: getToken()
        TS->>KVS: getString(auth_token)
        KVS-->>TS: newToken
        TS-->>RI: newToken
        RI->>User: 用新Token重试请求
    end
```

### 核心组件

| 组件 | 文件 | 职责 |
|------|------|------|
| `AuthManager` | `packages/services/auth/lib/src/manager.dart` | 认证逻辑：自动登录、Token持久化、登出 |
| `TokenStorage` | `packages/infrastructure/key_value_storage/lib/src/token_storage.dart` | Token读写，封装KeyValueStorage |
| `KeyValueStorage` | `packages/infrastructure/key_value_storage/` | Hive底层存储 |
| `TokenRenewalInterceptor` | `packages/infrastructure/api/lib/src/dio/renewal_token_intercaptor.dart` | 401自动续期，成功后写入Hive |

### 使用方式

```dart
// App启动时调用，自动检查Token
await sl<AuthManager>().handleLogin();

// 登录成功后保存Token
await sl<AuthManager>().saveToken(token, userId);

// 登出
await sl<AuthManager>().logout();

// 检查登录状态
sl<AuthManager>().isLoggedIn;
```

---

## 测试覆盖率

双轨报告：CI codecov + 本地 HTML。

详细指南：[docs/coverage-guide.md](docs/coverage-guide.md)

---

## UI 层统一模式

本项目建立了 UI 层的统一模式，减少模板代码，提升开发效率。

### 统一导航栏（CustomAppBar）

所有页面使用 CustomAppBar widget，统一 AppBar 样式。

```dart
AppScaffold(title: '首页', body: ...)
```

### 统一页面结构（AppScaffold）

AppScaffold widget 封装 Scaffold + CustomAppBar。

**简单模式**：
```dart
AppScaffold(title: '首页', body: BlocBuilder<...>(...))
```

**高级模式**：
```dart
AppScaffold(
  title: state.isLoading ? '登录中...' : '登录',
  body: BlocBuilder<LoginCubit, LoginState>(
    builder: (context, state) {
      return switch (state) {
        LoginLoading() => const Center(child: CircularProgressIndicator()),
        LoginLoaded() => LoginContent(data: state.data),
        LoginError() => ErrorWidget(state.error),
      };
    },
  ),
)
```

### 统一生命周期（LifecycleMixin）

```dart
class _EditPageState extends State<EditPage> with LifecycleMixin<EditPage> {
  @override
  void onPageEnter() { context.read<EditCubit>().loadData(); }
  @override
  void onPageLeave() { context.read<EditCubit>().saveData(); }
}
```

**详细指南**：[docs/ui-lifecycle-patterns-guide.md](docs/ui-lifecycle-patterns-guide.md)

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
- DI 规范：[docs/di-discipline.md](docs/di-discipline.md)（所有 Feature 必须使用构造函数注入，禁止直接调用 GetIt）
