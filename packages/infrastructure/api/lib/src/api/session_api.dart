import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'session_api.g.dart';

/// Session 业务域 API 接口
@RestApi(baseUrl: '')
abstract class SessionApi {
  factory SessionApi(Dio dio) = _SessionApi;

  /// 签到（Session 登录）
  @POST('/session')
  Future<Map<String, dynamic>> signIn(@Body() Map<String, dynamic> body);

  /// 签退（Session 登出）
  @DELETE('/session')
  Future<Map<String, dynamic>> signOut();
}
