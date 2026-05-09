# Flutter 脚手架增强设计文档

> **日期**: 2026-05-08  
> **范围**: 11 维度全面增强规划  
> **架构**: Melos Monorepo + Clean Architecture + Feature-first

---

## 1. 总体策略

### 1.1 优先级分档

| 分档 | 含义 | 维度 |
|------|------|------|
| P0 | 核心生产力——直接影响日常开发速度 | CLI 工具、API 集成、数据库 |
| P1 | 代码质量基建——减少 Bug，统一模式 | 状态/异常、依赖注入 |
| P2 | 锦上添花——长期收益，短期可搁置 | 环境/调试、设计系统、测试基建 |
| P3 | 保持现状——已经够好 | 路由、国际化、CI/CD |

### 1.2 推荐实施顺序

```
P1-1 Result<T>（纯 Dart sealed class，零依赖，地基先行）
  ↓
P0-1 CLI 工具（Mason bricks 用 Result<T> 模式生成模板）
  ↓
P0-2 API 集成（Retrofit + freezed，不改变 Repository 接口签约）
  ↓
P0-3 数据库（Hive migration + hive_model brick + Hive.init 路径统一）
  ↓
P1-2 依赖注入（injectable 代码生成，与 get_it 双轨运行）
  ↓
P2 锦上添花（Alice、ThemeExtension、测试外壳）
```

### 1.3 现状速览

| # | 维度 | 当前 | 目标 | 核心改造 |
|---|------|------|------|---------|
| 4 | CLI 工具 | 6.0 | 9.0 | 4 个 Mason bricks |
| 1 | API 集成 | 8.5 | 9.5 | Retrofit + freezed |
| 2 | 数据库 | 7.0 | 9.0 | Hive migration |
| 5 | 状态/异常 | 7.0 | 9.0 | Result<T> 模式 |
| 10 | 依赖注入 | 7.0 | 9.0 | injectable 代码生成 |
| 6 | 环境/调试 | 8.5 | 9.0 | Alice 抓包面板 |
| 7 | 设计系统 | 7.0 | 8.5 | ThemeExtension |
| 9 | 测试基建 | 7.0 | 8.5 | Widget Test 外壳 |
| 3 | 路由 | 9.0 | 保 | 仅 CLI 增强路由提示 |
| 8 | 国际化 | 8.0 | 保 | 保持 ARB+l10n.yaml |
| 11 | CI/CD | 8.0 | 保 | 保持 GitHub Actions |

---

## 2. P1-1：Result\<T\> 状态与异常统一（地基）

### 2.1 痛点

6 个 Cubit 中每种数据加载方法都手写 try-catch，模式重复 12+ 次：

```dart
Future<void> loadData() async {
  emit(const HomeState.loading());
  try {
    final data = await _repository.getHomeData();
    emit(HomeState.loaded(data: data));
  } on DomainException catch (e) {
    emit(HomeState.error(errorCode: e.message));
  }
}
```

### 2.2 设计方案

在 `packages/domain/lib/src/result.dart` 新增纯 Dart 密封类：

```dart
sealed class Result<T, E extends Exception> {
  const Result();
  R when<R>({required R Function(T data) success, required R Function(E error) failure});
}

class Success<T, E extends Exception> extends Result<T, E> {
  final T data;
  const Success(this.data);
  @override
  R when<R>({required R Function(T) success, required R Function(E) failure}) =>
      success(data);
}

class Failure<T, E extends Exception> extends Result<T, E> {
  final E error;
  const Failure(this.error);
  @override
  R when<R>({required R Function(T) success, required R Function(E) failure}) =>
      failure(error);
}
```

### 2.3 Repository 接口改造

```dart
// 之前：抛异常
abstract class HomeRepository {
  Future<HomeData> getHomeData();  // throws DomainException
}

// 之后：返回 Result
abstract class HomeRepository {
  Future<Result<HomeData, DomainException>> getHomeData();
}
```

### 2.4 Cubit 改造

```dart
// 之后：编译器强制处理两个分支，不会忘 catch
Future<void> loadData() async {
  emit(const HomeState.loading());
  final result = await _repository.getHomeData();
  emit(result.when(
    success: (data) => HomeState.loaded(data: data),
    failure: (e)   => HomeState.error(errorCode: e.message),
  ));
}
```

### 2.5 DioException → Result 桥梁

```dart
// 扩展方法，RepositoryImpl 里用
extension FutureResult<T> on Future<T> {
  Future<Result<T, DomainException>> toResult() async {
    try {
      final data = await this;
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    }
  }
}
```

### 2.6 影响范围

| 层级 | 改动 |
|------|------|
| domain | 新增 `result.dart`，Repository 接口返回 `Future<Result<T, DomainException>>` |
| feature Cubit | `try-catch` → `result.when(success:... failure:...)` |
| feature RepoImpl | `try { return data; } catch { throw ... }` → `api.xxx().toResult()` |
| Mason bricks | 生成时一步到位用 Result 模式 |
| 测试 | stub 返回类型改为 `Result<T, DomainException>` |

---

## 3. P0-1：CLI 工具增强

### 3.1 设计方案

在现有 1 个 Mason brick 基础上新增 3 个，总计 4 个：

| Brick | 命令 | 生成内容 |
|-------|------|---------|
| **feature**（增强） | `make create-feature name=X` | 现有模板 + Route 注册提示 + P1-1 Result 模式 |
| **api** | `make create-api name=X` | Retrofit interface + freezed 模型 + RepositoryImpl + DI |
| **model** | `make create-model name=X` | `@freezed class`（freezed + json_serializable）模型 |
| **hive_model** | `make create-hive-model name=X` | `@HiveType` 模型 + Adapter + Migration 骨架 + 注册 |

### 3.2 bricks 目录结构

```
bricks/
├── feature/__brick__/          # 增强现有
│   ├── lib/src/cubit/{{name}}_cubit.dart         # 用 Result.when()
│   ├── lib/src/cubit/{{name}}_state.dart         # @freezed sealed
│   ├── lib/src/repository/{{name}}_repository.dart       # 返回 Result<T>
│   ├── lib/src/repository/{{name}}_repository_impl.dart  # .toResult()
│   ├── lib/src/ui/{{name}}_page.dart
│   └── lib/src/di/setup.dart
├── api/__brick__/              # 新增
│   ├── lib/src/api/{{name}}_api.dart              # @RestApi Retrofit 接口
│   ├── lib/src/repository/{{name}}_repository_impl.dart
│   └── lib/src/di/setup.dart
├── model/__brick__/            # 新增
│   └── lib/src/models/{{name}}.dart               # @freezed 模型
└── hive_model/__brick__/       # 新增
    ├── lib/src/models/{{name}}.dart                # @HiveType 模型
    └── lib/src/migrations/{{name}}_migration.dart
```

### 3.3 生成示例：api brick

```dart
// {{name}}_api.dart — Retrofit 接口
@RestApi(baseUrl: '')
abstract class UserApi {
  factory UserApi(Dio dio) = _UserApi;

  @GET('/User/profile')
  Future<User> getProfile();

  @POST('/User/login')
  Future<LoginResponse> login(@Body() LoginRequest body);
}

// {{name}}_repository_impl.dart — Result 模式
class UserRepositoryImpl implements UserRepository {
  final UserApi _api;
  UserRepositoryImpl(this._api);

  @override
  Future<Result<User, DomainException>> getProfile() =>
      _api.getProfile().toResult();
}
```

---

## 4. P0-2：API 集成（Retrofit）

### 4.1 核心原则

Retrofit 作为 Dio 的上层代码生成层，不改造现有拦截器链。

```
Retrofit 生成的 _UserApi
         ↓ 内部使用
    sl<Dio>()  ← 同一个 Dio 实例，4 拦截器全部保留
         ↑ 由 createDio() 创建
```

### 4.2 关键集成点

| 问题 | 方案 |
|------|------|
| Dio 实例 | Retrofit 构造函数接受 `Dio dio`，直接传 `sl<Dio>()` |
| Base URL | `@RestApi(baseUrl: '')` 留空，运行时用 `dio.options.baseUrl`（已由 `setup.dart` 从 `IAppConfig.apiBaseUrl` 设置） |
| 拦截器链 | 不变。AutoCancel、TokenRenewal、AuthHeader、Log 全部保留 |
| 错误映射 | `DioExceptionMapper.toDomainException()` 在 `.toResult()` 扩展方法里用 |
| ApiEndpoints | **废除**。Retrofit 的 `@GET('/User/profile')` 本身即端点定义 |

### 4.3 不改变接口签约

P0-2 可在 P1-1 之前部署，此时 RepositoryImpl 返回 `Future<User>`（不改变接口）：

```dart
@override
Future<User> getProfile() async {
  try {
    return await _api.getProfile();   // 替换原来的 _dio.get(...)
  } on DioException catch (e) {
    throw e.toDomainException();
  }
}
```

到 P1-1 时改为 `Future<Result<User, DomainException>>`，只需改返回类型加 `.toResult()`。

---

## 5. P0-3：数据库增强（Hive）

### 5.1 现存问题

- `Hive.init()` 在 KeyValueStorage 和 BoxManager 各设路径 → **统一到 SDKInitializer.initPlugins()**
- 没有 Schema 迁移机制 → 新增 @HiveField 就崩溃
- typeId 管理需要手动协调

### 5.2 迁移策略：分两类

| 数据类型 | 策略 | 理由 |
|---------|------|------|
| **用户数据**（token、偏好） | 链式迁移 v1→v2→v3 | 不可丢失 |
| **缓存数据**（API 响应） | 版本不匹配就清空 | 可从网络重拉 |

### 5.3 链式迁移机制

```dart
// 版本追踪
final versionBox = await Hive.openBox('_schema_versions');
// 结构: { 'user_box': 2, 'order_box': 1 }

// 迁移定义
class UserMigrationV1ToV2 {
  int get fromVersion => 1;
  int get toVersion => 2;

  Future<void> apply(Box oldBox, Box newBox) async {
    for (final key in oldBox.keys) {
      final oldData = oldBox.get(key) as Map;
      final newData = {...oldData, 'newField': transform(oldData['oldField'])};
      await newBox.put(key, newData);
    }
  }
}

// 启动时自动执行
class MigrationRunner {
  Future<void> runAll() async {
    for (final migration in _migrations) {
      final current = versionBox.get(migration.boxName, defaultValue: 0);
      if (current == migration.fromVersion) {
        await migration.apply();
        await versionBox.put(migration.boxName, migration.toVersion);
      }
    }
  }
}
```

### 5.4 typeId 管理

- Mason brick 从 `register.yaml` 读取下一个可用 typeId
- 生成的 hive_model 包含 `@HiveType(typeId: <auto>)` + 完整 `@HiveField`
- 自动生成 Migration 骨架

---

## 6. P1-2：依赖注入代码化

### 6.1 当前

get_it 手动注册，每个包的 `di/setup.dart` 手写 `sl.registerFactory<X>(() => X(...))`

### 6.2 方案

injectable 代码生成替代手动注册。与现有 get_it 双轨运行，逐步迁移：

```dart
// 注解即可，不再手写 setup.dart
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository);
  final HomeRepository _repository;
}
// → build_runner 自动生成 get_it 注册代码到 *.config.dart
```

Mason bricks 生成的模板自带 `@injectable` 注解。

---

## 7. P2：锦上添花

### 7.1 环境/调试（#6）

- **Alice**：HTTP 抓包面板，仅 debug 模式
- **Logger 面板**：可视化日志查看
- **性能监控**：FPS、内存、启动耗时

```dart
if (kDebugMode) {
  dio.interceptors.add(alice.getDioInterceptor());
}
```

### 7.2 设计系统（#7）

- **ThemeExtension** 强类型：`context.colors.primary` 替代手写颜色
- 暗黑模式自动适配
- 组件补全：SearchBar、FilterChip、BottomSheet 等

### 7.3 测试基建（#9）

- **Widget Test 外壳**：自动注入 Router、Theme、i18n
- **Mock 体系**：保持 mocktail，brick 模板自带 mock 示例

---

## 8. P3：保持现状

### 8.1 路由（#3）

GoRouter + RouteModule + Auth Guard 已成熟（9.0/10）。CLI feature brick 增强：输出路由注册步骤提示。

### 8.2 国际化（#8）

保持 ARB + `l10n.yaml` + `flutter gen-l10n`。不做 slang 迁移。

### 8.3 CI/CD（#11）

保持 GitHub Actions（`ci.yml` + `coverage.yml`）。不做 Fastlane。

---

## 9. 全局检查清单

实施前需确认：

- [ ] `Hive.init()` 路径统一（KeyValueStorage 和 BoxManager 共用一个路径调用点）
- [ ] `ApiEndpoints` 废除后，TokenRenewalInterceptor 中的 `ApiBase.tokenRenewal` 常量移到独立位置
- [ ] 所有 Mason brick 模板适配 Result\<T\> 模式
- [ ] injectable 与现有 get_it 兼容（双轨运行，不破坏现有注册）
- [ ] `melos run validate` 每次变更后通过
