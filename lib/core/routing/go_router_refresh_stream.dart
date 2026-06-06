// lib/core/routing/go_router_refresh_stream.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// 把任意 Stream 桥接为 GoRouter 用的 Listenable
///
/// ```dart
/// final refresh = GoRouterRefreshStream(authCubit.stream);
/// GoRouter(refreshListenable: refresh, ...);
/// ```
///
/// 构造时立即 notifyListeners() 一次 (GoRouter 启动时需要首次触发)
/// 订阅 stream 后每次 emit 触发 notifyListeners() → GoRouter 重跑 redirect
/// dispose() 取消订阅, 避免 leak
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
