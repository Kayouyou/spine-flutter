# api

基于 Dio 的 HTTP 客户端基础设施。

## 使用方式

```dart
final dio = createDio(
  userTokenSupplier: () async => token,
  onNetworkDisconnected: () => logger.warning('离线'),
);
```

## 架构

- `createDio()` — 创建预配置的 Dio 实例（认证拦截器 + 网络断开回调 + 日志）
- 业务 API 调用由各 RepositoryImpl 直接使用 Dio 完成
- 不再使用 mixin 模式

## 依赖方向

```
api (infrastructure, 纯技术)
  ↑
domain → services → features
```
