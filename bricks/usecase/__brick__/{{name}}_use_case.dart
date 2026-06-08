import 'package:domain/domain.dart';

/// {{name.pascalCase()}} 用例
///
/// 职责: {{name.pascalCase()}} 业务逻辑封装
/// 依赖: I{{repository.pascalCase()}}Repository (domain 层接口)
class {{name.pascalCase()}}UseCase {
  final I{{repository.pascalCase()}}Repository _repository;

  const {{name.pascalCase()}}UseCase(this._repository);

  /// 执行 {{name.pascalCase()}} 操作
  ///
  /// 返回 Result<T, DomainException>, 调用方需穷尽匹配处理成功/失败
  Future<Result<dynamic, DomainException>> call() async {
    final result = await _repository.get{{repository.pascalCase()}}();
    return result;
  }
}
