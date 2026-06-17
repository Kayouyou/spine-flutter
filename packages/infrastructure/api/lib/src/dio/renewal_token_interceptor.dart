import 'dart:async';

import 'package:dio/dio.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:synchronized/synchronized.dart';

import '../../api.dart';

/// 优化版 Token 续期拦截器
///
/// 职责:
/// 1. 拦截 401/续期窗口内的业务响应
/// 2. 编排续期流程（加锁、串行、合并并发请求）
/// 3. 续期成功后批量重试 pending 请求
/// 4. 续期失败时降级回原始响应 + 触发 logout event
///
/// HTTP 细节委托给 refresh_api.dart，队列管理委托给 refresh_queue.dart
class TokenRenewalInterceptor extends Interceptor {
  TokenRenewalInterceptor(this._dio, [TokenStorage? tokenStorage]) {
    _tokenStorage = tokenStorage;
    _renewalLock = Lock();
  }

  final Dio _dio;
  TokenStorage? _tokenStorage;
  late final Lock _renewalLock;

  /// 日志输出实例
  AppLoggerInterface _logger = DefaultLogger();

  /// 设置Logger
  set logger(AppLoggerInterface logger) => _logger = logger;

  /// 设置TokenStorage（支持延迟注入）
  set tokenStorage(TokenStorage storage) {
    _tokenStorage = storage;
  }

  final RefreshQueue _queue = RefreshQueue();

  TokenRenewalState _renewalState = TokenRenewalState.idle;
  DateTime? _lastRenewalTime;
  Completer<bool>? _renewalCompleter;

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 1. 检查是否需要续期
    bool needsRenewal = false;
    try {
      needsRenewal = await shouldRenewToken(response);
    } catch (e) {
      _logger.error('检查是否需要续期时出错: $e');
      return handler.next(response);
    }

    if (!needsRenewal) {
      return handler.next(response);
    }

    _logger.info('请求需要续期: ${response.requestOptions.path}');

    // 3. 将当前请求添加到缓存队列
    final completer = Completer<Response>();
    unawaited(
      completer.future.then((newResponse) {
        handler.next(newResponse);
      }).catchError((error) {
        _logger.warning('续期过程中出错，返回原始响应: $error');
        handler.next(response);
      }),
    );

    _queue.add(PendingRequest(
      requestOptions: response.requestOptions,
      completer: completer,
      originalResponse: response,
    ));

    // 4. 启动或等待续期流程
    await _renewalLock.synchronized(() async {
      if (_renewalState == TokenRenewalState.renewing) {
        _logger.debug('已有续期正在进行，等待续期完成: ${response.requestOptions.path}');
        return;
      }

      if (_renewalState == TokenRenewalState.success &&
          _lastRenewalTime != null &&
          DateTime.now().difference(_lastRenewalTime!) < const Duration(seconds: 5)) {
        _logger.debug('短时间内已经续期成功，直接重试请求');
        await _drainRetry();
        return;
      }

      _renewalState = TokenRenewalState.renewing;
      _renewalCompleter = Completer<bool>();

      unawaited(Future.microtask(() async {
        try {
          _logger.info('开始执行token续期流程');

          final success = await performTokenRenewal(
            _dio,
            _tokenStorage,
            _lastRenewalTime,
            logger: _logger,
          );

          if (success) {
            _renewalState = TokenRenewalState.success;
            _lastRenewalTime = DateTime.now();
            _logger.info('续期成功，开始重试队列中的请求');
            await _drainRetry();
          } else {
            _renewalState = TokenRenewalState.failed;
            _logger.warning('续期失败，完成所有等待的请求（使用原始响应）');
            _drainFallback();
          }

          if (!_renewalCompleter!.isCompleted) {
            _renewalCompleter!.complete(success);
          }
        } catch (e) {
          _logger.error('续期过程中出错: $e');
          _drainFallback();
          if (!_renewalCompleter!.isCompleted) {
            _renewalCompleter!.complete(false);
          }
          _renewalState = TokenRenewalState.failed;
        } finally {
          Future.delayed(const Duration(seconds: 3), () {
            if (_renewalState != TokenRenewalState.renewing) {
              _renewalState = TokenRenewalState.idle;
            }
          });
        }
      }));
    });
  }

  Future<void> _drainRetry() async {
    await _queue.drain<void>(
      (p) async {
        final response = await retryRequestWithRetry(_dio, _tokenStorage, p.requestOptions);
        if (response != null) {
          p.completer.complete(response);
        } else {
          p.completer.complete(p.originalResponse);
        }
      },
      batchSize: 5,
      fireAndForget: false,
    );
    _logger.info('所有队列请求重试完成');
  }

  void _drainFallback() {
    _queue.drain<void>(
      (p) async => p.completer.complete(p.originalResponse),
      batchSize: 10,
      fireAndForget: true,
    );
    _logger.info('所有等待的请求完成');
  }
}
