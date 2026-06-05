import 'package:dio/dio.dart';
import 'package:api/api.dart' as api;
import 'package:domain/domain.dart';
import 'package:list_cache/list_cache.dart';

class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;
  final ListCacheManager<HomeData> _cacheManager;
  late final api.HomeApi _homeApi;

  HomeRepositoryImpl(this._dio)
      : _cacheManager = ListCacheManager<HomeData>(
          config: CacheConfig.staleWhileRevalidate(),
        ) {
    _homeApi = api.HomeApi(_dio);
  }

  @override
  Future<Result<HomeData, DomainException>> getHomeData() async {
    try {
      final result = await _cacheManager.fetch(
        cacheKey: 'home_data',
        page: 1,
        networkFetcher: () async {
          final apiData = await _homeApi.getHomeData();
          return [HomeData.fromJson(apiData.toJson())];
        },
      );
      if (result.data.isNotEmpty) {
        return Result.success(result.data.first);
      }
      return Result.failure(const NetworkException('No data'));
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }

  @override
  Future<Result<HomeData, DomainException>> refreshHomeData() async {
    await _cacheManager.clear('home_data');
    return getHomeData();
  }

  Future<void> clearCache() => _cacheManager.clear('home_data');
}
