import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import '../api/{{name}}_api.dart';

/// {{name.pascalCase()}} 数据仓储实现
///
/// 契约: 必须实现 domain 层 {{domainInterface}} 接口
/// 错误: 使用 toDomainException 映射 DioException → DomainException (AGENTS.md R8)
class {{name.pascalCase()}}RepositoryImpl implements {{domainInterface}} {
  final {{name.pascalCase()}}Api _api;

  {{name.pascalCase()}}RepositoryImpl(this._api);

{{#hasModel}}
  @override
  Future<Result<List<{{modelName.pascalCase()}}>, DomainException>> getList() async {
    try {
      final response = await _api.getList();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<{{modelName.pascalCase()}}, DomainException>> getById(String id) async {
    try {
      final response = await _api.getById(id);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }
{{/hasModel}}
{{^hasModel}}
  @override
  Future<Result<List<dynamic>, DomainException>> getList() async {
    try {
      final response = await _api.getList();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getById(String id) async {
    try {
      final response = await _api.getById(id);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(toDomainException(e));
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }
{{/hasModel}}
}
