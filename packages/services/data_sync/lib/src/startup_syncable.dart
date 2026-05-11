import 'package:flutter/foundation.dart';
import 'data_syncable.dart';

/// ⚠️ SCAFFOLD MODE: 示例实现，仅展示 DataSync 模式用法。
///
/// 真实项目应替换为:
/// - UserProfileSyncable（拉取用户信息）
/// - ConfigSyncable（同步远程配置）
/// - CacheWarmupSyncable（预热缓存）
///
/// 示例 Syncable：应用启动时同步用户偏好
///
/// 这是 DataSync 模式的最小示例。真实场景中可替换为：
/// - UserProfileSyncable（拉取用户信息）
/// - ConfigSyncable（同步远程配置）
/// - CacheWarmupSyncable（预热缓存）
class StartupSyncable implements DataSyncable {
  @override
  int get priority => 100; // 最高优先级，最先执行

  @override
  Future<bool> sync() async {
    if (kDebugMode) {
      debugPrint('StartupSyncable: 同步偏好设置（示例）');
    }
    // TODO: 替换为真实同步逻辑
    // await repository.pullLatestConfig();
    return true;
  }
}
