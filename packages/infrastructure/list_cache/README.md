# list_cache 包

通用列表缓存策略 — 任意模块可复用的列表级缓存。

## 内部结构

```
list_cache/
├── lib/
│   ├── list_cache.dart               # 导出入口
│   └── src/
│       ├── list_cache_manager.dart   # ListCacheManager（核心缓存管理）
│       ├── cache_config.dart         # CacheConfig（策略配置）
│       ├── cache_strategy.dart       # CacheStrategy（四种策略定义）
│       └── cache_result.dart         # CacheResult（缓存结果封装）
└── pubspec.yaml
```

## 四种策略

| 策略 | 工厂方法 | 行为 | 适用场景 |
|------|----------|------|----------|
| 先缓存后网络 | `CacheConfig.staleWhileRevalidate()` | 立即显示缓存 → 后台刷新 | 社交动态、商品列表 |
| 先网络后缓存 | `CacheConfig.networkFirst()` | 请求网络 → 成功缓存 → 失败兜底 | 关键数据、交易记录 |
| 仅缓存 | `CacheConfig(cacheOnly)` | 只读缓存，不请求网络 | 静态配置、说明页 |
| 仅网络 | `CacheConfig.networkOnly()` | 只请求网络，不缓存 | 敏感数据、一次性内容 |

## 使用

```dart
import 'package:list_cache/list_cache.dart';

// 在 RepositoryImpl 中注入
final _cacheManager = ListCacheManager<FeedItem>(
  config: CacheConfig.staleWhileRevalidate(pageSize: 20),
);

// 一行搞定缓存逻辑
final result = await _cacheManager.fetch(
  cacheKey: 'home_feed',
  page: page,
  networkFetcher: () async {
    final res = await _dio.get('/api/feed', queryParameters: {'page': page});
    return (res.data as List).map((e) => FeedItem.fromJson(e)).toList();
  },
);

// 根据结果决定 UI
if (result.isFromCache) { /* 数据来自缓存 */ }
if (!result.hasMore) { /* 已加载全部 */ }
```

## 分页行为

- **page=1**：自动清空旧缓存
- **page>1**：追加到已有缓存
- **下拉刷新**：重新请求 page=1

## 缓存 Key 规范

格式：`'模块名_列表名_参数'`

```dart
cacheKey: 'home_feed'                 // 首页动态
cacheKey: 'user_posts_${userId}'      // 按用户隔离
cacheKey: 'search_${keyword}'         // 按关键词隔离
```
