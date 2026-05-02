import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'detail_repository.dart';

/// 详情数据仓库实现
///
/// 职责：从API获取详情数据
class DetailRepositoryImpl implements DetailRepository {
  final Api _api;

  DetailRepositoryImpl(this._api);

  @override
  Future<Map<String, dynamic>> getDetailData(String id) async {
    try {
      final response = await _api.httpManager.get('/detail/$id').fire();
      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }
}