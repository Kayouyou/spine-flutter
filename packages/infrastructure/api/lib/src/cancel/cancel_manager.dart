import 'package:dio/dio.dart';

/// 请求取消管理器
///
/// 职责：管理页面级请求取消，避免页面退出后请求继续执行
/// 使用：
///   - 页面进入时注册CancelToken
///   - 页面退出时取消该页面所有请求
///   - RequestScope Widget自动管理
/// 优势：避免内存泄漏、减少无效网络请求
class CancelTokenManager {
  /// 单例实例
  static final instance = CancelTokenManager._();

  CancelTokenManager._();

  /// 页面请求Token映射表
  ///
  /// key: pageTag（页面标识）
  /// value: 该页面的所有CancelToken列表
  final Map<String, List<CancelToken>> _pageTokens = {};

  /// 注册页面请求Token
  ///
  /// 将请求的CancelToken与页面关联
  /// 页面退出时可批量取消该页面所有请求
  ///
  /// 参数：
  /// - pageTag: 页面唯一标识（如页面路径或自定义tag）
  /// - token: Dio CancelToken实例
  void register(String pageTag, CancelToken token) {
    _pageTokens.putIfAbsent(pageTag, () => []).add(token);
  }

  /// 取消页面所有请求
  ///
  /// 页面退出时调用，取消该页面所有未完成的请求
  /// 已完成的请求不受影响
  ///
  /// 参数：
  /// - pageTag: 页面标识
  /// - reason: 取消原因（可选，默认"Page disposed"）
  void cancelPage(String pageTag, [String? reason]) {
    final tokens = _pageTokens[pageTag];
    if (tokens != null) {
      for (final token in tokens) {
        // 取消请求，附带原因说明
        token.cancel(reason ?? 'Page disposed: $pageTag');
      }
      // 清空该页面的Token列表
      tokens.clear();
    }
  }

  /// 清理页面Token记录
  ///
  /// 页面彻底销毁时调用，移除该页面的Token映射
  /// 安全性：自动取消未完成的请求，避免孤立Token
  void cleanup(String pageTag) {
    // 安全：先取消未完成的请求
    cancelPage(pageTag, 'Cleanup: $pageTag');
    // 再移除记录
    _pageTokens.remove(pageTag);
  }

  /// 获取页面Token数量
  ///
  /// 用于调试，查看某页面有多少未完成请求
  int getTokenCount(String pageTag) {
    return _pageTokens[pageTag]?.length ?? 0;
  }

  /// 清理所有记录
  ///
  /// App退出或重置时调用
  void clearAll() {
    _pageTokens.clear();
  }

  /// 全局取消所有页面正在进行的请求
  ///
  /// 覆盖「退出 App / 切换账号」等需要立即终止全部在途请求的场景。
  /// 与 [clearAll] 的区别：本方法会真正对每个 [CancelToken] 触发取消（而非仅清记录），
  /// 避免切换账号后旧账号的请求仍返回并污染新会话。
  ///
  /// 参数：
  /// - reason: 取消原因（可选，默认"Global cancel"）
  void cancelAll([String? reason]) {
    for (final entry in _pageTokens.entries) {
      for (final token in entry.value) {
        token.cancel(reason ?? 'Global cancel: ${entry.key}');
      }
    }
    _pageTokens.clear();
  }
}