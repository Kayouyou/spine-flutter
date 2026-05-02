import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'home_repository.dart';

/// 首页数据仓库实现
///
/// 职责：从API获取首页数据，处理异常转换
/// 使用：通过DI获取 `sl<HomeRepository>()`
/// 异常处理：DioException转换为DomainException
class HomeRepositoryImpl implements HomeRepository {
  /// API客户端
  final Api _api;

  HomeRepositoryImpl(this._api);

  @override
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      // 调用API获取首页数据
      final response = await _api.httpManager.get('/home/data').fire();
      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      // 转换为DomainException
      throw e.toDomainException();
    }
  }

  @override
  Future<Map<String, dynamic>> refreshHomeData() async {
    try {
      // 强制刷新，不使用缓存
      final response = await _api.httpManager.get('/home/data').fire();
      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }
}