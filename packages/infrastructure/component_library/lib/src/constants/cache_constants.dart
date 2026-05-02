/// 缓存配置常量
class CacheConstants {
  CacheConstants._();

  /// 默认缓存过期时间
  static const Duration defaultTTL = Duration(hours: 24);

  /// 列表缓存最大条数
  static const int maxListSize = 100;

  /// 用户信息缓存过期时间
  static const Duration userTTL = Duration(days: 7);

  /// 配置数据缓存过期时间
  static const Duration configTTL = Duration(hours: 1);
}