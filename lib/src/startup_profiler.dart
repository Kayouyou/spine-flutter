import 'package:flutter/foundation.dart';

/// Startup Profiler — simple timing utility
class StartupProfiler {
  static final Stopwatch _watch = Stopwatch();

  static void start() {
    _watch.reset();
    _watch.start();
  }

  static void mark(String label) {
    if (kDebugMode) {
      debugPrint('⏱️ [Profiler] $label: ${_watch.elapsedMilliseconds}ms');
    }
  }

  static void report() {
    if (kDebugMode) {
      debugPrint('⏱️ [Profiler] Total: ${_watch.elapsedMilliseconds}ms');
    }
  }
}
