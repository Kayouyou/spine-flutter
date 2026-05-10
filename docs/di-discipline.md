# DI 依赖注入规范

## 核心原则

**所有 Feature 依赖必须通过构造函数注入或 BlocProvider 传递，严禁直接在 Feature 中调用 `GetIt.instance`。**

```dart
// ❌ 错误：直接调用 GetIt.instance
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = GetIt.instance<IAppConfig>(); // 禁止
    // ...
  }
}

// ✅ 正确：通过构造函数注入
class HomePage extends StatelessWidget {
  final HomeCubit _cubit;
  const HomePage(this._cubit, {super.key});

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

## 为什么禁止直接调用 GetIt？

1. **可测试性**：直接调用 GetIt 使单元测试必须使用真实的 DI 容器，无法 mock
2. **可追溯性**：依赖关系不清晰，无法从构造函数一眼看出需要哪些依赖
3. **一致性**：如果页面可以绕过 DI，那架构规范就形同虚设

## 正确的依赖注入方式

### 方式 1：构造函数注入（推荐）

```dart
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  final IAppConfig _config;

  HomeCubit(this._repository, this._config) : super(const HomeState());

  Future<void> loadData() async {
    // 使用注入的 config
    if (_config.enableDebugLog) {
      debugPrint('Loading home data...');
    }
    // ...
  }
}
```

### 方式 2：BlocProvider 传递

```dart
// 在路由中通过 BlocProvider 创建并注入
GoRoute(
  path: '/home',
  builder: (context, state) => BlocProvider(
    create: (context) => sl<HomeCubit>()..loadData(),
    child: const HomePage(),
  ),
)
```

### 方式 3：State 传递（读取状态而非直接读取依赖）

```dart
// 在 Cubit 中处理业务逻辑，页面只读取 State
class HomeCubit extends Cubit<HomeState> {
  // config 在 Cubit 内部使用，不暴露给 UI
  final IAppConfig _config;

  Future<void> loadData() async {
    if (_config.enableDebugLog) {
      debugPrint('Loading...');
    }
    // 业务逻辑...
    emit(state.copyWith(data: result));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // 只读取 state，不直接访问 config
        return Text(state.data.title);
      },
    );
  }
}
```

## App 层 vs Feature 层

### App 层专属

以下依赖属于 App 层，**不应该**在 Feature 中直接使用：

| 依赖 | 说明 | 正确位置 |
|------|------|----------|
| Alice | HTTP 调试面板 | `lib/app.dart` 或独立 DebugWrapper |
| Upgrader | 版本更新检查 | `lib/app.dart` 或独立 UpdateWrapper |
| Sentry | 崩溃监控 | lib 层初始化，Feature 通过 ErrorReporter 接口使用 |

### Feature 层专属

Feature 应该只关心自己的业务逻辑，任何 App 级别的调试/监控功能都不应该出现在 Feature 代码中。

```dart
// ❌ Feature 不应该包含 App 级别的依赖
import 'package:alice/alice.dart';  // 禁止
import 'package:upgrader/upgrader.dart';  // 禁止

// ✅ 正确的做法：在 app.dart 中组装
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DebugWrapper(  // Alice 在 App 层
        child: UpgradeWrapper(  // Upgrader 在 App 层
          child: FeatureHomePage(),  // Feature 保持纯净
        ),
      ),
    );
  }
}
```

## DI 注册规范

Feature 的依赖在 `di/setup.dart` 中注册：

```dart
// packages/features/feature_home/lib/di/setup.dart
void setupFeatureHome(ServiceLocator sl) {
  // 注册 Repository 实现
  sl.registerFactory<HomeRepository>(
    () => HomeRepositoryImpl(sl<Dio>(), sl<KeyValueStorage>()),
  );

  // 注册 Cubit（通过 factory，每次创建新实例）
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(sl<HomeRepository>(), sl<IAppConfig>()),
  );
}
```

## 常见误区

### Q1: 为什么不直接在页面使用 `GetIt.instance` 获取 config？

> 因为这样会导致页面和 DI 容器强耦合，无法独立测试。每次重构依赖都会影响大量页面。

### Q2: 为什么 Alice/Upgrader 不能在 Feature 中使用？

> 这些是开发/运维工具，不是业务逻辑。Feature 应该只关注自己的业务领域，跨 Feature 的通用功能应该在 services/ 或 lib/ 层处理。

### Q3: Feature 需要访问配置怎么办？

> 通过两种方式：
> 1. 在 Cubit 构造时注入，页面通过 State 读取
> 2. 通过 `context.read<HomeCubit>().state` 访问（但不要直接访问 cubit 内部的 config）

## 验证

使用 `melos analyze` 检查项目中是否存在禁止的模式：

```bash
# 搜索 GetIt.instance 在 Feature 中的使用
grep -r "GetIt.instance" packages/features/
```

如果发现违规，需要重构为构造函数注入模式。

## 相关文档

- [环境配置](./environment-config.md) - IAppConfig 正确使用方式
- [依赖注入说明](../lib/core/di/README.md) - ServiceLocator 详细用法
- [架构评分](./architecture-rating.md) - 审计发现与改进
