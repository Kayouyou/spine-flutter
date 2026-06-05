import 'package:equatable/equatable.dart';

/// 缓存操作结果
///
/// 告诉调用方数据的来源和缓存状态，Cubit 据此决定 UI 表现。
class CacheResult<T> extends Equatable {
  /// 数据（可能来自缓存或网络）
  final List<T> data;

  /// 数据来源
  final bool isFromCache;

  /// 是否有更多页
  final bool hasMore;

  /// 总条目数（如果 API 返回）
  final int? totalCount;

  const CacheResult({
    required this.data,
    this.isFromCache = false,
    this.hasMore = true,
    this.totalCount,
  });

  /// 创建缓存结果
  factory CacheResult.fromCache(List<T> data, {bool hasMore = true}) {
    return CacheResult(data: data, isFromCache: true, hasMore: hasMore);
  }

  /// 创建网络结果
  factory CacheResult.fromNetwork(
    List<T> data,
    {bool hasMore = true, int? totalCount,}
  ) {
    return CacheResult(
      data: data,
      hasMore: hasMore,
      totalCount: totalCount,
    );
  }

  @override
  List<Object?> get props => [data, isFromCache, hasMore, totalCount];
}