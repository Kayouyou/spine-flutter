import 'package:flutter/widgets.dart';
import 'package:api/api.dart';

/// 请求范围Widget
///
/// 职责：自动管理页面级请求取消
/// 使用：包装需要取消请求的页面内容
/// 原理：Widget销毁时自动调用CancelTokenManager.cancelPage
///
/// 示例：
/// ```dart
/// RequestScope(
///   tag: 'detail_page',
///   child: DetailContent(),
/// )
/// ```
class RequestScope extends StatefulWidget {
  /// 页面标识
  ///
  /// 用于关联该范围内的所有请求
  /// 建议：使用页面路径或功能名称作为tag
  final String tag;

  /// 子Widget
  final Widget child;

  const RequestScope({
    required this.tag,
    required this.child,
    super.key,
  });

  @override
  State<RequestScope> createState() => _RequestScopeState();
}

class _RequestScopeState extends State<RequestScope> {
  @override
  void dispose() {
    // Widget销毁时，取消该页面所有未完成请求
    CancelTokenManager.instance.cancelPage(widget.tag);
    // 清理Token记录
    CancelTokenManager.instance.cleanup(widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}