import 'dart:io';
import 'package:dio/dio.dart';
import 'package:domain_models/domain_models.dart';

///需要登录的异常
class NeedLogin extends HttpsException {
  NeedLogin({int code = 401, String message = '请先登录'}) : super(code, message);
}

///需要授权的异常
class NeedAuth extends HttpsException {
  NeedAuth(String message, {int code = 403, dynamic data})
      : super(code, message, data: data);
}

///网络异常统一格式类
class HttpsException implements Exception {
  final int code;
  final String message;
  final dynamic data;

  HttpsException(this.code, this.message, {this.data});

  factory HttpsException.create(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        {
          return HttpsException(-1, '请求取消');
        }
      case DioExceptionType.connectionTimeout:
        {
          return HttpsException(-1, '连接超时');
        }
      case DioExceptionType.sendTimeout:
        {
          return HttpsException(-1, '请求超时');
        }
      case DioExceptionType.receiveTimeout:
        {
          return HttpsException(-1, '响应超时');
        }
      case DioExceptionType.badResponse:
        {
          // logD('error.response.statusCode ： ${error.response!.statusCode}');
          try {
            final errCode = error.response!.statusCode;
            switch (errCode) {
              case 400:
                {
                  return HttpsException(errCode!, '请求语法错误');
                }
              case 401:
                {
                  return HttpsException(errCode!, '没有权限');
                }
              case 403:
                {
                  return HttpsException(errCode!, '服务器拒绝执行');
                }
              case 404:
                {
                  return HttpsException(errCode!, '无法连接服务器');
                }
              case 405:
                {
                  return HttpsException(errCode!, '请求方法被禁止');
                }
              case 500:
                {
                  return HttpsException(errCode!, '服务器内部错误');
                }
              case 502:
                {
                  return HttpsException(errCode!, '无效的请求');
                }
              case 503:
                {
                  return HttpsException(errCode!, '服务器挂了');
                }
              case 505:
                {
                  return HttpsException(errCode!, '不支持HTTP协议请求');
                }
              default:
                {
                  return HttpsException(
                      errCode!, error.response!.statusMessage!);
                }
            }
          } on Exception catch (_) {
            return HttpsException(-1, '未知错误');
          }
        }
      default:
        {
          if (error.message != null) {
            return HttpsException(-1, error.message ?? '');
          } else if (error.error is SocketException) {
            return HttpsException(-1, (error.error as SocketException).message);
          } else {
            return HttpsException(-1, error.response?.statusMessage ?? '');
          }
        }
    }
  }

  int get exceptionCode {
    return (data != null && data is Map) ? data['code'] ?? -1 : code;
  }
}

/// HttpsException 扩展 - 转换为 DomainException
/// 用于 HttpManager.fireInternal() 内部转换
/// Phase 2重构：使用ErrorCode枚举
extension HttpsExceptionExtension on HttpsException {
  /// 转换为 DomainException
  /// HTTP状态码映射到ErrorCode
  DomainException toDomainException() {
    final errorCode = _mapToErrorCode(this.code);
    return DomainException(
      errorCode,
      httpCode: this.code,
      rawData: this.data as Map<String, dynamic>?,
    );
  }

  /// HTTP状态码映射到ErrorCode
  static ErrorCode _mapToErrorCode(int code) {
    if (code == 401) return ErrorCode.unauthorized;
    if (code == 403) return ErrorCode.forbidden;
    if (code == 404) return ErrorCode.notFound;
    if (code == 500 || code == 502 || code == 503 || code == 505) {
      return ErrorCode.serverError;
    }
    return ErrorCode.unknown;
  }
}
