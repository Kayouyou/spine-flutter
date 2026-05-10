import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:api/src/models/user_profile.dart';
import 'package:api/src/models/update_profile_request.dart';

part 'user_api.g.dart';

@RestApi(baseUrl: '')
abstract class UserApi {
  factory UserApi(Dio dio) = _UserApi;

  @GET('/User/me')
  Future<UserProfile> getCurrentUser();

  @PUT('/User/profile')
  Future<UserProfile> updateProfile(@Body() UpdateProfileRequest body);

}
