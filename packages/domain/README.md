# domain

纯 Dart 业务领域层 — 不依赖 Flutter SDK。

## 职责

| 目录 | 内容 | 依赖 Flutter |
|------|------|-------------|
| models/ | 共用数据模型 | 否（纯 Dart） |
| repositories/ | 仓储抽象接口 | 否 |
| exceptions/ | 领域异常体系 | 否 |
| enums/ | 共用枚举 | 否 |

## 依赖方向

```
domain (纯 Dart, 只依赖 equatable)
  ↑
infrastructure (api, routing, key_value_storage)
  ↑
services, features
```

## 关键设计

- **不依赖 Flutter** — 可独立编译和测试
- **Repository 接口** — domain 定义接口，services/features 实现
- **Sealed 异常** — `DomainException` 是 sealed class，保证穷尽性匹配
