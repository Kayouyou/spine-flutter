import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:api/src/models/session_result.dart';
import 'package:api/src/models/sign_in_request.dart';

part 'session_api.g.dart';

@RestApi(baseUrl: '')
abstract class SessionApi {
  factory SessionApi(Dio dio) = _SessionApi;

  @POST('/session')
  Future<SessionResult> signIn(@Body() SignInRequest body);

  @DELETE('/session')
  Future<SessionResult> signOut();

}
