import 'package:dio/dio.dart';
import '{{name}}_repository.dart';

/// {{name.pascalCase()}} 数据仓库实现
///
/// 职责：通过 API 获取 {{name.pascalCase()}} 数据
/// 使用：在 DI setup 中注册为 Factory
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  final Dio _dio;

  {{name.pascalCase()}}RepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> get{{name.pascalCase()}}Data() async {
    final response = await _dio.get('/{{name}}');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> refresh{{name.pascalCase()}}Data() async {
    final response = await _dio.get('/{{name}}', queryParameters: {'refresh': true});
    return response.data as Map<String, dynamic>;
  }
}