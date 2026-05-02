import 'package:go_router/go_router.dart';
import 'route_context.dart';

/// 路由模块基类。每个模块实现 build() 返回自己的 GoRoute 列表。
///
/// 实现类应在顶部注释说明：
/// - 本模块包含哪些路径
/// - 是否有同一屏幕多处使用
/// - 参数差异是什么
/// - 涉及的特殊业务逻辑（L1~L9）
abstract class RouteModule {
  final RouteContext ctx;
  const RouteModule(this.ctx);

  /// 构建路由列表，返回的 RouteBase 列表会被注册到 GoRouter 的 routes 中。
  List<RouteBase> build();
}
