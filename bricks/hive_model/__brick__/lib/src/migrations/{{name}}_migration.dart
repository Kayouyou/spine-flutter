import 'package:hive/hive.dart';
import '../models/{{name}}.dart';

/// {{name.pascalCase()}} 数据迁移
class {{name.pascalCase()}}Migration {
  /// 执行迁移
  static Future<void> migrate({
    required Box<{{name.pascalCase()}}> box,
    required int oldVersion,
    required int newVersion,
  }) async {
    // V1 -> V2: 添加 description 字段
    if (oldVersion < 2) {
      for (var key in box.keys) {
        final item = box.get(key);
        if (item != null && item.description == null) {
          final updated = item.copyWith(description: '');
          await box.put(key, updated);
        }
      }
    }
  }
}
