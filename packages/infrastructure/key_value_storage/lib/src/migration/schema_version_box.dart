import 'package:hive/hive.dart';

/// 用于存储版本号的box名称
const String schemaVersionBoxName = '_schema_versions';

/// 架构版本追踪器
///
/// 跟踪每个box的当前架构版本
class SchemaVersionBox {
  late Box _box;
  bool _initialized = false;

  /// 初始化版本box
  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(schemaVersionBoxName);
    _initialized = true;
  }

  /// 获取box的当前版本（无版本时返回defaultValue）
  int getVersion(String boxName, {int defaultValue = 0}) {
    return _box.get(boxName, defaultValue: defaultValue) as int;
  }

  /// 设置box的版本
  Future<void> setVersion(String boxName, int version) async {
    await _box.put(boxName, version);
  }

  /// 获取所有box的版本
  Map<String, int> getAllVersions() {
    final Map<String, int> result = {};
    for (final key in _box.keys) {
      result[key as String] = _box.get(key) as int;
    }
    return result;
  }

  /// 清除所有版本（测试用）
  Future<void> clearAll() async {
    await _box.clear();
  }
}