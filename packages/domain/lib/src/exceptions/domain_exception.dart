/// 错误码枚举
///
/// 职责：统一定义所有业务错误类型，用于错误处理和国际化
/// 使用：DomainException.errorCode获取具体错误类型
/// 国际化：每个errorCode.name对应ARB文件中的key
enum ErrorCode {
  /// 网络连接失败
  networkError,

  /// 请求被取消
  requestCancelled,

  /// 连接超时
  connectionTimeout,

  /// 未授权（401）
  unauthorized,

  /// Token已过期
  tokenExpired,

  /// 禁止访问（403）
  forbidden,

  /// 资源不存在（404）
  notFound,

  /// 服务器错误（500）
  serverError,

  /// 输入参数无效
  invalidInput,

  /// 未知错误
  unknown,
}

/// 领域层统一异常基类
///
/// 所有 domain 层异常继承自此，UI 层可统一处理。
/// 使用 sealed class 保证穷尽性模式匹配。
sealed class DomainException implements Exception {
  /// 人类可读的错误信息
  final String message;

  const DomainException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// 网络或服务端错误 — 多数情况可重试
class NetworkException extends DomainException {
  /// HTTP 状态码（如果有）
  final int? statusCode;

  const NetworkException(super.message, {this.statusCode});
}

/// 认证令牌过期 — 需重新登录
class UnauthorizedException extends DomainException {
  const UnauthorizedException() : super('认证已过期');
}

/// 请求的资源不存在 — 对应 HTTP 404
class NotFoundException extends DomainException {
  const NotFoundException() : super('请求的资源不存在');
}

/// 客户端校验失败 — 携带各字段错误信息
class ValidationException extends DomainException {
  /// 字段名 → 错误信息的映射
  final Map<String, String> fieldErrors;

  const ValidationException(super.message, {this.fieldErrors = const {}});
}
