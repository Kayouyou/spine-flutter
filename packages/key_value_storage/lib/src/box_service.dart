import 'package:hive/hive.dart';
import 'box_manager.dart';
import 'cache_data.dart';

/// Box服务
///
/// 职责：封装Box CRUD操作，提供便捷的缓存API
class BoxService<T> {
  final String boxName;
  final BoxManager _manager = BoxManager.instance;

  BoxService(this.boxName);

  Future<Box<T>> _box() => _manager.getBox<T>(boxName);

  // 基础CRUD
  Future<void> put(String key, T value) async {
    final box = await _box();
    await box.put(key, value);
  }

  Future<T?> get(String key) async {
    final box = await _box();
    return box.get(key);
  }

  Future<void> delete(String key) async {
    final box = await _box();
    await box.delete(key);
  }

  Future<bool> contains(String key) async {
    final box = await _box();
    return box.containsKey(key);
  }

  // 批量操作
  Future<void> putAll(Map<String, T> items) async {
    final box = await _box();
    await box.putAll(items);
  }

  Future<List<T>> getAllValues() async {
    final box = await _box();
    return box.values.toList();
  }

  Future<List<String>> getAllKeys() async {
    final box = await _box();
    return box.keys.toList().cast<String>();
  }

  Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }

  // 排序/过滤
  Future<List<T>> getSorted(Comparator<T> comparator) async {
    final values = await getAllValues();
    values.sort(comparator);
    return values;
  }

  Future<List<T>> where(bool test(T element)) async {
    final values = await getAllValues();
    return values.where(test).toList();
  }

  // 过期机制
  Future<void> putWithExpiry(String key, T value, {Duration? ttl}) async {
    final data = CacheData<T>(value, ttl: ttl);
    final box = await _manager.getBox<CacheData<T>>('${boxName}_cache');
    await box.put(key, data);
  }

  Future<T?> getWithExpiry(String key) async {
    final box = await _manager.getBox<CacheData<T>>('${boxName}_cache');
    final data = box.get(key);
    if (data == null) return null;
    if (data.isExpired) {
      await box.delete(key);
      return null;
    }
    return data.value;
  }

  Future<int> get length async {
    final box = await _box();
    return box.length;
  }

  Future<bool> get isEmpty async {
    final box = await _box();
    return box.isEmpty;
  }
}