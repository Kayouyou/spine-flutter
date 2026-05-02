/// 列表缓存策略
enum ListCacheStrategy {
  /// 先缓存后网络（stale-while-revalidate）
  /// 适合：社交动态、商品列表 — 用户立刻看到内容，后台静默刷新
  cacheFirst,

  /// 先网络后缓存
  /// 适合：关键数据 — 必须拿到最新数据，失败时才用缓存兜底
  networkFirst,

  /// 仅缓存
  /// 适合：静态数据、设置项 — 永远不发起网络请求
  cacheOnly,

  /// 仅网络
  /// 适合：敏感数据、一次性内容 — 永远不使用缓存
  networkOnly,
}