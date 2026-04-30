# Flutter架构重构 - Phase 3.4: Token续期Logger改造 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 改造Token续期拦截器使用AppLogger，实现统一日志输出，不改续期逻辑

**Architecture:** 在TokenRenewalInterceptor中注入AppLogger，替换原有debugPrint调用，保持续期逻辑完全不变。

**Tech Stack:** 现有packages/api架构, lib/core/utils/logger.dart

---

## 文件结构概览

**修改文件：**

```
packages/api/
  src/
    dio/
      renewal_token_interceptor.dart  # 改造：注入AppLogger
```

**原则：只改日志输出，不改续期逻辑**

---

### Task 1: 检查现有TokenRenewalInterceptor

**Files:**
- Read: `packages/api/src/dio/renewal_token_interceptor.dart` (检查现有实现)

- [ ] **Step 1: 读取现有文件**

```bash
cat packages/api/src/dio/renewal_token_interceptor.dart
```

记录：
- 当前日志输出方式
- 续期逻辑结构
- 需改造的日志点

- [ ] **Step 2: 确认续期逻辑不变**

检查：
- Token获取逻辑
- 队列管理逻辑
- 重试请求逻辑

确保改造仅替换日志输出，不改任何续期逻辑。

---

### Task 2: 改造TokenRenewalInterceptor

**Files:**
- Modify: `packages/api/src/dio/renewal_token_interceptor.dart`

- [ ] **Step 1: 添加AppLogger注入**

修改 `packages/api/src/dio/renewal_token_interceptor.dart`：

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// 导入AppLogger（通过依赖注入）
// 注意：api包不应直接依赖app层，使用接口注入

/// Token续期拦截器
///
/// 职责：处理Token过期自动续期，避免用户重复登录
/// 续期流程：
///   1. 请求返回401
///   2. 拦截器暂停请求，加入队列
///   3. 续期Token
///   4. 续期成功，重试队列中的请求
///   5. 续期失败，清除队列，通知登出
///
/// Logger改造：
///   - 注入AppLogger接口
///   - 替换debugPrint为logger.log
///   - 续期逻辑完全不变
class TokenRenewalInterceptor extends Interceptor {
  /// Logger实例（可选）
  ///
  /// 通过setter注入，避免构造函数依赖
  /// 未注入时使用debugPrint fallback
  AppLogger? _logger;

  /// 设置Logger
  ///
  /// 在App启动后注入，替换默认debugPrint
  set logger(AppLogger logger) => _logger = logger;

  /// 日志输出
  ///
  /// 优先使用注入的Logger，否则fallback到debugPrint
  void _log(String message, {LogLevel level = LogLevel.info}) {
    if (_logger != null) {
      _logger.log(level, '[TokenRenewal] $message');
    } else if (kDebugMode) {
      debugPrint('[TokenRenewal] $message');
    }
  }

  // ===== 原续期逻辑保持不变 =====

  // Token续期请求队列
  final List<RequestOptions> _requestQueue = [];

  // 是否正在续期
  bool _isRenewing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 仅处理401错误
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    _log('收到401响应，开始Token续期', level: LogLevel.warning);

    // 暂停请求，加入队列
    _requestQueue.add(err.requestOptions);
    _log('请求加入队列，当前队列长度: ${_requestQueue.length}', level: LogLevel.debug);

    // 如果未在续期，开始续期
    if (!_isRenewing) {
      _isRenewing = true;
      _renewToken(err.requestOptions, handler);
    }
  }

  /// 续期Token
  ///
  /// 续期流程，逻辑不变
  Future<void> _renewToken(
    RequestOptions options,
    ErrorInterceptorHandler handler,
  ) async {
    _log('开始续期Token', level: LogLevel.info);

    try {
      // TODO: 实际Token续期逻辑
      // final newToken = await refreshToken();

      _log('Token续期成功', level: LogLevel.info);

      // 更新Token
      // options.headers['Authorization'] = 'Bearer $newToken';

      // 重试队列中的请求
      await _retryQueuedRequests();

      _isRenewing = false;
    } catch (e) {
      _log('Token续期失败: $e', level: LogLevel.error);

      // 续期失败，清除队列
      _requestQueue.clear();
      _isRenewing = false;

      // 通知登出
      // onLogout?.call();
    }
  }

  /// 重试队列请求
  ///
  /// 续期成功后重试所有暂停的请求
  Future<void> _retryQueuedRequests() async {
    _log('开始重试队列请求，数量: ${_requestQueue.length}', level: LogLevel.debug);

    while (_requestQueue.isNotEmpty) {
      final options = _requestQueue.removeAt(0);
      _log('重试请求: ${options.path}', level: LogLevel.debug);

      try {
        // await dio.fetch(options);
        _log('请求重试成功', level: LogLevel.info);
      } catch (e) {
        _log('请求重试失败: $e', level: LogLevel.warning);
      }
    }
  }
}

/// AppLogger接口
///
/// 定义日志接口，避免api包直接依赖app层
/// 实际实现由lib/core/utils/logger.dart提供
abstract class AppLogger {
  void log(LogLevel level, String message);
}

/// 日志级别枚举
///
/// 与lib/core/utils/logger.dart中LogLevel一致
enum LogLevel {
  debug,
  info,
  warning,
  error,
}
```

写入 `packages/api/src/dio/renewal_token_interceptor.dart`

- [ ] **Step 2: Commit**

```bash
git add packages/api/src/dio/renewal_token_interceptor.dart
git commit -m "feat(phase3.4): Token续期拦截器注入AppLogger

- logger setter注入Logger
- _log方法替换debugPrint
- LogLevel级别映射（debug/info/warning/error）
- 续期逻辑完全不变
- 中文注释说明改造原则

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: 定义日志级别映射表

**Files:**
- Add: 文档说明（本Plan文档中）

**日志级别映射：**

| 原日志内容 | LogLevel | 说明 |
|-----------|----------|------|
| 续期成功/获取token | info | 正常操作日志 |
| 队列操作/重试请求 | debug | 详细调试日志 |
| 续期失败/超时 | warning | 需关注的异常 |
| 出错/异常 | error | 错误情况 |

- [ ] **Step 1: 确认映射表已包含在代码注释中**

检查 `renewal_token_interceptor.dart` 中所有 `_log` 调用使用正确级别：

```dart
// 续期成功
_log('Token续期成功', level: LogLevel.info);

// 队列操作
_log('请求加入队列，当前队列长度: ...', level: LogLevel.debug);

// 续期失败
_log('Token续期失败: $e', level: LogLevel.error);

// 收到401
_log('收到401响应，开始Token续期', level: LogLevel.warning);
```

- [ ] **Step 2: Commit**

如需调整级别映射，提交：
```bash
git add packages/api/src/dio/renewal_token_interceptor.dart
git commit -m "feat(phase3.4): 调整日志级别映射

- 续期成功: info
- 队列操作: debug
- 续期失败: error
- 401响应: warning

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 在DI Setup中注入Logger

**Files:**
- Modify: `lib/core/di/setup.dart`

- [ ] **Step 1: 更新Api注入Logger**

修改 `lib/core/di/setup.dart`，在Api创建后注入Logger：

```dart
void setupDependencies() {
  // ===== 核心服务 =====

  // 日志服务
  sl.registerSingleton<AppLogger>(AppLogger());

  // API服务
  final api = Api(
    userTokenSupplier: () async {
      return sl<KeyValueStorage>().getString('token');
    },
    networkDisconnectedCallback: () {
      sl<AppLogger>().warning('网络连接已断开');
    },
  );

  // 注入Logger到Token续期拦截器
  // 注意：需要Api内部提供拦截器注入接口
  // api.setLogger(sl<AppLogger>());

  sl.registerSingleton<Api>(api);

  // ...其他注册...
}
```

注意：如果Api包未提供拦截器注入接口，需在Api类中添加setter：

```dart
// packages/api/lib/src/api.dart
class Api extends ApiBase with DemoApiMixin {
  // ...

  /// 设置Logger到Token续期拦截器
  void setLogger(AppLogger logger) {
    // _httpManager.interceptors.forEach((interceptor) {
    //   if (interceptor is TokenRenewalInterceptor) {
    //     interceptor.logger = logger;
    //   }
    // });
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/di/setup.dart packages/api/lib/src/api.dart
git commit -m "feat(phase3.4): DI注入Logger到Api

- setupDependencies中调用api.setLogger
- Api添加setLogger方法
- 中文注释说明注入流程

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: 验证编译

**Files:**
- 无新文件

- [ ] **Step 1: 运行Flutter分析**

```bash
flutter analyze
```

Expected: 无错误

- [ ] **Step 2: 尝试编译**

```bash
flutter build apk --debug
```

Expected: 编译成功

- [ ] **Step 3: 测试日志输出**

运行应用，触发Token续期场景（模拟401响应），检查：
1. AppLogger输出日志
2. 日志级别正确映射
3. 续期逻辑正常执行

- [ ] **Step 4: Final Commit**

```bash
git add -A
git commit -m "feat(phase3.4): Phase 3.4 Token续期Logger改造完成

完成内容：
- TokenRenewalInterceptor注入AppLogger
- logger setter注入，_log替换debugPrint
- LogLevel级别映射（info/debug/warning/error）
- DI Setup注入Logger到Api
- 续期逻辑完全不变
- 中文注释说明改造原则和映射规则

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Spec Coverage Check

| Design要求 | Plan任务覆盖 |
|-----------|-------------|
| 注入AppLogger | Task 2 |
| LogLevel映射 | Task 3 |
| logger setter | Task 2 |
| 续期逻辑不变 | Task 1, 2 |
| DI注入 | Task 4 |

---

## 改造原则确认

**原则：只改日志输出，不改续期逻辑**

检查：
1. Token获取逻辑：未修改 ✓
2. 队列管理逻辑：未修改 ✓
3. 重试请求逻辑：未修改 ✓
4. 仅替换debugPrint为logger.log ✓

---

Plan complete and saved to `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3d.md`.

**所有Plans生成完毕！**

**Plans列表：**
1. `docs/superpowers/plans/2026-04-30-flutter-architecture-phase1.md` - 基础设施
2. `docs/superpowers/plans/2026-04-30-flutter-architecture-phase2.md` - 核心机制
3. `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3a.md` - API增强
4. `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3b.md` - Hive缓存扩展
5. `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3c.md` - NetworkCubit
6. `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3d.md` - Token续期Logger改造

**执行顺序建议：**
Phase 1 → Phase 2 → Phase 3.1/3.2/3.3/3.4（可并行）

需要开始执行哪个Plan？