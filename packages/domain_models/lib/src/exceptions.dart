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

/// 域异常
///
/// 职责：统一应用层异常，携带ErrorCode用于国际化错误消息
/// 使用：
///   - API层抛出：throw DomainException(ErrorCode.networkError)
///   - UI层处理：exception.getMessage(context)获取本地化消息
/// 注意：所有业务异常都应转换为DomainException
class DomainException implements Exception {
  /// 错误码
  final ErrorCode errorCode;

  /// HTTP状态码（可选）
  final int? httpCode;

  /// 原始响应数据（可选，用于调试）
  final Map<String, dynamic>? rawData;

  /// 构造函数
  ///
  /// 参数：
  /// - errorCode: 错误码枚举
  /// - httpCode: HTTP状态码（可选）
  /// - rawData: 原始响应数据（可选）
  DomainException(
    this.errorCode,
    {
      this.httpCode,
      this.rawData,
    }
  );

  /// 获取本地化错误消息
  ///
  /// 使用errorCode.name作为ARB key查找国际化文本
  /// 示例：ErrorCode.networkError → ARB key "networkError"
  ///
  /// 注意：需要BuildContext获取AppLocalizations
  /// ARB文件必须包含所有ErrorCode.name对应的key
  ///
  /// 完整实现需要：
  /// 1. flutter gen-l10n生成AppLocalizations
  /// 2. MaterialApp配置localizationsDelegates
  /// 3. 通过BuildContext获取AppLocalizations实例
  ///
  /// 当前返回errorCode.name作为占位
  /// 完整实现后改为AppLocalizations.of(context)!.translate(errorCode.name)
  String getMessage() {
    // 占位实现：返回errorCode名称
    return errorCode.name;
  }

  @override
  String toString() {
    return 'DomainException: ${errorCode.name} (http: $httpCode)';
  }
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