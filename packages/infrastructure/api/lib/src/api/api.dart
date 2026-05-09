import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:api/src/models/.dart';

import 'package:api/src/models/.dart';

import 'package:api/src/models/.dart';


part 'auth_api.g.dart';

@RestApi(baseUrl: '')
abstract class Api {
  factory Api(Dio dio) = _Api;



  @POST('/User/Login/Password')
  Future<LoginResponse> login(@Body() LoginRequest body);




  @POST('/User/Register')
  Future<LoginResponse> register(@Body() LoginRequest body);






  @GET('/User/{username}')
  Future<UserProfile> username(@Path('username') String username);





  @POST('/User/forgot_password')
  Future<LoginResponse> forgotPassword(@Body() LoginRequest body);



}
