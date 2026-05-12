import '../models/detail_data.dart';
import '../repositories/detail_repository.dart';
import '../exceptions/domain_exception.dart';
import '../result.dart';

/// 获取详情数据用例
///
/// 编排 [DetailRepository.getDetailData]，将详情数据加载逻辑收拢到 domain 层。
class GetDetailDataUseCase {
  final DetailRepository _detailRepository;

  const GetDetailDataUseCase(this._detailRepository);

  /// 获取指定 ID 的详情数据
  Future<Result<DetailData, DomainException>> execute(String id) async {
    return _detailRepository.getDetailData(id);
  }
}
