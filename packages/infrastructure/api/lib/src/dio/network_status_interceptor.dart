import 'dart:async';

import 'package:dio/dio.dart';

import '../network/network_environment.dart';
import '../http/app_logger.dart';
import 'request_queue.dart';

/// 网络状态拦截器（断网入队 / 恢复重发）
///
/// 职责：
/// 1. 请求前检查连通性，断网时将请求入队并暂停（不调用 [RequestInterceptorHandler.next]）。
/// 2. 订阅 [NetworkEnvironment.connectionChanges]，网络恢复（true）且队列非空时自动重发。
/// 3. 通过 extra `enqueueOnOffline` 控制是否允许断网入队（默认允许；显式 false 则离线直接拒绝）。
///
/// R3 合规：仅依赖 dio / flutter / infra 内部（NetworkEnvironment、RequestQueue、AppLoggerInterface），
/// 不 import `package:services/...` 或 `package:network/...`，亦不引入任何 UI/Toast 依赖。
class NetworkStatusInterceptor extends Interceptor {
  /// Dio 实例，用于网络恢复后通过 [RequestQueue.flush] 重发离线请求。
  final Dio _dio;

  /// 网络环境抽象，提供连通性查询与变化流。
  final NetworkEnvironment _networkEnvironment;

  /// 离线请求队列。
  final RequestQueue _requestQueue;

  /// 注入的日志接口，默认回退到 [DefaultLogger]。
  AppLoggerInterface _logger = DefaultLogger();

  /// 连通性变化订阅，便于 [dispose] 取消。
  StreamSubscription<bool>? _connectionSub;

  NetworkStatusInterceptor(
    this._dio, {
    required NetworkEnvironment networkEnvironment,
    required RequestQueue requestQueue,
    AppLoggerInterface? logger,
  })  : _networkEnvironment = networkEnvironment,
        _requestQueue = requestQueue {
    if (logger != null) _logger = logger;
    // 订阅连通性变化：恢复（true）且队列非空时重发离线请求。
    _connectionSub = _networkEnvironment.connectionChanges.listen(_onConnectionChanged);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 仅当“离线”且“显式禁止入队”时才直接拒绝。
    // 注意：用 `== false` 判定，避免 extra 为 null 时被误当作 false。
    final enqueueOnOffline = options.extra['enqueueOnOffline'];
    final connected = await _networkEnvironment.isConnected();

    if (!connected) {
      if (enqueueOnOffline == false) {
        // 离线且禁止入队：直接拒绝，不入队。
        _logger.warning(
          '[NetworkStatusInterceptor] 离线且禁止入队，直接拒绝: ${options.path}',
        );
        handler.reject(
          DioException(
            requestOptions: options,
            error: '离线且禁止入队',
          ),
          false,
        );
        return;
      }

      // 断网：请求入队并暂停（不调用 next），等待网络恢复后重发。
      _logger.info('[NetworkStatusInterceptor] 断网，请求入队: ${options.path}');
      _requestQueue.enqueue(QueuedRequest(
        options: options,
        handler: handler,
      ));
      return;
    }

    handler.next(options);
  }

  /// 连通性变化回调：恢复连接且队列非空时触发重发。
  Future<void> _onConnectionChanged(bool connected) async {
    if (connected && !_requestQueue.isEmpty) {
      _logger.info('[NetworkStatusInterceptor] 网络恢复，开始重发离线队列');
      // flush 内部已通过各 QueuedRequest.handler.resolve/reject 收尾，
      // 重发过程中的异常由 flush 捕获并以 failIfNotResolved=false 拒绝，无需在此处理。
      await _requestQueue.flush((opts) => _dio.fetch(opts));
    }
  }

  /// 释放订阅，避免内存泄漏。
  void dispose() {
    _connectionSub?.cancel();
    _connectionSub = null;
  }
}
