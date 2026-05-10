import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:api/src/models/vehicle_data.dart';

part 'vehicle_api.g.dart';

@RestApi(baseUrl: '')
abstract class VehicleApi {
  factory VehicleApi(Dio dio) = _VehicleApi;

  @GET('/Vehicle/List')
  Future<VehicleData> getVehicleList();

  @GET('/Vehicle/Detail/Info')
  Future<VehicleData> getVehicleDetail();

  @GET('/Vehicle/Ranking/Query/Top/Info')
  Future<VehicleData> getVehicleRanking();

}
