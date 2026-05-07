import 'package:upgrader/upgrader.dart';

/// 强制更新检查服务
///
/// 可在任意页面调用 [check] 方法手动触发更新检查。
class ForceUpdateChecker {
  static final _upgrader = Upgrader();

  /// 手动触发更新检查
  static Future<void> check() async {
    await _upgrader.initialize();
  }
}