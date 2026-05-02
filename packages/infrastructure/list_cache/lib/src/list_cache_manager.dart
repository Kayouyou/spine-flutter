import 'package:hive/hive.dart';
import 'cache_strategy.dart';
import 'cache_config.dart';
import 'cache_result.dart';

/// 通用列表缓存管理器
///
/// 泛型 T — 列表中存储的数据类型。
/// 每个列表用 [cacheKey] 隔离，不同 key 的缓存互不影响。
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

  /// 生成缓存键格式
  String _pageKey(String cacheKey, int page) =>
      '${_boxPrefix}_${cacheKey}_p$page';

  /// 生成分页元数据键
  String _metaKey(String cacheKey) => '${_boxPrefix}_${cacheKey}_meta';

  /// 获取或打开 Box
  Future<Box> _getBox(String boxName) async {
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
  Future<List<T>> _readPage(String cacheKey, int page) async {
    final key = _pageKey(cacheKey, page);
    final box = await _getBox(key);
    final dynamic raw = box.get('data');
    if (raw == null) return [];
    if (raw is List) {
      return raw.cast<T>();
    }
    return [];
  }

  /// 写入一页缓存
  Future<void> _writePage(String cacheKey, int page, List<T> data) async {
    final key = _pageKey(cacheKey, page);
    final box = await _getBox(key);
    await box.put('data', data);

    // page=1 时清空后续页缓存（防止新旧数据混合）
    if (page == 1) {
      await _clearSubsequentPages(cacheKey);
    }
  }

  /// page=1 时清空后续页的缓存
  Future<void> _clearSubsequentPages(String cacheKey) async {
    for (int p = 2; p <= _config.maxCachedPages; p++) {
      final key = _pageKey(cacheKey, p);
      try {
        final box = await _getBox(key);
        await box.delete('data');
      } catch (_) {}
    }
  }

  /// 清空某个列表的所有缓存
  Future<void> clear(String cacheKey) async {
    for (int p = 1; p <= _config.maxCachedPages; p++) {
      final key = _pageKey(cacheKey, p);
      try {
        final box = await _getBox(key);
        await box.clear();
        _openedBoxes.remove(key);
      } catch (_) {}
    }
    // 清空元数据
    try {
      final metaBox = await _getBox(_metaKey(cacheKey));
      await metaBox.clear();
      _openedBoxes.remove(_metaKey(cacheKey));
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