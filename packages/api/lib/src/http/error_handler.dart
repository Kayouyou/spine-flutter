import 'dart:io';
import 'package:dio/dio.dart';
import 'http_error.dart';
import 'http_constant.dart';
import 'dart:convert';
import 'http_event_bus.dart';

/// 统一的错误处理器
/// 用于处理网络错误、Dio错误和业务逻辑错误
class ErrorHandler {
  /// 处理所有类型的错误并转换为HttpsException
  static HttpsException handleError(dynamic error,
      {dynamic response, dynamic data}) {
    // 1. 网络连接错误
    if (error is SocketException || error is OSError) {
      return HttpsException(HttpConstant.NetworkErrorCode, '网络异常', data: data);
    }

    // 1.1 增加超时错误特殊处理
    if (error is DioException &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout)) {
      return HttpsException(HttpConstant.NetworkErrorCode, '网络请求超时，请检查网络连接',
          data: data);
    }

    // 2. Dio错误
    if (error is DioException) {
      return HttpsException.create(error);
    }

    // 3. 业务逻辑错误(如果response包含code和message)
    if (response != null) {
      try {
        if (response is String) {
          // 3.1 尝试解析响应字符串为JSON
          try {
            final Map<String, dynamic> mapData = jsonDecode(response);
            // 确保code字段存在
            if (mapData.containsKey('code')) {
              final code = mapData['code'];
              final message = mapData['message'] ?? '未知错误';

              // token无法续期必须退出登录
              if (code == HttpConstant.reLoginCode) {
                HttpEventBus.instance.commit(EventKeys.logout);
              }

              if (code != 0 && code != 200) {
                return HttpsException(code, message, data: mapData);
              }
            }
          } catch (jsonError) {
            // JSON解析错误，返回格式错误异常
            return HttpsException(
                HttpConstant.UnknownErrorCode, '响应格式错误: $jsonError',
                data: response);
          }
        } else if (response is Map) {
          // 3.2 直接使用Map响应，确保code字段存在
          if (response.containsKey('code')) {
            final code = response['code'];
            // 确保code不为null
            if (code != null) {
              final message = response['message'] ?? '未知错误';

              // token无法续期必须退出登录
              if (code == HttpConstant.reLoginCode) {
                HttpEventBus.instance.commit(EventKeys.logout);
              }

              if (code != 0 && code != 200) {
                return HttpsException(code, message, data: response);
              }
            }
          }
        } else if (response is Response) {
          // 3.3 处理Dio Response对象
          final statusCode =
              response.statusCode ?? HttpConstant.UnknownErrorCode;

          // 处理非200状态码
          if (statusCode != 200) {
            return HttpsException(
                statusCode, '服务器错误: ${response.statusMessage ?? '未知错误'}',
                data: response.data);
          }

          // 处理responseData
          try {
            final responseData = response.data;
            if (responseData is Map && responseData.containsKey('code')) {
              final code = responseData['code'];
              if (code != null) {
                final message = responseData['message'] ?? '未知错误';

                if (code == HttpConstant.reLoginCode) {
                  HttpEventBus.instance.commit(EventKeys.logout);
                }

                if (code != 0 && code != 200) {
                  return HttpsException(code, message, data: responseData);
                }
              }
            }
          } catch (e) {
            // Response数据处理错误
            return HttpsException(statusCode, '响应处理错误: ${e.toString()}',
                data: data);
          }
        }
      } catch (e) {
        // 响应处理通用错误
        return HttpsException(
            HttpConstant.UnknownErrorCode, '响应处理错误: ${e.toString()}',
            data: data);
      }
    }

    // 4. 其他未知错误
    String errorMessage = _getErrorMessage(error);
    return HttpsException(HttpConstant.UnknownErrorCode, errorMessage,
        data: data);
  }

  /// 安全获取错误消息
  static String _getErrorMessage(dynamic error) {
    try {
      if (error is String) {
        return error;
      } else if (error is Exception || error is Error) {
        return error.toString();
      } else if (error != null) {
        try {
          return error.message ?? error.toString();
        } catch (_) {
          return error.toString();
        }
      } else {
        return '未知错误';
      }
    } catch (_) {
      return '未知错误';
    }
  }
}
