import 'package:hive/hive.dart';

/// Box管理器
///
/// 职责：统一管理Hive Box实例，避免重复打开
/// 使用：通过BoxService间接使用，或直接调用getBox
class BoxManager {
  static final instance = BoxManager._();
  BoxManager._();

  final Map<String, Box> _openedBoxes = {};

  Future<Box<T>> getBox<T>(String boxName) async {
    if (_openedBoxes.containsKey(boxName)) {
      return _openedBoxes[boxName] as Box<T>;
    }
    final box = await Hive.openBox<T>(boxName);
    _openedBoxes[boxName] = box;
    return box;
  }

  Future<void> closeAll() async {
    for (final box in _openedBoxes.values) {
      await box.close();
    }
    _openedBoxes.clear();
  }

  Future<void> close(String boxName) async {
    final box = _openedBoxes[boxName];
    if (box != null) {
      await box.close();
      _openedBoxes.remove(boxName);
    }
  }

  Future<void> deleteBox(String boxName) async {
    await close(boxName);
    await Hive.deleteBoxFromDisk(boxName);
  }

  int get openedCount => _openedBoxes.length;
  List<String> get openedBoxNames => _openedBoxes.keys.toList();
}