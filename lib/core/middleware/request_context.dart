/// 请求上下文 — 栈式 tag 传递
///
/// 设计决策: 不用 Zone。GoRouter 一次只有一个页面在前台，静态字段足够。
/// 嵌套 RequestScope（dialog / bottom sheet 场景）走栈：
///   pushTag('outer') → pushTag('inner') → popTag() → currentTag == 'outer'
class RequestContext {
  static final List<String> _stack = [];

  /// 推入一个 tag (用于嵌套 RequestScope 场景)
  static void pushTag(String tag) {
    _stack.add(tag);
  }

  /// 弹出栈顶 tag (最外层 dispose 时调用)
  static void popTag() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  /// 兼容旧 API: 直接 set 顶部 tag (不推荐新代码使用)
  static set tag(String tag) {
    if (_stack.isEmpty) {
      pushTag(tag);
    } else {
      _stack[_stack.length - 1] = tag;
    }
  }

  static String? get currentTag =>
      _stack.isEmpty ? null : _stack.last;

  /// 整栈清空 (顶层 RequestScope dispose 时)
  static void clear() => _stack.clear();
}
