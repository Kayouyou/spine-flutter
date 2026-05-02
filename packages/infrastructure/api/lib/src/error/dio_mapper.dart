import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

/// DioException到DomainException的映射扩展
///
/// 职责：将Dio底层异常转换为业务层统一的DomainException
/// 使用：dioException.toDomainException()
/// 注意：在API层catch DioException后立即转换
extension DioExceptionMapper on DioException {
  /// 转换为DomainException
  ///
  /// 根据DioException类型和HTTP状态码映射到对应ErrorCode
  /// HTTP状态码优先，DioException类型其次
  DomainException toDomainException() {
    final errorCode = _mapErrorCode(type, response?.statusCode);
    final statusCode = response?.statusCode;

    switch (errorCode) {
      case ErrorCode.unauthorized:
        return const UnauthorizedException();
      case ErrorCode.forbidden:
        return NetworkException('禁止访问', statusCode: statusCode);
      case ErrorCode.notFound:
        return const NotFoundException();
      case ErrorCode.serverError:
        return NetworkException('服务器错误', statusCode: statusCode);
      case ErrorCode.requestCancelled:
        return NetworkException('请求已取消');
      case ErrorCode.connectionTimeout:
        return NetworkException('连接超时', statusCode: statusCode);
      case ErrorCode.networkError:
        return NetworkException('网络连接失败', statusCode: statusCode);
      case ErrorCode.tokenExpired:
        return const UnauthorizedException();
      case ErrorCode.invalidInput:
        return ValidationException('无效的输入');
      case ErrorCode.unknown:
        return NetworkException('未知错误', statusCode: statusCode);
    }
  }

  /// 映射ErrorCode
  ///
  /// 优先使用HTTP状态码映射，其次使用DioException类型
  static ErrorCode _mapErrorCode(DioExceptionType type, int? statusCode) {
    // HTTP状态码优先
    if (statusCode != null) {
      return _statusCodeMap[statusCode] ?? ErrorCode.serverError;
    }
    // DioException类型其次
    return _typeMap[type] ?? ErrorCode.unknown;
  }

  /// HTTP状态码映射表
  ///
  /// 常见HTTP错误码对应业务ErrorCode
  static const Map<int, ErrorCode> _statusCodeMap = {
    401: ErrorCode.unauthorized,
    403: ErrorCode.forbidden,
    404: ErrorCode.notFound,
    500: ErrorCode.serverError,
  };

  /// DioException类型映射表
  ///
  /// Dio底层错误类型对应业务ErrorCode
  static const Map<DioExceptionType, ErrorCode> _typeMap = {
    DioExceptionType.cancel: ErrorCode.requestCancelled,
    DioExceptionType.connectionTimeout: ErrorCode.connectionTimeout,
    DioExceptionType.sendTimeout: ErrorCode.connectionTimeout,
    DioExceptionType.receiveTimeout: ErrorCode.connectionTimeout,
    DioExceptionType.connectionError: ErrorCode.networkError,
  };
}