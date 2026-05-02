import 'cache_strategy.dart';

/// 缓存配置
class CacheConfig {
  /// 缓存策略
  final ListCacheStrategy strategy;

  /// 缓存过期时长（null = 永不过期）
  final Duration? staleDuration;

  /// 每页条目数（用于分页 key 计算）
  final int pageSize;

  /// 最大缓存页数（超出后删除最早的页）
  final int maxCachedPages;

  const CacheConfig({
    this.strategy = ListCacheStrategy.cacheFirst,
    this.staleDuration,
    this.pageSize = 20,
    this.maxCachedPages = 10,
  });

  /// 快捷构造：先缓存后网络，5 分钟过期
  factory CacheConfig.staleWhileRevalidate({int pageSize = 20}) {
    return CacheConfig(
      strategy: ListCacheStrategy.cacheFirst,
      staleDuration: const Duration(minutes: 5),
      pageSize: pageSize,
    );
  }

  /// 快捷构造：先网络后缓存，1 小时过期
  factory CacheConfig.networkFirst({int pageSize = 20}) {
    return CacheConfig(
      strategy: ListCacheStrategy.networkFirst,
      staleDuration: const Duration(hours: 1),
      pageSize: pageSize,
    );
  }

  /// 快捷构造：仅网络，无缓存
  factory CacheConfig.networkOnly({int pageSize = 20}) {
    return CacheConfig(
      strategy: ListCacheStrategy.networkOnly,
      pageSize: pageSize,
    );
  }
}