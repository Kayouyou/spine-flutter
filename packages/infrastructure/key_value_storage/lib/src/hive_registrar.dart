import 'package:hive/hive.dart';
import 'cache_data.dart';

/// Hive Adapter注册器
///
/// 职责：统一注册所有Hive Adapter
class HiveRegistrar {
  static bool _registered = false;

  static Future<void> registerAll() async {
    if (_registered) return;
    Hive.registerAdapter(CacheDataAdapter());
    _registered = true;
  }

  static bool get isRegistered => _registered;
}
