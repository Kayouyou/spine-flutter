import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

/// 认证业务域 API 接口
@RestApi(baseUrl: '')
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  /// 用户登录
  @POST('/User/Login/Password')
  Future<Map<String, dynamic>> login(@Body() Map<String, dynamic> body);

  /// 用户注册
  @POST('/User/Register')
  Future<Map<String, dynamic>> register(@Body() Map<String, dynamic> body);

  /// 获取用户资料
  ///
  /// [username] 用户名
  @GET('/User/{username}')
  Future<Map<String, dynamic>> getProfile(@Path('username') String username);

  /// 忘记密码
  @POST('/User/forgot_password')
  Future<Map<String, dynamic>> forgotPassword(@Body() Map<String, dynamic> body);
}
