import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 日志上报拦截器
/// 用于错误日志上报、请求性能埋点等功能
class LogReportingInterceptor extends Interceptor {
  LogReportingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 记录请求开始时间用于性能指标
    options.extra['requestStartTime'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // 计算请求耗时
      _reportPerformanceMetrics(response);

      // 检查业务逻辑错误并上报
      if (response.data is Map && response.data['code'] != null) {
        final code = response.data['code'];
        if (code != 0 && code != 200) {
          _reportBusinessError(response.data);
        }
      }
    } catch (e) {
      debugPrint('LogReportingInterceptor.onResponse error: $e');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      _reportDioError(err);
    } catch (e) {
      debugPrint('LogReportingInterceptor.onError error: $e');
    }

    handler.next(err);
  }

  /// 上报Dio错误
  void _reportDioError(DioException error) {
    // 实际的错误上报逻辑，后期可能会与服务器API集成
    final errorType = error.type.toString();
    final errorMessage = error.message ?? '';
    final requestPath = error.requestOptions.path;

    debugPrint('API错误上报: [$errorType] $requestPath - $errorMessage');

    // 实现实际的错误上报逻辑
    // 例如:
    // 1. 发送到日志服务器
    // 2. 保存到本地数据库以便稍后上传
    // 3. 集成第三方日志服务
  }

  /// 上报业务逻辑错误
  void _reportBusinessError(Map<String, dynamic> data) {
    final code = data['code'];
    final message = data['message'] ?? '未知错误';

    debugPrint('业务错误上报: [code:$code] $message');

    // 实现业务错误上报逻辑
  }

  /// 上报性能指标
  void _reportPerformanceMetrics(Response response) {
    final startTime = response.requestOptions.extra['requestStartTime'];
    if (startTime != null) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      final path = response.requestOptions.path;
      final method = response.requestOptions.method;

      debugPrint('性能埋点: [$method] $path - ${duration}ms');

      // 实现性能指标上报逻辑
    }
  }
}
