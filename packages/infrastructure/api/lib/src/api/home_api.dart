import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'home_api.g.dart';

/// 首页业务域 API 接口
///
/// 使用 @RestApi(baseUrl: '') 让运行时使用 dio.options.baseUrl。
/// 路径定义在注解中：@GET('/home/data')
@RestApi(baseUrl: '')
abstract class HomeApi {
  /// 创建 HomeApi 实例
  ///
  /// [dio] 必须是已经配置好拦截器的 Dio 实例。
  factory HomeApi(Dio dio) = _HomeApi;

  /// 获取首页数据
  @GET('/home/data')
  Future<Map<String, dynamic>> getHomeData();
}
