import 'package:domain/domain.dart';

/// {{name.pascalCase()}} 仓储抽象
abstract class {{name.pascalCase()}}Repository {
  Future<Result<Map<String, dynamic>, DomainException>> get{{name.pascalCase()}}Data();

  Future<Result<Map<String, dynamic>, DomainException>> refresh{{name.pascalCase()}}Data();
}
