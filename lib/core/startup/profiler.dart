// Flutter imports:
import 'package:flutter/foundation.dart';

/// 启动性能计时器
///
/// 职责：测量App启动各阶段耗时，用于性能优化分析
/// 使用：在启动流程关键节点调用mark()记录时间
/// 注意：仅在Debug模式输出日志，生产环境零开销
class StartupProfiler {
  static final Stopwatch _watch = Stopwatch();

  /// 开始计时
  static void start() {
    _watch.reset();
    _watch.start();
  }

  /// 记录时间点
  static void mark(String label) {
    if (kDebugMode) {
      debugPrint('⏱️ [Profiler] $label: ${_watch.elapsedMilliseconds}ms');
    }
  }

  /// 输出总耗时
  static void report() {
    if (kDebugMode) {
      debugPrint('⏱️ [Profiler] 总耗时: ${_watch.elapsedMilliseconds}ms');
    }
  }
}
