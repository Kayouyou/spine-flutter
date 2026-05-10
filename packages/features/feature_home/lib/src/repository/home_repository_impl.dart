import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:list_cache/list_cache.dart';

/// 首页数据仓库实现
///
/// 职责：从API获取首页数据，使用缓存优先策略
/// 使用：通过DI获取 `sl<HomeRepository>()`
/// 异常处理：DioException转换为DomainException，返回Result类型
/// 缓存策略：staleWhileRevalidate（先缓存后网络，后台静默刷新）
/// 
/// Retrofit 迁移：使用 HomeApi 替代直接 Dio 调用
///  Typed API 返回 HomeData，这里转换为 Map<String, dynamic> 以保持接口兼容
class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;
  final ListCacheManager<Map<String, dynamic>> _cacheManager;
  late final HomeApi _homeApi;

  HomeRepositoryImpl(this._dio)
      : _cacheManager = ListCacheManager<Map<String, dynamic>>(
          config: CacheConfig.staleWhileRevalidate(pageSize: 20),
        ) {
    // Retrofit 使用同一个 Dio 实例，继承所有拦截器
    _homeApi = HomeApi(_dio);
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getHomeData() async {
    try {
      final result = await _cacheManager.fetch(
        cacheKey: 'home_data',
        page: 1,
        networkFetcher: () async {
          final response = await _homeApi.getHomeData();
          // Convert typed HomeData to Map for domain interface compatibility
          return [response.toJson()];
        },
      );
      if (result.data.isNotEmpty) {
        return Result.success(result.data.first);
      }
      return Result.success(<String, dynamic>{});
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
