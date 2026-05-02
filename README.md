# Flutter Project Scaffold

A reusable Flutter scaffold based on the ovsx architecture.

## Architecture

- **Monorepo-style**: Local packages under packages/ and packages/features/
- **Repository pattern**: Data access in packages/*_repository/
- **Feature packages**: UI features in packages/features/*
- **GoRouter navigation**: RouteModule pattern
- **Hive storage**: KeyValueStorage for local caching
- **Dio HTTP**: API package with interceptors

## Quick Start

```bash
fvm install
make get
make debug-simulator
```

## Creating New Repositories

```bash
make create-repo name=my_repository
```

## Creating New Features

```bash
make create-feature name=my_feature
```

## Adding API Modules

```bash
make add-api name=my_api
```

## 架构评分

当前架构评分：8.5+/10（2026-05 最佳实践升级后）

| 维度 | 评分 |
|------|------|
| 分层隔离 | 9/10 — 纯 Dart domain + 物理包强制 |
| Repository 模式 | 9/10 — 接口在 domain，组合注入 |
| 可测性 | 8/10 — 三层测试体系（单测/bloc/widget） |
| 依赖约束 | 8/10 — 物理隔离 + lint + CI |
| 错误处理 | 8/10 — sealed 异常体系 + 全局边界 |
| 启动可靠性 | 9/10 — 分阶段 await + 性能分析 |
