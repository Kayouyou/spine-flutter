import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';

/// 详情数据仓库实现
///
/// 职责：从API获取详情数据，返回Result类型处理成功和异常
/// 异常处理：DioException转换为DomainException
class DetailRepositoryImpl implements DetailRepository {
  final Dio _dio;

  DetailRepositoryImpl(this._dio);

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getDetailData(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.detail.item(id));
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }
}