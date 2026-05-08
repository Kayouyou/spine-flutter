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
        ['item1', 'item2'],
        hasMore: false,
      );
      
      expect(cacheResult.isFromCache, isTrue);
      expect(cacheResult.data, equals(['item1', 'item2']));
      expect(cacheResult.hasMore, isFalse);
      
      // Test network result
      final networkResult = CacheResult<String>.fromNetwork(
        ['item3', 'item4'],
        hasMore: true,
        totalCount: 100,
      );
      
      expect(networkResult.isFromCache, isFalse);
      expect(networkResult.data, equals(['item3', 'item4']));
      expect(networkResult.hasMore, isTrue);
      expect(networkResult.totalCount, equals(100));
    });

    test('default constructor creates network result', () {
      final result = CacheResult<int>(
        data: [1, 2, 3],
        isFromCache: false,
        hasMore: true,
      );
      
      expect(result.isFromCache, isFalse);
      expect(result.data, equals([1, 2, 3]));
      expect(result.hasMore, isTrue);
      expect(result.totalCount, isNull);
    });

    test('supports equality via Equatable', () {
      final result1 = CacheResult<String>.fromCache(['a', 'b']);
      final result2 = CacheResult<String>.fromCache(['a', 'b']);
      final result3 = CacheResult<String>.fromNetwork(['a', 'b']);
      
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
}