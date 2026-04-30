import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../api.dart';

class RetryInterceptor extends Interceptor {
  final Dio apiClient;

  RetryInterceptor({required this.apiClient});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    var retryCount = err.requestOptions.extra["retry_count"] ?? 0;
    err.requestOptions.extra["retry_count"] = retryCount + 1;

    if (canRetry(err) && retryCount <= HttpConstant.Retry_Max_Count) {
      if (kDebugMode) {
        debugPrint('******************开始执行 retry request******************');
      }
      // connection timeout retry
      var requestOptions = err.requestOptions;
      Options options = Options(
        method: requestOptions.method,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: requestOptions.extra,
        headers: requestOptions.headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
        requestEncoder: requestOptions.requestEncoder,
        responseDecoder: requestOptions.responseDecoder,
        listFormat: requestOptions.listFormat,
      );
      // err.requestOptions

      await Future.delayed(const Duration(seconds: 1));
      return await apiClient
          .request(
            requestOptions.path,
            cancelToken: requestOptions.cancelToken,
            data: requestOptions.data,
            onReceiveProgress: requestOptions.onReceiveProgress,
            options: options,
            onSendProgress: requestOptions.onSendProgress,
            queryParameters: requestOptions.queryParameters,
          )
          .then(handler.resolve,
              onError: (error) => handler
                  .reject(err.copyWith(error: HttpsException.create(err))));
    }

    handler.next(err);
  }
}

bool canRetry(DioException exception) {
  // if (kDebugMode) {
  //   return true;
  // }

  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
      {
        return true;
      }
    case DioExceptionType.sendTimeout:
      {
        return true;
      }
    case DioExceptionType.receiveTimeout:
      {
        return true;
      }
    default:
      {
        return false;
      }
  }
}
