# Flutter → OHOS 迁移规格文档（Spec）

- **生成时间**：2026-07-14
- **状态**：草稿（供审核，尚未执行）
- **目标 Flutter 版本**：`3.35.8-ohos-1.0.1`（Dart `3.9.2`）
- **基线（干净）**：`origin/main` 提交的 `.fvmrc` = `3.27.4-ohos-1.0.4`（Dart `3.6.2`）
- **参考项目**：`/Users/yeyangyang/jzf/ovs_upgrade_335`（同样运行于 `3.35.8-ohos-1.0.1`，分支名虽为 `flutter-3.35.7-ohos`）
- **强制约束**：迁移在**新建独立 Git 分支**上实施，绝不在 `main` 当前分支直接改动。

---

## 0. 迁移分支约定（强制）

> 用户明确：不能在当前分支迁移。必须新建分支。

| 项 | 值 |
|---|---|
| 新分支名 | `upgrade/ohos-flutter-3.35.8` |
| 起点 | `origin/main`（干净提交态） |
| 当前 `main` 工作区状态 | 有未提交的 `.fvm/*` 半切换改动（`.fvmrc` 已被改成 `3.35.8`、`.fvm/version=3.38.10`、实际 `flutter=3.35.8-ohos-1.0.1`）。这些改动是“半成品”，迁移时**丢弃重做**，不带入新分支。 |

**分支创建顺序（详见 §3）**：先暂存/丢弃 `main` 上的脏 `.fvm` 改动 → `git fetch` → 从 `origin/main` 切出新分支 → 在新分支上用 FVM 干净切换到目标版本。

---

## 1. 当前项目 vs 参考项目：版本与依赖差异分析

### 1.1 版本矩阵

| 维度 | 当前仓库（干净基线） | 目标（本次迁移） | 参考项目（已落地） |
|---|---|---|---|
| Flutter | `3.27.4-ohos-1.0.4` | `3.35.8-ohos-1.0.1` | `3.35.8-ohos-1.0.1` |
| Dart | `3.6.2` | `3.9.2` | `3.9.2` |
| OHOS 平台目录 `ohos/` | **无** | 需新建 | 完整（`entry`/`AppScope`/20+ 插件模块） |
| 构建脚本 `ohos_utils/` | 无 | 参考移植/精简 | 完整（`ohos_build.sh`/`ohos_fix.sh` 等） |
| 三方原生插件（webview/baidu/微信/广告/推送） | 无 | 无（仅前瞻） | 大量（已逐个适配） |
| 当前仓库实际工作区态 | 脏：`.fvm` 半切换至 3.35.8 | — | — |

### 1.2 当前骨架的关键依赖（来自 `pubspec.yaml`）与 OHOS 兼容性预判

骨架以**纯 Dart / 通用插件**为主，未引入参考项目那类重原生插件，因此 OHOS 适配工作量显著小于参考项目。下表为逐项预判（最终以 `flutter pub get` 实际解析为准）：

| 依赖 | 约束 | 类型 | OHOS 预判 |
|---|---|---|---|
| `flutter_bloc` / `hydrated_bloc` / `bloc` | ^9.1.1 / ^11.0.0 | 纯 Dart | ✅ 无碍 |
| `go_router` | ^14.2.7 | 纯 Dart | ✅ 路由正常 |
| `dio` | ^5.4.0 | 纯 Dart（+http） | ✅ 网络正常 |
| `freezed` / `build_runner` / `flutter_gen_runner` | ^2.5.2 / ^2.4.9 / ^5.7.0 | dev | ✅ 代码生成无碍 |
| `connectivity_plus` | ^6.0.0 | 有原生层 | ✅ 参考项目同样使用，OHOS 已注册；需确认 registrant |
| `hive_flutter` / `hive` | ^1.1.0 | 本地存储 | ⚠️ `hive` 纯 Dart，但存储路径依赖 `path_provider` 的 OHOS 实现；需确认 `path_provider_ohos` 解析到位 |
| `intl` | ^0.20.0 | 纯 Dart | ✅ 国际化正常 |
| `sentry_flutter` | ^8.13.0 | 有原生层 | ⚠️ Sentry 对 OHOS 的支持随版本演进；8.13 可能仅基础能力，需真机验证，必要时升 9.x |
| `upgrader` | ^10.3.0 | 含平台更新逻辑 | ⚠️ OHOS 无应用市场内更新通道；建议按 `Platform.isOHOS` 守卫禁用强制更新弹窗 |
| `alice` | ^0.4.2 | Flutter overlay | ⚠️ 叠层调试面板，需确认在 OHOS 渲染正常 |
| `flutter_launcher_icons` / `flutter_native_splash` | ^0.14.3 / ^2.4.1 | 资源生成（iOS/Android） | ⚠️ 不生成 OHOS icon/splash；OHOS 图标/开屏需在 `AppScope/app.json5` + `ohos/entry` 单独配置 |
| `flutter_lints` | ^4.0.0 | dev lint | ⚠️ Flutter 3.35 自带 lint 规则升级，建议升 `^5.0.0` 或保持（仅警告不致命） |
| `melos` | ^6.2.0 | 工作区 | ✅ 无碍 |

### 1.3 差异结论

1. **骨架复杂度低**：没有 WebView / 地图 / 微信 / 广告 / 推送等需逐个 hack 的原生插件，OHOS 适配核心是**工具链 + 平台目录 + 少量插件的注册与守卫**，而非大量运行时修补。
2. **真正会踩的坑**（来自参考项目经验）：`GeneratedPluginRegistrant.ets` 被覆盖、插件源码与 pub cache 版本错配、OHOS 不接受 `--dart-define-from-file`、`.env.ohos`/`.ohpmrc`/`.pub-cache-335` 的忽略与注入、DevEco/SDK 前置。这些在 §5 逐一给出方案。
3. **前瞻坑**（骨架暂未用到，但 §5 记录以免日后重复踩）：ArkWeb 内核升级、百度地图 `markerToMap` 空 identifier、广告插件 OHOS no-op。

---

## 2. 前置条件（机器 / CI 必须具备）

| 前置 | 说明 | 检查命令 |
|---|---|---|
| FVM 目标 SDK | 本地已缓存 `3.35.8-ohos-1.0.1`（`/Users/yeyangyang/fvm/versions/3.35.8-ohos-1.0.1`） | `fvm list` |
| DevEco Studio | 含 OHOS SDK（参考项目路径 `/Applications/DevEco-Studio.app`） | `ls /Applications/DevEco-Studio.app` |
| OHOS SDK 环境变量 | `HOS_SDK_HOME` / `DEVECO_SDK_HOME` 指向 SDK（`.../Contents/sdk`） | `echo $HOS_SDK_HOME` |
| hvigor | `DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw` | `hvigorw --version` |
| ohpm | 通过 `.ohpmrc` 配置registry（`https://ohpm.openharmony.cn/ohpm/`） | `ohpm -v` |
| Node | hvigor/ohpm 依赖 Node | `node -v` |
| 签名 | `entry-default-signed.hap` 需签名配置（参考项目用自动签名/debug 证书） | 见 DevEco 工程签名 |

> 若机器/CI 缺上述任一项，`flutter build hap` 与 `hvigorw assembleHap` 会失败。参考项目已沉淀 `OHOS_BUILD_CHECKLIST`（换机/CI 前置清单）——移植时可一并复制该清单文件。

---

## 3. FVM 版本切换步骤（在新分支上）

```bash
cd /Users/yeyangyang/Desktop/my_app

# ① 清理 main 上的脏 .fvm 改动（半切换状态，丢弃重做）
git stash push -m "wip: discard half-done fvm switch on main" -- .fvm   # 或：git checkout -- .fvm .fvmrc
git fetch origin

# ② 从干净 origin/main 切出迁移分支
git checkout -b upgrade/ohos-flutter-3.35.8 origin/main

# ③ 用 FVM 切换到目标版本（会改写 .fvmrc / .fvm/version 并重建软链）
fvm use 3.35.8-ohos-1.0.1 --force
# 校验
cat .fvmrc          # 期望 {"flutter": "3.35.8-ohos-1.0.1"}
flutter --version   # 期望 Flutter 3.35.8-ohos-1.0.1 • Dart 3.9.2

# ④ 提交 FVM 切换（基线变更，独立 commit 便于追溯）
git add .fvmrc .fvm/version .fvm/flutter_sdk .fvm/fvm_config.json
git commit -m "chore(fvm): switch Flutter SDK to 3.35.8-ohos-1.0.1"
```

> 注：`.fvm/flutter_sdk` 是软链，FVM 会自动指向缓存版本；不要手动改它。若 `fvm use` 报“版本未下载”，执行 `fvm install 3.35.8-ohos-1.0.1`（本地已存在，跳过）。

---

## 4. OHOS 平台适配步骤

### 4.1 生成平台目录

因当前仓库**没有** `ohos/` 目录，用 OHOS Flutter SDK 直接生成（生成的即 3.35 模板，天然正确，规避参考项目的“模板版本错配”坑）：

```bash
# 在迁移分支、已 fvm use 目标版本后
flutter create --platforms=ohos .
```

该命令生成：`ohos/AppScope`、`ohos/entry`、`ohos/build-profile.json5`、`ohos/hvigorfile.ts`、`ohos/oh-package.json5`、各插件模块目录及 `oh_modules` 软链。

### 4.2 环境配置文件（从参考项目移植）

- 新建 `.env.ohos`：注入编译期常量（`ovsx-app-token` 等骨架自己的令牌；骨架当前用 `env/.env.*` 三件套做 dev/staging/prod 注入，见 §5.7 关于 `--dart-define` 的讨论）。
- 新建 `.ohpmrc`：`registry=https://ohpm.openharmony.cn/ohpm/`（可加私有源）。
- 在 `.gitignore` 追加：`oh_modules/`（软链，不提交）、`.pub-cache-335/`（若有）、`ohos/**/build/`、`.flutter-plugins-dependencies`（由 pub get 生成，建议忽略）。

### 4.3 插件注册与 `ohos_fix` 模式

- 骨架插件（connectivity_plus/path_provider/hive 等）若 pub.dev 自带 ohos 实现，`flutter build hap` 会自动写入 `GeneratedPluginRegistrant.ets`。
- **坑（参考项目铁律）**：`flutter build hap` 会**重新生成** `GeneratedPluginRegistrant.ets` 并**丢弃本地/custom 插件**注册。骨架暂未引入 custom 插件，但仍建议保留一份最小 `ohos_fix.sh`：
  - 若日后加入本地插件（如 webview/baidu fork），必须在每次 `flutter build hap` **之后**重跑 `ohos_fix.sh` 把插件补回 registrant。
  - 提供最小 `ohos_fix.sh` 模板（仅做 registrant 兜底 + 模板选择），或直接移植参考项目的 `ohos_fix.sh`（它已按 `.fvmrc` 自动选 `templates/3.35`）。

### 4.4 构建脚本

移植参考项目 `ohos_utils/ohos_build.sh`（黑盒调用），其流程为：
1. `flutter pub get`
2. `ohos_fix.sh`（修 registrant / 同步插件源码）
3. `flutter build hap --release --dart-define=...`（重编 kernel；`--full` 模式）
4. 再次 `ohos_fix.sh`（被 build hap 覆盖后补回）
5. `hvigorw assembleHap -p product=default -p buildMode=release --no-daemon`
6. 产出 `ohos/entry/build/default/outputs/default/entry-default-signed.hap`

> 迁移阶段可先用 `debug` 模式快速验证：`ohos_utils/ohos_build.sh debug`。

---

## 5. OHOS 适配已知问题及解决方案（来自参考项目经验）

| # | 问题 | 现象 | 解决方案 | 骨架相关性 |
|---|---|---|---|---|
| K1 | `GeneratedPluginRegistrant.ets` 被覆盖 | build 后插件注册数减少，运行时 `MissingPluginException` | 每次 `flutter build hap` 后重跑 `ohos_fix.sh` | 当前低；引入 custom 插件后必踩 |
| K2 | 插件 ohos 源码与 pub cache 版本错配 | Dart 调新 channel，原生 HAR 仍是旧实现 | `ohos_fix.sh` 同步逻辑；或删 `ohos/<plugin>` 后重新 `pub get` | 插件升级时触发 |
| K3 | 模板版本错配（3.27/3.35 默认模板漏注册 app_links 等） | 部分插件未注册 | 按 `.fvmrc` 自动选 `templates/3.35` | 已规避（4.1 用 3.35 SDK 生成） |
| K4 | ArkWeb 132→144 内核升级（WebView） | H5 加载/SSL/排版异常 | 用 CPF 鸿蒙 fork `br_webview_flutter-v4.13.0_ohos`（dependency_overrides）+ `mixedMode(All)`/`fileAccess`/`onSslErrorEventReceive`；真机验收证书 | 前瞻（骨架暂无 webview） |
| K5 | 百度地图 `markerToMap` 不回传 identifier | 点 marker 不选中/不居中 | 改用经纬度在自有 marker 列表匹配 | 前瞻（骨架无地图） |
| K6 | 广告插件 OHOS 不展示 | 开屏/信息流/横幅不显示但不崩 | 接受 no-op，加注释守卫 | 前瞻 |
| K7 | **OHOS 不接受 `--dart-define-from-file`** | `ohos_build.sh` 收不到 env 文件 | 必须展开为多个 `--dart-define=K=V` 传入 | **高**（影响骨架 3 套 env 注入，见 §5.7） |
| K8 | `.pub-cache-335/` 与 `oh_modules` 软链未忽略 | 换机/CI 丢失缓存或被误提交 | 加入 `.gitignore` | 高 |
| K9 | 隐式依赖警告 | 直接 import 但未在 pubspec 声明，`dart analyze` 报 implicit dependency | 显式声明全部直接依赖（与 R1–R4 一致） | 中（契合现有守门规则） |
| K10 | DevEco/SDK/hvigor/ohpm/node 前置缺失 | `flutter build hap`/`hvigorw` 失败 | 机器与 CI 安装全套前置（§2） | 高 |
| K11 | `sentry_flutter`/`upgrader`/`alice` OHOS 支持 | 构建或运行异常 | 真机验证；`upgrader` 按 `Platform.isOHOS` 守卫禁用；必要时升 sentry 9.x | 中（需 §6 验证项覆盖） |

### 5.7 关于骨架 3 套 env 注入的特殊处理（K7 重点）

骨架当前通过 `env/.env.dev|staging|prod` + 启动时 assert（R5）做环境注入，Android/iOS 构建用 `--dart-define-from-file`。**OHOS 构建不接收 `--dart-define-from-file`**，因此：

- 为 OHOS 准备等价的 `--dart-define=KEY=VALUE` 列表（参考项目 `build.sh` 用 `json_to_dart_defines` 把 JSON 展开为列表）。
- 在 `ohos_utils/ohos_build.sh` 中传入该列表；命令行 `--dart-define` 优先级高于 `.env.ohos`。
- 确保 `EnvironmentConfig` 的 3 套字段在 OHOS 下同样齐全（否则启动时 assert 崩溃，R5）。

---

## 6. 迁移后验证与测试清单

### 6.1 静态 / 单元（不依赖设备）

- [ ] `cat .fvmrc` → `3.35.8-ohos-1.0.1`；`flutter --version` 一致
- [ ] `melos bs` 全量 bootstrap 成功
- [ ] `flutter pub get` 无依赖冲突（重点看 K2/K9 相关警告）
- [ ] `melos analyze`（`dart analyze` 仅拦 error）通过
- [ ] `melos test` 全绿（domain/services/features 逻辑层）
- [ ] `./scripts/check_deps.sh` 通过（依赖方向 R1/R3/R4 不被破坏）
- [ ] `make scaffold-check` 通过

### 6.2 OHOS 构建与运行

- [ ] `flutter create --platforms=ohos .` 成功生成 `ohos/`（或已存在且对齐 3.35 模板）
- [ ] `flutter build hap` 成功产出 `entry-default-signed.hap`
- [ ] `GeneratedPluginRegistrant.ets` 插件注册数符合预期（无 K1 丢失）
- [ ] 真机/模拟器冒烟：App 启动 → 路由跳转（go_router）→ 网络（dio）→ 本地存储（hive）→ 国际化（intl）→ 调试面板（alice，若启用）
- [ ] OHOS env 注入（`--dart-define` 列表）生效，`EnvironmentConfig` 三套字段齐全（R5 不崩）

### 6.3 三端回归（确认未引入回归）

- [ ] Android：`flutter build apk --release --dart-define-from-file=env/.env.dev` 通过
- [ ] iOS：`flutter build ipa --release` 通过
- [ ] OHOS：`flutter build hap --release` 通过
- [ ] 文档同步更新：AGENTS.md 中 Flutter 版本（当前误写 3.38.10）、README、env 说明

---

## 7. 回滚方案

因全程在独立分支 `upgrade/ohos-flutter-3.35.8` 实施，**回滚成本极低**：

1. **未合并即废弃**：`git checkout main` 回到原状；分支保留可复查，`git branch -D upgrade/ohos-flutter-3.35.8` 删除。
2. **分支内部分提交需撤销**：在分支上 `git revert <commits...>`（保留历史）或 `git reset --hard origin/main`（丢弃分支本地提交，谨慎）。
3. **FVM 回退**：`fvm use 3.27.4-ohos-1.0.4 --force` 恢复 `.fvmrc`；若已误改，可 `git checkout origin/main -- .fvmrc .fvm/version`。
4. **重建原生产物**：回滚后 `oh_modules` 与 `ohos/` 需重新 `flutter pub get`；若 `ohos/` 已提交且想彻底移除，`git clean -fd ohos` 谨慎执行（先确认无业务改动）。
5. **若已合并到 main**：按常规 revert PR 流程，单 commit 回退即可。

> 回滚红线：绝不在 `main` 上直接做破坏性 `reset --hard`，一律走分支 + revert。

---

## 8. 待确认 / 开放项（审核时请一并确认）

1. **目标版本**：已按确认采用 `3.35.8-ohos-1.0.1`（本地缓存唯一可用的 3.35.x OHOS 版，且与参考项目一致）。若你确实锁定 `3.35.7-ohos`，需先 `fvm install` 该版本再调整本 Spec。
2. **`sentry_flutter` / `upgrader` / `alice`**：是否接受“先迁移、真机验证、必要时升级版本”的策略？还是要求迁移即锁定已验证的 OHOS 兼容版本？
3. **`ohos/` 与 `ohos_utils/`**：是完整移植参考项目脚手架，还是仅取最小可用子集（生成 + 最小 `ohos_fix.sh` + `ohos_build.sh`）？
4. **OHOS icon / splash**：是否现在就补齐 `AppScope/app.json5` 与 `ohos/entry` 的图标/开屏资源？

---

## 9. 执行触发

本 Spec 仅供**审核**。确认后由我在 `upgrade/ohos-flutter-3.35.8` 分支按 §3→§4 顺序执行，并在每步后跑 §6 校验。也可指定改用独立 worktree 隔离执行。
