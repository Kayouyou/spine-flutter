// 示例：User模型及其Adapter
//
// 此文件展示如何为业务模型创建Hive Adapter
// 实际项目中，应使用build_runner生成
//
// 步骤：
// 1. 定义模型类，添加Hive注解
// 2. 运行 flutter pub run build_runner build
// 3. 生成的Adapter文件注册到DomainHiveRegistrar
//
// 示例模型：
// @HiveType(typeId: 1)
// class User {
//   @HiveField(0)
//   final String id;
//   @HiveField(1)
//   final String name;
//   @HiveField(2)
//   final String email;
//   User({required this.id, required this.name, required this.email});
// }