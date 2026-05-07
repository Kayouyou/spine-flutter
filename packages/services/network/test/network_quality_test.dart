import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/network_quality_monitor.dart';
import 'package:network/src/network_state.dart';

void main() {
  group('NetworkQualityMonitor', () {
    late NetworkQualityMonitor monitor;

    setUp(() {
      monitor = NetworkQualityMonitor(windowSize: 3);
    });

    test('default quality is good', () {
      expect(monitor.currentQuality, NetworkQuality.good);
    });

    test('low latency stays good', () {
      monitor.recordLatency(50);
      monitor.recordLatency(100);
      monitor.recordLatency(150);
      expect(monitor.currentQuality, NetworkQuality.good);
    });

    test('medium latency becomes slow', () {
      monitor.recordLatency(300);
      monitor.recordLatency(500);
      monitor.recordLatency(800);
      expect(monitor.currentQuality, NetworkQuality.slow);
    });

    test('high latency becomes poor', () {
      monitor.recordLatency(1500);
      monitor.recordLatency(2000);
      monitor.recordLatency(3000);
      expect(monitor.currentQuality, NetworkQuality.poor);
    });

    test('reset clears history', () {
      monitor.recordLatency(5000);
      expect(monitor.currentQuality, NetworkQuality.poor);
      monitor.reset();
      expect(monitor.currentQuality, NetworkQuality.good);
    });

    test('sliding window respects windowSize=3', () {
      monitor.recordLatency(100);
      monitor.recordLatency(200);
      monitor.recordLatency(300);
      expect(monitor.currentQuality, NetworkQuality.slow);
      // Push out the 100ms, now median is 300
      monitor.recordLatency(300);
      monitor.recordLatency(300);
      expect(monitor.currentQuality, NetworkQuality.slow);
    });
  });
}
