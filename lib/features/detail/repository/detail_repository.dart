/// 详情数据仓库接口
///
/// 职责：定义详情页数据获取的契约
abstract class DetailRepository {
  /// 获取详情数据
  ///
  /// 根据ID获取详情内容
  Future<Map<String, dynamic>> getDetailData(String id);
}