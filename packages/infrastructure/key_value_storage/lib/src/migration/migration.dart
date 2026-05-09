import 'package:hive/hive.dart';

/// 迁移策略枚举
enum MigrationStrategy {
  /// 链式迁移：从旧版本迁移到新版本（保留数据）
  chain,

  /// 版本不匹配时清除：清空并重建box（可安全丢弃的缓存数据）
  clearOnMismatch,
}

/// 架构迁移的抽象基类
abstract class Migration {
  /// 此迁移适用的box名称
  String get boxName;

  /// 此迁移的起始版本号
  int get fromVersion;

  /// 此迁移的目标版本号
  int get toVersion;

  /// 使用的迁移策略
  MigrationStrategy get strategy;

  /// 执行迁移
  Future<void> apply(Box oldBox, Box newBox);

  /// 迁移后的验证（返回true表示成功）
  Future<bool> validate(Box box);
}

/// 迁移异常
class MigrationException implements Exception {
  final String message;
  final String boxName;
  final int? fromVersion;
  final int? toVersion;

  MigrationException({
    required this.message,
    required this.boxName,
    this.fromVersion,
    this.toVersion,
  });

  @override
  String toString() =>
      'MigrationException: $message (box: $boxName, $fromVersion -> $toVersion)';
}