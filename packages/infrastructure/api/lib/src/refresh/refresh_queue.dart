import 'dart:async';

import 'package:dio/dio.dart';

/// Token 续期状态
///
/// 单一续期锁下的状态机，由 [TokenRenewalInterceptor] 维护
enum TokenRenewalState {
  /// 空闲状态，没有续期操作在进行
  idle,

  /// 正在进行续期操作
  renewing,

  /// 续期成功
  success,

  /// 续期失败
  failed,
}

/// 请求包装类，用于存储和恢复请求
///
/// 在 401/续期窗口内被拦截的业务请求会包装为 [PendingRequest]，
/// 等续期结束后批量用新 token 重试。
class PendingRequest {
  PendingRequest({
    required this.requestOptions,
    required this.completer,
    required this.originalResponse,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final RequestOptions requestOptions;
  final Completer<Response> completer;
  final Response originalResponse;
  final DateTime timestamp;

  /// 定义两个请求相同的标准：路径、方法、参数和数据都相同
  /// （注：原版用 .toString() 字符串比较，保留字节码）
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PendingRequest) return false;

    return requestOptions.path == other.requestOptions.path &&
        requestOptions.method == other.requestOptions.method &&
        requestOptions.queryParameters.toString() ==
            other.requestOptions.queryParameters.toString() &&
        requestOptions.data.toString() == other.requestOptions.data.toString();
  }

  @override
  int get hashCode =>
      requestOptions.path.hashCode ^
      requestOptions.method.hashCode ^
      requestOptions.queryParameters.toString().hashCode ^
      requestOptions.data.toString().hashCode;
}

/// Token 续期请求队列
///
/// 持有 401 窗口内被拦截的 [PendingRequest] 集合
class RefreshQueue {
  final Set<PendingRequest> _pendingRequests = {};

  int get size => _pendingRequests.length;

  void add(PendingRequest request) {
    _pendingRequests.add(request);
  }

  Future<void> drain<T>(
    Future<T> Function(PendingRequest) processor, {
    required int batchSize,
    required bool fireAndForget,
  }) async {
    if (_pendingRequests.isEmpty) return;

    final requests = List<PendingRequest>.from(_pendingRequests);
    requests.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _pendingRequests.clear();

    for (int i = 0; i < requests.length; i += batchSize) {
      final end = (i + batchSize < requests.length) ? i + batchSize : requests.length;
      final batch = requests.sublist(i, end);

      if (fireAndForget) {
        Future.wait(batch.map(processor));
      } else {
        await Future.wait(batch.map(processor));
      }

      if (end < requests.length) {
        if (fireAndForget) {
          Future.delayed(const Duration(milliseconds: 50));
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  }
}
