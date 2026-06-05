# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
