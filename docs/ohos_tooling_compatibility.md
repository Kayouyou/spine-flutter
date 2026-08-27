# 辅助开发工具 / 技能模块 / 脚本 — OpenHarmony (OHOS) 兼容性评估清单

> 评估对象：当前仓库内所有辅助开发工具、技能模块与脚本（构建编排、git hook、质量守门脚本、代码生成砖块、CI/CD、文档）。
> 评估基准：项目已切换至 Flutter OHOS fork `3.35.8-ohos-1.0.1`（见 `.fvmrc`），并完成 8+1 个 CPF 插件覆盖（见 `docs/ohos_plugin_compatibility_audit.md`）。
> 评估日期：2026-07-15

## 状态图例

| 状态 | 含义 |
| --- | --- |
| ✅ 已兼容 | 在 OHOS 环境下可直接使用 / 本就为 OHOS 设计 |
| 🟡 部分兼容 | 可用但存在平台写死、环境依赖或覆盖盲区等 caveat |
| ❌ 不兼容 | 当前不工作或缺失 OHOS 支持，会阻塞 OHOS 流程 |
| ⏳ 待验证 | 设计上兼容但未经 OHOS 真机/CI 验证，或仓库暂无功能性模块 |

## 一、总览表

| # | 工具 / 脚本 | 类别 | 兼容状态 |
| --- | --- | --- | --- |
| 1 | `Makefile` / `makefile` | 构建编排 | ✅ 已兼容（OHOS 目标齐备）/ 🟡 跨 OS 路径写死 |
| 2 | `melos.yaml` | Monorepo | ✅ 已兼容 |
| 3 | `.fvmrc` + `fvm` | SDK 版本锁定 | ✅ 已兼容（本地与 CI 已对齐 `3.35.x`） |
| 4 | `.githooks/pre-commit` | Git Hook | ✅ 已兼容（需 ohos fork 在 PATH） |
| 5 | `ohos_utils/ohos_build.sh` | OHOS 构建 | ✅ 已兼容（macOS/OHOS）/ 🟡 跨 OS 路径写死 |
| 6 | `ohos_utils/ohos_fix.sh` | OHOS 配置兜底 | ✅ 已兼容 |
| 7 | `.ohpmrc` | OHOS 包管理 | ✅ 已兼容（OHOS 原生） |
| 8 | `.hvigor/` | OHOS 构建系统 | ✅ 已兼容（OHOS 原生） |
| 9 | `.env.ohos` | OHOS 环境变量 | ✅ 已兼容（OHOS） |
| 10 | `ohos/`（原生工程） | OHOS 应用模块 | ✅ 已兼容（OHOS 原生目标） |
| 11 | `scripts/check_deps.sh` | 依赖方向守门 | ✅ 已兼容 |
| 12 | `scripts/check_l10n.sh` | 翻译一致性 | ✅ 已兼容 |
| 13 | `scripts/check_workspace_versions.dart` | 版本漂移检查 | ✅ 已兼容（CI 已对齐 `3.35.8`，可选纳入 SDK 断言） |
| 14 | `scripts/check_coverage.sh` | 覆盖率门槛 | ✅ 已兼容 |
| 15 | `scripts/coverage_local.sh` | 本地覆盖率报告 | ✅ 已兼容（macOS）/ 🟡 Windows 无 open |
| 16 | `scripts/scaffold_check.sh` | 脚手架体检 | ✅ 已兼容 |
| 17 | `bricks/`（Mason 砖块） | 代码生成 | ✅ 已兼容 |
| 18 | `mason.yaml` / `.mason/` | 砖块管理 | ✅ 已兼容 |
| 19 | `l10n.yaml` | 国际化生成 | ✅ 已兼容 |
| 20 | `.import_sorter.yaml` | import 排序 | ✅ 已兼容 |
| 21 | `scripts/add_feature_dependency.py` | pubspec 编辑 | ✅ 已兼容 |
| 22 | `scripts/rename_project.py` | 工程重命名 | 🟡 部分兼容（重命名未覆盖 OHOS 原生层） |
| 23 | `.github/workflows/ci.yml` | CI | 🟡 部分兼容（无 OHOS 产物，Flutter 已对齐 `3.35.8`）/ ✅ 校验层兼容 |
| 24 | `.github/workflows/coverage.yml` | CI 覆盖率 | 🟡 部分兼容（无 OHOS 覆盖率任务，Flutter 已对齐 `3.35.8`） |
| 25 | `.github/workflows/release.yml` | CI 发版 | 🟡 部分兼容（无 HAP 产物，Flutter 已对齐 `3.35.8`） |
| 26 | `.github/workflows/dependabot-pr.yml` | CI | 🟡 部分兼容（Flutter 已对齐 `3.35.8`） |
| 27 | `AGENTS.md` / `README.md` | 文档 | ✅ 已兼容（已同步 OHOS） |
| 28 | 自定义技能模块（`.workbuddy/skills` 等） | 技能 | ⏳ 待验证（仓库暂无功能性技能模块） |

---

## 二、逐项评估

### 1. `Makefile` / `makefile`
- **(1) 功能与用途**：统一构建/开发任务入口。`get`/`clean`/`lint`/`test`/`coverage-local`/`integration-test`；多环境 `dev`/`staging`/`prod`；Mason 生成（`create-feature`/`create-api`/`create-model`/`create-hive-model`/`create-usecase`/`scaffold-api`）；脚手架体检 `scaffold-check`；**OHOS 全系目标** `ohos-build`/`ohos-build-release`/`ohos-build-fast`/`ohos-fix`/`ohos-install`/`ohos-log*`/`ohos-deploy`/`ohos-run`；多平台 `build-android`/`build-ios`/`build-web`/`build-ohos`。
- **(2) 平台依赖**：`bash` + `make`，macOS/Linux 通用；OHOS 目标内部写死 `/Applications/DevEco-Studio.app/Contents/sdk` 与 `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw`（macOS 专属）。
- **(3) OHOS 兼容性**：✅ 已兼容。已具备完整 OHOS 构建/部署/日志目标；通用目标用 `.fvm/flutter_sdk/bin/flutter`（即 ohos fork）。
- **(4) 障碍与适配**：🟡 `HVIGORW` 路径硬编码 macOS；Linux/Windows 无 DevEco 对应路径时 OHOS 目标不可用（`DEVECO_SDK_HOME`/`HOS_SDK_HOME` 已有回退，但 `HVIGORW` 未参数化）。建议把 `HVIGORW` 也改为可配置环境变量。

### 2. `melos.yaml`
- **(1) 功能与用途**：Monorepo 包管理 + 脚本（`analyze`/`test`/`validate`/`check:deps`/`check:versions`/`check:coverage*`）。
- **(2) 平台依赖**：纯 Dart，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。`melos bs` 在 ohos fork 下正常工作，脚本均为 Dart/bash 静态/测试操作。
- **(4) 障碍与适配**：无。

### 3. `.fvmrc` + `fvm`
- **(1) 功能与用途**：锁定 Flutter SDK 版本（当前 `3.35.8-ohos-1.0.1`）。
- **(2) 平台依赖**：`fvm` 为 Dart 工具跨平台；SDK 按平台分发。
- **(3) OHOS 兼容性**：✅ 已兼容（本地）。这是 OHOS 适配的基石——本地 `fvm flutter` 与 Makefile 内的 `.fvm/flutter_sdk/bin/flutter` 即走 ohos fork。
- **(4) 障碍与适配**：🟡 **CI 未使用 fvm**，但通过 `subosito/flutter-action` 已显式锁 `3.35.8` stable，与本地 ohos fork 的 `3.35.8-ohos-1.0.1` **主版本（3.35）对齐**——Dart/框架层完全一致，仅差 OHOS 引擎工具链（CI 本就不产出 HAP）。版本漂移已消除；若需 CI 真正产出 HAP，仍须 self-hosted runner + OHOS SDK。

### 4. `.githooks/pre-commit`
- **(1) 功能与用途**：提交前守门——依赖方向 (`check_deps.sh`) → ARB 一致性 (`check_l10n.sh`) → `flutter analyze`（仅拦 error）→ 受影响包测试 (`melos test:affected`)。
- **(2) 平台依赖**：bash + `flutter`/`melos`（需 ohos fork 在 PATH，或经 fvm 包装）。
- **(3) OHOS 兼容性**：✅ 已兼容。与 ohos fork 配合正常；`Platform.operatingSystem=='ohos'` 仅为运行时分支，编译无碍。
- **(4) 障碍与适配**：依赖 `flutter`/`melos` 在 PATH。若 hook 环境未激活 ohos fork（误用系统 stable），可能与本地行为不一致。建议在 hook 前置 `fvm` 包装或文档明确需激活 ohos fork。

### 5. `ohos_utils/ohos_build.sh`
- **(1) 功能与用途**：OHOS HAP 构建编排——`pub get` → `ohos_fix.sh` → `flutter build hap`（注入 dart-define）→ 再次 fix → `hvigorw assembleHap`。已处理关键坑：`--dart-define-from-file` 不被 `flutter build hap` 支持（K7，脚本展开为 `--dart-define=K=V`）、`flutter build hap` 覆盖 `GeneratedPluginRegistrant.ets`（K1，--full 后兜底重跑 fix）。
- **(2) 平台依赖**：依赖 macOS（DevEco/hvigor/hdc）+ ohos fork flutter；硬编码 `/Applications/DevEco-Studio.app/...`。
- **(3) OHOS 兼容性**：✅ 已兼容（macOS/OHOS）。专为 OHOS 设计。
- **(4) 障碍与适配**：🟡 路径硬编码 macOS；`HVIGORW` 未参数化，Windows 路径不同。建议路径全部改为环境变量（已有 `DEVECO_SDK_HOME`/`HOS_SDK_HOME` 回退，补全 `HVIGORW`）。

### 6. `ohos_utils/ohos_fix.sh`
- **(1) 功能与用途**：OHOS 配置兜底——清理 stale `oh-package-lock.json5`（避免 `00617202 Fetch Local Package Failed`）、校验 `GeneratedPluginRegistrant.ets` 插件注册数。本骨架无自定义原生模块，故只做幂等清理+校验，不覆盖生成物。
- **(2) 平台依赖**：bash + `find`/`rm`，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 7. `.ohpmrc`
- **(1) 功能与用途**：配置 ohpm（OpenHarmony 包管理器）registry 地址。
- **(2) 平台依赖**：OHOS 专属（ohpm 仅 OHOS 构建链路使用）。
- **(3) OHOS 兼容性**：✅ 已兼容（OHOS 原生必要配置）。
- **(4) 障碍与适配**：非 OHOS 平台自动忽略，无碍。

### 8. `.hvigor/`
- **(1) 功能与用途**：hvigor（OHOS 官方构建系统）输出/配置目录。
- **(2) 平台依赖**：OHOS 专属。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 9. `.env.ohos`
- **(1) 功能与用途**：OHOS 构建用 dart-define 环境变量（API 地址、AccessKeyId、OSS、Sentry、路由守卫等）。由 `ohos_build.sh` 读取并展开注入。
- **(2) 平台依赖**：纯文本，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容（专为 OHOS 提供）。
- **(4) 障碍与适配**：密钥项（如 `API_ACCESS_KEY`/`OSS_ACCESS_KEY`/`SENTRY_DSN`）留空，应由 CI/部署平台注入而非提交——文件已有注释提醒。

### 10. `ohos/`（原生工程）
- **(1) 功能与用途**：Flutter OHOS 应用原生工程（ArkTS/ETS、hvigor 配置、`module.json5`、`build-profile.json5` 等）。
- **(2) 平台依赖**：OHOS 专属（ArkTS + hvigor）。
- **(3) OHOS 兼容性**：✅ 已兼容（OHOS 构建的目标产物）。
- **(4) 障碍与适配**：签名 bundleName 绑定本机 DevEco 签名 material，换机/换人需重新生成（已在 AGENTS.md 记录）。

### 11. `scripts/check_deps.sh`
- **(1) 功能与用途**：依赖方向规则 R1–R4（feature 不得引 spine_flutter；domain 须纯 Dart；infrastructure 不得依赖 services；services 不得依赖 features）。
- **(2) 平台依赖**：bash + `grep`，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。纯静态检查，与平台无关；R2 黑名单含 `path_provider`/`shared_preferences` 等仅约束 domain 纯度，非 OHOS 障碍。
- **(4) 障碍与适配**：可考虑补充规则：确保无包把 ohos 原生实现误放进 domain 层。

### 12. `scripts/check_l10n.sh`
- **(1) 功能与用途**：校验各 `app_*.arb` 与模板 `app_zh.arb` 的 key 一致性。
- **(2) 平台依赖**：bash + `python3`，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 13. `scripts/check_workspace_versions.dart`
- **(1) 功能与用途**：扫描所有 `pubspec.yaml`，检查关键依赖（get_it/go_router/dio/sentry_flutter 等）版本是否漂移。
- **(2) 平台依赖**：Dart，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：🟢 已覆盖主干——CI 的 `flutter-version` 已统一为 `3.35.8` stable，与本地 ohos fork 主版本（3.35）对齐，analyze/test 漂移已消除。可选增强：扩展该脚本把 `.fvmrc` 的 SDK 主版本纳入断言，作为长期防线防止版本再次漂移。

### 14. `scripts/check_coverage.sh`
- **(1) 功能与用途**：合并各包 `lcov.info`、过滤生成代码、计算行覆盖率并比对门槛（默认 80%）。
- **(2) 平台依赖**：bash + `lcov`，macOS/Linux 需预装 `lcov`（`brew install`/`apt-get install`）。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：依赖 `lcov` 预装；Windows 需 WSL/Git Bash。

### 15. `scripts/coverage_local.sh`
- **(1) 功能与用途**：本地跑 `flutter test --coverage` + `lcov`/`genhtml` 生成 HTML 报告并打开。
- **(2) 平台依赖**：bash；用 `open`（macOS）回退 `xdg-open`（Linux）；依赖 `lcov`/`genhtml`。
- **(3) OHOS 兼容性**：✅ 已兼容（macOS 主用，Linux 有回退）。
- **(4) 障碍与适配**：🟡 Windows 无 `open`/`xdg-open`（需 `start` 或手动打开）。建议增加 Windows 分支或文档提示。

### 16. `scripts/scaffold_check.sh`
- **(1) 功能与用途**：脚手架契约测试（feature/root 模板契约）+ `melos run validate`。
- **(2) 平台依赖**：bash + `flutter`/`dart`，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 17. `bricks/`（Mason 砖块）
- **(1) 功能与用途**：代码生成模板——`feature`/`api`/`model`/`hive_model`/`usecase`/`api_gen_spec`。由 `make create-*` 调用。
- **(2) 平台依赖**：Mason 模板（Dart/文本），平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。生成纯 Dart 代码，OHOS 作为 Flutter target 自动适用，砖块无需改动。
- **(4) 障碍与适配**：若未来砖块需注入 OHOS 专属逻辑（如 ohos 权限声明 `module.json5`），可扩展砖块；当前无需求。

### 18. `mason.yaml` / `.mason/`
- **(1) 功能与用途**：Mason 砖块管理配置。
- **(2) 平台依赖**：平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 19. `l10n.yaml`
- **(1) 功能与用途**：`flutter gen-l10n` 国际化生成配置（arb-dir / output 等）。
- **(2) 平台依赖**：平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 20. `.import_sorter.yaml`
- **(1) 功能与用途**：import 按架构层次排序的分组规则。
- **(2) 平台依赖**：平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 21. `scripts/add_feature_dependency.py`
- **(1) 功能与用途**：向 root `pubspec.yaml` 的 `FEATURE_DEPENDENCIES` 标记处插入新 feature 的 path 依赖。
- **(2) 平台依赖**：`python3`，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。
- **(4) 障碍与适配**：无。

### 22. `scripts/rename_project.py`
- **(1) 功能与用途**：全局重命名工程（6 种命名形式替换 + `git mv` Kotlin 目录 + 残留校验）。
- **(2) 平台依赖**：`python3` + `subprocess` 调 `git`/`grep`（Unix 工具；Windows 需 Git Bash/WSL）。
- **(3) OHOS 兼容性**：🟡 部分兼容。脚本本身跨平台；但**重命名覆盖列表未包含 OHOS 原生层**——`ohos/` 下的 bundleName（`module.json5`）、包名、ETS 中的包引用不会被替换，重命名后会残留旧标识且 DevEco 签名 bundleName 也需手动改。
- **(4) 障碍与适配**：扩展 `rename_project.py` 增加 OHOS 原生层重命名（bundleName / package / ets import path），并文档化需同步改 DevEco 签名 bundleName。

### 23. `.github/workflows/ci.yml`
- **(1) 功能与用途**：主 CI——`analyze` → `test` → `build`（apk + ios）。
- **(2) 平台依赖**：GitHub Actions，ubuntu/macos runners。
- **(3) OHOS 兼容性**：🟡 部分兼容（无 OHOS 构建产物）/ ✅ `analyze`+`test`+Android/iOS 校验层与本地 `3.35` 主版本一致（CI 已锁 `3.35.8` stable）。
  - `analyze`/`test`/Android/iOS 构建与平台无关代码兼容；
  - **不构建 OHOS**：GitHub 托管 runner 不预装 DevEco/OHOS SDK（hvigor/ohpm/hdc），且 OHOS 构建需 macOS 专用环境；
  - **SDK 版本已对齐**：CI 现用 `3.35.8` stable，与本地 `.fvmrc` 的 `3.35.8-ohos` **主版本（3.35）一致**（ohos fork 与稳定版 3.35.8 的 Dart/框架层相同），版本漂移已消除，analyze/test 结果与本地具代表性。
- **(4) 障碍与适配**：
  - GitHub 托管 runner 无法提供 OHOS SDK；
  - CI 的 Flutter 版本与本地 ohos fork 不一致。
  - 建议：① 新增 **self-hosted macOS runner**（装好 DevEco + OHOS SDK）跑 `ohos-build` 任务产出 HAP（CI 当前不产 HAP，属已知缺口）；② 版本对齐已完成——全部 workflow 的 `flutter-version` 已统一为 `3.35.8` stable，与本地主版本一致。

### 24. `.github/workflows/coverage.yml`
- **(1) 功能与用途**：测试覆盖率报告 + Codecov 上传。
- **(2) 平台依赖**：GitHub Actions ubuntu。
- **(3) OHOS 兼容性**：🟡 部分兼容。Flutter 已对齐 `3.35.8`，与 `ci.yml` 同源漂移已消除；OHOS 运行时 UI 测试仍无法在 runner 上覆盖（需真机/云测）。
- **(4) 障碍与适配**：可选新增 OHOS 真机/云测任务上报覆盖率。

### 25. `.github/workflows/release.yml`
- **(1) 功能与用途**：tag 触发发版校验 + 构建 Android APK / iOS Runner.app 产物 + 创建 GitHub Release（draft）。
- **(2) 平台依赖**：GitHub Actions ubuntu/macos。
- **(3) OHOS 兼容性**：🟡 部分兼容（无 HAP 产物）。仅产出 APK + Runner.app；Flutter 版本已与本地 `3.35` 主版本对齐，SDK 漂移已消除。HAP 产出需 self-hosted runner。
- **(4) 障碍与适配**：新增 self-hosted macOS job 产出签名 HAP 并上传 artifact；注意 HAP 签名依赖本机 DevEco 签名 material。

### 26. `.github/workflows/dependabot-pr.yml`
- **(1) 功能与用途**：Dependabot PR 增量 CI（melos bs + analyze + 受影响测试）。
- **(2) 平台依赖**：GitHub Actions ubuntu。
- **(3) OHOS 兼容性**：🟡 部分兼容。Flutter 已对齐 `3.35.8`，同 `ci.yml` 的版本漂移已消除。
- **(4) 障碍与适配**：同 #23。

### 27. `AGENTS.md` / `README.md`
- **(1) 功能与用途**：项目文档（架构、技术栈、OHOS 适配要点、已知坑、构建命令）。
- **(2) 平台依赖**：文本，平台无关。
- **(3) OHOS 兼容性**：✅ 已兼容。已同步记录 Flutter 版本、CPF 插件覆盖、`Platform.operatingSystem=='ohos'` 守卫、`pubspec_overrides.yaml` 接管机制、OHOS 构建命令与已知坑。
- **(4) 障碍与适配**：需随代码/工具演进持续更新（如本清单结论应回流）。

### 28. 自定义技能模块（`.workbuddy/skills` / `.superpowers` / `.claude`）
- **(1) 功能与用途**：当前仓库**无功能性自定义技能模块**——`.workbuddy/skills/` 为空；`.superpowers/` 仅含一次 brainstorm 会话状态；`.claude/` 仅 settings。**代码生成类"技能"目前由 Mason 砖块（#17）承担**。
- **(2) 平台依赖**：n/a。
- **(3) OHOS 兼容性**：⏳ 待验证。若未来引入自定义 agent skill 脚本，需注意 OHOS 平台差异。
- **(4) 障碍与适配**：无。建议：新增 skill 脚本时避免假设 Android/iOS/web 专属 API；平台相关逻辑用 `Platform.operatingSystem` 分支；不依赖被 OHOS 移除的插件原生接口。

---

## 三、关键发现与适配建议（优先级）

| 优先级 | 发现 | 建议 |
| --- | --- | --- |
| 🟡 中 | CI 全部 workflow 不构建/不出 OHOS HAP 产物（需 self-hosted runner）；Flutter 版本漂移已修复——统一为 `3.35.8` stable，与本地 ohos fork 主版本（3.35）一致 | 引入 self-hosted macOS runner（DevEco+OHOS SDK）新增 `ohos-build` 任务产出 HAP；可选扩展 `check_workspace_versions.dart` 把 `.fvmrc` 主版本纳入断言作长期防线 |
| 🟡 中 | OHOS 构建脚本（`ohos_build.sh`/`Makefile`）硬编码 macOS DevEco 路径 | 将 `HVIGORW` 及 DevEco 路径全部参数化为环境变量，提升 Linux/Windows 可移植性 |
| 🟡 中 | `rename_project.py` 重命名不覆盖 OHOS 原生层（bundleName/ets 引用） | 扩展脚本覆盖 `ohos/` 层并文档化需同步改 DevEco 签名 |
| 🟢 低 | `coverage_local.sh` 在 Windows 无 `open`/`xdg-open` | 增加 Windows `start` 分支或文档提示手动打开 |
| 🟢 低 | 自定义技能模块为空，潜在 OHOS 平台假设风险 | 引入 skill 时遵循平台分支规范 |

## 四、结论

- **绝大多数辅助工具已兼容 OHOS**：纯 Dart/bash 类（melos、质量守门脚本、Mason 砖块、l10n、import_sorter、文档）天然跨平台；OHOS 专属工具（`ohos_utils/*`、`.ohpmrc`、`.hvigor`、`.env.ohos`、`ohos/`）本就是为 OHOS 设计且已落地。
- **主要剩余缺口在 CI/CD 的 OHOS 产物**：GitHub 托管 runner 不提供 OHOS SDK，CI 仍**不产出 HAP**（属已知缺口，需 self-hosted runner）。但 CI 的 Flutter 版本（`3.35.8` stable）已与本地 ohos fork 主版本（3.35）对齐，analyze/test 漂移已消除——质量门禁重新对本地/真机具代表性。
- **次要 caveats**：OHOS 构建脚本路径写死 macOS、`rename_project.py` 未覆盖 OHOS 原生层——均为可低成本修复的可移植性/覆盖盲区。

> 关联文档：`docs/ohos_plugin_compatibility_audit.md`（插件级兼容性）、`AGENTS.md` 第 13 节（OHOS 已知坑）。
