import 'package:dio/dio.dart';
import 'package:api/api.dart' as api;
import 'package:domain/domain.dart';

/// {{name.pascalCase()}} 数据仓储实现
///
/// 注意：{{name.pascalCase()}}Repository 接口在 domain 包中定义。
/// 实现类引用 domain 包中的接口，遵循 Clean Architecture 原则。
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  final Dio _dio;

  {{name.pascalCase()}}RepositoryImpl(this._dio);

  @override
  Future<Result<{{name.pascalCase()}}Data, DomainException>> get{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name.snakeCase()}}');
      return Result.success({{name.pascalCase()}}Data.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }

  @override
  Future<Result<{{name.pascalCase()}}Data, DomainException>> refresh{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name.snakeCase()}}', queryParameters: {'refresh': 'true'});
      return Result.success({{name.pascalCase()}}Data.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    }
  }
}
