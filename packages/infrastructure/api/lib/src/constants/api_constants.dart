/// API 常量（基础设施级别，不属于业务域）
///
/// Token Renewal 路径保留在这里，因为它是基础设施共享端点，
/// 不属于任何业务域的 Retrofit 接口。
library;

abstract final class ApiConstants {
  /// Token 续期路径（基础设施共享端点）
  static const String tokenRenewal = '/User/Token/Renewal';
}
