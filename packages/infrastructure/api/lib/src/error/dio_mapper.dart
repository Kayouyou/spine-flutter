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
    return DomainException(
      errorCode,
      httpCode: response?.statusCode,
      rawData: response?.data as Map<String, dynamic>?,
    );
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