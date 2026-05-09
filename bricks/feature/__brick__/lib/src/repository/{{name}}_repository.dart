import 'package:domain/domain.dart';

/// {{name.pascalCase()}} 数据仓储接口
abstract class {{name.pascalCase()}}Repository {
  /// 获取 {{name.pascalCase()}} 数据
  ///
  /// 返回 Result: Success(Map) 或 Failure(DomainException)
  Future<Result<Map<String, dynamic>, DomainException>> get{{name.pascalCase()}}Data();

  /// 刷新 {{name.pascalCase()}} 数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Result<Map<String, dynamic>, DomainException>> refresh{{name.pascalCase()}}Data();
}
