import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part '{{name}}_api.g.dart';

/// {{name.pascalCase()}} API 接口
@RestApi()
abstract class {{name.pascalCase()}}Api {
  factory {{name.pascalCase()}}Api(Dio dio, {String baseUrl}) = __{{name.pascalCase()}}Api;

  /// 获取列表
  @GET('{{baseUrl}}')
  Future<List<dynamic>> getList();

  /// 获取单个
  @GET('{{baseUrl}}/{id}')
  Future<Map<String, dynamic>> getById(@Path('id') String id);

  /// 创建
  @POST('{{baseUrl}}')
  Future<Map<String, dynamic>> create(@Body() Map<String, dynamic> data);

  /// 更新
  @PUT('{{baseUrl}}/{id}')
  Future<Map<String, dynamic>> update(@Path('id') String id, @Body() Map<String, dynamic> data);

  /// 删除
  @DELETE('{{baseUrl}}/{id}')
  Future<void> delete(@Path('id') String id);
}
