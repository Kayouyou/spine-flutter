import '../result.dart';
import '../exceptions/domain_exception.dart';

/// 首页数据仓储接口
abstract class HomeRepository {
  /// 获取首页数据
  ///
  /// 返回 Result: Success(Map) 或 Failure(DomainException)
  Future<Result<Map<String, dynamic>, DomainException>> getHomeData();

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Result<Map<String, dynamic>, DomainException>> refreshHomeData();
}
