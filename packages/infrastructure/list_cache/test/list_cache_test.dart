import 'package:hive/hive.dart';
import 'package:list_cache/list_cache.dart';
import 'package:test/test.dart';

void main() {
  group('CacheConfig', () {
    test('creates with defaults', () {
      const config = CacheConfig();

      expect(config.strategy, equals(ListCacheStrategy.cacheFirst));
      expect(config.staleDuration, isNull);
      expect(config.pageSize, equals(20));
      expect(config.maxCachedPages, equals(10));
    });

    test('staleWhileRevalidate creates correctly', () {
      final config = CacheConfig.staleWhileRevalidate(pageSize: 30);

      expect(config.strategy, equals(ListCacheStrategy.cacheFirst));
      expect(config.staleDuration, equals(const Duration(minutes: 5)));
      expect(config.pageSize, equals(30));
    });

    test('networkFirst creates correctly', () {
      final config = CacheConfig.networkFirst(pageSize: 50);

      expect(config.strategy, equals(ListCacheStrategy.networkFirst));
      expect(config.staleDuration, equals(const Duration(hours: 1)));
      expect(config.pageSize, equals(50));
    });

    test('networkOnly creates correctly', () {
      final config = CacheConfig.networkOnly();

      expect(config.strategy, equals(ListCacheStrategy.networkOnly));
      expect(config.staleDuration, isNull);
    });
  });

  group('CacheResult', () {
    test('has isFromCache/isFromNetwork flags', () {
      // Test cache result
      final cacheResult = CacheResult<String>.fromCache(
        const ['item1', 'item2'],
        hasMore: false,
      );

      expect(cacheResult.isFromCache, isTrue);
      expect(cacheResult.data, equals(['item1', 'item2']));
      expect(cacheResult.hasMore, isFalse);

      // Test network result
      final networkResult = CacheResult<String>.fromNetwork(
        const ['item3', 'item4'],
        totalCount: 100,
      );

      expect(networkResult.isFromCache, isFalse);
      expect(networkResult.data, equals(['item3', 'item4']));
      expect(networkResult.hasMore, isTrue);
      expect(networkResult.totalCount, equals(100));
    });

    test('default constructor creates network result', () {
      const result = CacheResult<int>(
        data: [1, 2, 3],
      );

      expect(result.isFromCache, isFalse);
      expect(result.data, equals([1, 2, 3]));
      expect(result.hasMore, isTrue);
      expect(result.totalCount, isNull);
    });

    test('supports equality via Equatable', () {
      final result1 = CacheResult<String>.fromCache(const ['a', 'b']);
      final result2 = CacheResult<String>.fromCache(const ['a', 'b']);
      final result3 = CacheResult<String>.fromNetwork(const ['a', 'b']);

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });
  });

  group('ListCacheStrategy', () {
    test('contains all four strategies', () {
      expect(
        ListCacheStrategy.values,
        containsAll([
          ListCacheStrategy.cacheFirst,
          ListCacheStrategy.networkFirst,
          ListCacheStrategy.cacheOnly,
          ListCacheStrategy.networkOnly,
        ]),
      );
    });
  });

  group('ListCacheManager 单 box 多 key 结构', () {
    late ListCacheManager<String> cacheManager;

    setUp(() async {
      // 初始化 Hive 使用内存目录
      Hive.init('/tmp/hive_test_${DateTime.now().millisecondsSinceEpoch}');
      // 使用 networkFirst 策略避免后台刷新干扰测试
      cacheManager = ListCacheManager<String>(
        config: CacheConfig.networkFirst(),
      );
    });

    tearDown(() async {
      await cacheManager.closeAll();
      // 清理已知的测试 box
      final boxNames = ['list_cache_test_list', 'list_cache_home_feed'];
      for (final boxName in boxNames) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
        } catch (_) {}
      }
    });

    test('一个 cacheKey 只开一个 box', () async {
      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['item1', 'item2'],
      );

      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 2,
        networkFetcher: () async => ['item3', 'item4'],
      );

      // 验证：box 是打开的
      expect(Hive.isBoxOpen('list_cache_test_list'), isTrue);
    });

    test('多个 page 存储在同一个 box 内', () async {
      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['page1_item1'],
      );

      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 2,
        networkFetcher: () async => ['page2_item1'],
      );

      // 验证：box 内有 p1 和 p2 两个 key
      final box = await Hive.openBox('list_cache_test_list');
      expect(box.get('p1'), isNotNull);
      expect(box.get('p2'), isNotNull);
      expect((box.get('p1') as List).first, 'page1_item1');
      expect((box.get('p2') as List).first, 'page2_item1');
    });

    test('page=1 写入时清空后续页', () async {
      // 先写入 page 1 和 page 2
      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['old_item1'],
      );
      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 2,
        networkFetcher: () async => ['old_item2'],
      );

      // 重新写入 page 1（模拟下拉刷新）
      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['new_item1'],
      );

      // 验证：page 2 的缓存被清空
      final box = await Hive.openBox('list_cache_test_list');
      expect(box.get('p1'), isNotNull);
      expect(box.get('p2'), isNull); // page 2 被清空
    });

    test('clear(cacheKey) 删除整个 box', () async {
      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['item1'],
      );

      await cacheManager.clear('test_list');

      // 验证：box 已被删除
      expect(await Hive.boxExists('list_cache_test_list'), isFalse);
    });
  });

  group('staleDuration 缓存过期', () {
    late ListCacheManager<String> cacheManager;

    setUp(() async {
      Hive.init('/tmp/hive_test_${DateTime.now().millisecondsSinceEpoch}');
    });

    tearDown(() async {
      // 等待后台任务完成（cacheFirst 策略会触发后台刷新）
      await Future.delayed(const Duration(milliseconds: 200));
      await cacheManager.closeAll();
      final boxNames = ['list_cache_test_list', 'list_cache_home_feed'];
      for (final boxName in boxNames) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
        } catch (_) {}
      }
    });

    test('未配置 staleDuration 时缓存永不过期', () async {
      cacheManager = ListCacheManager<String>(
        config: const CacheConfig(), // 默认配置，永不过期
      );

      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['item1'],
      );

      // 等待一段时间（模拟缓存已存在）
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证：缓存仍然有效
      final result = await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['new_item1'],
      );

      expect(result.isFromCache, isTrue);
      expect(result.data, ['item1']);
    });

    test('配置 staleDuration 后缓存过期返回空列表', () async {
      cacheManager = ListCacheManager<String>(
        config: const CacheConfig(
          staleDuration: Duration(milliseconds: 50), // 50ms 过期
        ),
      );

      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['old_item1'],
      );

      // 等待缓存过期
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证：缓存已过期，触发重新拉取
      final result = await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['new_item1'],
      );

      expect(result.isFromCache, isFalse);
      expect(result.data, ['new_item1']);
    });

    test('写入时间戳正确存储', () async {
      cacheManager = ListCacheManager<String>(
        config: CacheConfig.staleWhileRevalidate(),
      );

      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['item1'],
      );

      // 验证：box 内有时间戳
      final box = await Hive.openBox('list_cache_test_list');
      final timestamp = box.get('t1');
      expect(timestamp, isNotNull);
      expect(timestamp, isA<int>());

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      final age = DateTime.now().difference(cachedAt);
      expect(age.inSeconds, lessThan(5)); // 应该在 5 秒内
    });

    test('缓存未过期时正常返回数据', () async {
      cacheManager = ListCacheManager<String>(
        config: const CacheConfig(
          staleDuration: Duration(minutes: 5), // 5 分钟过期
        ),
      );

      await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['item1'],
      );

      // 立即读取（缓存未过期）
      final result = await cacheManager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['new_item1'],
      );

      expect(result.isFromCache, isTrue);
      expect(result.data, ['item1']);
    });
  });
}
