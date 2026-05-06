/// 请求上下文 — 静态 tag 传递
///
/// 设计决策: 不用 Zone。GoRouter 一次只有一个页面在前台，静态字段足够。
/// 限制: 嵌套 RequestScope（如 dialog）需用 overrideTag，不要嵌套。
class RequestContext {
  static String? _currentTag;

  static void setTag(String tag) => _currentTag = tag;
  static String? get currentTag => _currentTag;
  static void clear() => _currentTag = null;
}
