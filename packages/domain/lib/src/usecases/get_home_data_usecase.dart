import '../models/home_data.dart';
import '../repositories/home_repository.dart';
import '../exceptions/domain_exception.dart';
import '../result.dart';

/// 获取首页数据用例
///
/// 编排 [HomeRepository.getHomeData]，将首页数据加载逻辑收拢到 domain 层。
class GetHomeDataUseCase {
  final HomeRepository _homeRepository;

  const GetHomeDataUseCase(this._homeRepository);

  /// 获取首页数据
  Future<Result<HomeData, DomainException>> execute() async {
    return _homeRepository.getHomeData();
  }
}
