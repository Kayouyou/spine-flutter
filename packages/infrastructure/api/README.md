# api 包

HTTP 网络请求层 — 基于 Dio 的 HTTP 客户端封装。

## 内部结构

```
api/
├── lib/
│   ├── api.dart                              # 导出入口（11 个活跃导出）
│   └── src/
│       ├── dio_factory.dart                  # Dio 工厂函数 createDio()
│       ├── endpoints/
│       │   └── api_endpoints.dart            # 🆕 集中式 API 端点注册表
│       ├── dio/
│       │   ├── header_interceptor.dart        # 请求签名拦截器
│       │   └── renewal_token_intercaptor.dart # Token 自动续期（状态机）
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

## 使用

```dart
import 'package:api/api.dart';

final dio = createDio(
  userTokenSupplier: () async => token,
  onNetworkDisconnected: () => logger.warning('离线'),
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

## 注册方式

- Dio: **Singleton**（全局唯一 HTTP 客户端）

## 重构历史

- 2026-05-06: 端点集中管理 + 死代码删除（~900行）+ 错误处理统一 + 业务泄露清理。文件数 19→13，Clean Architecture 评分 5/10→8.8/10。
