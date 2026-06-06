// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:api/api.dart';

// Project imports:
import '../middleware/request_context.dart';

/// 请求范围 Widget
///
/// 职责：自动从 GoRouter 提取 path 作为 tag，管理页面级请求取消
/// 使用：包装需要取消请求的页面内容
///
/// 示例：
/// ```dart
/// RequestScope(child: HomePage())
/// ```
///
/// Dialog 等非路由场景可指定 overrideTag:
/// ```dart
/// RequestScope(overrideTag: 'confirm_dialog', child: ...)
/// ```
class RequestScope extends StatefulWidget {
  /// 子 Widget
  final Widget child;

  /// 覆盖 tag（非路由场景使用，如 Dialog）
  ///
  /// 若未提供，自动从 GoRouter 提取当前路由的 fullPath
  final String? overrideTag;

  const RequestScope({required this.child, this.overrideTag, super.key});

  @override
  State<RequestScope> createState() => _RequestScopeState();
}

class _RequestScopeState extends State<RequestScope> {
  String? _tag;

  @override
  void initState() {
    super.initState();
    if (widget.overrideTag != null) {
      _tag = widget.overrideTag;
      RequestContext.pushTag(_tag!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tag == null) {
      _tag = _extractPathFromRouter();
      RequestContext.pushTag(_tag!);
    }
  }

  /// 从 GoRouter 提取当前路由的 fullPath 模板作为 tag
  ///
  /// 使用 fullPath 而非 uri.path:
  ///   - fullPath 返回 '/detail/:id'（模板，适用于所有同路由页面）
  ///   - uri.path 返回 '/detail/123'（实例化路径，每个 ID 不同 → tag 泄漏）
  String _extractPathFromRouter() {
    final fullPath = GoRouterState.of(context).fullPath;
    return fullPath ?? '/unknown';
  }

  @override
  void dispose() {
    if (_tag != null) {
      RequestContext.popTag();
      CancelTokenManager.instance.cleanup(_tag!);
    }
    RequestContext.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
