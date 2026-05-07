/// 首页数据仓库接口
abstract class HomeRepository {
  Future<Map<String, dynamic>> getHomeData();
  Future<Map<String, dynamic>> refreshHomeData();
}
