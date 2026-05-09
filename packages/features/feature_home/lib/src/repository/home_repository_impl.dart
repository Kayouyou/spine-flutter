import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:list_cache/list_cache.dart';

/// 首页数据仓库实现
///
/// 职责：从API获取首页数据，处理异常转换，使用缓存优先策略
/// 使用：通过DI获取 `sl<HomeRepository>()`
/// 异常处理：DioException转换为DomainException，返回Result类型
/// 缓存策略：staleWhileRevalidate（先缓存后网络，后台静默刷新）
class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;
  final ListCacheManager<Map<String, dynamic>> _cacheManager;

  HomeRepositoryImpl(this._dio)
      : _cacheManager = ListCacheManager<Map<String, dynamic>>(
          config: CacheConfig.staleWhileRevalidate(pageSize: 20),
        );

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getHomeData() async {
    try {
      final result = await _cacheManager.fetch(
        cacheKey: 'home_data',
        page: 1,
        networkFetcher: () async {
          final response = await _dio.get(ApiEndpoints.home.data);
          return [response.data as Map<String, dynamic>];
        },
      );
      if (result.data.isNotEmpty) {
        return Result.success(result.data.first);
      }
      return Result.success({});
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> refreshHomeData() async {
    await _cacheManager.clear('home_data');
    return getHomeData();
  }

  /// 清空首页缓存
  Future<void> clearCache() => _cacheManager.clear('home_data');
}