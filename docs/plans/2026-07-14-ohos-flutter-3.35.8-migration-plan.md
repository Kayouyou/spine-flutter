# Flutter → OHOS 迁移实施计划 (Implementation Plan)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 `spine_flutter` 从干净基线 `3.27.4-ohos-1.0.4` 迁移到 `3.35.8-ohos-1.0.1`，并新增 OpenHarmony（OHOS）平台的可构建/可运行能力，全部在独立分支 `upgrade/ohos-flutter-3.35.8` 上完成。

**Architecture:** 采用 FVM 切换 Flutter SDK + `flutter create --platforms=ohos .` 生成 OHOS 平台目录；沿用参考项目 `ovs_upgrade_335` 沉淀的 `ohos_build.sh` / `ohos_fix.sh` 构建与插件注册修复模式；骨架以纯 Dart/通用插件为主，仅需对 `upgrader`（OHOS 无应用市场更新通道）做平台守卫，并对 `sentry`/`alice` 做真机验证。环境注入沿用 `--dart-define`，因 OHOS 不支持 `--dart-define-from-file`，构建脚本负责把 `env/.env.*`（KEY=VALUE）展开为 `--dart-define=K=V`。

**Tech Stack:** Flutter `3.35.8-ohos-1.0.1` (Dart 3.9.2) / FVM / Melos monorepo / DevEco Studio + OHOS SDK + hvigor + ohpm + Node / OpenHarmony ArkTS(ets)。

> **执行隔离**：用户强制要求用新建 Git 分支（非 worktree）。本计划全程在 `upgrade/ohos-flutter-3.35.8` 分支执行；如需额外隔离，可 `git worktree add ../my_app-ohos upgrade/ohos-flutter-3.35.8` 但不强制。
> **配套设计文档**：`docs/plans/2026-07-14-ohos-flutter-3.35.8-migration-spec.md`（本计划严格遵照其章节）。

---

## 任务依赖关系（概览）

```
T0.1 切分支 ─┬─ T0.2 前置校验
             │
T1.1 FVM切换 ─ T1.2 校验+提交
             │
T2.1 生成ohos/ ─ T2.2 校验+提交
             │
T3.1 .env.ohos ┐
T3.2 .ohpmrc   ├─ T3.3 .gitignore ─ T3.4 提交
T3.x (env展开) ┘
             │
T4.1 melos bs ─ T4.2 pub get ─ T4.3 analyze ─ T4.4 test ─ T4.5 check_deps ─ T4.6 提交
             │
T5.1 ohos_build.sh ┐
T5.2 ohos_fix.sh  ├─ T5.3 提交
             │
T6.1 upgrader守卫(+测试) ┐
T6.2 sentry守卫(验证)    ├─ T6.4 提交
T6.3 alice验证          ┘
             │
T7.1 build hap ─ T7.2 registrant/产物校验 ─ T7.3 提交
             │
T8.1 OHOS冒烟 ─ T8.2 Android回归 ─ T8.3 iOS回归 ─ T8.4 提交
             │
T9.1 AGENTS.md ┐
T9.2 README    ├─ T9.3 提交
             │
T10.1 回滚预案复核
```

> 规则：每个 Task 完成后单独 `git commit`（频繁提交、原子化）。所有命令默认在仓库根 `/Users/yeyangyang/Desktop/my_app` 执行。

---

## Phase 0 — 准备与分支（前提）

### Task 0.1: 清理脏改动并从干净 `origin/main` 切出迁移分支

**Files:**
- Modify: `.fvmrc`, `.fvm/version`, `.fvm/flutter_sdk`, `.fvm/fvm_config.json`（将被 FVM 在 T1.1 重写；此处先丢弃当前半成品）
- Create（branch）: `upgrade/ohos-flutter-3.35.8`

**Step 1: 丢弃 main 上半切换的 .fvm 改动**
```bash
cd /Users/yeyangyang/Desktop/my_app
git stash push -m "wip: discard half-done fvm switch on main" -- .fvm .fvmrc
git fetch origin
```
Expected: stash 成功；`git status` 仅剩 stash 提示，工作区恢复为 `origin/main` 提交态（`.fvmrc` = `3.27.4-ohos-1.0.4`）。

**Step 2: 从 origin/main 切出新分支**
```bash
git checkout -b upgrade/ohos-flutter-3.35.8 origin/main
```
Expected: `Switched to a new branch 'upgrade/ohos-flutter-3.35.8'`.

**Step 3: 提交（本步仅建立分支，无代码改动，可跳过 commit；stash 保留以备核查）**
> 不需 commit（仅分支指针）。stash 后续可 `git stash drop` 删除。

**Acceptance:** `git branch --show-current` 输出 `upgrade/ohos-flutter-3.35.8`；`git log -1 --oneline` 与 `origin/main` 一致。

### Task 0.2: 校验机器/CI 前置条件（DevEco/SDK/hvigor/ohpm/node）

**Files:** 无（仅校验）

**Step 1: 逐项检查**
```bash
fvm list | grep -E "3.35.8-ohos-1.0.1" && echo "SDK_OK"
test -d /Applications/DevEco-Studio.app && echo "DEVECO_OK"
test -n "$HOS_SDK_HOME" && echo "SDK_HOME=$HOS_SDK_HOME" || echo "SET HOS_SDK_HOME"
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --version 2>/dev/null && echo "HVIGOR_OK" || echo "HVIGOR_MISSING"
ohpm -v 2>/dev/null && echo "OHPM_OK" || echo "OHPM_MISSING"
node -v
```
Expected: `SDK_OK` 与 `DEVECO_OK` 必现；`HOS_SDK_HOME` 需已导出（否则 `export HOS_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`）；hvigor/ohpm/node 可用。

**Step 2: 缺失项处理**
若任一缺失，暂停并安装（DevEco Studio + Command Line Tools；ohpm 随 DevEco 或 `npm i -g @ohos/ohpm-cli`；Node 用系统/ nvm）。记录到 `.env.ohos`/CI 文档。

**Acceptance:** 全部前置项输出 `*_OK`（或已记录缺失项处理方案）。

---

## Phase 1 — FVM 版本切换

### Task 1.1: 用 FVM 切换到 `3.35.8-ohos-1.0.1`

**Files:**
- Modify: `.fvmrc`, `.fvm/version`, `.fvm/flutter_sdk`(软链), `.fvm/fvm_config.json`

**Step 1: 切换**
```bash
fvm use 3.35.8-ohos-1.0.1 --force
```
Expected: 输出包含 `Flutter SDK 3.35.8-ohos-1.0.1 ...` 且 `.fvmrc updated`。

**Step 2: 校验**
```bash
cat .fvmrc
flutter --version
```
Expected: `.fvmrc` 为 `{"flutter": "3.35.8-ohos-1.0.1"}`；`flutter --version` 首行 `Flutter 3.35.8-ohos-1.0.1 • channel [user-branch] • ... Dart 3.9.2`。

### Task 1.2: 提交 FVM 切换

**Step 1: 提交**
```bash
git add .fvmrc .fvm/version .fvm/flutter_sdk .fvm/fvm_config.json
git commit -m "chore(fvm): switch Flutter SDK to 3.35.8-ohos-1.0.1"
```
**Acceptance:** `git show --stat HEAD` 仅含 `.fvm*` 文件；`flutter --version` 为目标版本。

---

## Phase 2 — 新增 OHOS 平台目录

### Task 2.1: 生成 OHOS 平台代码

**Files:**
- Create: `ohos/AppScope/...`, `ohos/entry/...`, `ohos/build-profile.json5`, `ohos/hvigorfile.ts`, `ohos/oh-package.json5`, `oh_modules/`(软链，不提交)

**Step 1: 生成**
```bash
flutter create --platforms=ohos .
```
Expected: 输出含 `Ohos ... created`；生成 `ohos/` 目录（3.35 模板，规避 Spec K3 模板错配坑）。

**Step 2: 不提交生成物**
> `oh_modules`/构建产物稍后在 `.gitignore` 处理；本步先检查生成结果。

### Task 2.2: 校验生成并暂存结构

**Step 1: 校验关键文件存在**
```bash
test -f ohos/AppScope/app.json5 && echo "APPSCOPE_OK"
test -f ohos/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets && echo "REGISTRANT_OK"
ls ohos/entry/src/main/ets/
```
Expected: `APPSCOPE_OK` 与 `REGISTRANT_OK`；存在 `EntryAbility.ets`/`Index.ets`/`plugins/`。

**Step 2: 提交 ohos 结构（不含 oh_modules/build）**
```bash
# 先加 .gitignore 片段（见 T3.3）或直接：
git add ohos
git commit -m "feat(ohos): scaffold OHOS platform via flutter create"
```
**Acceptance:** `git ls-files ohos | head` 列出 `ohos/AppScope/app.json5` 等；无 `oh_modules` 被跟踪（`git ls-files | grep oh_modules` 为空）。

---

## Phase 3 — 环境配置文件

### Task 3.1: 创建 `.env.ohos`（OHOS 编译期常量）

**Files:**
- Create: `.env.ohos`

**Step 1: 从 `env/.env.dev` 对齐字段写入**
参考骨架 `EnvironmentConfig` 所需字段（`lib/config.dart`）：`ENV`、`API_HOST`（API 根地址权威源，`apiBaseUrl` 由其派生）、`API_ACCESS_KEY_ID`、`OSS_BUCKET`、`OSS_ENDPOINT`、`OSS_ACCESS_KEY`、`SENTRY_DSN`、`APP_STORE_ID`、`APP_VERSION`、`BUILD_NUMBER`、`ENABLE_AUTH_GUARD`。
```bash
cat > .env.ohos <<'EOF'
ENV=dev
API_HOST=dev-host.placeholder.invalid
API_ACCESS_KEY_ID=
OSS_BUCKET=dev-bucket.placeholder.invalid
OSS_ENDPOINT=https://oss-cn-zhangjiakou.aliyuncs.com
OSS_ACCESS_KEY=
SENTRY_DSN=
APP_STORE_ID=
APP_VERSION=0.3.0
BUILD_NUMBER=0
ENABLE_AUTH_GUARD=true
EOF
```
Expected: `.env.ohos` 写入 11 行 KEY=VALUE。

> 注意：`.env.ohos` 仅作 OHOS 构建兜底；生产值由 `ohos_build.sh` 的 `--dart-define` 列表覆盖（命令行优先，对应 Spec K7）。**不要在此写入真实密钥并提交**——生产密钥走 CI 变量。

### Task 3.2: 创建 `.ohpmrc`

**Files:**
- Create: `.ohpmrc`

**Step 1: 写入 registry**
```bash
cat > .ohpmrc <<'EOF'
registry=https://ohpm.openharmony.cn/ohpm/
EOF
```
Expected: `.ohpmrc` 含上述 registry 行。

### Task 3.3: 更新 `.gitignore`

**Files:**
- Modify: `.gitignore`

**Step 1: 追加 OHOS 忽略项**
```bash
cat >> .gitignore <<'EOF'

# ===== OHOS (Flutter 3.35 migration) =====
oh_modules/
**/oh_modules/
.pub-cache-335/
ohos/**/build/
ohos/**/.hvigor/
.flutter-plugins-dependencies
ohos/.idea/
EOF
```
Expected: `.gitignore` 末尾新增 OHOS 段。

**Step 2: 校验 oh_modules 不再被跟踪**
```bash
git status --porcelain | grep -E "oh_modules" && echo "LEAK!" || echo "CLEAN"
```
Expected: `CLEAN`（无 oh_modules 出现在待提交列表）。

### Task 3.4: 提交环境配置

**Step 1: 提交**
```bash
git add .env.ohos .ohpmrc .gitignore
git commit -m "chore(ohos): add .env.ohos, .ohpmrc and gitignore for OHOS"
```
**Acceptance:** `git show --stat HEAD` 含这三个文件；`git ls-files | grep oh_modules` 为空。

---

## Phase 4 — 依赖解析与静态校验

### Task 4.1: Melos bootstrap

**Step 1: 全量 bootstrap**
```bash
melos bs
```
Expected: 各 package 链接成功，结尾无 error。

### Task 4.2: 解析依赖（`flutter pub get`，关注 K2/K9）

**Step 1: 根工程 pub get**
```bash
flutter pub get
```
Expected: `Running "flutter pub get"...` → `... dependencies resolved`。**重点检查**：无 `version solving failed`；留意警告中是否出现 implicit dependency（Spec K9）或插件 ohos 源码与 cache 不一致（K2）。

**Step 2: 记录警告**
若 `pub get` 报某插件无 OHOS 实现或 implicit dependency，写入本 Task 备注，供 T6/T8 处理。

### Task 4.3: 静态分析

**Step 1: 全量 analyze（仅拦 error）**
```bash
melos analyze
```
Expected: 无 `error:` 输出（`--no-fatal-infos --no-fatal-warnings` 下警告不致命）。

### Task 4.4: 单元测试

**Step 1: 全量测试**
```bash
melos test
```
Expected: `All tests passed` 或各 package 测试通过（Dart/逻辑层，不依赖设备）。

### Task 4.5: 依赖方向守门（R1/R3/R4）

**Step 1: 运行守门脚本**
```bash
./scripts/check_deps.sh
```
Expected: 脚本以 0 退出，无依赖方向违规。

### Task 4.6: 提交解析结果

**Step 1: 提交（若有 lock/生成文件变更）**
```bash
git add pubspec.lock
git commit -m "chore(deps): resolve dependencies under Flutter 3.35.8-ohos" || echo "no changes"
```
**Acceptance:** `melos analyze`、`melos test`、`check_deps.sh` 三项全绿。

---

## Phase 5 — 构建脚本

### Task 5.1: 创建 `ohos_utils/ohos_build.sh`（含 env 展开，解决 K7）

**Files:**
- Create: `ohos_utils/ohos_build.sh`

**Step 1: 写入构建脚本**
脚本要点（完整可参考参考项目 `ohos_utils/ohos_build.sh`）：
1. `FLUTTER=.fvm/flutter_sdk/bin/flutter`；`HVIGORW=/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw`；`DEVECO_SDK_HOME` 来自环境。
2. **K7 关键**：将 `env/.env.<ENV>`（KEY=VALUE）展开为 `--dart-define=K=V` 列表：
```bash
env_to_defines() {
  local f="$1" out=()
  while IFS='=' read -r k v; do
    [ -z "$k" ] && continue; [[ "$k" =~ ^# ]] && continue
    k=$(echo "$k" | xargs); v=$(echo "$v" | xargs)
    out+=("--dart-define=$k=$v")
  done < "$f"
  printf '%s\n' "${out[*]}"
}
```
3. 流程：`flutter pub get` → `ohos_fix.sh` → `flutter build hap --$MODE ${DEFINES[*]}`（`--full` 时）→ 再次 `ohos_fix.sh` → `hvigorw assembleHap -p product=default -p buildMode=$MODE --no-daemon`。
4. 用法：`./ohos_utils/ohos_build.sh debug [--full] --env=dev`（env 决定读取 `env/.env.<ENV>`）。

**Step 2: 加执行权限**
```bash
chmod +x ohos_utils/ohos_build.sh
```

### Task 5.2: 创建最小 `ohos_fix.sh`（registrant 兜底 + 模板选择，解决 K1/K2/K3）

**Files:**
- Create: `ohos_utils/ohos_fix.sh`

**Step 1: 写入最小修复脚本**
骨架当前无 custom 本地插件，最小版只需：
- 按 `.fvmrc` 选模板目录（3.35 → `ohos/templates/3.35`；本迁移恒为 3.35）。
- 兜底：若 `GeneratedPluginRegistrant.ets` 中插件注册数为 0 或缺失，提示需补注册（未来引入本地插件时扩展同步逻辑，参考参考项目 `ohos_fix.sh` 的 Python 同步段）。
- 输出当前注册插件数便于校验。

**Step 2: 加执行权限**
```bash
chmod +x ohos_utils/ohos_fix.sh
```

### Task 5.3: 提交构建脚本

**Step 1: 提交**
```bash
git add ohos_utils
git commit -m "feat(ohos): add ohos_build.sh / ohos_fix.sh build scripts"
```
**Acceptance:** `bash -n ohos_utils/ohos_build.sh && bash -n ohos_utils/ohos_fix.sh` 语法检查通过（无输出即 OK）。

---

## Phase 6 — 插件守卫与适配（代码，含 TDD）

### Task 6.1: `upgrader` OHOS 守卫（含单元测试，解决 Spec §5.7/§K11）

**Files:**
- Modify: `lib/app.dart:174-176`
- Create: `lib/core/services/upgrade_guard.dart`（纯函数，便于测试）
- Create: `test/unit/bootstrap/upgrade_guard_test.dart`

**Step 1: 写失败测试**
`test/unit/bootstrap/upgrade_guard_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/bootstrap/bootstrap_options.dart';
import 'package:my_app/core/services/upgrade_guard.dart';

void main() {
  test('enableUpgradePrompt=false -> 不包裹', () {
    final o = BootstrapOptions(enableUpgradePrompt: false);
    expect(shouldWrapUpgrade(o, isOhos: false), isFalse);
  });
  test('enableUpgradePrompt=true 且非OHOS -> 包裹', () {
    final o = BootstrapOptions(enableUpgradePrompt: true);
    expect(shouldWrapUpgrade(o, isOhos: false), isTrue);
  });
  test('OHOS 平台 -> 永远不包裹(无应用市场更新通道)', () {
    final o = BootstrapOptions(enableUpgradePrompt: true);
    expect(shouldWrapUpgrade(o, isOhos: true), isFalse);
  });
}
```
**Step 2: 运行测试确认失败**
```bash
flutter test test/unit/bootstrap/upgrade_guard_test.dart
```
Expected: FAIL（`Couldn't find ... upgrade_guard`）。

**Step 3: 实现纯函数**
`lib/core/services/upgrade_guard.dart`:
```dart
import '../bootstrap/bootstrap_options.dart';

/// OHOS 无应用市场内更新通道，强制禁用 upgrader 包裹。
bool shouldWrapUpgrade(BootstrapOptions options, {required bool isOhos}) =>
    options.enableUpgradePrompt && !isOhos;
```

**Step 4: 修改调用点**
`lib/app.dart` 第 174 行附近：
```dart
import 'package:my_app/core/services/upgrade_guard.dart';
import 'dart:io';
...
if (shouldWrapUpgrade(options, isOhos: Platform.isOHOS)) {
  app = UpgradeWrapper(child: app);
}
```

**Step 5: 运行测试确认通过**
```bash
flutter test test/unit/bootstrap/upgrade_guard_test.dart
```
Expected: `All tests passed`.

**Step 6: 提交**
```bash
git add lib/core/services/upgrade_guard.dart lib/app.dart test/unit/bootstrap/upgrade_guard_test.dart
git commit -m "fix(ohos): guard upgrader UpgradeWrapper on OHOS (no app-market channel)"
```

### Task 6.2: `sentry_flutter` OHOS 守卫与验证（解决 K11）

**Files:**
- Modify（按需）: `packages/services/error/lib/...`（定位 `SentryFlutter.init` 调用点，通常在 error 服务 bootstrap）
- Test（按需）: 真机验证为主，不强制单测

**Step 1: 定位 init 调用**
```bash
grep -rn "SentryFlutter.init" lib packages
```
**Step 2: 真机验证**
在 OHOS 设备/模拟器运行，观察 Sentry 初始化是否报错或崩溃（8.x 对 OHOS 支持可能有限）。
**Step 3: 按需加守卫**
若初始化异常，将 init 包一层 `if (!Platform.isOHOS)`（或捕获异常），保留 `SentryReporter` 在非 OHOS 生效；OHOS 下 `captureException` 静默 no-op。
**Acceptance:** OHOS 启动不因 Sentry 崩溃；非 OHOS 行为不变。

### Task 6.3: `alice` OHOS 验证（解决 K11）

**Files:** `lib/app.dart:61`（调试面板）、`packages/infrastructure/api/lib/src/dio_factory.dart`（AliceInterceptor）

**Step 1: 真机验证**
OHOS 运行（开 `enableDebugTools`）确认 Alice 悬浮窗/拦截面板正常渲染；Dio 请求在 Alice 中可见。
**Step 2: 按需守卫**
若 OHOS 上 overlay 异常，在 `lib/app.dart:60` 与 `dio_factory` 的 AliceInterceptor 注入处加 `!Platform.isOHOS` 守卫。
**Acceptance:** OHOS 调试面板可用或不崩；生产（默认关）不受影响。

### Task 6.4: 提交插件适配
```bash
git add -A packages/services/error lib/app.dart packages/infrastructure/api
git commit -m "fix(ohos): harden sentry/alice for OHOS (guard where needed)" || echo "no changes"
```

---

## Phase 7 — OHOS 构建

### Task 7.1: 构建 HAP（debug）

**Step 1: 运行构建脚本**
```bash
./ohos_utils/ohos_build.sh debug --env=dev
```
Expected: 脚本依次 pub get → fix → hvigorw assembleHap；结尾 `✅ [ohos_build] 构建完成！` 并给出 `entry-default-signed.hap` 路径。

**Step 2: 失败排查**
若 `flutter build hap` 报 `Error:`，查 `/tmp/flutter_build_hap.log`；常见为 K1/K2 → 重跑 `ohos_fix.sh` 后重试。

### Task 7.2: 校验 registrant 与产物

**Step 1: 检查插件注册数（K1）**
```bash
grep -c 'add(new' ohos/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets
test -f ohos/entry/build/default/outputs/default/entry-default-signed.hap && echo "HAP_OK"
```
Expected: 注册数 > 0（与 `flutter pub get` 解析到的 ohos 插件数一致，骨架预期较小如 connectivity_plus/path_provider 等）；`HAP_OK`。

### Task 7.3: 提交 ohos 生成物（按需）
```bash
git add ohos
git commit -m "build(ohos): generate registrant + hap build artifacts" || echo "no new tracked files"
```
**Acceptance:** `flutter build hap` 成功；`entry-default-signed.hap` 存在；registrant 插件数符合预期。

---

## Phase 8 — 真机/模拟器冒烟与三端回归

### Task 8.1: OHOS 真机/模拟器冒烟
**Step 1: 安装并启动**
```bash
# 用 DevEco Studio 打开 ohos/ 或直接 hdc install
hdc install ohos/entry/build/default/outputs/default/entry-default-signed.hap
```
**Step 2: 冒烟清单**（逐项勾选）
- [ ] App 正常启动，无 `MissingPluginException`
- [ ] 路由跳转（go_router）正常
- [ ] 网络请求（dio）成功
- [ ] 本地存储（hive）读写正常
- [ ] 国际化（intl）切换正常
- [ ] `--dart-define` 注入的 env 生效（`EnvironmentConfig` 三套字段齐全，无 R5 启动崩溃）
- [ ] 调试面板（alice，若启用）正常
**Acceptance:** 全部勾选通过；失败项回到 T6/T7 修复后重测。

### Task 8.2: Android 回归
```bash
flutter build apk --release --dart-define-from-file=env/.env.dev
```
Expected: `app-release.apk` 产出，无回归。

### Task 8.3: iOS 回归
```bash
flutter build ipa --release --dart-define-from-file=env/.env.prod
```
Expected: `.ipa` 产出（iOS 仍用 `--dart-define-from-file`，不受影响）。

### Task 8.4: 提交回归修复（如有）
```bash
git add -A && git commit -m "fix: address OHOS/three-platform regression findings" || echo "no changes"
```

---

## Phase 9 — 文档更新

### Task 9.1: 更新 `AGENTS.md` Flutter 版本
**Files:** Modify `AGENTS.md`（技术栈表与正文中的 `3.38.10`）
**Step 1:** 将 `Flutter 3.38.10 (FVM 锁 stable channel)` 改为 `Flutter 3.35.8-ohos-1.0.1 (FVM 锁 ohos 分支)`；同步 Dart 版本 `3.9.2`。

### Task 9.2: 更新 `README.md` / env 说明
**Files:** Modify `README.md`（新增 OHOS 构建段）
**Step 1:** 补充：OHOS 前置（DevEco/SDK/hvigor/ohpm/node）、`make`/脚本命令 `./ohos_utils/ohos_build.sh debug --env=dev`、env 注入差异（OHOS 用 `--dart-define` 而非 `--dart-define-from-file`）。

### Task 9.3: 提交文档
```bash
git add AGENTS.md README.md
git commit -m "docs: update Flutter version and add OHOS build guide"
```
**Acceptance:** `AGENTS.md` 版本号正确；README 含 OHOS 段。

---

## Phase 10 — 回滚预案复核（Spec §7）

### Task 10.1: 确认分支孤立、回滚路径清晰
**Step 1: 复核**
```bash
git branch --show-current          # upgrade/ohos-flutter-3.35.8
git log --oneline origin/main..HEAD | head   # 本分支全部提交
git status --porcelain | head      # 应基本干净（仅未提交修复）
```
**Step 2: 记录回滚命令到 PR 描述**
- 未合并即废弃：`git checkout main`（分支保留可复查，`git branch -D upgrade/ohos-flutter-3.35.8` 删除）。
- 分支内撤销：`git revert <commits>` 或 `git reset --hard origin/main`。
- FVM 回退：`fvm use 3.27.4-ohos-1.0.4 --force`。
**Acceptance:** 回滚步骤写入 PR/MR 描述；确认未合 main 前任何改动均可丢弃。

---

## 完成判据（Definition of Done）

- [ ] 分支 `upgrade/ohos-flutter-3.35.8` 从干净 `origin/main` 切出，main 未受改动
- [ ] `.fvmrc` = `3.35.8-ohos-1.0.1`；`flutter --version` 一致
- [ ] `ohos/` 生成且 `flutter build hap` 成功产出 `entry-default-signed.hap`
- [ ] `melos analyze` / `melos test` / `./scripts/check_deps.sh` 全绿
- [ ] `upgrader` 在 OHOS 被守卫（单测通过）
- [ ] `sentry`/`alice` OHOS 验证通过（或已守卫）
- [ ] OHOS 真机冒烟清单全勾；Android/iOS 回归无碍
- [ ] `AGENTS.md`/`README` 已更新
- [ ] 回滚预案写入 PR 描述

> 本计划仅描述执行步骤，未执行任何改动。确认后按 Task 顺序由 `executing-plans` 逐任务实施并在每步后校验。
