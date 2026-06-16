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
      case ErrorCode.invalidInput:
        return const ValidationException('无效的输入');
      case ErrorCode.conflict:
        return const ConflictException();
      case ErrorCode.rateLimited:
        return const RateLimitedException();
      case ErrorCode.serverError:
        return NetworkException('服务器错误', statusCode: statusCode);
      case ErrorCode.requestCancelled:
        return const NetworkException('请求已取消');
      case ErrorCode.connectionTimeout:
        return NetworkException('连接超时', statusCode: statusCode);
      case ErrorCode.networkError:
        return NetworkException('网络连接失败', statusCode: statusCode);
      case ErrorCode.tokenExpired:
      case ErrorCode.tokenInvalid:
        return const UnauthorizedException();
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
    // 4xx 客户端错误
    400: ErrorCode.invalidInput, // Bad Request - 请求参数错误
    401: ErrorCode.unauthorized, // Unauthorized - 未认证
    403: ErrorCode.forbidden, // Forbidden - 无权限
    404: ErrorCode.notFound, // Not Found - 资源不存在
    409: ErrorCode.conflict, // Conflict - 资源冲突
    422: ErrorCode.invalidInput, // Unprocessable Entity - 请求格式正确但语义错误
    429: ErrorCode.rateLimited, // Too Many Requests - 请求频率超限
    
    // 5xx 服务端错误
    500: ErrorCode.serverError, // Internal Server Error
    502: ErrorCode.serverError, // Bad Gateway
    503: ErrorCode.serverError, // Service Unavailable
    504: ErrorCode.serverError, // Gateway Timeout
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