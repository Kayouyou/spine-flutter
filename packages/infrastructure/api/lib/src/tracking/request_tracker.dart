import 'package:flutter/foundation.dart';

/// 请求追踪器
///
/// 职责：追踪请求执行过程，记录耗时和状态
/// 使用：
///   - 在请求开始时调用track方法注册请求
///   - 在请求完成时调用complete方法结束追踪
///   - 可查看pendingRequests获取未完成请求列表
/// 优势：
///   - 监控请求耗时，便于性能分析
///   - 追踪未完成请求，避免请求遗漏
///   - debugPrint输出，仅在调试模式可见
///
/// 注意：本模块已实现，需手动集成到HttpManager.send()方法中
/// 集成方式：在请求开始时track()，完成时complete()
class RequestTracker {
  /// 单例实例
  static final instance = RequestTracker._();

  RequestTracker._();

  /// 请求信息映射表
  ///
  /// key: requestId（请求唯一标识）
  /// value: _RequestInfo（请求详情）
  final Map<String, _RequestInfo> _requests = {};

  /// 追踪请求
  ///
  /// 注册一个请求到追踪器，开始计时
  ///
  /// 参数：
  /// - requestId: 请求唯一标识
  /// - path: 请求路径
  /// - startTime: 请求开始时间（可选，默认当前时间）
  void track(String requestId, String path, DateTime? startTime) {
    _requests[requestId] = _RequestInfo(
      path: path,
      startTime: startTime ?? DateTime.now(),
    );
  }

  /// 完成请求追踪
  ///
  /// 结束请求计时，输出耗时日志
  ///
  /// 参数：
  /// - requestId: 请求唯一标识
  void complete(String requestId) {
    final info = _requests[requestId];
    if (info != null) {
      final duration = DateTime.now().difference(info.startTime);
      debugPrint('Request $requestId: ${info.path} - ${duration.inMilliseconds}ms');
      _requests.remove(requestId);
    }
  }

  /// 获取未完成请求列表
  ///
  /// 用于调试，查看当前所有未完成的请求
  List<_RequestInfo> get pendingRequests => _requests.values.toList();

  /// 获取未完成请求数量
  int get pendingCount => _requests.length;

  /// 清理所有追踪记录
  ///
  /// App退出或重置时调用
  void clearAll() => _requests.clear();
}

/// 请求信息内部类
class _RequestInfo {
  /// 请求路径
  final String path;

  /// 请求开始时间
  final DateTime startTime;

  _RequestInfo({required this.path, required this.startTime});
}