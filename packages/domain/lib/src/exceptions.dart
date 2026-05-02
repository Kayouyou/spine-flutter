export 'exceptions/domain_exception.dart';

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

// ===== 兼容旧代码的异常类（逐步废弃） =====

/// 用户名未注册异常
@Deprecated('Use DomainException with ErrorCode.unauthorized')
class UserNameIsNotRegisterException implements Exception {}

/// 用户名已注册异常
@Deprecated('Use DomainException with ErrorCode.invalidInput')
class UserNameIsRegisterException implements Exception {}

/// 无效凭证异常
@Deprecated('Use DomainException with ErrorCode.unauthorized')
class InvalidCredentialsException implements Exception {
  final int code;
  final String message;
  InvalidCredentialsException(this.code, this.message);
}

/// 空搜索结果异常
@Deprecated('Use DomainException with ErrorCode.notFound')
class EmptySearchResultException implements Exception {}

/// 需要用户认证异常
@Deprecated('Use DomainException with ErrorCode.unauthorized')
class UserAuthenticationRequiredException implements Exception {}

/// 用户名已被占用异常
@Deprecated('Use DomainException with ErrorCode.invalidInput')
class UsernameAlreadyTakenException implements Exception {}

/// 邮箱已注册异常
@Deprecated('Use DomainException with ErrorCode.invalidInput')
class EmailAlreadyRegisteredException implements Exception {}