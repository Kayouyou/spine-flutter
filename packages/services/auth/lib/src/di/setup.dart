import 'package:get_it/get_it.dart';
import 'package:auth/src/manager.dart';

/// 注册 Auth 服务到 DI 容器
///
/// 当前 AuthManager 无外部依赖，后续可扩展：
/// - api: API 客户端
/// - storage: 本地存储
/// - userCubit: 用户状态管理
void setupAuth(GetIt sl) {
  sl.registerSingleton<AuthManager>(AuthManager());
}