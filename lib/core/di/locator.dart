// Package imports:
import 'package:get_it/get_it.dart';

/// 全局服务定位器
///
/// 使用GetIt实现依赖注入，管理所有服务的生命周期
/// 使用方式：
///   - 注册服务：`sl.registerSingleton<Type>(instance)`
///   - 获取服务：`sl<Type>()`
final sl = GetIt.instance;
