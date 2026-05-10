import 'package:dio/dio.dart';
import 'package:api/api.dart' as api;
import 'package:domain/domain.dart';

/// 详情数据仓库实现
class DetailRepositoryImpl implements DetailRepository {
  final Dio _dio;
  late final api.DetailApi _detailApi;

  DetailRepositoryImpl(this._dio) {
    _detailApi = api.DetailApi(_dio);
  }

  @override
  Future<Result<DetailData, DomainException>> getDetailData(String id) async {
    try {
      final apiData = await _detailApi.getDetailData(id);
      return Result.success(DetailData.fromJson(apiData.toJson()));
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }
}
