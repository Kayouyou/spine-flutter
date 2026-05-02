/// 首页数据仓库接口
///
/// 职责：定义首页数据获取的契约
/// 使用：RepositoryImpl实现，Cubit通过接口调用
/// 好处：便于测试Mock和未来替换实现
abstract class HomeRepository {
  /// 获取首页数据
  ///
  /// 返回首页展示所需的数据
  /// 失败时抛出DomainException
  Future<Map<String, dynamic>> getHomeData();

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Map<String, dynamic>> refreshHomeData();
}