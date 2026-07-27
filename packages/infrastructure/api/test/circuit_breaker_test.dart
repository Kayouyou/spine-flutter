import 'package:flutter_test/flutter_test.dart';
import 'package:api/api.dart';

void main() {
  group('CircuitBreaker 熔断器', () {
    test('连续失败达阈值后进入 open 且拒绝请求', () {
      // 使用较长冷却时间，确保冷却未过
      final breaker = CircuitBreaker(
        failureThreshold: 3,
        resetDuration: const Duration(seconds: 60),
        halfOpenMaxCalls: 2,
      );

      breaker.recordFailure();
      breaker.recordFailure();
      // 未达阈值，仍可放行
      expect(breaker.state, CircuitState.closed);
      expect(breaker.allowRequest, isTrue);

      breaker.recordFailure();
      // 达阈值 -> open
      expect(breaker.state, CircuitState.open);
      expect(breaker.allowRequest, isFalse);
    });

    test('open 状态下 recordSuccess 不会立即恢复（需先 halfOpen）', () {
      final breaker = CircuitBreaker(
        failureThreshold: 2,
        resetDuration: const Duration(seconds: 60),
        halfOpenMaxCalls: 2,
      );

      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, CircuitState.open);

      // open 态直接记录成功不应恢复
      breaker.recordSuccess();
      expect(breaker.state, CircuitState.open);
      expect(breaker.allowRequest, isFalse);
    });

    test('冷却结束后自动转 halfOpen，探测成功回到 closed', () {
      // 使用零冷却时间，调用 allowRequest 即视为冷却已过
      final breaker = CircuitBreaker(
        failureThreshold: 2,
        resetDuration: Duration.zero,
        halfOpenMaxCalls: 2,
      );

      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, CircuitState.open);

      // 冷却时间为零，allowRequest 触发自动半开
      expect(breaker.allowRequest, isTrue);
      expect(breaker.state, CircuitState.halfOpen);

      // 半开态探测成功 -> 回到 closed
      breaker.recordSuccess();
      expect(breaker.state, CircuitState.closed);
      expect(breaker.allowRequest, isTrue);
    });

    test('closed 态未达阈值失败次数时仍放行请求', () {
      final breaker = CircuitBreaker(
        failureThreshold: 5,
        resetDuration: const Duration(seconds: 60),
        halfOpenMaxCalls: 2,
      );

      breaker.recordFailure();
      breaker.recordFailure();
      breaker.recordFailure();
      // 未达阈值 5
      expect(breaker.state, CircuitState.closed);
      expect(breaker.allowRequest, isTrue);
      expect(breaker.failureCount, 3);
    });

    test('半开态探测失败会重新熔断', () {
      final breaker = CircuitBreaker(
        failureThreshold: 1,
        resetDuration: Duration.zero,
        halfOpenMaxCalls: 2,
      );

      breaker.recordFailure(); // -> open
      expect(breaker.allowRequest, isTrue); // -> halfOpen
      expect(breaker.state, CircuitState.halfOpen);

      breaker.recordFailure(); // 半开探测失败 -> 重新 open
      expect(breaker.state, CircuitState.open);
      expect(breaker.allowRequest, isFalse); // 冷却未过
    });
  });
}
