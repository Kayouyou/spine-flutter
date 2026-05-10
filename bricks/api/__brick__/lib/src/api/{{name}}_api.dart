import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
{{#hasModel}}import 'package:domain/domain.dart';{{/hasModel}}

part '{{name}}_api.g.dart';

/// {{name.pascalCase()}} API 接口
@RestApi()
abstract class {{name.pascalCase()}}Api {
  factory {{name.pascalCase()}}Api(Dio dio, {String baseUrl}) = _{{name.pascalCase()}}Api;

{{#hasModel}}
  /// 获取列表
  @GET('{{{baseUrl}}}')
  Future<List<{{modelName.pascalCase()}}>> getList();

  /// 获取单个
  @GET('{{{baseUrl}}}/{id}')
  Future<{{modelName.pascalCase()}}> getById(@Path('id') String id);

  /// 创建
  @POST('{{{baseUrl}}}')
  Future<{{modelName.pascalCase()}}> create(@Body() Map<String, dynamic> data);

  /// 更新
  @PUT('{{{baseUrl}}}/{id}')
  Future<{{modelName.pascalCase()}}> update(@Path('id') String id, @Body() Map<String, dynamic> data);
{{/hasModel}}
{{^hasModel}}
  /// 获取列表
  @GET('{{{baseUrl}}}')
  Future<dynamic> getList();

  /// 获取单个
  @GET('{{{baseUrl}}}/{id}')
  Future<Map<String, dynamic>> getById(@Path('id') String id);

  /// 创建
  @POST('{{{baseUrl}}}')
  Future<Map<String, dynamic>> create(@Body() Map<String, dynamic> data);

  /// 更新
  @PUT('{{{baseUrl}}}/{id}')
  Future<Map<String, dynamic>> update(@Path('id') String id, @Body() Map<String, dynamic> data);
{{/hasModel}}

  /// 删除
  @DELETE('{{{baseUrl}}}/{id}')
  Future<void> delete(@Path('id') String id);
}
