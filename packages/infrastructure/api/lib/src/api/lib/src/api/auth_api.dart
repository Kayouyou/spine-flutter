import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

part 'auth_api.g.dart';

/// Auth API 接口
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;


  /// 获取列表
  @GET('/api/v1')
  Future<List<LoginRequest,LoginResponse,UserProfile>> getList();

  /// 获取单个
  @GET('/api/v1/{id}')
  Future<LoginRequest,LoginResponse,UserProfile> getById(@Path('id') String id);

  /// 创建
  @POST('/api/v1')
  Future<LoginRequest,LoginResponse,UserProfile> create(@Body() Map<String, dynamic> data);

  /// 更新
  @PUT('/api/v1/{id}')
  Future<LoginRequest,LoginResponse,UserProfile> update(@Path('id') String id, @Body() Map<String, dynamic> data);



  /// 删除
  @DELETE('/api/v1/{id}')
  Future<void> delete(@Path('id') String id);
}
