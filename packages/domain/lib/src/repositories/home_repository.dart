import '../result.dart';
import '../exceptions/domain_exception.dart';
import '../models/home_data.dart';

/// 首页数据仓储接口
abstract class HomeRepository {
  /// 获取首页数据
  Future<Result<HomeData, DomainException>> getHomeData();

  /// 刷新首页数据
  Future<Result<HomeData, DomainException>> refreshHomeData();
}
