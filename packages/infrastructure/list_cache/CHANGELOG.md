# Changelog

所有针对 list_cache 包的显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [0.2.0] - 2026-06-16

### Breaking Changes

- **重构存储结构**：从"每页一个 box"改为"每个 cacheKey 一个 box"
  - 旧设计：`list_cache_home_feed_p1`、`list_cache_home_feed_p2`...（每页独立 box）
  - 新设计：`list_cache_home_feed`（单个 box，内部使用 `p1`、`p2`... 作为 key）
  - **资源安全**：50 页列表只占 1 个 box（旧设计占 50 个）

### Added

- **staleDuration 缓存过期机制**
  - 读取时检查缓存时间戳，过期则触发重新拉取
  - 写入时同步存储时间戳 `t{page}`
  - 支持 `null`（永不过期）和 `Duration`（指定过期时间）
  
- **migrateFromV1() 数据迁移方法**
  - 扫描所有 Hive box，删除匹配 `*_p\d+$` 的旧格式 box
  - 首次升级时调用一次即可清理旧数据

### Changed

- **_getBox() 方法**：接受 cacheKey 而非 boxName，内部调用 _boxName()
- **_readPage() 方法**：增加过期检查，过期返回空列表
- **_writePage() 方法**：同步写入时间戳 `t{page}`
- **clear() 方法**：删除整个 box（使用 deleteFromDisk）而非清空内容
- **_clearSubsequentPages()**：在单个 box 内删除多个 key（`p2`~`pN` 和 `t2`~`tN`）

### Removed

- **_metaKey() 方法**：不再需要元数据 box
- **_pageKey() 方法**：被 _boxName() 替代

### Fixed

- 修复大量 page 导致打开过多 box 的资源耗尽风险
- 修复 staleDuration 配置未生效的问题

## [0.1.0] - 2024-05-07

### Added

- 初始版本
- 四种缓存策略：cacheFirst、networkFirst、cacheOnly、networkOnly
- CacheConfig 配置类
- CacheResult 结果封装
- 基础分页缓存功能
