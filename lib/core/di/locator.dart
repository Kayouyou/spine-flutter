// Package imports:
import 'package:get_it/get_it.dart';

/// 全局 Service Locator
///
/// 使用方式（按推荐程度排序）：
/// 1. 构造函数注入（推荐）：MyClass(sl<Dep>())
/// 2. 全局访问：sl.get<MyClass>() 或 sl<MyClass>()
/// 3. 直接访问：GetIt.instance<MyClass>()（不推荐）
///
/// 配合 injectable 使用：
/// - 用 @injectable 注解的类自动生成注册代码
/// - 手动注册继续工作（双轨策略）
final sl = GetIt.instance;

// 导出 injectable.dart 的 getIt
export 'injectable.dart' show getIt;