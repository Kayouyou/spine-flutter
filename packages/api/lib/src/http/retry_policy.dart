import 'package:dio/dio.dart';

/// 重试策略
///
/// 职责：定义请求失败时的重试行为
/// 使用：
///   - 配置maxRetries设置最大重试次数
///   - 配置retryableTypes设置可重试的错误类型
///   - 配置retryableStatusCodes设置可重试的HTTP状态码
/// 预定义策略：
///   - none: 不重试
///   - standard: 标准3次重试
///   - aggressive: 激进5次重试
class RetryPolicy {
  /// 最大重试次数
  final int maxRetries;

  /// 重试间隔时间
  final Duration retryDelay;

  /// 可重试的Dio异常类型
  final List<DioExceptionType> retryableTypes;

  /// 可重试的HTTP状态码
  final List<int> retryableStatusCodes;

  /// 构造重试策略
  ///
  /// 参数：
  /// - maxRetries: 最大重试次数（默认0，不重试）
  /// - retryDelay: 重试间隔（默认1秒）
  /// - retryableTypes: 可重试的异常类型（默认超时类型）
  /// - retryableStatusCodes: 可重试的状态码（默认502, 503, 504）
  const RetryPolicy({
    this.maxRetries = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.retryableTypes = const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ],
    this.retryableStatusCodes = const [502, 503, 504],
  });

  /// 无重试策略
  ///
  /// 默认行为，请求失败直接返回错误
  static const RetryPolicy none = RetryPolicy();

  /// 标准重试策略
  ///
  /// 最大3次重试，适合一般网络不稳定场景
  static const RetryPolicy standard = RetryPolicy(maxRetries: 3);

  /// 激进重试策略
  ///
  /// 最大5次重试，间隔500ms，包含500状态码
  /// 适合高可用要求的场景
  static const RetryPolicy aggressive = RetryPolicy(
    maxRetries: 5,
    retryDelay: Duration(milliseconds: 500),
    retryableStatusCodes: [500, 502, 503, 504],
  );

  /// 判断是否应该重试
  ///
  /// 参数：
  /// - error: Dio异常对象
  /// - retryCount: 当前已重试次数
  ///
  /// 返回：true表示应该重试，false表示不应重试
  bool shouldRetry(DioException error, int retryCount) {
    // 已达到最大重试次数，不再重试
    if (retryCount >= maxRetries) return false;

    // 异常类型匹配，可以重试
    if (retryableTypes.contains(error.type)) return true;

    // HTTP状态码匹配，可以重试
    final statusCode = error.response?.statusCode;
    if (statusCode != null && retryableStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  /// 获取重试延迟时间
  ///
  /// 参数：
  /// - retryCount: 当前重试次数
  ///
  /// 返回：延迟时间Duration
  ///
  /// 注意：当前实现返回固定延迟，可扩展为指数退避
  Duration getRetryDelay(int retryCount) => retryDelay;
}