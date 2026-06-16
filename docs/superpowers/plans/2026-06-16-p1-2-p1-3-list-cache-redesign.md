# P1-2 + P1-3: list_cache 单 box 多 key 重构 + staleDuration 实现

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构 list_cache 存储结构，从"每页一个 Hive box"改为"每个 cacheKey 一个 box + page 作为内部 key"，同时实现 staleDuration 缓存过期机制。

**Architecture:** 单 box 多 key 模式 — 每个 cacheKey 只开一个 Hive box，page 数据以 `p1`/`p2`/... 为 key 存储在 box 内，时间戳以 `ts1`/`ts2`/... 为 key 存储。staleDuration 在读取时通过比较时间戳判断是否过期。

**Tech Stack:** Dart, Hive 2.x, mocktail (testing), bloc_test (testing)

**Spec:** `docs/superpowers/specs/2026-06-16-p1-2-p1-3-list-cache-redesign.md` (待补充)

---

## File Structure

### Files to Modify
- `packages/infrastructure/list_cache/lib/src/list_cache_manager.dart` — 核心重构：box 结构、读写方法、staleDuration 实现
- `packages/infrastructure/list_cache/lib/src/cache_config.dart` — 添加 staleDuration 注释
- `packages/infrastructure/list_cache/test/list_cache_test.dart` — 添加单 box 多 key 和 staleDuration 测试
- `packages/infrastructure/list_cache/README.md` — 更新缓存 Key 规范和内部结构说明

### Files to Create (none — 无新文件)

---

## Task 1: 单 box 多 key 重构 — _boxName 和 _getBox

**Files:**
- Modify: `packages/infrastructure/list_cache/lib/src/list_cache_manager.dart:37-51`
- Test: `packages/infrastructure/list_cache/test/list_cache_test.dart`

### 背景

当前设计：每个 page 开一个独立 Hive box（`list_cache_home_feed_p1`），导致 50 页 = 50 个 box，有文件句柄耗尽风险。

新设计：每个 cacheKey 只开一个 box（`list_cache_home_feed`），page 数据以 `p1`/`p2`/... 为内部 key。

### 改动说明

1. 删除 `_pageKey` 方法
2. 新增 `_boxName` 方法
3. 修改 `_getBox` 方法接受 cacheKey 而非 boxName

### 代码

```dart
// list_cache_manager.dart

// 删除:
// String _pageKey(String cacheKey, int page) =>
//     '${_boxPrefix}_${cacheKey}_p$page';

// 新增:
/// 生成 box 名称
///
/// 每个 cacheKey 对应一个独立的 Hive box，box 内部以 page 编号为 key 存储数据。
/// 例如：cacheKey='home_feed' → box 名='list_cache_home_feed'
String _boxName(String cacheKey) => '${_boxPrefix}_$cacheKey';

// 修改 _getBox:
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
```

### 测试

```dart
// list_cache_test.dart
group('单 box 多 key 结构', () {
  test('_boxName 生成正确的 box 名称', () {
    // 验证：一个 cacheKey 只对应一个 box 名
    // box 名格式：'{prefix}_{cacheKey}'
    // 例如：list_cache_home_feed
  });
});
```

### 提交

```bash
git add packages/infrastructure/list_cache/lib/src/list_cache_manager.dart
git commit -m "refactor(list_cache): 单 box 多 key 结构 — _boxName 和 _getBox

- 删除 _pageKey 方法
- 新增 _boxName 方法：每个 cacheKey 对应一个 box
- 修改 _getBox：接受 cacheKey 而非 boxName
- 为 _getBox 添加详细注释"
```

---

## Task 2: 单 box 多 key 重构 — _readPage 和 _writePage

**Files:**
- Modify: `packages/infrastructure/list_cache/lib/src/list_cache_manager.dart:155-177`

### 改动说明

1. `_readPage`：从 cacheKey box 读取 `p{page}` key
2. `_writePage`：写入 `p{page}` key，同时写入 `ts{page}` 时间戳（为 staleDuration 预留）

### 代码

```dart
// list_cache_manager.dart

/// 读取一页缓存
///
/// 从 cacheKey 对应的 box 中读取 key='p{page}' 的数据。
/// 返回空列表如果数据不存在或类型不匹配。
Future<List<T>> _readPage(String cacheKey, int page) async {
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
/// 将数据写入 cacheKey 对应的 box，key='p{page}'。
/// 同时写入时间戳 key='ts{page}'，用于 staleDuration 过期判断。
///
/// 当 page=1 时，自动清空后续页的缓存（防止新旧数据混合）。
Future<void> _writePage(String cacheKey, int page, List<T> data) async {
  final box = await _getBox(cacheKey);
  await box.put('p$page', data);
  await box.put('ts$page', DateTime.now().millisecondsSinceEpoch);

  // page=1 时清空后续页缓存（防止新旧数据混合）
  if (page == 1) {
    await _clearSubsequentPages(cacheKey);
  }
}
```

### 提交

```bash
git add packages/infrastructure/list_cache/lib/src/list_cache_manager.dart
git commit -m "refactor(list_cache): 单 box 多 key — _readPage 和 _writePage

- _readPage: 从 box 读取 'p{page}' key
- _writePage: 写入 'p{page}' 和 'ts{page}' 时间戳
- 为两个方法添加详细注释"
```

---

## Task 3: 单 box 多 key 重构 — _clearSubsequentPages

**Files:**
- Modify: `packages/infrastructure/list_cache/lib/src/list_cache_manager.dart:179-188`

### 改动说明

从"遍历多个 box"改为"清空单个 box 内的多个 key"。

### 代码

```dart
// list_cache_manager.dart

/// page=1 时清空后续页的缓存
///
/// 在同一个 box 内删除 key='p{2..maxCachedPages}' 和 'ts{2..maxCachedPages}'。
/// 防止新旧数据混合（下拉刷新时 page=1 重新拉取，后续页需要重新加载）。
Future<void> _clearSubsequentPages(String cacheKey) async {
  final box = await _getBox(cacheKey);
  for (int p = 2; p <= _config.maxCachedPages; p++) {
    try {
      await box.delete('p$p');
      await box.delete('ts$p');
    } catch (_) {}
  }
}
```

### 提交

```bash
git add packages/infrastructure/list_cache/lib/src/list_cache_manager.dart
git commit -m "refactor(list_cache): 单 box 多 key — _clearSubsequentPages

- 从遍历多个 box 改为清空单个 box 内的多个 key
- 同时删除 'p{page}' 和 'ts{page}' 时间戳
- 添加详细注释"
```

---

## Task 4: 单 box 多 key 重构 — clear 和 clearAll

**Files:**
- Modify: `packages/infrastructure/list_cache/lib/src/list_cache_manager.dart:190-224`

### 改动说明

1. `clear(cacheKey)`：直接删除整个 box（`deleteFromDisk`）
2. `clearAll()`：删除所有以 `_boxPrefix` 开头的 box
3. 删除 `_metaKey` 方法（不再需要）

### 代码

```dart
// list_cache_manager.dart

// 删除:
// String _metaKey(String cacheKey) => '${_boxPrefix}_${cacheKey}_meta';

/// 清空某个列表的所有缓存
///
/// 直接删除 cacheKey 对应的整个 box（包括文件）。
/// 这是最彻底的清理方式，下次访问会重新创建 box。
Future<void> clear(String cacheKey) async {
  final boxName = _boxName(cacheKey);
  try {
    final box = _openedBoxes.remove(boxName);
    if (box != null) {
      await box.deleteFromDisk();
    }
  } catch (_) {}
}

/// 清空所有列表缓存（慎用）
///
/// 删除所有以 _boxPrefix 开头的 box（包括文件）。
/// 典型用途：用户登出时清空所有缓存数据。
Future<void> clearAll() async {
  final keysToRemove = _openedBoxes.keys
      .where((name) => name.startsWith(_boxPrefix))
      .toList();

  for (final key in keysToRemove) {
    try {
      final box = _openedBoxes[key]!;
      await box.deleteFromDisk();
    } catch (_) {}
  }
  _openedBoxes.removeWhere((k, _) => k.startsWith(_boxPrefix));
}
```

### 提交

```bash
git add packages/infrastructure/list_cache/lib/src/list_cache_manager.dart
git commit -m "refactor(list_cache): 单 box 多 key — clear 和 clearAll

- clear(cacheKey): 直接删除整个 box (deleteFromDisk)
- clearAll(): 删除所有以 _boxPrefix 开头的 box
- 删除不再需要的 _metaKey 方法
- 为两个方法添加详细注释"
```

---

## Task 5: staleDuration 实现 — _isStale 和 _readPage 集成

**Files:**
- Modify: `packages/infrastructure/list_cache/lib/src/list_cache_manager.dart` (新增方法 + 修改 _readPage)

### 背景

`staleDuration` 参数定义了但从未使用。现在单 box 多 key 结构已就位，可以在 box 内存储时间戳，实现真正的缓存过期。

### 改动说明

1. 新增 `_isStale` 方法：检查指定 page 的缓存是否过期
2. 修改 `_readPage`：如果缓存过期，返回空列表（触发重新拉取）

### 代码

```dart
// list_cache_manager.dart

/// 检查指定 page 的缓存是否过期
///
/// 通过比较 box 内存储的时间戳 'ts{page}' 和当前时间，
/// 判断是否超过 [_config.staleDuration]。
///
/// 返回：
/// - `true` — 缓存已过期，应该重新拉取
/// - `false` — 缓存有效，或者没有配置 staleDuration，或者没有缓存
Future<bool> _isStale(String cacheKey, int page) async {
  final staleDuration = _config.staleDuration;
  if (staleDuration == null) return false; // 未配置过期时间

  final box = await _getBox(cacheKey);
  final timestamp = box.get('ts$page');
  if (timestamp == null) return false; // 没有缓存

  final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
  final age = DateTime.now().difference(cachedAt);
  return age > staleDuration;
}

// 修改 _readPage:
/// 读取一页缓存
///
/// 从 cacheKey 对应的 box 中读取 key='p{page}' 的数据。
/// 如果配置了 staleDuration 且缓存已过期，返回空列表。
/// 返回空列表如果数据不存在或类型不匹配。
Future<List<T>> _readPage(String cacheKey, int page) async {
  // 检查缓存是否过期
  if (await _isStale(cacheKey, page)) {
    return []; // 缓存过期，触发重新拉取
  }

  final box = await _getBox(cacheKey);
  final dynamic raw = box.get('p$page');
  if (raw == null) return [];
  if (raw is List) {
    return raw.cast<T>();
  }
  return [];
}
```

### 提交

```bash
git add packages/infrastructure/list_cache/lib/src/list_cache_manager.dart
git commit -m "feat(list_cache): 实现 staleDuration 缓存过期机制

- 新增 _isStale 方法：检查缓存是否超过 staleDuration
- 修改 _readPage：缓存过期时返回空列表
- 在 _writePage 中已存储时间戳 'ts{page}'
- 为 _isStale 添加详细注释"
```

---

## Task 6: 数据迁移 — migrateFromV1 方法

**Files:**
- Modify: `packages/infrastructure/list_cache/lib/src/list_cache_manager.dart` (新增方法)

### 背景

旧版本每个 page 一个 box（`list_cache_home_feed_p1`），新版本每个 cacheKey 一个 box（`list_cache_home_feed`）。需要提供迁移方法清理旧格式 box。

### 改动说明

新增 `migrateFromV1` 方法：扫描所有 Hive box，删除旧格式的 box（匹配 `*_p\d+$` 正则）。

### 代码

```dart
// list_cache_manager.dart

/// 迁移：清理旧版本 box（每页一个 box 的格式）
///
/// 旧版本（v1）每个 page 开一个独立 box：
///   - list_cache_home_feed_p1
///   - list_cache_home_feed_p2
///   - ...
///
/// 新版本（v2）每个 cacheKey 一个 box，page 作为内部 key：
///   - list_cache_home_feed (内部: p1, p2, ...)
///
/// 此方法会删除所有旧格式的 box。首次升级时调用一次即可。
/// 调用方式：
/// ```dart
/// final cacheManager = ListCacheManager<String>(config: config);
/// await cacheManager.migrateFromV1();
/// ```
Future<void> migrateFromV1() async {
  final allBoxNames = Hive.boxNames();
  final oldFormatPattern = RegExp(r'^${_boxPrefix}_.*_p\d+$');
  
  for (final boxName in allBoxNames) {
    if (oldFormatPattern.hasMatch(boxName)) {
      try {
        final box = await Hive.openBox(boxName);
        await box.deleteFromDisk();
      } catch (_) {}
    }
  }
}
```

### 提交

```bash
git add packages/infrastructure/list_cache/lib/src/list_cache_manager.dart
git commit -m "feat(list_cache): 添加 migrateFromV1 数据迁移方法

- 扫描所有 Hive box，删除旧格式 (每页一个 box)
- 正则匹配: ^{prefix}_.*_p\d+$
- 首次升级时调用一次即可
- 添加详细注释说明迁移逻辑"
```

---

## Task 7: 单元测试 — 单 box 多 key 结构

**Files:**
- Modify: `packages/infrastructure/list_cache/test/list_cache_test.dart`

### 背景

现有测试只覆盖 CacheConfig、CacheResult、ListCacheStrategy，没有测试 ListCacheManager 的核心行为。需要添加单 box 多 key 结构的测试。

### 测试用例

1. 一个 cacheKey 只开一个 box
2. 多个 page 存储在同一个 box 内
3. 读写 page 数据正确
4. page=1 写入时清空后续页
5. clear(cacheKey) 删除整个 box
6. 50 个 page 只开 1 个 box（资源测试）

### 代码

```dart
// list_cache_test.dart
import 'package:hive/hive.dart';
import 'package:list_cache/list_cache.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    Hive.init('/tmp/hive_test_${DateTime.now().millisecondsSinceEpoch}');
  });

  tearDown(() async {
    await Hive.close();
    // 清理测试目录
  });

  group('ListCacheManager 单 box 多 key 结构', () {
    test('一个 cacheKey 只开一个 box', () async {
      final manager = ListCacheManager<String>(
        config: CacheConfig.staleWhileRevalidate(),
      );

      await manager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['item1', 'item2'],
      );

      await manager.fetch(
        cacheKey: 'test_list',
        page: 2,
        networkFetcher: () async => ['item3', 'item4'],
      );

      // 验证：Hive 中只有 1 个 box
      final boxNames = Hive.boxNames().where((n) => n.startsWith('list_cache_test_list'));
      expect(boxNames.length, 1);
      expect(boxNames.first, 'list_cache_test_list');
    });

    test('多个 page 存储在同一个 box 内', () async {
      final manager = ListCacheManager<String>(
        config: CacheConfig.staleWhileRevalidate(),
      );

      await manager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['page1_item1'],
      );

      await manager.fetch(
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
      final manager = ListCacheManager<String>(
        config: CacheConfig.staleWhileRevalidate(),
      );

      // 先写入 page 1 和 page 2
      await manager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['old_item1'],
      );
      await manager.fetch(
        cacheKey: 'test_list',
        page: 2,
        networkFetcher: () async => ['old_item2'],
      );

      // 重新写入 page 1（模拟下拉刷新）
      await manager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['new_item1'],
      );

      // 验证：page 2 的缓存被清空
      final box = await Hive.openBox('list_cache_test_list');
      expect(box.get('p1'), isNotNull);
      expect(box.get('p2'), isNull); // page 2 被清空
    });

    test('50 个 page 只开 1 个 box（资源测试）', () async {
      final manager = ListCacheManager<String>(
        config: CacheConfig.staleWhileRevalidate(),
      );

      for (int i = 1; i <= 50; i++) {
        await manager.fetch(
          cacheKey: 'test_list',
          page: i,
          networkFetcher: () async => ['item$i'],
        );
      }

      // 验证：只有 1 个 box 被打开
      final boxNames = Hive.boxNames().where((n) => n.startsWith('list_cache_test_list'));
      expect(boxNames.length, 1);
    });

    test('clear(cacheKey) 删除整个 box', () async {
      final manager = ListCacheManager<String>(
        config: CacheConfig.staleWhileRevalidate(),
      );

      await manager.fetch(
        cacheKey: 'test_list',
        page: 1,
        networkFetcher: () async => ['item1'],
      );

      await manager.clear('test_list');

      // 验证：box 已被删除
      final boxNames = Hive.boxNames().where((n) => n.startsWith('list_cache_test_list'));
      expect(boxNames.isEmpty, isTrue);
    });
  });
}
```

### 提交

```bash
git add packages/infrastructure/list_cache/test/list_cache_test.dart
git commit -m "test(list_cache): 添加单 box 多 key 结构测试

- 测试一个 cacheKey 只开一个 box
- 测试多个 page 存储在同一个 box 内
- 测试 page=1 写入时清空后续页
- 测试 50 个 page 只开 1 个 box（资源测试）
- 测试 clear(cacheKey) 删除整个 box"
```

---

## Task 8: 单元测试 — staleDuration 过期机制

**Files:**
- Modify: `packages/infrastructure/list_cache/test/list_cache_test.dart`

### 测试用例

1. 未配置 staleDuration 时缓存永不过期
2. 配置 staleDuration 后缓存过期返回空列表
3. 写入时间戳正确存储
4. 缓存未过期时正常返回数据

### 代码

```dart
// list_cache_test.dart

group('staleDuration 缓存过期', () {
  test('未配置 staleDuration 时缓存永不过期', () async {
    final manager = ListCacheManager<String>(
      config: const CacheConfig(
        strategy: ListCacheStrategy.cacheFirst,
        staleDuration: null, // 永不过期
      ),
    );

    await manager.fetch(
      cacheKey: 'test_list',
      page: 1,
      networkFetcher: () async => ['item1'],
    );

    // 等待一段时间（模拟缓存已存在）
    await Future.delayed(const Duration(milliseconds: 100));

    // 验证：缓存仍然有效
    final result = await manager.fetch(
      cacheKey: 'test_list',
      page: 1,
      networkFetcher: () async => ['new_item1'],
    );

    expect(result.isFromCache, isTrue);
    expect(result.data, ['item1']);
  });

  test('配置 staleDuration 后缓存过期返回空列表', () async {
    final manager = ListCacheManager<String>(
      config: const CacheConfig(
        strategy: ListCacheStrategy.cacheFirst,
        staleDuration: Duration(milliseconds: 50), // 50ms 过期
      ),
    );

    await manager.fetch(
      cacheKey: 'test_list',
      page: 1,
      networkFetcher: () async => ['old_item1'],
    );

    // 等待缓存过期
    await Future.delayed(const Duration(milliseconds: 100));

    // 验证：缓存已过期，触发重新拉取
    final result = await manager.fetch(
      cacheKey: 'test_list',
      page: 1,
      networkFetcher: () async => ['new_item1'],
    );

    expect(result.isFromCache, isFalse);
    expect(result.data, ['new_item1']);
  });

  test('写入时间戳正确存储', () async {
    final manager = ListCacheManager<String>(
      config: CacheConfig.staleWhileRevalidate(),
    );

    await manager.fetch(
      cacheKey: 'test_list',
      page: 1,
      networkFetcher: () async => ['item1'],
    );

    // 验证：box 内有时间戳
    final box = await Hive.openBox('list_cache_test_list');
    final timestamp = box.get('ts1');
    expect(timestamp, isNotNull);
    expect(timestamp, isA<int>());
    
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final age = DateTime.now().difference(cachedAt);
    expect(age.inSeconds, lessThan(5)); // 应该在 5 秒内
  });

  test('缓存未过期时正常返回数据', () async {
    final manager = ListCacheManager<String>(
      config: const CacheConfig(
        strategy: ListCacheStrategy.cacheFirst,
        staleDuration: Duration(minutes: 5), // 5 分钟过期
      ),
    );

    await manager.fetch(
      cacheKey: 'test_list',
      page: 1,
      networkFetcher: () async => ['item1'],
    );

    // 立即读取（缓存未过期）
    final result = await manager.fetch(
      cacheKey: 'test_list',
      page: 1,
      networkFetcher: () async => ['new_item1'],
    );

    expect(result.isFromCache, isTrue);
    expect(result.data, ['item1']);
  });
});
```

### 提交

```bash
git add packages/infrastructure/list_cache/test/list_cache_test.dart
git commit -m "test(list_cache): 添加 staleDuration 缓存过期测试

- 测试未配置 staleDuration 时缓存永不过期
- 测试配置 staleDuration 后缓存过期返回空列表
- 测试写入时间戳正确存储
- 测试缓存未过期时正常返回数据"
```

---

## Task 9: 单元测试 — 数据迁移 migrateFromV1

**Files:**
- Modify: `packages/infrastructure/list_cache/test/list_cache_test.dart`

### 测试用例

1. migrateFromV1 清理旧格式 box
2. 不影响新格式 box

### 代码

```dart
// list_cache_test.dart

group('数据迁移 migrateFromV1', () {
  test('清理旧格式 box（每页一个 box）', () async {
    // 模拟旧格式 box
    await Hive.openBox('list_cache_home_feed_p1');
    await Hive.openBox('list_cache_home_feed_p2');
    await Hive.openBox('list_cache_home_feed_p3');

    final manager = ListCacheManager<String>(
      config: CacheConfig.staleWhileRevalidate(),
    );

    await manager.migrateFromV1();

    // 验证：旧格式 box 已被删除
    final oldBoxes = Hive.boxNames().where((n) => n.contains('_p'));
    expect(oldBoxes.isEmpty, isTrue);
  });

  test('不影响新格式 box', () async {
    final manager = ListCacheManager<String>(
      config: CacheConfig.staleWhileRevalidate(),
    );

    // 创建新格式 box
    await manager.fetch(
      cacheKey: 'home_feed',
      page: 1,
      networkFetcher: () async => ['item1'],
    );

    // 运行迁移
    await manager.migrateFromV1();

    // 验证：新格式 box 仍然存在
    final newBoxes = Hive.boxNames().where((n) => n == 'list_cache_home_feed');
    expect(newBoxes.length, 1);
  });
});
```

### 提交

```bash
git add packages/infrastructure/list_cache/test/list_cache_test.dart
git commit -m "test(list_cache): 添加数据迁移 migrateFromV1 测试

- 测试清理旧格式 box（每页一个 box）
- 测试不影响新格式 box"
```

---

## Task 10: 更新 README.md 文档

**Files:**
- Modify: `packages/infrastructure/list_cache/README.md`

### 改动说明

1. 更新"内部结构"说明（单 box 多 key）
2. 更新"缓存 Key 规范"说明
3. 添加"缓存过期"说明
4. 添加"数据迁移"说明

### 代码

```markdown
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

## 存储结构

**单 box 多 key 模式**：每个 cacheKey 对应一个 Hive box，page 数据以 `p1`/`p2`/... 为内部 key。

```
cacheKey: 'home_feed'
  → box 名: 'list_cache_home_feed'
    → p1: [item1, item2, ..., item20]
    → p2: [item21, item22, ..., item40]
    → ts1: 1718500000000  (时间戳，用于过期判断)
    → ts2: 1718500005000
```

**资源安全**：一个 cacheKey 只开一个 box，即使浏览 50 页也只占 1 个 box。

## 缓存过期 (staleDuration)

`CacheConfig.staleWhileRevalidate()` 和 `CacheConfig.networkFirst()` 默认配置了 `staleDuration`：

- `staleWhileRevalidate`: 5 分钟过期
- `networkFirst`: 1 小时过期
- `networkOnly`: 无过期（不使用缓存）

缓存过期后，下次读取会触发重新拉取网络数据。

## 数据迁移 (v1 → v2)

旧版本（v1）每个 page 开一个独立 box，新版本（v2）每个 cacheKey 一个 box。首次升级时调用一次迁移方法：

```dart
final cacheManager = ListCacheManager<String>(config: config);
await cacheManager.migrateFromV1(); // 清理旧格式 box
```

迁移方法会扫描所有 Hive box，删除匹配 `*_p\d+$` 的旧格式 box。
```

### 提交

```bash
git add packages/infrastructure/list_cache/README.md
git commit -m "docs(list_cache): 更新 README — 单 box 多 key + staleDuration + 迁移

- 更新存储结构说明：单 box 多 key 模式
- 添加缓存过期 (staleDuration) 说明
- 添加数据迁移 (migrateFromV1) 说明
- 更新示例代码"
```

---

## Task 11: 运行全量测试 + 静态分析

### 步骤

1. 运行 list_cache 包测试
2. 运行 feature_home 测试（确保集成不受影响）
3. 运行静态分析

### 命令

```bash
# 运行 list_cache 测试
cd packages/infrastructure/list_cache
flutter test

# 运行 feature_home 测试（确保集成不受影响）
cd ../../features/feature_home
flutter test

# 运行静态分析
cd /Users/yeyangyang/Desktop/my_app
flutter analyze packages/infrastructure/list_cache
```

### 预期输出

```
✅ list_cache: 所有测试通过
✅ feature_home: 所有测试通过
✅ flutter analyze: 无错误
```

### 提交（如果有修复）

```bash
# 如果测试或分析发现问题，修复后提交
git add .
git commit -m "fix(list_cache): 修复测试/分析发现的问题

- [具体修复内容]"
```

---

## Task 12: 更新 CHANGELOG.md

**Files:**
- Modify: `packages/infrastructure/list_cache/CHANGELOG.md`

### 代码

```markdown
## 0.0.2

### Breaking Changes

- **重构存储结构**：从"每页一个 Hive box"改为"每个 cacheKey 一个 box"
  - 旧版本：`list_cache_home_feed_p1`、`list_cache_home_feed_p2` → 多个 box
  - 新版本：`list_cache_home_feed`（内部 key: `p1`、`p2`）→ 单个 box
  - 资源更安全：50 页列表只占 1 个 box（旧版本占 50 个）

### Features

- **实现 staleDuration 缓存过期机制**
  - `staleWhileRevalidate`: 5 分钟过期
  - `networkFirst`: 1 小时过期
  - 缓存过期后自动触发重新拉取

- **添加 migrateFromV1 数据迁移方法**
  - 清理旧格式 box（每页一个 box）
  - 首次升级时调用一次即可

### Documentation

- 更新 README.md：存储结构、缓存过期、数据迁移说明
```

### 提交

```bash
git add packages/infrastructure/list_cache/CHANGELOG.md
git commit -m "chore(list_cache): 更新 CHANGELOG — v0.0.2 重构 + staleDuration + 迁移"
```

---

## Task 13: 最终验证 + 提交

### 步骤

1. 运行 `melos test`（全量测试）
2. 运行 `melos analyze`（全量分析）
3. 检查 `./scripts/check_deps.sh`（依赖方向）

### 命令

```bash
cd /Users/yeyangyang/Desktop/my_app

# 全量测试
melos test

# 全量分析
melos analyze

# 依赖方向检查
./scripts/check_deps.sh
```

### 预期输出

```
✅ melos test: 所有测试通过
✅ melos analyze: 无错误
✅ check_deps.sh: R1/R3/R4 全部通过
```

### 最终提交（如果需要）

```bash
# 如果有任何修复，提交
git add .
git commit -m "chore: list_cache 重构完成 — 单 box 多 key + staleDuration

- 重构存储结构：每个 cacheKey 一个 box
- 实现 staleDuration 缓存过期
- 添加 migrateFromV1 数据迁移
- 更新文档和 CHANGELOG
- 所有测试通过，静态分析无错误"

# 推送到远程
git push origin feat/p1-2-p1-3-list-cache-redesign
```

---

## 完成标准

- [ ] 所有 13 个 Task 完成
- [ ] 单 box 多 key 重构完成
- [ ] staleDuration 缓存过期实现完成
- [ ] migrateFromV1 数据迁移方法完成
- [ ] 所有测试通过（list_cache + feature_home + 全量）
- [ ] 静态分析无错误
- [ ] 文档和注释更新完成
- [ ] CHANGELOG 更新

---

## 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|:---:|:---:|---------|
| 旧数据无法读取 | 高 | 低 | 提供 `migrateFromV1` 清理方法 |
| feature_home 集成失败 | 低 | 中 | Task 11 会验证，失败时修复 |
| 性能回退 | 低 | 中 | 单 box 读写性能 ≥ 多 box（减少文件句柄） |
| Hive box 打开失败 | 低 | 高 | 添加错误处理和日志 |

---

**Estimated time:** 3-4 小时
**Risk level:** 中（结构性重构，但有充分测试覆盖）
**Breaking changes:** 是（存储结构变更，需要数据迁移）
