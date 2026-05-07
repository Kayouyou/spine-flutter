/// {{name.pascalCase()}} 数据仓库接口
///
/// 职责：定义 {{name.pascalCase()}} 数据获取的契约
/// 使用：RepositoryImpl 实现，Cubit 通过接口调用
/// 好处：便于测试 Mock 和未来替换实现
abstract class {{name.pascalCase()}}Repository {
  /// 获取 {{name.pascalCase()}} 数据
  ///
  /// 返回 {{name.pascalCase()}} 展示所需的数据
  /// 失败时抛出 DomainException
  Future<Map<String, dynamic>> get{{name.pascalCase()}}Data();

  /// 刷新 {{name.pascalCase()}} 数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Map<String, dynamic>> refresh{{name.pascalCase()}}Data();
}