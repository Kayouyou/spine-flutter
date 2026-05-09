import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'detail_api.g.dart';

/// 详情页业务域 API 接口
@RestApi(baseUrl: '')
abstract class DetailApi {
  factory DetailApi(Dio dio) = _DetailApi;

  /// 获取详情数据
  ///
  /// [id] 详情项 ID
  @GET('/detail/{id}')
  Future<Map<String, dynamic>> getDetailData(@Path('id') String id);
}
