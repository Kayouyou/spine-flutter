# api 包

HTTP 网络请求层 — 基于 Dio 的 HTTP 客户端封装。

## 内部结构

```
api/
├── lib/
│   ├── api.dart                              # 导出入口
│   └── src/
│       ├── dio/
│       │   ├── header_interceptor.dart        # 请求头拦截器
│       │   ├── renewal_token_intercaptor.dart # Token 自动续期拦截器
│       │   └── retry_interceptor.dart         # 失败重试拦截器
│       ├── http/
│       │   ├── http_constant.dart            # HTTP 常量（超时、重试）
│       │   ├── token_supplier.dart           # Token 提供者接口
│       │   └── app_logger.dart               # API 日志
│       ├── error/                            # API 错误处理
│       └── tracking/                         # 请求追踪
└── pubspec.yaml
```

## 核心功能

- **Token 自动续期** — `RenewalTokenInterceptor` 监听 401，自动刷新 Token
- **请求重试** — `RetryInterceptor` 网络失败自动重试
- **请求头注入** — `HeaderInterceptor` 自动添加 Auth Token、设备信息
- **并发限制** — 请求队列管理，防止并发过多
- **取消管理** — `CancelTokenManager` 页面销毁时取消未完成请求

## 使用

```dart
import 'package:api/api.dart';

final dio = createDio(
  userTokenSupplier: () async => token,
  onNetworkDisconnected: () => logger.warning('离线'),
);
dio.options.baseUrl = 'https://api.example.com';

// 注册到 DI
sl.registerSingleton<Dio>(dio);
```

## 注册方式

- Dio: **Singleton**（全局唯一 HTTP 客户端）
