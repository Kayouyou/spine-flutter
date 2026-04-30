import 'package:hive/hive.dart';

/// Domain Models Hive Adapter注册器
///
/// 职责：注册业务模型的Hive Adapter
/// TypeId分配：
///   - 1: User（示例）
///   - 2+: 其他业务模型
class DomainHiveRegistrar {
  static bool _registered = false;

  static void registerAll() {
    if (_registered) return;
    // 示例：注册User Adapter
    // Hive.registerAdapter(UserAdapter());
    _registered = true;
  }

  static bool get isRegistered => _registered;
}