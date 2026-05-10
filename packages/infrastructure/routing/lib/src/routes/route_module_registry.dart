import 'package:go_router/go_router.dart';
import 'route_context.dart';
import 'route_module.dart';

/// 路由模块注册中心 — 收集各 Feature 的路由模块，统一构建 GoRouter 路由列表
///
/// 使用方式：
/// 1. Feature 层在 DI setup 中注册路由模块：
///    RouteModuleRegistry.instance.register('feature_home', (ctx) => HomeRouteModule(ctx));
///
/// 2. App 层构建路由时调用：
///    final routes = RouteModuleRegistry.instance.buildAll(ctx);
///
/// 设计意图：
/// - Feature 只需注册路由工厂，无需关心路由组装顺序
/// - App 层统一管理路由组装，支持 AuthGuard、ShellRoute 等全局配置
abstract class RouteModuleRegistry {
  /// 单例实例
  static final RouteModuleRegistry instance = _RouteModuleRegistryImpl();

  /// 注册路由模块
  ///
  /// featureName: 用于标识模块（如 'feature_home'），便于调试
  /// factory: 路由模块工厂函数，接收 RouteContext，返回 RouteModule
  void register(String featureName, RouteModule Function(RouteContext) factory);

  /// 构建所有已注册路由模块的路由列表
  List<RouteBase> buildAll(RouteContext ctx);

  /// 获取指定 Feature 的路由列表
  List<RouteBase> get(String featureName, RouteContext ctx);

  /// 清空已注册的路由模块（用于测试或重置）
  void clear();
}

/// RouteModuleRegistry 实现（单例）
class _RouteModuleRegistryImpl implements RouteModuleRegistry {
  final Map<String, RouteModule Function(RouteContext)> _modules = {};

  @override
  void register(String featureName, RouteModule Function(RouteContext) factory) {
    if (_modules.containsKey(featureName)) {
      throw StateError('RouteModule "$featureName" already registered. Call clear() first if needed.');
    }
    _modules[featureName] = factory;
  }

  @override
  List<RouteBase> buildAll(RouteContext ctx) {
    final routes = <RouteBase>[];
    for (final entry in _modules.entries) {
      final module = entry.value(ctx);
      routes.addAll(module.build());
    }
    return routes;
  }

  @override
  List<RouteBase> get(String featureName, RouteContext ctx) {
    final factory = _modules[featureName];
    if (factory == null) {
      throw StateError('RouteModule "$featureName" not registered');
    }
    return factory(ctx).build();
  }

  @override
  void clear() {
    _modules.clear();
  }
}