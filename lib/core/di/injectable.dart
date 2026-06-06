// Package imports:
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injectable.config.dart';

/// 全局 Service Locator
///
/// 使用方式：
/// - sl<YourService>() 或 GetIt.instance<YourService>()
/// - 推荐通过构造函数注入依赖
final getIt = GetIt.instance;

/// Injectable 初始化入口
///
/// 必须在 setupDependencies() 第一行调用，且此时 GetIt 尚未注册任何实例
/// 后续手动 sl.registerSingleton(...) 会覆盖自动生成的同名注册
@InjectableInit()
void configureDependencies() => getIt.init();