import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class KeyValueStorage {
  static const _defaultBoxKey = 'default';

  KeyValueStorage({HiveInterface? hive}) : _hive = hive ?? Hive;

  final HiveInterface _hive;

  Future<Box<T>> _openBox<T>(String key) async {
    if (_hive.isBoxOpen(key)) {
      return _hive.box(key) as Box<T>;
    }
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(p.join(appDir.path, 'hive'));
    return _hive.openBox<T>(key);
  }

  Future<void> putString(String key, String value) async {
    final box = await _openBox<String>(_defaultBoxKey);
    await box.put(key, value);
  }

  Future<String?> getString(String key) async {
    final box = await _openBox<String>(_defaultBoxKey);
    return box.get(key);
  }

  Future<void> putInt(String key, int value) async {
    final box = await _openBox<int>(_defaultBoxKey);
    await box.put(key, value);
  }

  Future<int?> getInt(String key) async {
    final box = await _openBox<int>(_defaultBoxKey);
    return box.get(key);
  }

  Future<void> putBool(String key, bool value) async {
    final box = await _openBox<bool>(_defaultBoxKey);
    await box.put(key, value);
  }

  Future<bool?> getBool(String key) async {
    final box = await _openBox<bool>(_defaultBoxKey);
    return box.get(key);
  }

  Future<void> delete(String key) async {
    final box = await _openBox<String>(_defaultBoxKey);
    await box.delete(key);
  }
}
