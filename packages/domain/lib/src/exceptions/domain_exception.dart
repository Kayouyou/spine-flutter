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

  /// Token 已失效，需重新登录（对应后端 code 1000103）
  tokenInvalid,

  /// 禁止访问（403）
  forbidden,

  /// 资源不存在（404）
  notFound,

  /// 服务器错误（500）
  serverError,

  /// 输入参数无效（400/422）
  invalidInput,

  /// 资源冲突（409）
  conflict,

  /// 请求频率超限（429）
  rateLimited,

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

/// 资源冲突 — 对应 HTTP 409
///
/// 典型场景：用户名已存在、订单状态冲突等
class ConflictException extends DomainException {
  const ConflictException() : super('资源冲突');
}

/// 请求频率超限 — 对应 HTTP 429
///
/// 典型场景：短时间内请求过多，触发限流
class RateLimitedException extends DomainException {
  const RateLimitedException() : super('请求过于频繁，请稍后再试');
}

/// 业务层错误 — 后端在成功 HTTP 响应（200）中返回的非 0 业务码
///
/// 与基础设施层错误（网络/HTTP 状态）区分：业务错误表示“请求已到达服务端且被处理，
/// 但业务逻辑判定为失败”（如参数校验不通过、余额不足、业务状态冲突等）。
///
/// 由 [ResponseEnvelopeInterceptor] 在检测到 `{code, message, data}` 信封结构且 code != 0
/// （且非续期码 1000102）时抛出，经 [DioExceptionMapper.toDomainException] 短路原样透传，
/// 最终被 [FutureResult.toResult] 收口为 `Result.failure`。
class BusinessException extends DomainException {
  /// 后端业务码（如 1000102 为续期码、其它为非 0 业务错误码）
  final int code;

  const BusinessException(this.code, String message) : super(message);
}
