import 'package:domain/domain.dart';
import '../api/{{name}}_api.dart';

/// {{name.pascalCase()}} 数据仓储实现
class {{name.pascalCase()}}RepositoryImpl {
  final {{name.pascalCase()}}Api _api;

  {{name.pascalCase()}}RepositoryImpl(this._api);

  Future<Result<List<dynamic>, DomainException>> getList() async {
    try {
      final response = await _api.getList();
      return Result.success(response);
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>, DomainException>> getById(String id) async {
    try {
      final response = await _api.getById(id);
      return Result.success(response);
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }
}
