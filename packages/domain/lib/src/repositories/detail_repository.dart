import '../result.dart';
import '../exceptions/domain_exception.dart';
import '../models/detail_data.dart';

/// 详情数据仓储接口
abstract class DetailRepository {
  /// 获取详情数据
  Future<Result<DetailData, DomainException>> getDetailData(String id);
}
