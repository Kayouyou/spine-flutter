import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:api/src/models/home_data.dart';

part 'home_api.g.dart';

@RestApi(baseUrl: '')
abstract class HomeApi {
  factory HomeApi(Dio dio) = _HomeApi;

  @GET('/home/data')
  Future<HomeData> getHomeData();

}
