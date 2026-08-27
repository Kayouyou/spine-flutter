# OHOS 插件兼容性审计清单

> 生成时间：2026-07-14
> 项目：spine_flutter（分支 `upgrade/ohos-flutter-3.35.8`，Flutter `3.35.8-ohos-1.0.1`）
> 对照项目：OVS（`/Users/yeyangyang/jzf/ovs_upgrade_335`）

## 一、检查结论（摘要）

当前项目的 `ohos/oh-package.json5` 与 `ohos/entry/oh-package.json5` 中 `dependencies` 均为 `{}`——
**OHOS 原生侧完全没有接入任何插件适配器**。对比 OVS 项目，它在 `ohos/` 下为每个带原生能力的插件都放置了
`*_ohos` 原生实现目录（如 `path_provider_ohos`、`shared_preferences_ohos`、`connectivity_plus` 等），
并在 `oh-package.json5` 中声明对应的 ohpm 依赖。

通过解析 `.flutter-plugins-dependencies`（`plugins` 按平台分组）可知：
**当前项目 `ohos` 平台段仅有 `integration_test` 一个插件**，其余所有带原生实现的插件都未在 OHOS 上注册实现。
这正是此前 OHOS 构建后界面空白、进程约 5 秒 `onAbilityDied` 死掉的根因之一——`path_provider` 等插件在 Dart 侧
调用时找不到 OHOS 原生实现，导致引擎初始化/首次 platform channel 调用失败。

> **OVS 的集成模式（必须参照）**：
> 1. `pubspec.yaml` 的 `dependency_overrides` 把官方插件指向 CPF-Flutter 的 git ohos 分支（如 `br_path_provider-v2.1.5_ohos`）；
> 2. `ohos/oh-package.json5` 的 `dependencies` 引入对应的 `*_ohos` 原生实现（来自 `ohos/` 下的目录或 `har/` 文件）。

> ⚠️ **关于 Flutter SDK 版本的统一澄清（已纠正）**：
> OVS 的 `.fvmrc` 为 `"flutter": "3.35.8-ohos-1.0.1"`，**与本项目完全一致**。OVS 部分代码注释里出现的「3.27 推荐」
> 指的是某些插件在更早 3.27 阶段做过验证，**并不表示 OVS 的 Flutter SDK 是 3.27**。因此本项目可直接复用 OVS 的
> CPF-Flutter ohos 分支集成方案，无需担心主 SDK 版本不匹配。

> **OVS 实际使用的 git ref（可直接照搬，来源 `/Users/yeyangyang/jzf/ovs_upgrade_335/pubspec.yaml`）**：
> - `path_provider` → `CPF-Flutter/flutter_packages` `br_path_provider-v2.1.5_ohos`（子版本与本项目 lock 2.1.5 ✅吻合）
> - `shared_preferences` → `CPF-Flutter/flutter_packages` `br_shared_preferences-v2.5.4_ohos`（注意：本项目 lock 为 **2.5.5**，子版本差一位，需确认该分支是否覆盖 2.5.5 或回锁到 2.5.4）
> - `url_launcher` → `CPF-Flutter/flutter_packages` `br_url_launcher-v6.3.2_ohos`
> - `permission_handler` → `CPF-Flutter/flutter_permission_handler` `br_v12.0.1_ohos`
> - `device_info_plus` → 直接覆盖为 `^9.0.3`（OVS 用 direct override 而非 git 分支）
> - `package_info_plus` → 直接覆盖为 `^8.1.0`

---

## 二、清单 A：直接声明（direct main）且缺少 OHOS 原生支持的插件

| # | 插件名 | 声明版本 | 已解析版本(lock) | 原生能力 | 运行时关键点 | OVS 集成方式（参照） | 优先级 |
|---|--------|---------|----------------|---------|------------|-------------------|-------|
| 1 | `path_provider` | `^2.0.2` | **2.1.5** | 应用文档/缓存目录 | HydratedBloc、Hive、shared_preferences 均依赖它获取目录 | CPF-Flutter git `br_path_provider-v2.1.5_ohos` + `oh-package` 引入 `path_provider_ohos` | 🔴 P0（最可能导致启动崩溃） |
| 2 | `shared_preferences` | `^2.2.2` | **2.5.5** | KV 存储（PreferenceKey 实现） | `key_value_storage` 包的持久化后端 | CPF-Flutter git `br_shared_preferences-v2.5.4_ohos` + `shared_preferences_ohos` | 🔴 P0 |
| 3 | `connectivity_plus` | `^6.0.0` | **6.1.5** | 网络连通状态 | `network` 服务的弱网检测 | CPF-Flutter git `br_connectivity_plus-v7.0.0_ohos`（注意需升到 7.0.0 分支）| 🟠 P1 |
| 4 | `sentry_flutter` | `^8.13.0` | **8.14.2** | 原生崩溃采集 | `ErrorReporter`(Sentry) 抽象的生产实现 | OVS **未使用**（注释掉）。需另找 ohos 兼容方案或评估禁用原生上报 | 🟠 P1 |
| 5 | `hive_flutter` | `^1.1.0` | **1.1.0** | 纯 Dart 转发，依赖 `path_provider` | `LocaleCubit` 持久化 | 随 `path_provider` 的 OHOS 实现一并解决（无独立原生） | 🟠 P1（依赖 #1） |
| 6 | `upgrader` | `^10.3.0` | **10.3.0** | 纯 Dart，依赖 `url_launcher` 打开商店 | OHOS 无应用商店 | 已在 `app.dart` 用 `shouldWrapUpgrade` 在 OHOS 上禁用（运行时无需原生） | 🟡 P2（已禁用） |
| 7 | `alice` | `^0.4.2` | **0.4.2** | 纯 Dart HTTP 调试 UI | 无原生依赖 | 无需 OHOS 处理 | ✅ 无需处理 |

---

## 三、清单 B：间接依赖（transitive）且缺少 OHOS 原生支持的插件

这些插件未被业务代码直接 import，而是由清单 A 中的插件（或其它包）传递引入；
但 Flutter 解析后它们仍会被打包进构建，**OHOS 构建同样需要它们的 ohos 实现**，否则报
`platform ohos not implemented`。请按上游来源逐一核实。

| # | 插件名 | 已解析版本(lock/.flutter-plugins) | 推测上游来源 | 原生能力 | OVS 是否集成 | 核实建议 |
|---|--------|------|-----------|---------|------------|---------|
| 1 | `device_info_plus` | 10.1.2 | 由 `sentry_flutter` 引入 | 设备信息 | ❌ 未集成（OVS 也在缺 ohos 列表） | 确认 sentry 是否真的需要；或找 CPF-Flutter 对应 ohos 分支 |
| 2 | `package_info_plus` | 6.0.0 | 由 `sentry_flutter` / `upgrader` 引入 | 包信息 | ❌ 未集成 | 同上 |
| 3 | `url_launcher` | 6.3.1 | 由 `upgrader` 引入 | 打开链接/商店 | ✅ CPF `br_url_launcher-v6.3.2_ohos` + `url_launcher_ohos` | 参照 OVS 做 override + oh-package |
| 4 | `permission_handler` | 11.4.0 | 通知/定位等（需核实具体引用点） | 系统权限 | ✅ CPF `br_v12.0.1_ohos` + `permission_handler_ohos` | 先 grep 确认本项目是否真的使用，再决定 |
| 5 | `flutter_local_notifications` | 17.2.4 | 间接（需核实） | 本地通知 | ❌ OVS 无此插件 | 确认来源；若需要则找 ohos 适配 |
| 6 | `open_filex` | 4.7.0 | 间接（需核实） | 打开文件 | ❌ OVS 无此插件 | 确认来源；评估是否移除/替换 |
| 7 | `sensors_plus` | 5.0.1 | 间接（需核实） | 传感器 | ❌ OVS 无此插件 | 确认来源 |
| 8 | `share_plus` | 9.0.0 | 间接（需核实） | 系统分享 | ✅ CPF `br_share_plus-v12.0.1_ohos` | 确认来源后参照 OVS 集成 |
| 9 | `jni` / `jni_flutter` | （随宿主） | 由 `open_filex` 等引入 | JNI 互操作 | ❌ | 随 `open_filex` 处理 |

> 提示：可用以下命令确认清单 B 各插件的真实上游：
> `grep -rn "device_info_plus\|package_info_plus\|permission_handler\|url_launcher\|open_filex\|flutter_local_notifications\|sensors_plus\|share_plus" packages/ lib/`
> 或直接运行 `.fvm/flutter_sdk/bin/flutter pub deps` 查看依赖树。

---

## 四、已正确支持 / 无需 OHOS 原生处理的插件

- `integration_test`：已自带 OHOS 实现（`.flutter-plugins-dependencies` 的 ohos 段）。
- 纯 Dart 包（无 `plugin:` 原生映射，天然跨平台）：`get_it`、`equatable`、`flutter_bloc`、
  `hydrated_bloc`、`replay_bloc`、`bloc_concurrency`、`freezed_annotation`、`intl`、
  `flutter_easyloading`、`flutter_screenutil`、`go_router`、`rxdart`、`dio`、`cupertino_icons`、
  `crypto`、`uuid`、`synchronized`、`retrofit`、`hive`、`alice`、`upgrader`。
- `upgrader`：虽为 direct main，但已在 `app.dart` 用 `shouldWrapUpgrade(enableUpgradePrompt, isOhos)` 在 OHOS 上禁用，不触发原生调用。

---

## 五、集成建议（参照 OVS 模式，落地到本项目）

1. **`pubspec.yaml` 增加 `dependency_overrides`**（指向 CPF-Flutter 的 git ohos 分支），至少覆盖：
   - `path_provider`（-> `br_path_provider-v2.1.5_ohos`）
   - `shared_preferences`（-> `br_shared_preferences-v2.5.4_ohos`）
   - `connectivity_plus`（-> `br_connectivity_plus-v7.0.0_ohos`，需同步升级声明的 `^6.0.0`）
   - `url_launcher`（-> `br_url_launcher-v6.3.2_ohos`）
   - `permission_handler`（-> `br_v12.0.1_ohos`）
   - `share_plus`（-> `br_share_plus-v12.0.1_ohos`）
2. **`ohos/oh-package.json5` 的 `dependencies`** 引入对应 `*_ohos` 原生实现目录 / `har`：
   参照 OVS 的 `oh-package.json5`（`path_provider_ohos`、`shared_preferences_ohos`、
   `connectivity_plus`、`url_launcher_ohos`、`permission_handler_ohos`、`share_plus` 等）。
3. **`sentry_flutter`**：OVS 完全未使用，建议评估（a）替换为有 ohos 支持的错误上报，或
   （b）在 OHOS 上仅保留 Dart 层 `ErrorReporter`（console），不初始化原生 SDK。
4. **清理清单 B 的幽灵依赖**：先 grep 确认 `device_info_plus`、`flutter_local_notifications`、
   `open_filex`、`sensors_plus` 等是否真的被使用；若仅由 `sentry_flutter` 传递引入，可随 sentry 方案一并处理。

---

## 六、待用户手动核实项

- [x] `path_provider` / `shared_preferences` / `connectivity_plus` 的 CPF-Flutter ohos 分支版本兼容性 —— **已确认无版本风险**：OVS 的 `.fvmrc` 同样为 `3.35.8-ohos-1.0.1`，与本项目 Flutter 版本**完全一致**，因此 OVS 用过的那套 CPF-Flutter ohos 分支插件可直接照搬，无需担心 flutter 主版本不匹配。（仅需确认各插件分支的子版本号与本项目 lock 版本吻合，见清单 A/B。）
- [ ] `sentry_flutter` 在 OHOS 上的兼容方案（禁用原生 / 找 fork / 换 SDK）。
- [ ] 清单 B 各间接插件的真实上游与是否必要。
- [ ] `permission_handler` 在本项目的具体使用点（grep `permission_handler` 确认）。

---

## 七、执行记录（2026-07-14，按清单落地）

### 7.1 关键发现（执行中修正）
1. **`pubspec_overrides.yaml` 接管了 `dependency_overrides`**：本项目是 melos monorepo，`flutter pub get` 实际读取 `pubspec_overrides.yaml`（melos 自动生成），**忽略 `pubspec.yaml` 里的 `dependency_overrides`**。因此 git 覆盖必须写进 `pubspec_overrides.yaml`（同时保留 `pubspec.yaml` 的，便于 melos 重新生成时不丢）。
2. **CPF 部分分支改了包名**：`sensors_plus` 的 `br_sensors_plus-v7.0.0_ohos` 分支 `pubspec.yaml` 的 `name` 是 `sensors_plus_ohos`（与主包名不符，pub get 报 "name doesn't match"）。改用 `br_sensors_plus-v6.1.1_ohos`（保持 `name: sensors_plus`）解决。
3. **`permission_handler` 的 CPF 分支不提供 ohos**：`br_v12.0.1_ohos` 的 pubspec **未声明 ohos 平台**（只有 android/ios/web/windows）。该分支只是升版本，ohos 原生实现要靠 `permission_handler_ohos` 这个独立原生包（OVS 是在 `oh-package.json5` 手动加的 har）。即本覆盖对 ohos 实际无效，需另行处理。
4. **`connectivity_plus` 用 `v6.1.0_ohos` 而非 `v7.0.0_ohos`**：本项目 `network_cubit.dart` 已用 `List<ConnectivityResult>` 新 API（6.0.0 引入），故 6.1.0 即可，无需升 7.0.0 改代码。
5. 解析结果：path_provider_ohos / shared_preferences_ohos / url_launcher_ohos 作为 `_ohos` 原生子包被自动拉入（来自 openharmony-sig / openharmony-tpc 的 flutter_packages.git）。

### 7.2 已落地的 git 覆盖（两文件一致：pubspec.yaml + pubspec_overrides.yaml）
| 插件 | CPF 仓库 | 分支 | 解析版本 | 状态 |
|---|---|---|---|---|
| path_provider | flutter_packages | br_path_provider-v2.1.5_ohos | 2.1.5 | ✅ ohos 生效 |
| shared_preferences | flutter_packages | br_shared_preferences-v2.5.4_ohos | 2.5.4 | ✅ ohos 生效 |
| url_launcher | flutter_packages | br_url_launcher-v6.3.2_ohos | 6.3.2 | ✅ ohos 生效 |
| connectivity_plus | flutter_plus_plugins | br_connectivity_plus-v6.1.0_ohos | 6.1.0 | ✅ ohos 生效 |
| device_info_plus | flutter_plus_plugins | br_device_info_plus_v11.4.0_ohos | 9.1.0 | ✅ ohos 生效 |
| package_info_plus | flutter_plus_plugins | br_package_info_plus-v8.1.0_ohos | 8.1.0 | ✅ ohos 生效 |
| sensors_plus | flutter_plus_plugins | br_sensors_plus-v6.1.1_ohos | 6.1.1 | ✅ ohos 生效 |
| share_plus | flutter_plus_plugins | br_share_plus-v10.1.1_ohos | 10.1.1 | ✅ ohos 生效 |
| permission_handler | flutter_permission_handler | br_v12.0.1_ohos | 12.0.1 | ⚠️ 该分支无 ohos 平台声明，覆盖无效 |

### 7.3 验证（=`flutter pub get` 后）
`.flutter-plugins-dependencies` 的 ohos 段由 1 个（integration_test）增至 9 个：
`connectivity_plus / device_info_plus / package_info_plus / sensors_plus / share_plus / path_provider_ohos / shared_preferences_ohos / url_launcher_ohos / integration_test`。
`flutter build hap --debug` 成功（BUILD_EXIT=0，产出 `entry-default-signed.hap`）。

### 7.4 运行时验证（装真机实测，**空白屏已修复**）
- 设备：HUAWEI（hdc `FMR0224129000151`）。
- 安装新 hap 后 `aa start` 启动，`aa dump -l` 确认进程**存活**（mission #606 在桌面前台）。
- Flutter 完整初始化（来自 AppLauncher Profiler 日志）：
  `Flutter binding 初始化 → HydratedStorage 初始化(76ms) → BlocObserver → 错误处理器+Sentry reporter 绑定 → 环境校验通过 → DI 完成 → SDK 初始化完成 → AuthManager.handleLogin 发起 /User/me 请求`。
- **关键页面已渲染**：`AceFocus: view: page/2 first show, node: Stack`（之前完全空白、无任何 Flutter 引擎日志，根因正是 path_provider 等无 ohos 原生 → `initPlugins` 在 `runApp` 前崩溃）。
- 仍有**非致命**告警：`DartMessenger --> Uncaught exception in binary message listener undefined is not callable @MethodChannel.ets:228`，来源是某个插件在 OHOS 上注册了 MethodChannel 但原生 handler 未实现（见 7.5）。

### 7.5 剩余缺口 / 不确定插件（按用户要求单独反馈）
以下插件 CPF 无 ohos 分支或分支无 ohos 平台声明，构建能过（Flutter 跳过），但运行时需关注：

1. **`sentry_flutter`（8.14.2）— 直接依赖，最该处理** ⚠️
   - 在 `lib/core/startup/launcher.dart` 与 `packages/services/error/lib/src/sentry_reporter.dart` 直接初始化。
   - CPF / gitcode 上**找不到任何 sentry ohos 分支**。
   - 启动时的 `undefined is not callable` 极可能来自它（原生 reporter 无 OHOS MethodChannel handler）。
   - 建议（二选一，等你拍板）：
     - (a) 在 `AppLauncher` 用 `Platform.operatingSystem != 'ohos'` 守卫，OHOS 上只挂 Dart 层 console reporter，不初始化原生 SDK；
     - (b) 找 sentry 的 OHOS fork / 等官方支持。
2. **`permission_handler`（12.0.1）— 覆盖无效** ⚠️
   - CPF 分支 `br_v12.0.1_ohos` 的 pubspec **未声明 ohos 平台**，覆盖对 ohos 不生效。
   - 经 grep **业务代码未直接使用**（仅 transitive），故当前不阻塞；若将来某 feature 用到，需仿 OVS 在 `oh-package.json5` 手动加 `permission_handler_ohos` 原生 har。
3. **`flutter_local_notifications` / `open_filex` — 仅 transitive** 🟡
   - 均经 `alice`（调试工具）传递引入，CPF 无 ohos 分支。
   - 当前不阻塞运行时；`alice` 是调试期工具，可在 OHOS 发布构建里不启用。
4. **`jni` / `jni_flutter` — 仅 transitive、预期不阻塞** 🟢
   - 由 `path_provider_android`（Android 变体）引入；OHOS 构建只注册 `_ohos` 变体，不引入 Android 变体，已验证不影响构建与启动。

> **结论**：清单 A/B 中**有 CPF 分支的 8 个插件已全部生效**，空白屏根因已消除，App 在真机正常渲染并跑通启动流程。`sentry_flutter` 是唯一需要你决策的直接依赖（建议方案 a 守卫），其余为低优先级的 transitive/未使用项。

