import 'dart:async';

import 'package:dio/dio.dart';

import '../http/app_logger.dart';

/// 离线队列中的请求项
///
/// 持有原始 [RequestOptions] 与请求拦截器处理器 [handler]，
/// 在网络恢复时由 [RequestQueue.flush] 顺序重发并 resolve/reject。
///
/// 使用 [RequestInterceptorHandler] 是因为离线入队发生在请求阶段（onRequest），
/// 而它同样提供 resolve/reject，可在恢复后完成该请求。
class QueuedRequest {
  QueuedRequest({
    required this.options,
    required this.handler,
    DateTime? enqueuedAt,
  }) : enqueuedAt = enqueuedAt ?? DateTime.now();

  /// 待重发的请求配置
  final RequestOptions options;

  /// 请求拦截器处理器，用于最终 resolve/reject 本次请求
  final RequestInterceptorHandler handler;

  /// 入队时间，便于排查与排序
  final DateTime enqueuedAt;
}

/// 离线请求队列
///
/// 断网/不可达时将请求入队，网络恢复后通过 [flush] 按入队顺序重发，
/// 或通过网络不可恢复时调用 [clear] 统一以失败结束。
///
/// 日志统一走注入的 [AppLoggerInterface]，默认回退到 [DefaultLogger]。
class RequestQueue {
  /// 构造一个离线请求队列
  ///
  /// [maxSize] 队列最大容量，超过时丢弃最旧请求，默认 100。
  RequestQueue({this.maxSize = 100});

  /// 队列最大容量（入队上限）
  final int maxSize;

  final List<QueuedRequest> _queue = [];

  /// 注入的日志接口，默认使用 [DefaultLogger]
  AppLoggerInterface _logger = DefaultLogger();

  /// 注入自定义日志实现（与既有拦截器一致的模式）
  set logger(AppLoggerInterface logger) => _logger = logger;

  /// 当前队列是否为空
  bool get isEmpty => _queue.isEmpty;

  /// 当前队列长度
  int get length => _queue.length;

  /// 将请求加入队列
  ///
  /// 若队列已达 [maxSize]，丢弃最旧请求（队首）后再入队，
  /// 避免断网期间无限积压。
  void enqueue(QueuedRequest request) {
    if (_queue.length >= maxSize) {
      final dropped = _queue.removeAt(0);
      _logger.warning(
        '[RequestQueue] 队列已满(上限 $maxSize)，丢弃最旧请求: ${dropped.options.path}',
      );
    }
    _queue.add(request);
    _logger.debug(
      '[RequestQueue] 请求入队: ${request.options.path}，当前队列长度: ${_queue.length}',
    );
  }

  /// 网络恢复后顺序重发队列中的全部请求
  ///
  /// [fetch] 为实际执行请求的函数（通常包一层 Dio.fetch）。
  /// 成功则 [QueuedRequest.handler.resolve]，失败则 [QueuedRequest.handler.reject]，
  /// 且 reject 使用 [failIfNotResolved] = false 避免重复 resolve 抛异常。
  /// 全部完成后清空队列。
  Future<void> flush(
    Future<Response<dynamic>> Function(RequestOptions) fetch,
  ) async {
    if (_queue.isEmpty) return;

    final requests = List<QueuedRequest>.from(_queue);
    _queue.clear();

    _logger.info('[RequestQueue] 开始按序重发 ${requests.length} 个离线请求');

    for (final queued in requests) {
      try {
        final response = await fetch(queued.options);
        queued.handler.resolve(response);
      } catch (e) {
        final err = e is DioException
            ? e
            : DioException(requestOptions: queued.options, error: e);
        // failIfNotResolved=false：fetch 内部可能已处理，避免重复 resolve 抛异常
        queued.handler.reject(err, false);
      }
    }

    _logger.info('[RequestQueue] 离线队列重发完成');
  }

  /// 清空队列，所有请求以失败告终
  ///
  /// [reason] 为清空原因，包装为 [DioException.error] 传递给各 handler。
  void clear(Object? reason) {
    final clearReason = reason ?? '离线队列已清空';
    if (_queue.isNotEmpty) {
      _logger.warning('[RequestQueue] 清空队列(${_queue.length} 个)，原因: $clearReason');
    }

    for (final queued in _queue) {
      queued.handler.reject(
        DioException(
          requestOptions: queued.options,
          error: clearReason,
        ),
        false,
      );
    }
    _queue.clear();
  }
}
