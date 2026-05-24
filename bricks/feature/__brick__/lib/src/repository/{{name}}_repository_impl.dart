import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import '{{name}}_repository.dart';

/// {{name.pascalCase()}} 数据仓储实现
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  final Dio _dio;

  {{name.pascalCase()}}RepositoryImpl(this._dio);

  @override
  Future<Result<Map<String, dynamic>, DomainException>> get{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name.snakeCase()}}');
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> refresh{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name.snakeCase()}}', queryParameters: {'refresh': 'true'});
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }
}
