# api 包

HTTP 网络请求层 — 基于 Dio 的 HTTP 客户端封装。

## 内部结构

```
api/
├── lib/
│   ├── api.dart                              # 导出入口
│   └── src/
│       ├── dio_factory.dart                  # Dio 工厂函数 createDio()
│       ├── endpoints/
│       │   └── api_endpoints.dart            # 集中式 API 端点注册表
│       ├── dio/
│       │   ├── header_interceptor.dart        # 请求签名拦截器
│       │   ├── renewal_token_intercaptor.dart # Token 自动续期（状态机, 编排层）
│       │   └── error_interceptor.dart         # Dio 错误上报（5xx/网络错 → AppErrorHandler）
│       ├── refresh/
│       │   ├── refresh_queue.dart            # 续期请求队列 + PendingRequest + drain
│       │   └── refresh_api.dart              # 续期 HTTP 调用 + Token 处理 + 代理
│       ├── http/
│       │   ├── http_constant.dart            # HTTP 常量（超时、主机、错误码）
│       │   ├── http_event_bus.dart           # 事件总线（logout、hasToken）
│       │   ├── token_supplier.dart           # Token 提供者抽象接口
│       │   └── app_logger.dart               # 日志抽象接口
│       ├── error/
│       │   └── dio_mapper.dart               # DioException → DomainException 映射
│       ├── cancel/
│       │   ├── cancel_manager.dart           # 请求取消管理器
│       │   └── auto_cancel_interceptor.dart   # 自动取消拦截器
│       └── test/ ...                          # 测试文件
└── pubspec.yaml
```

## 核心功能

- **端点集中管理** — `api_endpoints.dart` 统一管理所有 API 路径，按域嵌套分组
- **Token 自动续期** — `TokenRenewalInterceptor` 监听 401，自动刷新 Token
- **请求头签名** — `HeaderInterceptor` SHA1 签名注入
- **取消管理** — `CancelTokenManager` 页面销毁时取消未完成请求
- **错误映射** — `DioExceptionMapper` 单一路径：DioException → DomainException
- **Dio 错误上报** — `ErrorInterceptor` 自动上报 5xx/网络错，4xx 业务期望错误跳过；通过 `createDio` 的 `onDioError` 回调桥接到 `AppErrorHandler`
- **Retrofit 代码生成** — 基于注解的 HTTP 客户端自动生成

### Retrofit API 接口

api 包支持两种调用方式：传统 Dio 和 Retrofit 代码生成。

```
api/
├── lib/
│   ├── api.dart
│   └── src/
│       ├── api/
│       │   ├── home_api.dart        # 首页 API
│       │   ├── detail_api.dart      # 详情 API
│       │   └── user_api.dart        # 用户 API
│       └── error/
│           ├── dio_mapper.dart      # DioException → DomainException
│           └── future_result.dart   # Future.toResult() 扩展
```

**Retrofit 使用：**
```dart
// 1. 创建接口实例（共享 Dio 和拦截器）
final homeApi = HomeApi(dio);

// 2. 调用方法
final response = await homeApi.getHomeData();

// 3. 转换为 Result（推荐）
final result = await dio.get('/api').toResult();
```

**Dio 调用转换为 Result（推荐）：**
```dart
final result = await dio.get('/api/users').toResult();
result.when(
  success: (data) => print(data),
  failure: (error) => print(error),
);
```

## 使用

```dart
import 'package:api/api.dart';

final dio = createDio(
  userTokenSupplier: () async => token,
  onNetworkDisconnected: () => logger.warning('离线'),
  onDioError: (err, stack, {context = const {}}) {
    // 桥接到 AppErrorHandler（推荐在 app shell 装配）
    AppErrorHandler.instance.reportError(err, stack, isFatal: true, context: context);
  },
);

// 端点使用集中常量
dio.get(ApiEndpoints.home.data);
dio.post(ApiEndpoints.auth.login, data: {...});

// 错误处理
try {
  await dio.get(ApiEndpoints.detail.item(id));
} on DioException catch (e) {
  throw e.toDomainException();  // → DomainException
}
```

### ErrorInterceptor 过滤规则

| 错误类型 | 是否上报 | 原因 |
|----------|----------|------|
| 5xx（500/502/503/504） | ✅ 上报 | 服务端异常，需要 Sentry 告警 |
| 网络错误（连接超时、connectionError） | ✅ 上报 | 可能是 DNS / 代理 / 后端宕机 |
| 4xx（400/401/403/404/422） | ❌ 跳过 | 业务期望错误（参数错、未登录、资源不存在），属正常流程 |
| `handler.next(err)` | 始终调用 | 链路不断，LogInterceptor 仍能记录所有错误 |

context 字段透传：`{source: 'dio', method, url, status, type}`，由 `ErrorInterceptor` 构造、`createDio` 回调透明转发。

## R3 守门：`onDioError` 为什么是 callback

`packages/infrastructure/api` **不能** import `package:error/error.dart`（AGENTS.md R3：infrastructure 不依赖 services）。所以 `ErrorInterceptor` 把错误通过 `(DioException, StackTrace?, {context}) => void` 回调向外暴露，由 app shell（`lib/core/di/setup.dart`）负责把 callback 接到 `AppErrorHandler.instance.reportError`。这让 `api` 包保持纯基础设施身份。

不传 `onDioError` 也合法：拦截器不在链中，业务错误上报由调用方自己负责。

## 注册方式

- Dio: **Singleton**（全局唯一 HTTP 客户端）

## 重构历史

- 2026-06-08: 加 `ErrorInterceptor` + `createDio.onDioError` 回调桥接（4xx 跳过、5xx/网络错上报），R3 守门
- 2026-06-06: Token 续期拦截器拆分为 3 文件 (refresh_queue + refresh_api + 主胶水), 死代码清理 32 项, 砖块契约升级 (domainInterface 强制)
- 2026-05-06: 端点集中管理 + 死代码删除（~900行）+ 错误处理统一 + 业务泄露清理。文件数 19→13，Clean Architecture 评分 5/10→8.8/10。
