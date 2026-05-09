import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../ui/detail_page.dart';

/// 详情页路由模块
///
/// 包含路径: /detail, /detail/:id
class DetailRouteModule extends RouteModule {
  const DetailRouteModule(super.ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/detail',
        pageBuilder: (context, state) {
          Widget page = const DetailPage();
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return MaterialPage(child: page);
        },
      ),
      GoRoute(
        path: '/detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          Widget page = DetailPage(id: id);
          if (ctx.routeWrapper != null) {
            page = ctx.routeWrapper!(page);
          }
          return MaterialPage(child: page);
        },
      ),
    ];
  }
}
