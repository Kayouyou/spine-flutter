import 'dart:async';
import 'network_state.dart';

class NetworkQualityMonitor {
  final int _windowSize;
  final List<int> _recentLatencies = [];
  StreamController<NetworkQuality>? _controller;

  NetworkQualityMonitor({int windowSize = 5}) : _windowSize = windowSize;

  Stream<NetworkQuality> get qualityStream {
    _controller ??= StreamController<NetworkQuality>.broadcast();
    return _controller!.stream;
  }

  void recordLatency(int latencyMs) {
    _recentLatencies.add(latencyMs);
    if (_recentLatencies.length > _windowSize) {
      _recentLatencies.removeAt(0);
    }
    _emitQuality();
  }

  NetworkQuality get currentQuality {
    if (_recentLatencies.isEmpty) return NetworkQuality.good;
    final sorted = List<int>.from(_recentLatencies)..sort();
    final median = sorted[sorted.length ~/ 2];
    if (median < 200) return NetworkQuality.good;
    if (median < 1000) return NetworkQuality.slow;
    return NetworkQuality.poor;
  }

  void _emitQuality() => _controller?.add(currentQuality);

  void reset() {
    _recentLatencies.clear();
    _controller?.add(NetworkQuality.good);
  }

  void dispose() => _controller?.close();
}
