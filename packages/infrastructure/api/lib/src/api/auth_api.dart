import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:api/src/models/login_response.dart';
import 'package:api/src/models/login_request.dart';
import 'package:api/src/models/user_profile.dart';

part 'auth_api.g.dart';

@RestApi(baseUrl: '')
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('/User/Login/Password')
  Future<LoginResponse> login(@Body() LoginRequest body);

  @POST('/User/Register')
  Future<LoginResponse> register(@Body() LoginRequest body);

  @GET('/User/{username}')
  Future<UserProfile> getProfile(@Path('username') String username);

  @POST('/User/forgot_password')
  Future<LoginResponse> forgotPassword(@Body() LoginRequest body);

}
