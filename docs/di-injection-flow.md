# DI 注入流程与数据流

## 架构全景

```mermaid
flowchart TD
    subgraph Entry["应用入口 (main.dart)"]
        E1["main() → runApp(SpineFlutter())"]
    end

    subgraph Composition["依赖注入编排 (lib/core/di/setup.dart)"]
        direction TB
        S1["GetIt 服务定位器"]
        S2["注册 Dio 网络客户端"]
        S3["注册 TokenStorage 令牌存储"]
        S4["注册认证服务 setupAuth"]
        S5["注册数据同步 setupDataSync（可选）"]
        FR["功能注册中心 FeatureRegistry"]
        FR1["注册 feature_home"]
        FR2["注册 feature_auth"]
        FR3["注册 feature_detail"]
        RUN["统一执行 runAll(sl)"]
        
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

    subgraph FeatureSetup["功能模块初始化 (runAll 遍历调用)"]
        direction TB
        FS1["setupFeatureHome(GetIt sl)"]
        FS2["注册 HomeRepository (Dio 实现)"]
        FS3["注册 HomeCubit (注入 Repository)"]
        FS4["注册路由模块，通过闭包传入 createCubit 工厂"]
        
        FS5["setupFeatureAuth(GetIt sl)"]
        FS6["注册 LoginCubit (注入 AuthRepository)"]
        FS7["注册路由模块，通过闭包传入 createCubit 工厂"]
        
        FS1 --> FS2 --> FS3 --> FS4
        FS5 --> FS6 --> FS7
    end

    subgraph Routing["用户导航触发路由"]
        direction TB
        G1["GoRouter (底部导航 StatefulShellRoute)"]
        G2["用户点击导航到 /home"]
        G3["GoRouter 匹配路由 → HomeRouteModule.pageBuilder(context, state)"]
        G4["pageBuilder 内部：用 createCubit() 创建 Cubit，包裹 HomePage"]
        G5["套上 ctx.routeWrapper (RequestScope 自动取消请求)"]
        
        G1 --> G2 --> G3 --> G4 --> G5
    end

    subgraph DataFlow["数据流 (以 HomeCubit 为例)"]
        direction TB
        D1["HomePage 调用 context.read&lt;HomeCubit&gt;().loadData()"]
        D2["HomeCubit 调用 _repository.getHomeData()"]
        D3["Repository 发起 Dio HTTP 请求"]
        D4["返回 Result.success(data) 或 Result.failure(error)"]
        D5["result.when() 穷尽匹配 → emit(HomeLoaded / HomeError) → UI 更新"]
        
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

GetIt 是 **服务定位器 (Service Locator)**，在这个项目中的定位：

```
┌─────────────────────────────────────────────────────────────┐
│  GetIt (服务定位器)                                           │
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
Feature 内部依赖方向（从上到下，逐层构造函数注入）：

  HomePage (页面/视图层)
    │
    │  context.read<HomeCubit>()  ← BlocProvider 在路由构建时注入
    ▼
  HomeCubit (状态管理层)
    │
    │  构造函数注入: HomeCubit(this._repository)
    ▼
  HomeRepository (仓储抽象接口)
    │
    │  构造函数注入: HomeRepositoryImpl(this._dio)
    ▼
  Dio HTTP 客户端 → 发起 API 请求
```

**关键原则：**
- **Feature 不直接访问 GetIt** — 所有依赖通过构造函数注入，不在页面或路由中 `GetIt.instance<T>()`
- **Repository 是接口** — Feature 依赖抽象，不依赖具体实现
- **Cubit 是桥梁** — UI 通过 BlocProvider 获取 Cubit，Cubit 通过构造函数获取 Repository
- **RouteModule 是胶水层** — setup.dart 通过闭包 `createCubit: () => sl<XxxCubit>()` 把 GetIt 解析延迟到路由构建时
