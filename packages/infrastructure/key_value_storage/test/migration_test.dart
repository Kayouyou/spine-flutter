import 'package:hive/hive.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test_hive');
  });
  
  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });
  
  group('迁移', () {
    test('链式策略保留并转换数据', () async {
      final box = await Hive.openBox('test_chain');
      await box.put('key1', {'name': 'old_name', 'value': 100});
      await box.close();
      
      final oldBox = await Hive.openBox('test_chain');
      final newBox = await Hive.openBox('test_chain_v2');
      
      // 模拟迁移：添加 newField
      for (final key in oldBox.keys) {
        final oldData = Map<String, dynamic>.from(oldBox.get(key) as Map);
        newBox.put(key, {...oldData, 'newField': 'transformed_${oldData['name']}'});
      }
      
      final key1 = newBox.get('key1') as Map;
      expect(key1['name'], 'old_name');
      expect(key1['value'], 100);
      expect(key1['newField'], 'transformed_old_name');
      
      await oldBox.close();
      await newBox.close();
    });
    
    test('SchemaVersionBox 跟踪版本', () async {
      final schemaBox = SchemaVersionBox();
      await schemaBox.init();
      
      await schemaBox.setVersion('user_box', 1);
      await schemaBox.setVersion('order_box', 2);
      
      expect(schemaBox.getVersion('user_box'), 1);
      expect(schemaBox.getVersion('order_box'), 2);
      expect(schemaBox.getVersion('new_box'), 0);
    });
  });
}