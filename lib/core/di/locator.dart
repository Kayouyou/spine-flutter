// Package imports:
import 'package:get_it/get_it.dart';

/// 全局 Service Locator
///
/// 使用方式：
/// - sl<YourService>() 或 GetIt.instance<YourService>()
/// - 推荐通过构造函数注入依赖
final getIt = GetIt.instance;

/// 简写：sl<AuthManager>() 等价于 getIt<AuthManager>()
///
/// 注意：sl 只是 getIt 的别名，不要直接 import GetIt.instance
final sl = getIt;