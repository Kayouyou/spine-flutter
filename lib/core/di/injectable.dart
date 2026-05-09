// Package imports:
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

part 'injectable.config.dart';

/// 全局 Service Locator
///
/// 使用方式：
/// - sl<YourService>() 或 GetIt.instance<YourService>()
/// - 推荐通过构造函数注入依赖
final getIt = GetIt.instance;

/// Injectable 初始化配置
///
/// 在 setupDependencies() 中调用 configureDependencies(getIt)
/// 自动注册所有 @injectable/@singleton/@lazySingleton 注解的类
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies(GetIt getIt) {
  // 基础注册：所有 @injectable/@singleton/@lazySingleton 注解的类
  // 将在生成文件 injectable.config.dart 中自动注册
  // 运行: flutter pub run build_runner build --delete-conflicting-outputs
}