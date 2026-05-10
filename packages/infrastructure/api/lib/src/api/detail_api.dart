import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:api/src/models/detail_data.dart';

part 'detail_api.g.dart';

@RestApi(baseUrl: '')
abstract class DetailApi {
  factory DetailApi(Dio dio) = _DetailApi;

  @GET('/detail/{id}')
  Future<DetailData> getDetailData(@Path('id') String id);

}
