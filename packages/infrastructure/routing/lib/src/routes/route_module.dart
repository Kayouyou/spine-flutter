import 'package:flutter/material.dart';
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

  List<RouteBase> build();

  /// 统一包装模板: routeWrapper 为 null 时返回原 page, 否则包一层
  ///
  /// 避免 5 个 RouteModule 各自写 if/?? 模板
  Widget wrap(Widget page) {
    final wrapper = ctx.routeWrapper;
    if (wrapper == null) return page;
    return wrapper(page);
  }
}
