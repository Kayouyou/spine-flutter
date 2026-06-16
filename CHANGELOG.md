# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-06-10

### Added

- **component_library 完整设计系统升级**:
  - Design Tokens: AppColors (15 颜色，支持暗色主题)、AppRadius (6 级圆角)、AppShadows (4 级阴影)
  - 原子组件: AppButton (5 变体 × 4 尺寸 × 4 图标位置 + 渐变/自定义/防抖)、AppTextField (统一输入框)、AppDialog、AppCard、AppSection、AppToast (EasyLoading 封装)
  - 现有组件暗色主题适配: EmptyState、ErrorCard 使用 context.colors
- **feature_settings 包**: 设置页面（语言切换、调试开关、登出、版本信息）
- **Sentry 增强配置**: release/environment 字段，dev 环境使用 ConsoleReporter
- **API 层文档**: docs/api-layer-guide.md（拦截器链、Token 续期、请求取消机制）
- **版本追踪扩展**: check_workspace_versions.dart 追踪 17 个关键依赖包
- **覆盖率门槛**: 80% 最低覆盖率要求（scripts/check_coverage.sh）
- **集成测试骨架**: integration_test/app_test.dart

### Changed

- **文档扩充**: auth-route-guard.md (37→80+行)、coverage-guide.md (33→80+行)、deep-link-guide.md (47→80+行)
- **移除 injectable 死代码**: 删除 injectable.dart + injectable.config.dart + pubspec 依赖（全局 0 个 @injectable 注解）

### Fixed

- **Result API 使用修复**: test/helpers/fake_auth_manager.dart 使用 Success/Failure 直接构造
- **lints 版本漂移**: key_value_storage lints ^1.0.1 → ^2.0.0

## [0.2.0] - 2026-06-06

### Added

- **api 包 RefreshApi 模块**: `shouldRenewToken` / `retryRequestWithRetry` / `_retryRequest` (14 字段 Options 重建) / `performTokenRenewal` / `processRenewalResponse` / `_executeRenewalRequest` / `_configureProxy`, 拆出后每个函数单一职责
- **api 包 RefreshQueue 模块**: `TokenRenewalState` 4 态枚举 (idle / renewing / success / failed) + `PendingRequest` 3 字段封装 + `drain(batchSize, fireAndForget)` 合并原 2 个 90% 重复排空方法
- **api 包单测覆盖**: RefreshQueue add 去重 / 12 条目分 3 批 / fireAndForget 时机, RefreshApi shouldRenewToken 3 个 code 路径, PendingRequest 4 字段构造 + 路径/方法/参数相等性, TokenRenewalInterceptor 注入与状态枚举
- **bricks/api domainInterface 必填变量**: 强制 `implements` domain 接口 + 改用 `toDomainException` + DI 注册键改为接口, 避免砖块产物又重新 leak 实现类型

### Changed

- **api 包 Token 续期拦截器重构**: 716 行单文件拆为 3 个职责清晰文件 (`renewal_token_intercaptor.dart` 状态机+编排 / `refresh_api.dart` HTTP / `refresh_queue.dart` 队列), 2 个 90% 重复排空方法合并为字节码等价的 `_drain`, 修 `ovsx-app-token` 命名错误
- **api 包 barrel 收紧**: `api.dart` 删零引用 export, `component_library.dart` 同步清理
- **api 包死代码清理**: 删除 32 项零引用产物 (3 个 zero-call api 类 + 5 个死 DTO + 3 个死 spec + 2 个 README + 1 个残废脚本 + tracking/ 空目录等), 同步清理 mason.yaml/makefile 引用
- **bricks/api 契约升级**: 强制砖块产物实现 domain 接口而非暴露实现类型

### Removed

- **bricks/api_gen + bricks/api_gen_spec**: 2 个死砖块已删除 (被 bricks/api 替代)
- **scripts/gen_api.dart**: 残废脚本已删除
- **makefile 6 个 gen-* target**: gen-api / gen-all-apis / refresh-api / gen-api-mason / gen-all-apis-mason / refresh-api-mason 已清理
- **api 包 3 个死依赖**: `pretty_dio_logger` / `connectivity_plus` (network service 保留自己的 dep) / `queue` 从 `pubspec.yaml` 移除
- **api 包公开 `retryRequest`**: 零生产调用方, 与私有 `_retryRequest` 重复, 统一为唯一私有原语
- **api 包 `PendingRequest.handler` 死字段**: 主流程用 `completer.future` 链式回调, 字段从未被 drain 读取
- **api 包 `ApiConstants` 笔误**: `api_endpoints.dart` deprecation 消息指向不存在的 `ApiConstants`, 改为 `ApiEndpoints`

### Fixed

- **api 包续期静默失败**: `_executeRenewalRequest` 用 `validateStatus: (s) => true` 吞掉所有 4xx/5xx, 加 `logger.warning` 输出非 2xx 状态码和 body
- **api 包 `processRenewalResponse` 测试覆盖**: 5 个 case 覆盖 reLoginCode (logout 事件) / 成功 token 写入 / 缺 token / null storage / 异常 JSON

## [0.1.0] - 2026-06-05

首个公开版本。项目从 internal scaffold → 公开 GitHub 仓库,
CI/工具链/AI 守则全部定型。

### Added

- **依赖自动化**: Dependabot 配置 (15 个 monorepo 目录, 5 个 group 合并 PR) + 专用 `dependabot-pr.yml` workflow (跑 `melos bs` + analyze + test:affected)
- **AI 协作规范**: `AGENTS.md` (13 章, 含 R1-R10 硬规则 / 5 个关键概念 / 7 个修改场景 / 提交 / 错误处理 / 监控)
- **开源门面**: MIT `LICENSE` / README badge (CI / Dependabot / License / Flutter 3.38.10 / Dart 3 / Monorepo / AI-friendly) / README "维护" 章节 (自动化维护表 + 分支保护 + 贡献流程)
- **代码质量基线**: 3 条现代 lint 规则 (`avoid_returning_null_for_void` / `avoid_redundant_argument_values` / `unnecessary_lambdas`)
- **社区协作模板**: `.github/PULL_REQUEST_TEMPLATE.md` (7 段) + Issue bug/feature 模板
- **发版自动化**: `.github/workflows/release.yml` (v*.*.* tag 触发, 校验 pubspec version 跟 tag 一致, 跑 analyze + test + build APK/iOS, 自动建 draft GitHub Release)

### Changed

- **仓库可见性**: private → **public**, 开启 main 分支保护 (linear history + no force push + 4 status check 必过)
- **Flutter 升级**: 3.22.3 → **3.38.10** (5 文件统一: AGENTS.md / README badge / `ci.yml` ×3 / `dependabot-pr.yml` / `coverage.yml`)
- **Analyzer 报告**: 93 issues → **0 issues** (18 info 清完, 移除 2 条 Dart 3.3 已弃用规则)
- **依赖锁定**: `hive` 统一 `^2.2.3` (修复 `key_value_storage` 与 `list_cache` 版本冲突)
- **错误处理**: `unawaited()` 包住 4 个 fire-and-forget 异步调用; 字符串插值规范化; 命名修正 (`Proxy_Ip` → `proxyIp`)
- **API 抽象**: `RequestContext.setTag()` 改为 setter (`RequestContext.tag =`), 杜绝 void 返回值违反 lint
- **commit 邮箱去敏**: 本地 `git config user.email` 改为 `13092497+Kayouyou@users.noreply.github.com`, 新 commit 不再含个人 gmail

### Fixed

- `home_page_test` const instance field 改成 `static const`, 通过 `const_instance_field` 检查
- 移除历史 commit 中 61 个误 tracked 的 `build/test_cache/*.cache.dill.track.dill` 文件 (用 `git filter-repo` 重写 273 个 commit)
- 推送 5020 对象 / 128 MiB → 293 对象 / 21.39 KiB (仓库瘦身 6000×)
- 修复 macOS 推送时 PAT 缺 `workflow` scope 导致的 workflow 文件推送被拒
- 修复 dart fix 自动改坏两个 pubspec.yaml 的 `hive: any` 写法

### Security

- PAT 加 `workflow` scope 才能 push `.github/workflows/*.yml`
- 公开前 audit 干净: 无明文 secret (PAT / SSH key / AWS key 全无)
- 邮箱去敏降低垃圾邮件风险

[0.1.0]: https://github.com/Kayouyou/spine-flutter/releases/tag/v0.1.0
[0.2.0]: https://github.com/Kayouyou/spine-flutter/releases/tag/v0.2.0
[0.3.0]: https://github.com/Kayouyou/spine-flutter/releases/tag/v0.3.0
