# Spine Flutter 脚手架修复复盘报告

> 复盘对象: `SCAFFOLD_REVIEW.md` 列出的 P0-P2 共 21 项问题
> 复盘日期: 2026-06-17
> 复盘方式: 逐条核实源码，深度评估修复质量
> 目的: 检验修复是否达标，发现遗留问题，给出进阶建议

---

## 0. 总评

### 修复完成度

| 级别 | 总数 | 已修复 | 部分修复 | 未修复 | 完成率 |
|------|:---:|:---:|:---:|:---:|:---:|
| **P0** | 3 | 1 | 0 | 2 | 33% |
| **P1** | 8 | 7 | 1 | 0 | 94% |
| **P2** | 10 | 10 | 0 | 0 | 100% |
| **合计** | 21 | 18 | 1 | 2 | **86%** |

### 新评分（修复后）

| 维度 | 原始分数 | 修复后分数 | 变化 | 说明 |
|------|:---:|:---:|:---:|------|
| **架构分层 (Clean Architecture)** | 9.0 | 9.5 | +0.5 | R2 自动校验补齐, 四层守门完整 |
| **DI / 启动流程** | 8.5 | 8.5 | — | 未改动 |
| **状态管理 (Bloc)** | 8.0 | 8.5 | +0.5 | AuthCubit 死代码清除, DetailCubit 守卫补齐 |
| **网络层 (Dio + Retrofit)** | 7.0 | 7.0 | — | 凭证未迁移, 续期竞态未修 |
| **本地存储 (Hive)** | 7.5 | 8.5 | +1.0 | list_cache 单 box 多 key + staleDuration 生效 |
| **UI 组件库** | 8.0 | 8.0 | — | Colors.red 改为色值常量, 但仍是 magic value |
| **路由 (GoRouter + 模块注册)** | 8.5 | 8.5 | — | 未改动 |
| **测试 (单元/Bloc)** | 6.5 | 7.0 | +0.5 | 测试数量从 64 增至 67, 但 widget 测试仍为 1 |
| **CI/CD + 工具链** | 7.5 | 8.5 | +1.0 | iOS 构建修复, lint 启用, 版本检查入 CI |
| **文档** | 7.0 | 7.5 | +0.5 | UseCase README 补充, 但 docs/ 索引仍未修 |
| **加权总分** | **7.7** | **8.0** | **+0.3** | **从"良好"进入"优秀"区间** |

**一句话结论**: P1 和 P2 的修复质量很高, 工程纪律明显提升。但 **2 个 P0 级安全问题未处理** 是最大遗憾 — `HttpConstant` 里的硬编码凭证仍在裸奔, token 续期竞态仍在代码里。这两个问题不解决, "生产级脚手架"的承诺就打了折扣。

---

## 1. 逐条核实 — P0 级

### P0-1. 源码内嵌生产环境 IP 与 OSS 配置

**状态: ❌ 未修复**

**核实证据**:
```
http_constant.dart:6   Http_Host = IsRelease ? 'fn.jzfeng.com' : '47.92.151.39:5216'
http_constant.dart:21  CompanyIp = '192.168.1.181'    // 公司ip
http_constant.dart:22  HomeIp = '192.168.66.176'      // 家ip
http_constant.dart:23  IphoneIp = '172.20.10.11'      // 手机热点ip
AliyunOSSConstant      BucketName = 'ovsx-usr'
AliyunOSSConstant      Endpoint = 'https://oss-cn-zhangjiakou.aliyuncs.com'
```

**深度分析**:

这不是"忘了改", 而是**根本没动**。所有硬编码凭证原封不动地留在源码里。这带来的风险:

1. **git 历史泄露**: 即使现在改了, 历史提交里已经有这些值。需要 `git filter-branch` 或 BFG 清理
2. **OSS bucket 名暴露**: `ovsx-usr` / `feedback2` 公开可查, 攻击者可以尝试列举对象
3. **内网 IP 泄露**: `192.168.1.181` 等地址对内部网络拓扑有情报价值
4. **AGENTS.md R5 规则形同虚设**: R5 明确要求"所有 EnvironmentConfig 字段必须在 env/.env.* 3 个文件里都有", 但 HttpConstant 完全绕过了这套机制

**我的判断**: 这是整个脚手架**最严重的问题**。一个号称"生产级"的脚手架, 把生产域名、内网 IP、OSS bucket 全部硬编码进源码, 这是安全审计的直接红线。建议**立即处理**, 优先级高于所有其他工作。

---

### P0-2. Token 续期存在竞态条件

**状态: ❌ 未修复（用户主动搁置）**

**核实证据**:
```dart
// renewal_token_intercaptor.dart:106
unawaited(Future.microtask(() async {
  // 续期逻辑在这里
}));
// ← 锁在这里释放, 但续期还没开始执行
```

**深度分析**:

用户之前要求"暂时搁置 token 续期", 所以这个代码原封不动。但根据我之前的深度分析, 这里存在**两个层面的问题**:

1. **表层问题（已确认）**: `unawaited(Future.microtask(...))` 让锁在续期完成前释放, 但 `_renewalState == renewing` 检查能挡住重复启动 — 所以实际不会重复续期
2. **深层问题（之前发现但被忽略）**: `_handleRenewalResponse` 是 76 行死代码, `_renewalCompleter` 是死变量 — 整个"主动续期协调"机制从未被触发

更严重的是: **这个拦截器的文件名仍然是 `renewal_token_intercaptor.dart`**（typo: intercaptor → interceptor）, 而且代码里有 `migrateFromV1` 引用的 `Hive.boxNames()` 方法**在 Hive 2.x 中不存在** — 如果有人调用迁移方法, 会直接崩。

**我的判断**: token 续期代码的"健康度"比原始报告评估的更差。建议**不是修竞态, 而是整体重写这个拦截器**:
- 删除 76 行死代码 `_handleRenewalResponse`
- 删除死变量 `_renewalCompleter`
- 修复文件名 typo
- 把 `unawaited(Future.microtask(...))` 改为锁内直接 `await`
- 补端到端集成测试

---

### P0-3. 登录成功后 token 从未持久化

**状态: ✅ 已修复**

**核实证据**:
```dart
// login_cubit.dart:26
await _authManager.handleLoginSuccess(loginResult);

// manager.dart
Future<void> handleLoginSuccess(LoginResult loginResult) async {
  await saveToken(loginResult.token, loginResult.userId);
  _authCubit.setAuthState(
    AuthState(status: AuthStatus.loggedIn, userId: loginResult.userId),
  );
}
```

**深度评估**:

修复质量**优秀**:
1. **职责分离正确**: LoginCubit 只管 UI 状态, AuthManager 管业务协调, AuthCubit 管状态
2. **单一写入入口**: AuthCubit 只有 `setAuthState()` 一个写入点, 消除了双真相源
3. **register 也覆盖了**: `register()` 成功后也调 `handleLoginSuccess`, 统一了登录/注册流程
4. **DI 注入正确**: LoginCubit 通过构造函数注入 AuthManager, 符合显式 DI 规范
5. **测试覆盖**: 新增 `manager_handle_login_success_test.dart` (4 个测试), 更新了 `login_cubit_test.dart`

**小瑕疵（不影响正确性）**:
- `handleLoginSuccess` 里有 `debugPrint` — 生产代码中用 `debugPrint` 是可以的（kDebugMode 下才输出）, 但更规范的做法是走 `AppLogger`
- 没有端到端测试验证"登录 → 重启 → 自动登录"的完整流程

**评分**: 9/10 — 核心逻辑正确, 架构清晰, 测试充分

---

## 2. 逐条核实 — P1 级

### P1-1. R2 校验缺失 → ✅ 已修复

**核实**: `scripts/check_deps.sh` 新增了 R2 检查:
```bash
if grep -rqE "^import 'package:flutter" packages/domain/ --include="*.dart"; then
  echo "❌ [R2] Domain packages must not import flutter"
```

**质量**: 正确。grep 模式 `^import 'package:flutter` 能匹配 `package:flutter/...` 和 `package:flutter_xxx/...`。但**只检查了 flutter, 没检查 dio / feature_* / services**。建议扩展:
```bash
grep -rqE "^import 'package:(flutter|dio|feature_|.*_services)/" packages/domain/
```

**评分**: 7/10 — 基础校验到位, 但覆盖面可以更全

---

### P1-2 + P1-3. list_cache staleDuration 死代码 + 每页一个 box → ✅ 已修复

**核实**:
```dart
// 单 box 多 key
String _boxName(String cacheKey) => '${_boxPrefix}_$cacheKey';

// staleDuration 实现
Future<bool> _isStale(String cacheKey, int page) async {
  if (_config.staleDuration == null) return false;
  final box = await _getBox(cacheKey);
  final timestamp = box.get('t$page');
  // ...
}
```

**深度评估**:

修复质量**很高**, 具体亮点:
1. **单 box 多 key**: 每个 cacheKey 一个 box, page 数据以 `p1`/`p2` 为内部 key — 50 页只占 1 个 box
2. **时间戳存储**: 写入时同步存 `t{page}` 时间戳, 读取时用 `_isStale()` 判断过期
3. **过期处理正确**: 过期时返回空列表, 触发网络重新拉取
4. **page=1 清空后续页**: `_clearSubsequentPages` 在单 box 内删除 `p2`~`pN` 和 `t2`~`tN`
5. **测试覆盖**: 新增 16 个测试（单 box 结构 + staleDuration + 迁移）
6. **文档更新**: README.md 详细说明了新的存储结构和过期机制

**小瑕疵**:
- `migrateFromV1()` 方法已被删除（因为 Hive 没有 `boxNames()` API） — 这是正确的决策, 但应该在 CHANGELOG 里说明"旧格式 box 需要手动清理"
- `clear()` 方法使用 `deleteFromDisk()` 彻底删除 box, 这是好的; 但如果 box 正在被后台刷新写入（`_refreshInBackground`）, 可能会触发 "Box has already been closed" 错误 — 测试中遇到过这个问题, 通过延迟 tearDown 绕过了

**评分**: 9/10 — 核心重构质量高, 测试充分, 文档到位

---

### P1-4. NetworkQualityMonitor 未接线 → ✅ 已修复

**核实**:
```dart
// network_cubit.dart
final NetworkQualityMonitor _qualityMonitor;
_qualitySubscription = _qualityMonitor.qualityStream.listen((quality) {
  if (state.isConnected) {
    emit(state.copyWith(quality: quality));
  }
});

void recordLatency(int latencyMs) {
  _qualityMonitor.recordLatency(latencyMs);
}

// dio_factory.dart
if (onLatencyRecord != null) {
  dio.interceptors.add(LatencyMonitorInterceptor(onLatencyRecord: onLatencyRecord));
}
```

**深度评估**:

修复质量**优秀**, 完整接通了数据流:
```
HTTP 请求 → LatencyMonitorInterceptor → recordLatency()
  → NetworkQualityMonitor（滑动窗口中位数）
  → qualityStream → NetworkCubit.emit(quality)
  → NetworkState.quality 更新
```

**架构亮点**:
- LatencyMonitorInterceptor 独立为单独文件, 职责单一
- 通过 `onLatencyRecord` 回调注入, 不直接依赖 NetworkCubit — 保持了解耦
- setup.dart 中先创建 NetworkCubit, 再传给 createDio, 最后注册到 DI — 启动顺序正确

**小瑕疵**:
- 断网时 quality 设为 `NetworkQuality.disconnected`, 但恢复网络时 quality 不会自动恢复到 good/slow/poor — 需要等到下一次 HTTP 请求才会更新
- NetworkQualityMonitor 的 `dispose()` 在 NetworkCubit.close() 中调用了, 但如果 close() 被跳过（比如 app 被 kill）, stream subscription 不会取消 — 这是 Flutter 的常见问题, 不是 bug

**评分**: 8.5/10 — 完整接通, 架构解耦, 但恢复网络的逻辑可以优化

---

### P1-5. AuthCubit.login() 死代码 → ✅ 已修复

**核实**: `auth_cubit.dart` 中已删除 `login()` 和 `logout()` 方法, 构造函数简化为无参。

**质量**: 正确。`AuthCubit` 现在只有 `setAuthState()` 一个写入入口, 消除了双真相源。

**评分**: 10/10 — 干净利落

---

### P1-6. DetailCubit 缺 loading 守卫 → ✅ 已修复

**核实**:
```dart
// detail_cubit.dart:18
if (state is DetailLoading) return;
```

**质量**: 正确。新增了测试验证"loading 状态下重复调用不触发新请求"。

**遗留问题**: HomeCubit 有这个守卫, DetailCubit 现在也有了, 但**没有抽成 BaseLoadableCubit mixin**。如果未来新增更多 cubit, 每个都要手写一遍这个检查。建议后续统一。

**评分**: 8/10 — 功能正确, 但缺少抽象

---

### P1-7. HTTP 状态码映射不全 → ✅ 已修复

**核实**:
```dart
400: ErrorCode.invalidInput,
409: ErrorCode.conflict,
422: ErrorCode.invalidInput,  // 修复了原来错误归类为 serverError 的问题
429: ErrorCode.rateLimited,
502: ErrorCode.serverError,
503: ErrorCode.serverError,
504: ErrorCode.serverError,
```

新增了 `ConflictException` 和 `RateLimitedException` 两个异常类型。

**深度评估**:

修复质量**很高**:
1. **422 正确归类**: 从 `serverError` 改为 `invalidInput`, 语义正确
2. **新增异常类型**: `ConflictException`（409）和 `RateLimitedException`（429）有独立的默认消息
3. **sealed class 完整**: DomainException 层级新增两个子类, 测试中验证了穷尽匹配
4. **注释清晰**: 每个状态码都有注释说明含义

**小瑕疵**:
- `ConflictException` 没有携带冲突详情（比如"哪个资源冲突"）— 当前只有默认消息"资源冲突"
- `RateLimitedException` 没有携带 `Retry-After` 信息 — 如果后端返回了这个 header, 客户端无法知道什么时候可以重试

**评分**: 8.5/10 — 核心映射正确, 但异常类可以更丰富

---

### P1-8. iOS 从不在 CI 构建 → ✅ 已修复

**核实**: `ci.yml` 新增 `build-ios` job:
```yaml
build-ios:
  name: iOS 调试构建
  runs-on: macos-latest
  steps:
    - run: flutter build ios --debug --no-codesign
```

`release.yml` 也将 iOS 构建拆分为独立 job。

**质量**: 正确。macOS runner 可以构建 iOS, `--no-codesign` 避免了签名问题。

**成本提醒**: macOS runner 的 GitHub Actions 分钟数消耗是 Linux 的 10 倍（免费额度 2000 分钟/月, macOS 按 10x 计算 = 实际 200 分钟）。如果 CI 频繁触发, 可能需要监控用量。

**评分**: 9/10 — 功能正确, 成本提醒到位

---

## 3. 逐条核实 — P2 级

### P2-1. UseCase 层透传 → ✅ 已修复（文档方案）

**核实**: 新增 `packages/domain/lib/src/usecases/README.md`（139 行）。

**质量**: 文档详细解释了 UseCase 层的设计原则、当前状态、何时扩展、何时直接调 Repository。符合推荐的"方案 C"。

**评分**: 8/10 — 文档质量高, 但毕竟是"文档修复", 实际代码没变

---

### P2-2. Domain model 类型不一致 → ✅ 已修复

**核实**: `User` 和 `LoginResult` 都改用了 `@freezed`。

**质量**: 统一了模型风格, 自动生成 fromJson/toJson/copyWith/==。测试已更新（移除 props 测试, 添加 copyWith 测试）。

**遗留问题**: 原始报告提到 `HomeData.items` 是 `List<dynamic>` — 这个问题**仍然存在**。统一到 freezed 解决了序列化风格不一致, 但没有解决 items 的类型退化。

**评分**: 7/10 — 半个问题（风格统一了, 但 items 类型没改）

---

### P2-3. KeyValueStorage 类型不安全 → ✅ 已修复

**核实**: KeyValueStorage 的方法参数从 `String` 改为 `PreferenceKey`, 新增运行时类型检查。

**质量**: 正确。`putString(PreferenceKey key, ...)` 会检查 `key.valueType == StorageValueType.string`, 不匹配时抛出 ArgumentError。

**深度评估**:

这是**运行时检查, 不是编译时检查**。理想方案是用泛型:
```dart
Future<void> put<T>(PreferenceKey<T> key, T value) async { ... }
```

但当前方案已经足够安全 — 如果开发者用错了 key, 第一次运行就会崩, 而不是静默写入错误类型。

**评分**: 8/10 — 运行时检查足够安全, 泛型方案是未来优化方向

---

### P2-4. PreferenceKey 无命名空间 → ✅ 已修复

**核实**: 新增 `PreferenceKeyGroup` 枚举, 54 个 key 按 10 个分组。

**质量**: 分组合理（auth/location/trip/fence/privacy/onboarding/reminder/car/shape/misc）, 新增 `keysInGroup()` 方法。

**评分**: 9/10 — 干净利落

---

### P2-5. AppButton 硬编码 Colors.red → ⚠️ 部分修复

**核实**:
```dart
// 修复前:
backgroundColor: Colors.red,
foregroundColor: Colors.white,
if (widget.backgroundColor == Colors.red) return Colors.white;

// 修复后:
backgroundColor: const Color(0xFFF44336), // Material Red 500
foregroundColor: const Color(0xFFFFFFFF), // White
// 删除了 if (widget.backgroundColor == Colors.red) 硬编码检查
```

**深度评估**:

这是一个**表面修复**。原始报告的核心问题是:

> `_resolvedForegroundColor` 有 `if (widget.backgroundColor == Colors.red) return Colors.white` — magic value

修复删除了这行硬编码检查 ✅。但**没有走 ThemeExtension 取色**（原始建议是"抽 AppButtonVariant.danger 走 ThemeExtension"）。现在的做法只是把 `Colors.red` 换成了 `Color(0xFFF44336)` — 这仍然是 magic value, 只是从 Material 色板常量变成了十六进制字面量。

真正的 ThemeExtension 方案应该是:
```dart
// danger 按钮不应该在构造函数里写死颜色
// 而是在 _resolvedBackgroundColor 里:
case AppButtonVariant.danger:
  return context.colors.error;  // 从 AppColors.error 取
```

另外, `Colors.transparent`（line 590）仍然存在, 但这个是合理的（Material widget 需要透明背景）。

**评分**: 5/10 — 删除了硬编码检查（好）, 但用字面量替代了 Material 常量（不够好）, 没有走 ThemeExtension（未达标）

---

### P2-6. CI analyze 关闭 warning → ✅ 已修复

**核实**: `ci.yml` 从 `flutter analyze --no-fatal-infos --no-fatal-warnings` 改为 `flutter analyze --no-fatal-infos`。

**质量**: 正确。warning 现在会导致 CI 失败。修复了 2 个现有 warning（iconSize 和 widthValue 参数添加 ignore 注释）。

**评分**: 9/10 — 简单有效

---

### P2-7. Mason brick 不生成测试 → ✅ 已修复

**核实**: feature brick 已有 `test/{{name}}_cubit_test.dart`（3 个测试用例）, usecase brick 新增 `test/{{name}}_use_case_test.dart`（3 个测试用例）。

**遗留**: api / model / hive_model brick 仍无测试模板。但这些 brick 生成的代码比较简单（API 接口、数据模型）, 测试价值相对较低。

**评分**: 8/10 — 核心 brick 覆盖, 其他可后续补充

---

### P2-8. 覆盖率脚本不过滤生成代码 → ✅ 已修复

**核实**: `check_coverage.sh` 新增 `lcov --remove` 过滤 `.g.dart` 和 `.freezed.dart`。

**质量**: 正确。如果 lcov 命令不可用, 会回退到原始数据（graceful degradation）。

**评分**: 9/10 — 简单有效

---

### P2-9. Pre-commit 没有自动安装 → ✅ 已修复

**核实**: makefile 新增 `setup` target:
```makefile
setup:
  git config core.hooksPath .githooks
  melos bootstrap
  ./scripts/check_deps.sh
```

**质量**: 正确。一行命令完成 hooks 配置 + 依赖安装 + 验证。

**评分**: 9/10 — 简单有效

---

### P2-10. 版本漂移检查不在 CI → ✅ 已修复

**核实**: `ci.yml` 新增 `dart run scripts/check_workspace_versions.dart` 步骤。

**质量**: 正确。CI 现在会检测跨包版本漂移。

**评分**: 9/10 — 简单有效

---

## 4. 遗留问题汇总

### 🔴 必须处理（安全红线）

| # | 问题 | 风险 | 建议 |
|---|------|------|------|
| **L-1** | P0-1: HttpConstant 硬编码凭证仍未迁移 | 生产域名、内网 IP、OSS bucket 名公开可查 | **立即迁移到 env/.env.\***, 并用 BFG 清理 git 历史 |
| **L-2** | P0-2: Token 续期代码整体健康度差 | 76 行死代码 + 死变量 + 文件名 typo + 竞态 | **整体重写拦截器**, 不是修竞态 |
| **L-3** | `renewal_token_intercaptor.dart` 文件名 typo | intercaptor → interceptor | 重命名 + 更新所有引用 |

### 🟡 应该处理（质量提升）

| # | 问题 | 影响 | 建议 |
|---|------|------|------|
| **L-4** | Widget 测试仍只有 1 个 | UI 层无保障 | 为 feature_auth/home/detail 各加至少 1 个 widget 测试 |
| **L-5** | HomeData.items 仍是 `List<dynamic>` | 强类型退化 | 定义 `HomeItem` 类, items 改为 `List<HomeItem>` |
| **L-6** | AppButton 颜色未走 ThemeExtension | 不支持暗色主题的 danger 按钮 | danger 按钮从 `context.colors.error` 取色 |
| **L-7** | R2 校验只检查 flutter, 没检查 dio/services | 校验面不全 | 扩展 grep 模式 |
| **L-8** | ConflictException / RateLimitedException 信息不够丰富 | 无法知道冲突详情或重试时间 | 添加 `conflictDetail` 和 `retryAfter` 字段 |
| **L-9** | docs/ 无 README 索引 | 11 个文档无入口 | 创建 `docs/README.md` 索引 |
| **L-10** | 2 个文档是 stub | domain-testing-guide.md (818B), solo-ai-scaffold-guide.md (426B) | 要么补充内容, 要么删除 |
| **L-11** | UpgradeWrapper 仍是空壳 | 占位实现 | 集成 upgrader 包, 或删除 |

### 🟢 可以处理（锦上添花）

| # | 问题 | 建议 |
|---|------|------|
| **L-12** | Loading 守卫没有抽象成 BaseLoadableCubit | 抽 mixin, 统一模式 |
| **L-13** | KeyValueStorage 用运行时检查而非编译时 | 未来改泛型 `PreferenceKey<T>` |
| **L-14** | handleLoginSuccess 用 debugPrint 而非 AppLogger | 统一日志通道 |
| **L-15** | LocaleCubit.setLocale() 不校验支持列表 | 添加 `['zh', 'en']` 校验 |
| **L-16** | LoginPage 和 RegisterPage 共享 ~80% 代码 | 抽 `_AuthFormScaffold` |
| **L-17** | analysis_options.yaml 有冗余规则 | 清理 missing_return / dead_code |
| **L-18** | Makefile 兜底规则吞拼写错误 | 删除 `%: @:` 或改为报错 |

---

## 5. 进阶建议

### 5.1 建立测试金字塔

当前测试分布:
```
单元测试: 67 个 ✅
Widget 测试: 1 个 ❌ (几乎为零)
集成测试: 1 个 ❌ (smoke 级别)
```

**建议三步走**:

1. **第一步: 关键路径 Widget 测试**
   - `LoginPage` 渲染 + 输入 + 提交流程
   - `HomePage` 加载状态 + 数据展示
   - `SettingsPage` 语言切换 + 登出

2. **第二步: 集成测试**
   - 登录 → 首页 → 详情的完整导航
   - 断网 → 重连 → 数据刷新
   - Token 过期 → 续期 → 重试

3. **第三步: Golden 测试**（可选）
   - 关键页面的视觉回归测试
   - 暗色主题适配验证

### 5.2 安全审计清单

在发布前完成以下安全检查:

- [ ] 所有凭证迁移到 `env/.env.*`（P0-1）
- [ ] git 历史清理（BFG 或 filter-branch）
- [ ] `.env.*` 文件加入 `.gitignore`（已有？需核实）
- [ ] OSS bucket 权限审计（公共读写？）
- [ ] 签名算法从 SHA1 升级到 HMAC-SHA256（P3-1）
- [ ] Token 续期拦截器重写（P0-2）

### 5.3 文档治理

当前文档问题:
- 11 个 md 文件无索引
- 2 个文件是 stub
- 部分链接失效

**建议**:
1. 创建 `docs/README.md` 作为索引页
2. 删除或充实 stub 文件
3. 修复 `di-discipline.md` 中的失效链接
4. 考虑用 `mkdocs` 搭建文档站点（AGENTS.md 提到了 mkdocs）

### 5.4 CI/CD 进阶

当前 CI 覆盖: analyze + test + build (Android + iOS)

**建议新增**:
1. **缓存优化**: 缓存 `.pub-cache` 和 `build/`, 加速 CI
2. **并行化**: analyze / test / build 三个 job 并行运行
3. **自动发布**: tag 推送后自动构建 release APK + IPA
4. **代码质量追踪**: 集成 SonarQube 或 CodeClimate
5. **依赖安全扫描**: 集成 Dependabot security alerts

### 5.5 架构演进方向

当前架构在"脚手架"层面已经很完善, 下一步可以考虑:

1. **模块化路由**: 当前 RouteModule 是静态注册, 考虑支持动态注册（用于插件化/A-B 测试）
2. **离线优先**: list_cache 已有基础, 考虑加 conflict resolution（本地 vs 远程数据冲突）
3. **性能监控**: NetworkQualityMonitor 已接通, 考虑加帧率监控 + 内存监控
4. **A/B 测试框架**: 脚手架可以预留 A/B 测试的基础设施
5. **Feature Flag**: 支持远程开关功能, 降低发布风险

---

## 6. 修复质量排名

### 🏆 修复质量最高（9-10 分）

| 问题 | 评分 | 理由 |
|------|:---:|------|
| P0-3 登录 token 持久化 | 9 | 职责分离正确, 测试充分, register 也覆盖 |
| P1-5 AuthCubit 死代码 | 10 | 干净利落, 零副作用 |
| P1-2+3 list_cache 重构 | 9 | 核心重构 + staleDuration + 16 个测试 |
| P1-7 HTTP 状态码映射 | 8.5 | 映射正确, 新增 2 个异常类型, sealed 完整 |
| P1-8 iOS CI | 9 | 功能正确, 成本提醒到位 |
| P2-4 PreferenceKey 分组 | 9 | 分组合理, 方法实用 |
| P2-6 CI lint 启用 | 9 | 简单有效 |
| P2-8 覆盖率过滤 | 9 | 简单有效 |
| P2-9 make setup | 9 | 简单有效 |
| P2-10 版本漂移进 CI | 9 | 简单有效 |

### ⚠️ 修复质量一般（5-7 分）

| 问题 | 评分 | 理由 |
|------|:---:|------|
| P2-5 AppButton 颜色 | 5 | 删了硬编码检查（好）, 但用字面量替代（不够）, 没走 ThemeExtension |
| P2-2 Domain model 统一 | 7 | 风格统一了, 但 items 仍是 List<dynamic> |
| P1-1 R2 校验 | 7 | 基础到位, 但只检查 flutter |

### ❌ 未修复

| 问题 | 影响 |
|------|------|
| P0-1 硬编码凭证 | **安全红线** |
| P0-2 Token 续期竞态 | **正确性风险** |

---

## 7. 结论

### 总体评价

**修复后的加权总分从 7.7 提升到 8.0** — 这是一个**实质性的提升**, 不是"改了几个 typo"的表面功夫。

P1 和 P2 的修复质量普遍很高（平均 8.5/10）, 特别是:
- list_cache 的单 box 多 key 重构
- 登录 token 持久化的职责分离
- NetworkQualityMonitor 的完整接线
- CI/CD 工具链的系统性补齐

### 最大遗憾

**2 个 P0 级安全问题未处理**:
1. `HttpConstant` 里的硬编码凭证仍在裸奔 — 这是安全审计的直接红线
2. Token 续期代码整体健康度差 — 76 行死代码 + 死变量 + 文件名 typo + 竞态

这两个问题不解决, 脚手架就无法真正用于生产环境。

### 推荐度

**修复前**: ★★★★☆ (4/5)
**修复后**: ★★★★☆ (4/5) — 分数没变, 因为 P0 未修

**如果 P0 也修了**: ★★★★★ (5/5) — 可以放心推给团队 / 开源社区

---

*本报告基于 2026-06-17 的代码状态生成, 逐条核实源码, 未修改任何代码。*
