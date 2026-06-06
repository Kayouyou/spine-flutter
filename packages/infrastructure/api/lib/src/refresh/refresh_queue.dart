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
    required this.handler,
    required this.originalResponse,
  }) : timestamp = DateTime.now();

  final RequestOptions requestOptions;
  final Completer<Response> completer;
  final ResponseInterceptorHandler handler;
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
