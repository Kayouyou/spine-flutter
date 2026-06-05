# API 包最佳实践重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构 `packages/infrastructure/api/`：端点集中管理 + 死代码删除 + 错误处理统一 + 业务泄露清理

**Architecture:** 新建 `api_endpoints.dart` 集中管理所有 API 端点（按后端路径前缀分组 + 基础设施共享端点独立），统一到 `DioExceptionMapper.toDomainException()` 单一错误路径，删除 7 个死代码文件（~900行），将业务概念（OVSTap、业务EventKeys、EmptyCarListCode）提取到正确层级。

**Tech Stack:** Dart 3.x, Flutter, Dio, Clean Architecture + Feature-First

---

## File Structure Map

```
创建:
  packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart  # 端点注册表
  lib/core/events/tab_events.dart                                   # OVSTap 枚举新位置

修改:
  packages/infrastructure/api/lib/api.dart                          # barrel 导出精简
  packages/infrastructure/api/lib/src/http/http_constant.dart       # 移除业务码 + 重命名
  packages/infrastructure/api/lib/src/http/http_event_bus.dart      # 移除 OVSTap + 业务 EventKeys
  packages/infrastructure/api/lib/src/http/http_error.dart          # 删除 NeedLogin/NeedAuth/HttpsExceptionExtension
  packages/infrastructure/api/lib/src/dio/renewal_token_intercaptor.dart  # token路径改为引用 ApiBase
  packages/features/feature_home/lib/src/repository/home_repository_impl.dart  # 端点引用迁移
  packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart # 端点引用迁移
  packages/domain/lib/src/exceptions/domain_exception.dart          # 新增 tokenInvalid 枚举

删除:
  packages/infrastructure/api/lib/src/url_builder.dart
  packages/infrastructure/api/lib/src/dio/token_interceptor.dart
  packages/infrastructure/api/lib/src/dio/retry_interceptor.dart
  packages/infrastructure/api/lib/src/http/retry_policy.dart
  packages/infrastructure/api/lib/src/http/concurrent_limiter.dart
  packages/infrastructure/api/lib/src/tracking/request_tracker.dart
  packages/infrastructure/api/lib/src/dio/log_reporting_interceptor.dart
  packages/infrastructure/api/lib/src/http/error_handler.dart

测试清理:
  packages/infrastructure/api/test/token_renewal_interceptor_test.dart  # 删除 RetryPolicy/ConcurrentLimiter/RequestTracker 测试组
  packages/infrastructure/api/test/api_endpoints_test.dart              # 新建端点注册表测试
```

---

### Task 1: 创建端点注册表 api_endpoints.dart

**Files:**
- Create: `packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart`
- Modify: `packages/infrastructure/api/lib/api.dart:25` (新增导出)

- [ ] **Step 1: 创建 api_endpoints.dart**

```dart
/// API 端点注册表
///
/// 集中管理所有 API 端点路径。单一 baseUrl 来源。
/// 分组标准：按后端路径前缀分第一层，基础设施共享端点独立放 ApiBase。
///
/// 使用：
/// ```dart
/// _dio.get(ApiEndpoints.home.data);
/// _dio.post(ApiEndpoints.auth.login, data: {...});
/// ```
library;

import 'package:api/src/http/http_constant.dart';

abstract final class ApiBase {
  /// 基础 URL（引用 HttpConstant 的环境感知逻辑）
  static String get baseUrl =>
      'http${HttpConstant.IsRelease ? 's' : ''}://${HttpConstant.Http_Host}';

  /// Token 续期路径（基础设施共享端点，不属于任何业务域）
  static const String tokenRenewal = '/User/Token/Renewal';
}

// ─── 按后端路径前缀分组的业务域 ───

abstract final class _Home {
  static const String _prefix = '/home';
  static const String data = '$_prefix/data';
}

abstract final class _Detail {
  static const String _prefix = '/detail';
  static String item(String id) => '$_prefix/$id';
}

abstract final class _Auth {
  static const String _prefix = '/User';
  static const String login = '$_prefix/Login/Password';
  static const String register = '$_prefix/Register';
  static String profile(String username) => '$_prefix/$username';
  static const String forgotPassword = '$_prefix/forgot_password';
}

abstract final class _Session {
  static const String _prefix = '/session';
  static const String signIn = '$_prefix';
  static const String signOut = '$_prefix';
}

abstract final class _Vehicle {
  static const String _prefix = '/Vehicle';
  static const String list = '$_prefix/List';
  static const String detail = '$_prefix/Detail/Info';
  static const String ranking = '$_prefix/Ranking/Query/Top/Info';
}

// ─── 统一入口 ───

abstract final class ApiEndpoints {
  static const home = _Home;
  static const detail = _Detail;
  static const auth = _Auth;
  static const session = _Session;
  static const vehicle = _Vehicle;

  /// Token 续期（共享端点）
  static const String tokenRenewal = ApiBase.tokenRenewal;
}
```

运行: `flutter analyze packages/infrastructure/api/`
预期: 零错误

- [ ] **Step 2: 在 api.dart 新增 api_endpoints 导出**

Edit `packages/infrastructure/api/lib/api.dart`:
```dart
export 'src/endpoints/api_endpoints.dart';
```
加在文件末尾（在所有现有导出之后）。

- [ ] **Step 3: 提交**

```bash
git add packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart
git add packages/infrastructure/api/lib/api.dart
git commit -m "feat(api): add centralized api_endpoints registry"
```

---

### Task 2: 迁移 RepositoryImpl 端点引用

**Files:**
- Modify: `packages/features/feature_home/lib/src/repository/home_repository_impl.dart:20,32`
- Modify: `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart:16`
- Modify: `packages/infrastructure/api/lib/src/dio/renewal_token_intercaptor.dart` (token路径)

- [ ] **Step 1: 迁移 home_repository_impl.dart**

将 `/home/data` 替换为 `ApiEndpoints.home.data`：

```dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;

  HomeRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final response = await _dio.get(ApiEndpoints.home.data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }

  @override
  Future<Map<String, dynamic>> refreshHomeData() async {
    try {
      final response = await _dio.get(ApiEndpoints.home.data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }
}
```

- [ ] **Step 2: 迁移 detail_repository_impl.dart**

将 `/detail/$id` 替换为 `ApiEndpoints.detail.item(id)`：

```dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'detail_repository.dart';

class DetailRepositoryImpl implements DetailRepository {
  final Dio _dio;

  DetailRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getDetailData(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.detail.item(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }
}
```

- [ ] **Step 3: 迁移 renewal_token_intercaptor.dart 中的 token 续期路径**

将硬编码的 `/User/Token/Renewal` 替换为 `ApiBase.tokenRenewal`。

搜索 `renewal_token_intercaptor.dart` 中 `/User/Token/Renewal` 字符串的位置，替换为 `ApiBase.tokenRenewal`。需要新增 import：
```dart
import 'package:api/src/endpoints/api_endpoints.dart' show ApiBase;
```

运行: `flutter analyze` 确认零错误。

- [ ] **Step 4: 验证 & 提交**

```bash
flutter analyze
flutter test
git add packages/features/feature_home/lib/src/repository/home_repository_impl.dart
git add packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart
git add packages/infrastructure/api/lib/src/dio/renewal_token_intercaptor.dart
git commit -m "refactor(api): migrate RepositoryImpl endpoints to ApiEndpoints constants"
```

---

### Task 3: 错误处理清理 — 确定 HttpsException 形态

**Files:**
- Read: `packages/infrastructure/api/lib/src/http/http_error.dart`
- Delete: `packages/infrastructure/api/lib/src/http/error_handler.dart`
- Modify: `packages/infrastructure/api/lib/src/http/http_error.dart` (删除 NeedLogin/NeedAuth/HttpsExceptionExtension)
- Modify: `packages/infrastructure/api/lib/api.dart` (清理导出)

- [ ] **Step 1: 确认 HttpsException.create 外部引用**

```bash
# 在 http_error.dart 的 HttpsException.create 工厂上做 LSP 引用检查
cd /Users/yeyangyang/Desktop/spine_flutter
```

如果 `lsp_find_references` 显示零外部引用（仅 `http_error.dart` 自身和要删除的 `retry_interceptor.dart`），则删除整个 `http_error.dart`。
如果有外部引用（如 `retry_policy.dart` 测试），则保留 HttpsException 类和 `HttpsException.create` 工厂，删除其余。

**假设结果**：零外部引用（因为 `error_handler.dart` 和 `retry_policy.dart` 都即将删除）→ 完整删除 `http_error.dart`。

- [ ] **Step 2: 删除 error_handler.dart**

```bash
rm packages/infrastructure/api/lib/src/http/error_handler.dart
```

- [ ] **Step 3: 删除 http_error.dart（若无外部引用）**

```bash
rm packages/infrastructure/api/lib/src/http/http_error.dart
```

如有外部引用，改为编辑删除 NeedLogin/NeedAuth/HttpsExceptionExtension，仅保留 HttpsException 类和 `HttpsException.create` 工厂。

- [ ] **Step 4: 清理 api.dart barrel 导出**

移除以下行：
```dart
export 'src/http/http_error.dart';          // 若完整删除文件
export 'src/http/error_handler.dart';       // 已删除
```

- [ ] **Step 5: 验证 DioExceptionMapper 正常工作**

```bash
flutter analyze
flutter test packages/features/feature_home/
flutter test packages/features/feature_detail/
```

预期: 测试通过，错误处理无变化。

- [ ] **Step 6: 提交**

```bash
git add -A packages/infrastructure/api/lib/src/http/
git add packages/infrastructure/api/lib/api.dart
git commit -m "refactor(api): remove dead error handling code (ErrorHandler, NeedLogin, NeedAuth, HttpsExceptionExtension)"
```

---

### Task 4: 死代码删除

**Files:**
- Delete: 7 个死代码文件
- Modify: `packages/infrastructure/api/lib/api.dart` (清理导出)
- Modify: `packages/infrastructure/api/test/token_renewal_interceptor_test.dart` (删除已删文件的测试组)

- [ ] **Step 1: 删除 7 个文件**

```bash
rm packages/infrastructure/api/lib/src/url_builder.dart
rm packages/infrastructure/api/lib/src/dio/token_interceptor.dart
rm packages/infrastructure/api/lib/src/dio/retry_interceptor.dart
rm packages/infrastructure/api/lib/src/http/retry_policy.dart
rm packages/infrastructure/api/lib/src/http/concurrent_limiter.dart
rm packages/infrastructure/api/lib/src/tracking/request_tracker.dart
rm packages/infrastructure/api/lib/src/dio/log_reporting_interceptor.dart
```

- [ ] **Step 2: 清理 api.dart barrel 导出**

移除以下导出行：
```dart
export 'src/http/retry_policy.dart';               // 删除
export 'src/http/concurrent_limiter.dart';         // 删除
export 'src/dio/log_reporting_interceptor.dart';   // 删除
export 'src/tracking/request_tracker.dart';        // 删除
```

barrel 当前 24 行 → 目标 ~20 行。

- [ ] **Step 3: 删除 token_renewal_interceptor_test.dart 中的废弃测试组**

打开文件，删除以下测试组（group 块）：
- `group('RetryPolicy', () { ... });`
- `group('ConcurrentLimiter', () { ... });`
- `group('ConcurrentLimiters', () { ... });`
- `group('RequestTracker', () { ... });`

保留 TokenRenewalInterceptor、CancelTokenManager、AutoCancelInterceptor 测试。

- [ ] **Step 4: 验证 & 提交**

```bash
flutter analyze packages/infrastructure/api/
flutter test packages/infrastructure/api/
```

预期: `flutter analyze` 零错误，所有保留测试通过。

```bash
git add -A packages/infrastructure/api/
git commit -m "refactor(api): remove 7 dead code files (~900 lines)"
```

已删除文件：
- `url_builder.dart` (73行) — FavQs 业务代码
- `token_interceptor.dart` (247行) — 被 renewal_token_intercaptor 替代
- `retry_interceptor.dart` (83行) — 未被 Dio 注册
- `retry_policy.dart` (100行) — 为已删除的 HttpManager 设计
- `concurrent_limiter.dart` (167行) — 同上
- `request_tracker.dart` (82行) — 同上
- `log_reporting_interceptor.dart` (87行) — 从未加入拦截器链

---

### Task 5: 业务泄露清理

**Files:**
- Create: `lib/core/events/tab_events.dart` (OVSTap 新位置)
- Modify: `packages/infrastructure/api/lib/src/http/http_event_bus.dart` (移除 OVSTap + 业务 EventKeys)
- Modify: `packages/infrastructure/api/lib/src/http/http_constant.dart` (移除业务码 + 重命名)
- Modify: `packages/domain/lib/src/exceptions/domain_exception.dart` (新增 tokenInvalid 枚举)

- [ ] **Step 1: 创建 lib/core/events/tab_events.dart — 搬迁 OVSTap**

```dart
/// 应用标签页枚举
///
/// 从 infrastructure/api 中提取，属于应用层核心概念。
/// 所有 feature 可共用此枚举。
enum OVSTap {
  home,
  car,
  find,
  story,
  mine,
}
```

- [ ] **Step 2: 清理 http_event_bus.dart**

从 `http_event_bus.dart` 中删除：
1. `OVSTap` 枚举（lines 34-40）
2. 业务 `EventKeys`: `addNewCar`, `updateCar`, `updateLogs`, `exchangeTab`, `updateWeather`, `updateCar`, `hideTabBar`, `showTabBar`
3. `homeTap` static const

保留：
- `HttpEventBus` 类和其方法
- `EventKeys.logout`, `EventKeys.hasToken`（认证相关）

`http_event_bus.dart` 清理后应约 30 行（仅事件总线基础设施 + 认证事件）。

需要同步更新所有引用 `OVSTap` 和已删除 `EventKeys` 的文件中的 import。搜索指令：
```bash
grep -r "OVSTap\|EventKeys\.addNewCar\|EventKeys\.updateCar\|EventKeys\.updateWeather" packages/ --include="*.dart"
```

- [ ] **Step 3: 清理 http_constant.dart 业务常量**

删除以下行：
```dart
static const int EmptyCarListCode = 9;       // line 35 — 车辆业务错误码
static const int msgVCodeMaxLength = 5;      // line 29 — 短信业务规则
```

重命名：
```dart
// 之前
static const int renewalTokenCode = 1000102;  // line 27
// 之后
static const int reTokenCode = 1000102;        // Token 续期 code（基础设施自有常量）
```

`reLoginCode = 1000103` 保持不变。

同步更新引用 `renewalTokenCode` 的代码：
```bash
grep -r "renewalTokenCode" packages/infrastructure/api/ --include="*.dart"
```
找到 `token_interceptor.dart`（即将删除）、`renewal_token_intercaptor.dart`、`error_handler.dart`（已删除）。更新 `renewal_token_intercaptor.dart` 中的引用为 `reTokenCode`。

- [ ] **Step 4: 新增 domain tokenInvalid 枚举**

在 `packages/domain/lib/src/exceptions/domain_exception.dart` 的 `ErrorCode` 枚举中添加：
```dart
/// Token 已失效，需重新登录（对应后端 code 1000103）
tokenInvalid,
```

通过 grep 确认 `tokenExpired` 已存在：
```bash
grep "tokenExpired" packages/domain/lib/src/exceptions/domain_exception.dart
```

- [ ] **Step 5: 更新引用 & 验证**

```bash
flutter analyze
flutter test
```

确认无编译错误。

- [ ] **Step 6: 提交**

```bash
git add lib/core/events/tab_events.dart
git add packages/infrastructure/api/lib/src/http/http_event_bus.dart
git add packages/infrastructure/api/lib/src/http/http_constant.dart
git add packages/infrastructure/api/lib/src/dio/renewal_token_intercaptor.dart
git add packages/domain/lib/src/exceptions/domain_exception.dart
git commit -m "refactor: extract business concepts from infrastructure layer"
```

---

### Task 6: 最终验证

**Files:**
- Verify: 全项目

- [ ] **Step 1: 全项目代码分析**

```bash
flutter analyze
```

预期: 零错误。如有错误，逐个修复。

- [ ] **Step 2: 运行测试套件**

```bash
flutter test
```

预期: 全部测试通过。

- [ ] **Step 3: 验证端点管理合规**

```bash
# 验证 repository 层无内联字符串
grep -r "_dio.get('/" packages/features/ --include="*.dart"
grep -r "_dio.post('/" packages/features/ --include="*.dart"
```

预期: 零匹配（所有端点已迁移到 `ApiEndpoints.*`）。

- [ ] **Step 4: 验证死代码删除完整性**

```bash
# 所有被删除的文件不应存在
ls packages/infrastructure/api/lib/src/url_builder.dart 2>&1
ls packages/infrastructure/api/lib/src/dio/token_interceptor.dart 2>&1
ls packages/infrastructure/api/lib/src/http/error_handler.dart 2>&1
```

预期: 全部 "No such file or directory"。

- [ ] **Step 5: 提交最终结果**

```bash
git add -A
git commit -m "refactor(api): final verification — all specs passing"
```

---

## 总结

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| 文件数 | 19 | 13 |
| 死代码行数 | ~900 | 0 |
| 错误处理路径 | 3 | 1 (DioExceptionMapper) |
| 业务泄漏点 | 5 | 0 |
| 端点管理 | 散落内联字符串 | 集中式 ApiEndpoints |
| barrel 导出数 | 14 | ~11 |
| commit 数 | — | 6 |
