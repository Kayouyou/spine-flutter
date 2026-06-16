import 'package:dio/dio.dart';

/// 网络延迟监控拦截器
///
/// 记录每次 HTTP 请求的延迟，用于网络质量评估。
/// 延迟数据通过 [onLatencyRecord] 回调传递给 NetworkCubit。
///
/// 拦截器链位置：放在最后，只统计实际网络耗时（不含其他拦截器处理时间）。
class LatencyMonitorInterceptor extends Interceptor {
  final void Function(int latencyMs) onLatencyRecord;
  final Map<RequestOptions, int> _requestTimestamps = {};

  LatencyMonitorInterceptor({required this.onLatencyRecord});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTimestamps[options] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _recordLatency(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordLatency(err.requestOptions);
    handler.next(err);
  }

  void _recordLatency(RequestOptions options) {
    final startTime = _requestTimestamps.remove(options);
    if (startTime != null) {
      final latencyMs = DateTime.now().millisecondsSinceEpoch - startTime;
      onLatencyRecord(latencyMs);
    }
  }
}
