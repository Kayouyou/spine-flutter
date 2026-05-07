/// 详情数据仓库接口
abstract class DetailRepository {
  Future<Map<String, dynamic>> getDetailData(String id);
}
