import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'vehicle_api.g.dart';

/// 车辆业务域 API 接口
@RestApi(baseUrl: '')
abstract class VehicleApi {
  factory VehicleApi(Dio dio) = _VehicleApi;

  /// 获取车辆列表
  @GET('/Vehicle/List')
  Future<Map<String, dynamic>> getVehicleList();

  /// 获取车辆详情
  @GET('/Vehicle/Detail/Info')
  Future<Map<String, dynamic>> getVehicleDetail();

  /// 获取车辆排行榜
  @GET('/Vehicle/Ranking/Query/Top/Info')
  Future<Map<String, dynamic>> getVehicleRanking();
}
