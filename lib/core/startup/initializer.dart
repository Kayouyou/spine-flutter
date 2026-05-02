// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:key_value_storage/key_value_storage.dart';

/// SDK初始化器
///
/// 职责：初始化第三方SDK，如推送、统计、支付等
/// 使用：在AppLauncher启动流程中调用
/// 注意：SDK初始化应异步进行，不阻塞首屏渲染
class SDKInitializer {
  /// 初始化第三方SDK
  ///
  /// 包括推送SDK、统计SDK、支付SDK等
  /// 建议在后台线程执行，避免阻塞UI
  Future<void> initPlugins() async {
    if (kDebugMode) {
      debugPrint('🚀 [SDKInitializer] initPlugins: 开始初始化...');
    }

    // 初始化Hive Adapter
    await HiveRegistrar.registerAll();
    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] Hive Adapter注册完成');
    }

    // TODO: 初始化推送SDK
    // TODO: 初始化统计SDK
    // TODO: 初始化支付SDK
    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] initPlugins: 初始化完成');
    }
  }
}
