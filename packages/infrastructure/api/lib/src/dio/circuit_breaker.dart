import 'dart:async';

import '../http/app_logger.dart';

/// 熔断器状态枚举
enum CircuitState {
  /// 关闭：正常放行请求
  closed,

  /// 打开：熔断中，拒绝所有请求
  open,

  /// 半开：冷却结束后放行少量探测请求，验证服务是否恢复
  halfOpen,
}

/// 熔断器
///
/// 用于防止依赖服务持续失败时大量重试导致雪崩。
/// 三种状态：
/// - [CircuitState.closed]：正常状态，记录失败次数
/// - [CircuitState.open]：失败达阈值后熔断，冷却期内拒绝全部请求
/// - [CircuitState.halfOpen]：冷却结束后放行少量探测请求，判断服务是否恢复
///
/// 与 Gitee 参考实现保持一致的状态机逻辑，差异点：
/// 1. 所有日志输出改为注入的 [AppLoggerInterface]（不再使用 debugPrint）。
/// 2. 不依赖 services/network，仅依赖 infra 内部与 flutter。
class CircuitBreaker {
  /// 失败次数阈值，达到后触发熔断（closed -> open）
  final int failureThreshold;

  /// 熔断冷却时间，open 态持续该时长后自动转为 halfOpen
  final Duration resetDuration;

  /// 半开状态下允许通过的探测请求数
  final int halfOpenMaxCalls;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  int _halfOpenCalls = 0;

  /// 日志输出实例，默认使用 [DefaultLogger]。
  /// 可通过 [logger] setter 注入主应用实现，打破依赖循环。
  AppLoggerInterface _logger = DefaultLogger();

  /// 设置日志输出实例（支持延迟注入）。
  set logger(AppLoggerInterface logger) => _logger = logger;

  /// 状态变化流，便于上层监听熔断事件
  final StreamController<CircuitState> _stateController =
      StreamController<CircuitState>.broadcast();

  /// 暴露状态变化流
  Stream<CircuitState> get stateStream => _stateController.stream;

  /// 当前熔断器状态
  CircuitState get state => _state;

  /// 当前累计失败次数
  int get failureCount => _failureCount;

  CircuitBreaker({
    this.failureThreshold = 10,
    this.resetDuration = const Duration(seconds: 30),
    this.halfOpenMaxCalls = 3,
  });

  /// 是否允许请求通过。
  ///
  /// - closed：始终允许。
  /// - open：仅当冷却时间结束后自动转入 halfOpen 并允许（受 halfOpenMaxCalls 限制）。
  /// - halfOpen：在允许的探测次数内允许，超出则拒绝。
  bool get allowRequest {
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        // 检查冷却时间是否已过
        if (_lastFailureTime != null &&
            DateTime.now().difference(_lastFailureTime!) >= resetDuration) {
          // 冷却完毕，自动进入半开状态
          _halfOpenCalls = 0;
          _transitionTo(CircuitState.halfOpen);
          return true;
        }
        return false;
      case CircuitState.halfOpen:
        // 半开状态下只允许少量探测请求通过
        if (_halfOpenCalls < halfOpenMaxCalls) {
          _halfOpenCalls++;
          return true;
        }
        return false;
    }
  }

  /// 记录一次成功请求。
  ///
  /// 仅在 halfOpen 状态下生效：探测成功说明服务已恢复，关闭熔断器回到 closed。
  /// 注意：open 状态下直接调用 [recordSuccess] 不会恢复（需先经过冷却转为 halfOpen）。
  void recordSuccess() {
    if (_state == CircuitState.halfOpen) {
      _logger.info('[CircuitBreaker] 探测成功，熔断器关闭');
      _failureCount = 0;
      _transitionTo(CircuitState.closed);
    }
  }

  /// 记录一次失败请求。
  ///
  /// - halfOpen 状态下失败：立即重新熔断（open）。
  /// - closed 状态下失败计数达 [failureThreshold]：触发熔断（open）并记录打开时间。
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      // 半开状态下探测失败，重新熔断
      _logger.warning('[CircuitBreaker] 探测失败，熔断器重新打开');
      _transitionTo(CircuitState.open);
      return;
    }

    if (_failureCount >= failureThreshold) {
      _logger.warning(
        '[CircuitBreaker] 失败次数 $_failureCount 达阈值 $failureThreshold，熔断器打开',
      );
      _transitionTo(CircuitState.open);
    }
  }

  /// 手动重置熔断器到 closed 状态。
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _halfOpenCalls = 0;
    _transitionTo(CircuitState.closed);
  }

  void _transitionTo(CircuitState newState) {
    if (_state != newState) {
      _logger.debug('[CircuitBreaker] 状态变更: $_state -> $newState');
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// 释放状态流资源。
  void dispose() {
    _stateController.close();
  }
}
