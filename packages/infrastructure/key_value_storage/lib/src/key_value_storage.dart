import 'package:hive/hive.dart';
import 'preference_key.dart';

class KeyValueStorage {
  static const _defaultBoxKey = 'default';

  KeyValueStorage({HiveInterface? hive}) : _hive = hive ?? Hive;

  final HiveInterface _hive;

  Future<Box> _openBox(String key) async {
    if (_hive.isBoxOpen(key)) {
      return _hive.box(key);
    }
    return _hive.openBox(key);
  }

  /// Type-safe string storage
  /// Throws [ArgumentError] if key's valueType is not string
  Future<void> putString(PreferenceKey key, String value) async {
    if (key.valueType != StorageValueType.string) {
      throw ArgumentError('Key ${key.name} expects ${key.valueType}, not string');
    }
    final box = await _openBox(_defaultBoxKey);
    await box.put(key.rawKey, value);
  }

  /// Type-safe string retrieval
  /// Throws [ArgumentError] if key's valueType is not string
  Future<String?> getString(PreferenceKey key) async {
    if (key.valueType != StorageValueType.string) {
      throw ArgumentError('Key ${key.name} expects ${key.valueType}, not string');
    }
    final box = await _openBox(_defaultBoxKey);
    return box.get(key.rawKey) as String?;
  }

  /// Type-safe int storage
  /// Throws [ArgumentError] if key's valueType is not int
  Future<void> putInt(PreferenceKey key, int value) async {
    if (key.valueType != StorageValueType.int) {
      throw ArgumentError('Key ${key.name} expects ${key.valueType}, not int');
    }
    final box = await _openBox(_defaultBoxKey);
    await box.put(key.rawKey, value);
  }

  /// Type-safe int retrieval
  /// Throws [ArgumentError] if key's valueType is not int
  Future<int?> getInt(PreferenceKey key) async {
    if (key.valueType != StorageValueType.int) {
      throw ArgumentError('Key ${key.name} expects ${key.valueType}, not int');
    }
    final box = await _openBox(_defaultBoxKey);
    return box.get(key.rawKey) as int?;
  }

  /// Type-safe bool storage
  /// Throws [ArgumentError] if key's valueType is not bool
  Future<void> putBool(PreferenceKey key, bool value) async {
    if (key.valueType != StorageValueType.bool) {
      throw ArgumentError('Key ${key.name} expects ${key.valueType}, not bool');
    }
    final box = await _openBox(_defaultBoxKey);
    await box.put(key.rawKey, value);
  }

  /// Type-safe bool retrieval
  /// Throws [ArgumentError] if key's valueType is not bool
  Future<bool?> getBool(PreferenceKey key) async {
    if (key.valueType != StorageValueType.bool) {
      throw ArgumentError('Key ${key.name} expects ${key.valueType}, not bool');
    }
    final box = await _openBox(_defaultBoxKey);
    return box.get(key.rawKey) as bool?;
  }

  /// Delete a value by key
  Future<void> delete(PreferenceKey key) async {
    final box = await _openBox(_defaultBoxKey);
    await box.delete(key.rawKey);
  }
}
