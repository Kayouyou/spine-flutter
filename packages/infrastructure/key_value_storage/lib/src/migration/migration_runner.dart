import 'package:hive/hive.dart';
import 'migration.dart';
import 'schema_version_box.dart';

/// 迁移执行器 - 在应用启动时运行所有已注册的迁移
class MigrationRunner {
  final SchemaVersionBox _schemaVersionBox;
  final List<Migration> _migrations = [];

  MigrationRunner(this._schemaVersionBox);

  /// 注册迁移
  void registerMigration(Migration migration) {
    _migrations.add(migration);
  }

  /// 运行所有已注册的迁移
  Future<void> run() async {
    // 按fromVersion排序以确保正确顺序
    _migrations.sort((a, b) => a.fromVersion.compareTo(b.fromVersion));

    for (final migration in _migrations) {
      await _runMigration(migration);
    }
  }

  Future<void> _runMigration(Migration migration) async {
    final currentVersion = _schemaVersionBox.getVersion(migration.boxName);

    // 已达目标版本，跳过
    if (currentVersion >= migration.toVersion) {
      return;
    }

    // 版本不匹配
    if (currentVersion != migration.fromVersion) {
      switch (migration.strategy) {
        case MigrationStrategy.chain:
          throw MigrationException(
            message: '检测到版本差距，期望版本 ${migration.fromVersion}，发现 $currentVersion',
            boxName: migration.boxName,
            fromVersion: currentVersion,
            toVersion: migration.toVersion,
          );
        case MigrationStrategy.clearOnMismatch:
          // 清除box并设置新版本
          await _clearAndRecreate(migration);
          return;
      }
    }

    // 根据策略执行迁移
    switch (migration.strategy) {
      case MigrationStrategy.chain:
        await _runChainMigration(migration);
        break;
      case MigrationStrategy.clearOnMismatch:
        await _clearAndRecreate(migration);
        break;
    }

    // 验证并更新版本
    final box = Hive.box(migration.boxName);
    final isValid = await migration.validate(box);
    if (!isValid) {
      throw MigrationException(
        message: '迁移验证失败',
        boxName: migration.boxName,
        fromVersion: migration.fromVersion,
        toVersion: migration.toVersion,
      );
    }

    await _schemaVersionBox.setVersion(migration.boxName, migration.toVersion);
  }

  Future<void> _runChainMigration(Migration migration) async {
    final oldBox = await Hive.openBox(migration.boxName);
    final newBoxName = '${migration.boxName}_v${migration.toVersion}';
    final newBox = await Hive.openBox(newBoxName);

    try {
      await migration.apply(oldBox, newBox);

      await oldBox.close();
      await newBox.close();

      await Hive.deleteBoxFromDisk(migration.boxName);
      await Hive.box(newBoxName).rename(migration.boxName);
    } catch (e) {
      await newBox.close();
      await Hive.deleteBoxFromDisk(newBoxName);
      rethrow;
    }
  }

  Future<void> _clearAndRecreate(Migration migration) async {
    final boxName = migration.boxName;

    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }

    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox(boxName);

    await _schemaVersionBox.setVersion(boxName, migration.toVersion);
  }
}