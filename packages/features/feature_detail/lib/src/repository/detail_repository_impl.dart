import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';

/// 详情数据仓库实现
///
/// 职责：从API获取详情数据
/// Retrofit 迁移：使用 DetailApi 替代直接 Dio 调用
class DetailRepositoryImpl implements DetailRepository {
  final Dio _dio;
  late final DetailApi _detailApi;

  DetailRepositoryImpl(this._dio) {
    _detailApi = DetailApi(_dio);
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getDetailData(String id) async {
    try {
      final response = await _detailApi.getDetailData(id);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }
}