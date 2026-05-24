# DI 注入流程与数据流

## 架构全景

```mermaid
flowchart TD
    subgraph Entry["App Entry (main.dart)"]
        E1["main() → runApp(MyApp())"]
    end

    subgraph Composition["Composition Root (lib/core/di/setup.dart)"]
        direction TB
        S1["GetIt (Service Locator)"]
        S2["sl.registerSingleton&lt;Dio&gt;(createDio(...))"]
        S3["sl.registerSingleton&lt;TokenStorage&gt;(...)"]
        S4["setupAuth(sl)"]
        S5["setupDataSync(sl) (可选)"]
        FR["FeatureRegistry"]
        FR1["instance.register('feature_home', setupFeatureHome)"]
        FR2["instance.register('feature_auth', setupFeatureAuth)"]
        FR3["instance.register('feature_detail', setupFeatureDetail)"]
        RUN["FeatureRegistry.instance.runAll(sl)"]
        
        S1 --> S2
        S1 --> S3
        S1 --> S4
        S1 --> S5
        S4 --> FR
        FR --> FR1
        FR --> FR2
        FR --> FR3
        FR1 --> RUN
        FR2 --> RUN
        FR3 --> RUN
    end

    subgraph FeatureSetup["Feature Setup Functions (runAll 调用)"]
        direction TB
        FS1["setupFeatureHome(GetIt sl)"]
        FS2["sl.registerFactory&lt;HomeRepository&gt;(HomeRepositoryImpl(sl&lt;Dio&gt;()))"]
        FS3["sl.registerFactory&lt;HomeCubit&gt;(HomeCubit(sl&lt;HomeRepository&gt;()))"]
        FS4["RouteModuleRegistry.register('feature_home', (ctx) => HomeRouteModule(ctx, createCubit: () => sl&lt;HomeCubit&gt;()))"]
        
        FS5["setupFeatureAuth(GetIt sl)"]
        FS6["sl.registerFactory&lt;LoginCubit&gt;(LoginCubit(sl&lt;AuthRepository&gt;()))"]
        FS7["RouteModuleRegistry.register('feature_auth', (ctx) => AuthRouteModule(ctx, createCubit: () => sl&lt;LoginCubit&gt;()))"]
        
        FS1 --> FS2 --> FS3 --> FS4
        FS5 --> FS6 --> FS7
    end

    subgraph Routing["UI Layer + Routing"]
        direction TB
        G1["GoRouter (StatefulShellRoute)"]
        G2["用户导航 /home"]
        G3["GoRouter 匹配 /home → HomeRouteModule.pageBuilder(context, state)"]
        G4["pageBuilder 内部：BlocProvider(create: (_) => createCubit()) → HomePage()"]
        G5["ctx.routeWrapper!(page) (RequestScope 自动取消请求)"]
        
        G1 --> G2 --> G3 --> G4 --> G5
    end

    subgraph DataFlow["数据流 (以 HomeCubit 为例)"]
        direction TB
        D1["HomePage 调用 context.read&lt;HomeCubit&gt;().loadData()"]
        D2["HomeCubit._repository.getHomeData() (构造函数注入)"]
        D3["HomeRepositoryImpl._dio.get('/home')"]
        D4["Result.success(data) / Result.failure(error)"]
        D5["result.when(success: emit(HomeLoaded(data)), failure: emit(HomeError(errorCode)))"]
        
        D1 --> D2 --> D3 --> D4 --> D5
    end

    Entry --> Composition
    RUN --> FS1
    RUN --> FS5
    FS4 --> Routing
    FS7 --> Routing
    G5 --> DataFlow

    classDef entry fill:#e8f5e9,stroke:#4caf50,stroke-width:2
    classDef composition fill:#e3f2fd,stroke:#2196f3,stroke-width:2
    classDef feature fill:#f3e5f5,stroke:#9c27b0,stroke-width:2
    classDef routing fill:#e8eaf6,stroke:#3f51b5,stroke-width:2
    classDef dataflow fill:#fff8e1,stroke:#ffc107,stroke-width:2

    class E1 entry
    class S1,S2,S3,S4,S5,FR,FR1,FR2,FR3,RUN composition
    class FS1,FS2,FS3,FS4,FS5,FS6,FS7 feature
    class G1,G2,G3,G4,G5 routing
    class D1,D2,D3,D4,D5 dataflow
```

## GetIt 的作用

GetIt 是 **Service Locator**（服务定位器），在这个项目中的定位：

```
┌─────────────────────────────────────────────────────────────┐
│  GetIt (Service Locator)                                     │
│                                                              │
│  ✓ 唯一真相：所有共享依赖的唯一注册点和获取点                   │
│  ✓ 生命周期管理：singleton / factory / lazySingleton          │
│  ✓ 依赖解析：通过 sl<T>() 按类型获取已注册的实例               │
│                                                              │
│  注册方式：                                                    │
│  - registerSingleton<T>(factory) → 全局唯一，立即创建          │
│  - registerFactory<T>(factory)   → 每次 sl<T>() 创建新实例     │
│  - registerLazySingleton<T>(f)   → 首次调用时创建              │
│                                                              │
│  使用场景：                                                    │
│  - Composition Root (setup.dart) → 编排所有依赖               │
│  - Feature setup functions       → 注册 feature 级依赖        │
│  - ❌ Feature route/page 中禁止直接 GetIt.instance<T>()       │
└─────────────────────────────────────────────────────────────┘
```

## Feature 如何利用 Repository / UseCase

```
Feature 内部依赖方向：

  HomePage (UI Layer)
    │
    │  context.read<HomeCubit>()  ← BlocProvider 注入
    ▼
  HomeCubit (State Management)
    │
    │  构造函数注入: HomeCubit(this._repository)
    ▼
  HomeRepository (抽象接口)
    │
    │  构造函数注入: HomeRepositoryImpl(this._dio)
    ▼
  Dio HTTP Client → API 请求
```

**关键原则：**
- **Feature 不直接访问 GetIt** — 所有依赖通过构造函数注入
- **Repository 是接口** — Feature 依赖抽象，不依赖具体实现
- **Cubit 是桥梁** — UI 通过 BlocProvider 获取 Cubit，Cubit 通过构造函数获取 Repository
- **RouteModule 是胶水层** — setup.dart 通过闭包 `createCubit: () => sl<XxxCubit>()` 把 GetIt 解析延迟到路由构建时
