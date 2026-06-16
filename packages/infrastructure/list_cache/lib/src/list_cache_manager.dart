import 'package:hive/hive.dart';
import 'cache_strategy.dart';
import 'cache_config.dart';
import 'cache_result.dart';

/// 通用列表缓存管理器
///
/// 泛型 T — 列表中存储的数据类型。
/// 每个列表用 [cacheKey] 隔离，不同 key 的缓存互不影响。
///
/// 设计：每个 cacheKey 对应一个独立的 Hive box，page 数据以 'p1'/'p2'/...
/// 为内部 key 存储，避免为每一页单独开 box 导致文件句柄耗尽。
///
/// 使用方式：
/// ```dart
/// final cacheManager = ListCacheManager<FeedItem>(
///   config: CacheConfig.staleWhileRevalidate(),
/// );
///
/// final result = await cacheManager.fetch(
///   cacheKey: 'home_feed',
///   page: 1,
///   networkFetcher: () => api.fetchHomeFeed(page: 1),
/// );
/// ```
class ListCacheManager<T> {
  final CacheConfig _config;
  final String _boxPrefix;

  /// 已打开的 Box 缓存（避免重复打开）
  final Map<String, Box> _openedBoxes = {};

  ListCacheManager({
    required CacheConfig config,
    String boxPrefix = 'list_cache',
  })  : _config = config,
        _boxPrefix = boxPrefix;

  /// 生成 box 名称
  ///
  /// 每个 cacheKey 对应一个独立的 Hive box，box 内部以 page 编号为 key 存储数据。
  /// 例如：cacheKey='home_feed' → box 名='list_cache_home_feed'
  String _boxName(String cacheKey) => '${_boxPrefix}_$cacheKey';

  /// 获取或打开 Box
  ///
  /// [cacheKey] — 列表唯一标识，决定 box 名称
  /// 每个 cacheKey 只开一个 box，内部存储多页数据。
  Future<Box> _getBox(String cacheKey) async {
    final boxName = _boxName(cacheKey);
    if (_openedBoxes.containsKey(boxName)) {
      return _openedBoxes[boxName]!;
    }
    final box = await Hive.openBox(boxName);
    _openedBoxes[boxName] = box;
    return box;
  }

  /// 核心方法：获取列表数据
  ///
  /// [cacheKey] — 唯一标识这个列表（如 'home_feed'、'user_posts_123'）
  /// [page] — 当前页码，1-based
  /// [networkFetcher] — 网络请求函数，返回本页数据
  Future<CacheResult<T>> fetch({
    required String cacheKey,
    required int page,
    required Future<List<T>> Function() networkFetcher,
  }) async {
    return switch (_config.strategy) {
      ListCacheStrategy.cacheFirst =>
        _cacheFirst(cacheKey, page, networkFetcher),
      ListCacheStrategy.networkFirst =>
        _networkFirst(cacheKey, page, networkFetcher),
      ListCacheStrategy.cacheOnly => _cacheOnly(cacheKey, page),
      ListCacheStrategy.networkOnly => _networkOnly(networkFetcher),
    };
  }

  /// 策略：先缓存后网络
  Future<CacheResult<T>> _cacheFirst(
    String cacheKey,
    int page,
    Future<List<T>> Function() networkFetcher,
  ) async {
    // 1. 先读缓存，立刻返回
    List<T> cachedData = [];
    try {
      cachedData = await _readPage(cacheKey, page);
    } catch (_) {}

    // 2. 如果缓存非空，先返回缓存数据
    if (cachedData.isNotEmpty) {
      // 后台刷新网络（不 await）
      _refreshInBackground(cacheKey, page, networkFetcher);
      return CacheResult.fromCache(cachedData);
    }

    // 3. 缓存为空，等待网络
    try {
      final networkData = await networkFetcher();
      await _writePage(cacheKey, page, networkData);
      return CacheResult.fromNetwork(networkData);
    } catch (_) {
      return const CacheResult(data: [], isFromCache: true);
    }
  }

  /// 策略：先网络后缓存
  Future<CacheResult<T>> _networkFirst(
    String cacheKey,
    int page,
    Future<List<T>> Function() networkFetcher,
  ) async {
    try {
      final networkData = await networkFetcher();
      await _writePage(cacheKey, page, networkData);
      return CacheResult.fromNetwork(networkData);
    } catch (_) {
      // 网络失败，尝试缓存兜底
      try {
        final cachedData = await _readPage(cacheKey, page);
        if (cachedData.isNotEmpty) {
          return CacheResult.fromCache(cachedData);
        }
      } catch (_) {}
      rethrow; // 缓存也失败了，向上抛
    }
  }

  /// 策略：仅缓存
  Future<CacheResult<T>> _cacheOnly(String cacheKey, int page) async {
    try {
      final cachedData = await _readPage(cacheKey, page);
      return CacheResult.fromCache(cachedData);
    } catch (_) {
      return const CacheResult(data: [], isFromCache: true);
    }
  }

  /// 策略：仅网络
  Future<CacheResult<T>> _networkOnly(
    Future<List<T>> Function() networkFetcher,
  ) async {
    final networkData = await networkFetcher();
    return CacheResult.fromNetwork(networkData);
  }

  /// 后台刷新（不等待）
  void _refreshInBackground(
    String cacheKey,
    int page,
    Future<List<T>> Function() networkFetcher,
  ) {
    networkFetcher().then((data) {
      _writePage(cacheKey, page, data);
    }).catchError((_) {
      // 后台刷新失败不报错，用户已经看到缓存数据
    });
  }

  /// 读取一页缓存
  ///
  /// 从 cacheKey 对应的 box 中，以 'p$page' 为 key 读取该页数据。
  /// 如果配置了 staleDuration 且缓存已过期，返回空列表（触发网络重新获取）。
  Future<List<T>> _readPage(String cacheKey, int page) async {
    // 检查缓存是否过期
    if (await _isStale(cacheKey, page)) {
      await _deletePage(cacheKey, page);
      return [];
    }

    final box = await _getBox(cacheKey);
    final dynamic raw = box.get('p$page');
    if (raw == null) return [];
    if (raw is List) {
      return raw.cast<T>();
    }
    return [];
  }

  /// 写入一页缓存
  ///
  /// 将数据写入 cacheKey 对应的 box，以 'p$page' 为内部 key。
  /// 同时写入时间戳 't$page' 用于缓存过期判断。
  Future<void> _writePage(String cacheKey, int page, List<T> data) async {
    final box = await _getBox(cacheKey);
    await box.put('p$page', data);
    await box.put('t$page', DateTime.now().millisecondsSinceEpoch);

    // page=1 时清空后续页缓存（防止新旧数据混合）
    if (page == 1) {
      await _clearSubsequentPages(cacheKey);
    }
  }

  /// page=1 时清空后续页的缓存
  ///
  /// 在同一个 box 内，逐个删除 'p2'、'p3'... 等内部 key 和对应的 't2'、't3'... 时间戳。
  Future<void> _clearSubsequentPages(String cacheKey) async {
    try {
      final box = await _getBox(cacheKey);
      for (int p = 2; p <= _config.maxCachedPages; p++) {
        await box.delete('p$p');
        await box.delete('t$p');
      }
    } catch (_) {}
  }

  /// 删除指定页的缓存数据和时间戳
  Future<void> _deletePage(String cacheKey, int page) async {
    try {
      final box = await _getBox(cacheKey);
      await box.delete('p$page');
      await box.delete('t$page');
    } catch (_) {}
  }

  /// 检查缓存是否过期
  ///
  /// 如果配置了 staleDuration，比较当前时间与缓存时间戳。
  /// 返回 true 表示缓存已过期，需要重新从网络获取。
  Future<bool> _isStale(String cacheKey, int page) async {
    if (_config.staleDuration == null) return false;

    final box = await _getBox(cacheKey);
    final dynamic timestamp = box.get('t$page');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final age = DateTime.now().difference(cacheTime);
    return age > _config.staleDuration!;
  }

  /// 清空某个列表的所有缓存
  ///
  /// 删除 cacheKey 对应的整个 box（从磁盘删除）。
  Future<void> clear(String cacheKey) async {
    final boxName = _boxName(cacheKey);
    try {
      // 关闭 box（如果已打开）
      if (_openedBoxes.containsKey(boxName)) {
        final box = _openedBoxes.remove(boxName)!;
        await box.close();
      }
      // 从磁盘删除 box
      await Hive.deleteBoxFromDisk(boxName);
    } catch (_) {}
  }

  /// 清空所有列表缓存（慎用）
  ///
  /// 注意：此方法会清空所有以 _boxPrefix 开头的已打开 Box
  Future<void> clearAll() async {
    // 清空所有已打开且以 _boxPrefix 开头的 Box
    final keysToRemove = _openedBoxes.keys
        .where((name) => name.startsWith(_boxPrefix))
        .toList();

    for (final key in keysToRemove) {
      try {
        final box = _openedBoxes[key]!;
        await box.clear();
        _openedBoxes.remove(key);
      } catch (_) {}
    }
  }

  /// 关闭所有已打开的 Box（资源释放）
  Future<void> closeAll() async {
    for (final box in _openedBoxes.values) {
      try {
        await box.close();
      } catch (_) {}
    }
    _openedBoxes.clear();
  }
}