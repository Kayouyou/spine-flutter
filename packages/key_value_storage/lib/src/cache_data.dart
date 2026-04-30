import 'package:hive/hive.dart';

part 'cache_data.g.dart';

/// 缓存数据包装类
///
/// 职责：为数据添加过期时间，支持TTL机制
/// Hive Adapter：需要生成CacheDataAdapter
@HiveType(typeId: 0)
class CacheData<T> {
  @HiveField(0)
  final T value;

  @HiveField(1)
  final DateTime expireAt;

  CacheData(this.value, {Duration? ttl})
    : expireAt = DateTime.now().add(ttl ?? const Duration(hours: 24));

  bool get isExpired => DateTime.now().isAfter(expireAt);

  Duration get remainingTime {
    final remaining = expireAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpiringSoon({Duration threshold = const Duration(minutes: 5)}) {
    return remainingTime <= threshold;
  }
}