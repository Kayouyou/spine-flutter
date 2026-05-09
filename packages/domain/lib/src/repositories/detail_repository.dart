import '../result.dart';
import '../exceptions/domain_exception.dart';

/// 详情数据仓储接口
abstract class DetailRepository {
  /// 获取详情数据
  ///
  /// 返回 Result: Success(Map) 或 Failure(DomainException)
  Future<Result<Map<String, dynamic>, DomainException>> getDetailData(String id);
}
