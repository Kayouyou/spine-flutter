# Flutter架构重构 - Phase 3.1: API增强 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现API增强功能，包括请求取消管理、请求追踪、重试策略、API分组Mixin、并发限制器

**Architecture:** 在现有Api包基础上扩展，新增CancelTokenManager、RequestTracker、RetryPolicy等模块。使用Mixin模式组织API分组。

**Tech Stack:** Dio ^5.2.0, 现有packages/api架构

---

## 文件结构概览

**创建的新文件：**

```
packages/api/
  src/
    cancel/
      cancel_manager.dart      # CancelTokenManager
      README.md
    tracking/
      request_tracker.dart     # RequestTracker
      README.md
    http/
      retry_policy.dart        # RetryPolicy
      concurrent_limiter.dart  # ConcurrentLimiter
    modules/
      user/
        user_api.dart          # UserApi Mixin
        README.md
      home/
        home_api.dart          # HomeApi Mixin
        README.md
      order/
        order_api.dart         # OrderApi Mixin
        README.md

lib/
  core/
    widgets/
      request_scope.dart       # RequestScope Widget
```

**依赖Phase 1/2完成项：**
- packages/api现有架构
- lib/core/utils/logger.dart

---

### Task 1: 创建CancelTokenManager

**Files:**
- Create: `packages/api/src/cancel/cancel_manager.dart`
- Create: `packages/api/src/cancel/README.md`
- Modify: `packages/api/lib/api.dart` (导出cancel模块)

- [ ] **Step 1: 创建cancel目录**

```bash
mkdir -p packages/api/src/cancel
```

- [ ] **Step 2: 创建CancelTokenManager**

```dart
import 'package:dio/dio.dart';

/// 请求取消管理器
///
/// 职责：管理页面级请求取消，避免页面退出后请求继续执行
/// 使用：
///   - 页面进入时注册CancelToken
///   - 页面退出时取消该页面所有请求
///   - RequestScope Widget自动管理
/// 优势：避免内存泄漏、减少无效网络请求
class CancelTokenManager {
  /// 单例实例
  static final instance = CancelTokenManager._();

  CancelTokenManager._();

  /// 页面请求Token映射表
  ///
  /// key: pageTag（页面标识）
  /// value: 该页面的所有CancelToken列表
  final Map<String, List<CancelToken>> _pageTokens = {};

  /// 注册页面请求Token
  ///
  /// 将请求的CancelToken与页面关联
  /// 页面退出时可批量取消该页面所有请求
  ///
  /// 参数：
  /// - pageTag: 页面唯一标识（如页面路径或自定义tag）
  /// - token: Dio CancelToken实例
  void register(String pageTag, CancelToken token) {
    _pageTokens.putIfAbsent(pageTag, () => []).add(token);
  }

  /// 取消页面所有请求
  ///
  /// 页面退出时调用，取消该页面所有未完成的请求
  /// 已完成的请求不受影响
  ///
  /// 参数：
  /// - pageTag: 页面标识
  /// - reason: 取消原因（可选，默认"Page disposed"）
  void cancelPage(String pageTag, [String? reason]) {
    final tokens = _pageTokens[pageTag];
    if (tokens != null) {
      for (final token in tokens) {
        // 取消请求，附带原因说明
        token.cancel(reason ?? 'Page disposed: $pageTag');
      }
      // 清空该页面的Token列表
      tokens.clear();
    }
  }

  /// 清理页面Token记录
  ///
  /// 页面彻底销毁时调用，移除该页面的Token映射
  /// 注意：仅移除记录，不取消请求（请求已在cancelPage中取消）
  void cleanup(String pageTag) {
    _pageTokens.remove(pageTag);
  }

  /// 获取页面Token数量
  ///
  /// 用于调试，查看某页面有多少未完成请求
  int getTokenCount(String pageTag) {
    return _pageTokens[pageTag]?.length ?? 0;
  }

  /// 清理所有记录
  ///
  /// App退出或重置时调用
  void clearAll() {
    _pageTokens.clear();
  }
}
```

写入 `packages/api/src/cancel/cancel_manager.dart`

- [ ] **Step 3: 创建README**

```markdown
# 请求取消模块

## 职责
管理页面级请求取消，避免页面退出后请求继续执行。

## 使用示例

### 手动管理
```dart
// 创建CancelToken
final token = CancelToken();
CancelTokenManager.instance.register('home_page', token);

// 发起请求
await api.get('/data').cancelToken(token).fire();

// 页面退出时取消
CancelTokenManager.instance.cancelPage('home_page');
CancelTokenManager.instance.cleanup('home_page');
```

### RequestScope自动管理
```dart
RequestScope(
  tag: 'detail_page',
  child: DetailContent(),
)
// Widget销毁时自动取消请求
```

## 设计原理
1. 每个页面有唯一tag标识
2. 页面内所有请求共用tag
3. 页面退出时批量取消所有未完成请求

## 依赖关系
- dio: CancelToken来源

## 性能警告
- Token映射表内存占用，页面退出后需cleanup清理
- 大量请求时Token列表可能较长，建议分批管理
```

写入 `packages/api/src/cancel/README.md`

- [ ] **Step 4: 导出cancel模块**

修改 `packages/api/lib/api.dart`：

```dart
export 'src/api.dart';
export 'src/modules/modules.dart';
export 'src/http/http_error.dart';
export 'src/http/http_event_bus.dart';
export 'src/http/http_constant.dart';
export 'src/http/error_handler.dart';
export 'src/http/token_supplier.dart';
export 'src/dio/log_reporting_interceptor.dart';
// Phase 2
export 'src/error/dio_mapper.dart';
// Phase 3.1新增
export 'src/cancel/cancel_manager.dart';
```

- [ ] **Step 5: 验证文件创建**

```bash
ls -la packages/api/src/cancel/
cat packages/api/src/cancel/cancel_manager.dart
```

Expected: cancel目录和文件创建成功

- [ ] **Step 6: Commit**

```bash
git add packages/api/src/cancel/ packages/api/lib/api.dart
git commit -m "feat(phase3.1): 创建CancelTokenManager请求取消管理

- register注册页面Token
- cancelPage批量取消页面请求
- cleanup清理页面记录
- 中文注释说明使用场景和性能警告

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 创建RequestScope Widget

**Files:**
- Create: `lib/core/widgets/request_scope.dart`
- Modify: `lib/core/widgets/README.md`

- [ ] **Step 2: 创建RequestScope**

```dart
import 'package:flutter/widgets.dart';
import 'package:api/api.dart';

/// 请求范围Widget
///
/// 职责：自动管理页面级请求取消
/// 使用：包装需要取消请求的页面内容
/// 原理：Widget销毁时自动调用CancelTokenManager.cancelPage
///
/// 示例：
/// ```dart
/// RequestScope(
///   tag: 'detail_page',
///   child: DetailContent(),
/// )
/// ```
class RequestScope extends StatefulWidget {
  /// 页面标识
  ///
  /// 用于关联该范围内的所有请求
  /// 建议：使用页面路径或功能名称作为tag
  final String tag;

  /// 子Widget
  final Widget child;

  const RequestScope({
    required this.tag,
    required this.child,
    super.key,
  });

  @override
  State<RequestScope> createState() => _RequestScopeState();
}

class _RequestScopeState extends State<RequestScope> {
  @override
  void dispose() {
    // Widget销毁时，取消该页面所有未完成请求
    CancelTokenManager.instance.cancelPage(widget.tag);
    // 清理Token记录
    CancelTokenManager.instance.cleanup(widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

写入 `lib/core/widgets/request_scope.dart`

- [ ] **Step 3: 更新widgets README**

修改 `lib/core/widgets/README.md`：

```markdown
# 通用组件模块

## 职责
提供跨Feature共享的通用UI组件。

## 组件列表

### RequestScope
请求范围管理Widget，自动取消页面退出后的请求。

```dart
RequestScope(
  tag: 'detail_page',
  child: DetailContent(),
)
```

### NetworkBanner（Phase 3.3）
网络状态提示Banner。

## 使用示例
```dart
// 在页面顶层包装
RequestScope(
  tag: 'home_page',
  child: BlocProvider(
    create: (context) => HomeCubit()..loadData(),
    child: HomePageContent(),
  ),
)
```

## 依赖关系
- api: CancelTokenManager
- flutter_bloc（部分组件）

## 性能警告
- RequestScope仅管理请求取消，不影响UI渲染性能
- 避免过度嵌套Stack层叠
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/widgets/
git commit -m "feat(phase3.1): 创建RequestScope Widget

- 自动管理页面请求取消
- dispose时调用CancelTokenManager
- 中文注释说明使用方式和原理

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: 创建RequestTracker

**Files:**
- Create: `packages/api/src/tracking/request_tracker.dart`
- Create: `packages/api/src/tracking/README.md`

- [ ] **Step 1: 创建tracking目录**

```bash
mkdir -p packages/api/src/tracking
```

- [ ] **Step 2: 创建RequestTracker**

```dart
/// 请求追踪器
///
/// 职责：追踪请求执行过程，记录耗时和状态
/// 使用：
///   - track开始追踪请求
///   - complete结束追踪并输出耗时日志
///   - pendingRequests获取当前未完成请求列表
/// 用途：调试、性能分析、请求监控
class RequestTracker {
  /// 单例实例
  static final instance = RequestTracker._();

  RequestTracker._();

  /// 请求信息映射表
  ///
  /// key: requestId（请求唯一标识）
  /// value: 请求信息（路径、开始时间）
  final Map<String, _RequestInfo> _requests = {};

  /// 开始追踪请求
  ///
  /// 记录请求开始时间，用于后续计算耗时
  ///
  /// 参数：
  /// - requestId: 请求唯一标识（如UUID或自定义）
  /// - path: 请求路径（用于日志输出）
  /// - startTime: 开始时间（默认当前时间）
  void track(String requestId, String path, DateTime? startTime) {
    _requests[requestId] = _RequestInfo(
      path: path,
      startTime: startTime ?? DateTime.now(),
    );
  }

  /// 结束追踪请求
  ///
  /// 计算请求耗时并输出日志，移除追踪记录
  ///
  /// 参数：
  /// - requestId: 请求标识
  void complete(String requestId) {
    final info = _requests[requestId];
    if (info != null) {
      // 计算耗时
      final duration = DateTime.now().difference(info.startTime);
      // 输出调试日志（可集成AppLogger）
      // 格式：Request {id}: {path} - {duration}ms
      debugPrint('Request $requestId: ${info.path} - ${duration.inMilliseconds}ms');
      // 移除记录
      _requests.remove(requestId);
    }
  }

  /// 获取未完成请求列表
  ///
  /// 用于调试，查看当前有哪些请求正在进行
  List<_RequestInfo> get pendingRequests => _requests.values.toList();

  /// 获取未完成请求数量
  int get pendingCount => _requests.length;

  /// 清理所有追踪记录
  void clearAll() {
    _requests.clear();
  }
}

/// 请求信息
///
/// 记录单个请求的路径和开始时间
class _RequestInfo {
  /// 请求路径
  final String path;

  /// 开始时间
  final DateTime startTime;

  _RequestInfo({required this.path, required this.startTime});
}
```

写入 `packages/api/src/tracking/request_tracker.dart`

- [ ] **Step 3: 创建README**

```markdown
# 请求追踪模块

## 职责
追踪请求执行过程，记录耗时和状态。

## 使用示例
```dart
// 开始追踪
final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
RequestTracker.instance.track(requestId, '/user/info', DateTime.now());

// 发起请求
await api.get('/user/info').fire();

// 结束追踪
RequestTracker.instance.complete(requestId);
```

## 输出格式
```
Request req_123456: /user/info - 245ms
```

## 依赖关系
- flutter/foundation.dart: debugPrint

## 性能警告
- 追踪记录占用内存，请求完成后自动清理
- 大量并发请求时pendingRequests列表可能较长
- 生产环境建议禁用或使用AppLogger过滤
```

写入 `packages/api/src/tracking/README.md`

- [ ] **Step 4: 导出tracking模块**

修改 `packages/api/lib/api.dart`：

```dart
// Phase 3.1新增
export 'src/cancel/cancel_manager.dart';
export 'src/tracking/request_tracker.dart';
```

- [ ] **Step 5: Commit**

```bash
git add packages/api/src/tracking/ packages/api/lib/api.dart
git commit -m "feat(phase3.1): 创建RequestTracker请求追踪

- track开始追踪请求
- complete结束追踪并输出耗时
- pendingRequests获取未完成请求列表
- 中文注释说明调试用途

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 创建RetryPolicy

**Files:**
- Create: `packages/api/src/http/retry_policy.dart`

- [ ] **Step 1: 创建RetryPolicy**

```dart
import 'package:dio/dio.dart';

/// 重试策略
///
/// 职责：定义请求重试规则，包括重试次数、延迟、可重试类型等
/// 使用：ApiBuilder.retry()配置重试策略
/// 常量策略：
///   - none: 不重试（默认）
///   - standard: 标准重试（3次）
///   - aggressive: 激进重试（5次）
class RetryPolicy {
  /// 最大重试次数
  ///
  /// 0表示不重试
  final int maxRetries;

  /// 重试延迟时间
  ///
  /// 每次重试前的等待时间
  final Duration retryDelay;

  /// 可重试的DioException类型
  ///
  /// 这些类型的错误会触发重试
  final List<DioExceptionType> retryableTypes;

  /// 可重试的HTTP状态码
  ///
  /// 这些状态码的响应会触发重试
  final List<int> retryableStatusCodes;

  const RetryPolicy({
    this.maxRetries = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.retryableTypes = const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ],
    this.retryableStatusCodes = const [502, 503, 504],
  });

  /// 不重试策略
  ///
  /// 默认策略，请求失败直接返回错误
  static const RetryPolicy none = RetryPolicy();

  /// 标准重试策略
  ///
  /// 重试3次，每次间隔1秒
  /// 适用场景：一般网络请求
  static const RetryPolicy standard = RetryPolicy(maxRetries: 3);

  /// 激进重试策略
  ///
  /// 重试5次，每次间隔0.5秒
  /// 适用场景：关键数据请求、高并发场景
  static const RetryPolicy aggressive = RetryPolicy(
    maxRetries: 5,
    retryDelay: Duration(milliseconds: 500),
    retryableStatusCodes: [500, 502, 503, 504],
  );

  /// 判断是否应该重试
  ///
  /// 根据DioException类型和HTTP状态码判断是否触发重试
  ///
  /// 参数：
  /// - error: Dio异常
  /// - retryCount: 当前已重试次数
  ///
  /// 返回：true表示应该重试，false表示不应重试
  bool shouldRetry(DioException error, int retryCount) {
    // 已达到最大重试次数
    if (retryCount >= maxRetries) return false;

    // 检查异常类型
    if (retryableTypes.contains(error.type)) return true;

    // 检查HTTP状态码
    final statusCode = error.response?.statusCode;
    if (statusCode != null && retryableStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  /// 获取下次重试延迟时间
  ///
  /// 可扩展实现指数退避等策略
  Duration getRetryDelay(int retryCount) {
    // 简单实现：固定延迟
    return retryDelay;
    // 指数退避实现（可选）：
    // return retryDelay * (1 << retryCount);
  }
}
```

写入 `packages/api/src/http/retry_policy.dart`

- [ ] **Step 2: Commit**

```bash
git add packages/api/src/http/retry_policy.dart
git commit -m "feat(phase3.1): 创建RetryPolicy重试策略

- 可配置重试次数、延迟、类型、状态码
- none/standard/aggressive三种预设策略
- shouldRetry判断是否触发重试
- 中文注释说明策略选择

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: 创建ConcurrentLimiter

**Files:**
- Create: `packages/api/src/http/concurrent_limiter.dart`

- [ ] **Step 1: 创建ConcurrentLimiter**

```dart
import 'dart:collection';
import 'package:domain_models/domain_models.dart';

/// 并发请求限制器
///
/// 职责：限制同时执行的请求数量，避免服务器压力过大
/// 使用：execute包装请求，限制器自动排队管理
/// 常量限制器：
///   - upload: 上传请求限制（3个并发）
///   - standard: 标准请求限制（5个并发）
///   - sync: 同步请求限制（2个并发）
///
/// 示例：
/// ```dart
/// final result = await ConcurrentLimiters.standard.execute(
///   () => api.get('/data').fire(),
///   priority: 1,
/// );
/// ```
class ConcurrentLimiter {
  /// 最大并发数
  final int maxConcurrent;

  /// 待执行请求队列
  ///
  /// 按优先级排序，优先级高的先执行
  final Queue<_PendingRequest> _queue = Queue();

  /// 当前正在执行的请求数量
  int _currentRunning = 0;

  ConcurrentLimiter({this.maxConcurrent = 5});

  /// 执行请求
  ///
  /// 如果当前并发数未达上限，立即执行
  /// 否则加入队列等待执行
  ///
  /// 参数：
  /// - request: 请求执行函数
  /// - priority: 优先级（数值越大优先级越高）
  /// - tag: 请求标签（用于批量取消）
  ///
  /// 返回：请求执行结果
  Future<T> execute<T>(
    Future<T> Function() request,
    {int priority = 0, String? tag}
  ) async {
    // 未达上限，立即执行
    if (_currentRunning < maxConcurrent) {
      return _runRequest<T>(request);
    }

    // 已达上限，加入队列等待
    final pending = _PendingRequest<T>(
      request: request,
      priority: priority,
      tag: tag,
    );
    _queue.add(pending);
    // 按优先级排序队列
    _sortQueue();
    // 等待执行完成
    return pending.completer.future;
  }

  /// 内部执行请求
  ///
  /// 执行请求并管理计数，完成后触发下一个队列请求
  Future<T> _runRequest<T>(Future<T> Function() request) async {
    _currentRunning++;
    try {
      final result = await request();
      return result;
    } finally {
      _currentRunning--;
      // 执行完成后，检查队列是否有待执行请求
      _processNext();
    }
  }

  /// 处理队列中的下一个请求
  void _processNext() {
    if (_queue.isEmpty || _currentRunning >= maxConcurrent) return;

    final pending = _queue.removeFirst();
    // 异步执行，不阻塞当前线程
    _runRequest(pending.request).then((result) {
      pending.completer.complete(result);
    }).catchError((error) {
      pending.completer.completeError(error);
    });
  }

  /// 按优先级排序队列
  ///
  /// 优先级高的请求排在前面
  void _sortQueue() {
    final sorted = _queue.toList();
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    _queue.clear();
    _queue.addAll(sorted);
  }

  /// 取消指定标签的所有待执行请求
  ///
  /// 用于批量取消某功能的请求
  void cancelTag(String tag) {
    final toCancel = _queue.where((p) => p.tag == tag).toList();
    for (final pending in toCancel) {
      pending.completer.completeError(
        DomainException(ErrorCode.requestCancelled),
      );
      _queue.remove(pending);
    }
  }

  /// 获取队列长度
  int get queueLength => _queue.length;

  /// 获取当前执行数
  int get currentRunning => _currentRunning;
}

/// 待执行请求
///
/// 封装请求信息，支持优先级和取消
class _PendingRequest<T> {
  final Future<T> Function() request;
  final int priority;
  final String? tag;
  final Completer<T> completer = Completer<T>();

  _PendingRequest({
    required this.request,
    required this.priority,
    this.tag,
  });
}

/// 并发限制器集合
///
/// 职责：提供不同场景的预设限制器
/// 使用：ConcurrentLimiters.upload/standard/sync
class ConcurrentLimiters {
  ConcurrentLimiters._();

  /// 上传请求限制器
  ///
  /// 最大并发：3
  /// 适用场景：文件上传、图片上传
  static final upload = ConcurrentLimiter(maxConcurrent: 3);

  /// 标准请求限制器
  ///
  /// 最大并发：5
  /// 适用场景：一般数据请求
  static final standard = ConcurrentLimiter(maxConcurrent: 5);

  /// 同步请求限制器
  ///
  /// 最大并发：2
  /// 适用场景：数据同步、批量操作
  static final sync = ConcurrentLimiter(maxConcurrent: 2);
}
```

写入 `packages/api/src/http/concurrent_limiter.dart`

- [ ] **Step 2: 导出ConcurrentLimiter**

修改 `packages/api/lib/api.dart`：

```dart
// Phase 3.1新增
export 'src/cancel/cancel_manager.dart';
export 'src/tracking/request_tracker.dart';
export 'src/http/retry_policy.dart';
export 'src/http/concurrent_limiter.dart';
```

- [ ] **Step 3: Commit**

```bash
git add packages/api/src/http/concurrent_limiter.dart packages/api/lib/api.dart
git commit -m "feat(phase3.1): 创建ConcurrentLimiter并发限制器

- execute包装请求，自动排队管理
- 支持优先级排序
- cancelTag批量取消请求
- ConcurrentLimiters预设三种限制器
- 中文注释说明使用场景

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: 创建API分组Mixin（UserApi）

**Files:**
- Create: `packages/api/src/modules/user/user_api.dart`
- Create: `packages/api/src/modules/user/README.md`

- [ ] **Step 1: 创建user模块目录**

```bash
mkdir -p packages/api/src/modules/user
```

- [ ] **Step 2: 创建UserApi Mixin**

```dart
import '../api.dart';

/// 用户API Mixin
///
/// 职责：定义用户相关API接口，Repository可直接mixin使用
/// 使用：
/// ```dart
/// class UserRepositoryImpl with UserApi {
///   @override
///   final HttpManager api;
///   ...
/// }
/// ```
/// 好处：
/// - API定义集中管理
/// - Repository实现简洁
/// - 便于Mock测试
mixin UserApi {
  /// API客户端
  ///
  /// 子类需提供HttpManager实例
  HttpManager get api;

  /// 用户登录
  ///
  /// 参数：
  /// - username: 用户名
  /// - password: 密码
  ///
  /// 返回：登录响应（包含token等）
  Future<dynamic> login({
    required String username,
    required String password,
  }) {
    return api.post('/user/login')
      .addParam('username', username)
      .addParam('password', password)
      .fire();
  }

  /// 获取用户信息
  ///
  /// 返回：用户详细信息
  Future<dynamic> getUserInfo() {
    return api.get('/user/info').fire();
  }

  /// 用户登出
  ///
  /// 清除服务器端登录状态
  Future<dynamic> logout() {
    return api.post('/user/logout').fire();
  }

  /// 更新用户信息
  ///
  /// 参数：
  /// - data: 更新数据
  Future<dynamic> updateUser(Map<String, dynamic> data) {
    return api.put('/user/info')
      .addParams(data)
      .fire();
  }
}
```

写入 `packages/api/src/modules/user/user_api.dart`

- [ ] **Step 3: 创建README**

```markdown
# 用户API模块

## 职责
定义用户相关API接口，使用Mixin模式简化Repository实现。

## 使用示例

### Repository使用Mixin
```dart
class UserRepositoryImpl implements UserRepository with UserApi {
  @override
  final HttpManager api;
  final BoxService<User> _userBox;

  UserRepositoryImpl(this.api, this._userBox);

  Future<User> getUserInfo({bool forceRefresh = false}) async {
    // 检查缓存
    if (!forceRefresh) {
      final cached = await _userBox.get('current_user');
      if (cached != null) return cached;
    }
    // 调用API
    final response = await super.getUserInfo();
    final user = User.fromJson(response);
    // 更新缓存
    await _userBox.put('current_user', user);
    return user;
  }
}
```

## Mixin设计优势
1. API定义集中管理，避免散落各处
2. Repository实现简洁，仅关注业务逻辑
3. 便于Mock测试，可单独Mock Mixin方法

## API列表
- login: 用户登录
- getUserInfo: 获取用户信息
- logout: 用户登出
- updateUser: 更新用户信息

## 依赖关系
- api: HttpManager实例

## 性能警告
无
```

写入 `packages/api/src/modules/user/README.md`

- [ ] **Step 4: Commit**

```bash
git add packages/api/src/modules/user/
git commit -m "feat(phase3.1): 创建UserApi Mixin

- login/getUserInfo/logout/updateUser方法
- Repository可直接mixin使用
- 中文注释说明Mixin设计优势

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: 创建HomeApi和OrderApi Mixin

**Files:**
- Create: `packages/api/src/modules/home/home_api.dart`
- Create: `packages/api/src/modules/home/README.md`
- Create: `packages/api/src/modules/order/order_api.dart`
- Create: `packages/api/src/modules/order/README.md`

- [ ] **Step 1: 创建home和order目录**

```bash
mkdir -p packages/api/src/modules/home
mkdir -p packages/api/src/modules/order
```

- [ ] **Step 2: 创建HomeApi Mixin**

```dart
import '../api.dart';

/// 首页API Mixin
///
/// 职责：定义首页相关API接口
mixin HomeApi {
  /// API客户端
  HttpManager get api;

  /// 获取首页数据
  ///
  /// 返回：首页展示数据
  Future<dynamic> getHomeData() {
    return api.get('/home/data').fire();
  }

  /// 获取首页推荐列表
  ///
  /// 参数：
  /// - page: 页码
  /// - size: 每页数量
  Future<dynamic> getRecommendList({
    int page = 1,
    int size = 20,
  }) {
    return api.get('/home/recommend')
      .addParam('page', page)
      .addParam('size', size)
      .fire();
  }
}
```

写入 `packages/api/src/modules/home/home_api.dart`

- [ ] **Step 3: 创建OrderApi Mixin**

```dart
import '../api.dart';

/// 订单API Mixin
///
/// 职责：定义订单相关API接口
mixin OrderApi {
  /// API客户端
  HttpManager get api;

  /// 获取订单列表
  ///
  /// 参数：
  /// - status: 订单状态（可选）
  /// - page: 页码
  /// - size: 每页数量
  Future<dynamic> getOrderList({
    String? status,
    int page = 1,
    int size = 20,
  }) {
    final builder = api.get('/order/list')
      .addParam('page', page)
      .addParam('size', size);
    if (status != null) {
      builder.addParam('status', status);
    }
    return builder.fire();
  }

  /// 获取订单详情
  ///
  /// 参数：
  /// - orderId: 订单ID
  Future<dynamic> getOrderDetail(String orderId) {
    return api.get('/order/$orderId').fire();
  }

  /// 创建订单
  ///
  /// 参数：
  /// - data: 订单数据
  Future<dynamic> createOrder(Map<String, dynamic> data) {
    return api.post('/order/create')
      .addParams(data)
      .fire();
  }

  /// 取消订单
  ///
  /// 参数：
  /// - orderId: 订单ID
  /// - reason: 取消原因（可选）
  Future<dynamic> cancelOrder(String orderId, {String? reason}) {
    final builder = api.post('/order/$orderId/cancel');
    if (reason != null) {
      builder.addParam('reason', reason);
    }
    return builder.fire();
  }
}
```

写入 `packages/api/src/modules/order/order_api.dart`

- [ ] **Step 4: 创建README文件**

Home README:
```markdown
# 首页API模块

## 职责
定义首页相关API接口。

## API列表
- getHomeData: 获取首页数据
- getRecommendList: 获取推荐列表

## 使用示例
```dart
class HomeRepositoryImpl with HomeApi {
  @override
  HttpManager get api => _api;
}
```
```

Order README:
```markdown
# 订单API模块

## 职责
定义订单相关API接口。

## API列表
- getOrderList: 订单列表
- getOrderDetail: 订单详情
- createOrder: 创建订单
- cancelOrder: 取消订单

## 使用示例
```dart
class OrderRepositoryImpl with OrderApi {
  @override
  HttpManager get api => _api;
}
```
```

- [ ] **Step 5: Commit**

```bash
git add packages/api/src/modules/home/ packages/api/src/modules/order/
git commit -m "feat(phase3.1): 创建HomeApi和OrderApi Mixin

- HomeApi: getHomeData/getRecommendList
- OrderApi: getOrderList/getOrderDetail/createOrder/cancelOrder
- 中文注释说明方法用途

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: 验证编译

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

- [ ] **Step 3: Final Commit**

```bash
git add -A
git commit -m "feat(phase3.1): Phase 3.1 API增强完成

完成内容：
- CancelTokenManager: 页面级请求取消管理
- RequestScope Widget: 自动管理请求取消
- RequestTracker: 请求追踪和耗时记录
- RetryPolicy: 重试策略（none/standard/aggressive）
- ConcurrentLimiter: 并发请求限制器
- API分组Mixin: UserApi/HomeApi/OrderApi
- 所有模块添加中文README和注释

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Spec Coverage Check

| Design要求 | Plan任务覆盖 |
|-----------|-------------|
| CancelTokenManager | Task 1 |
| RequestScope Widget | Task 2 |
| RequestTracker | Task 3 |
| RetryPolicy | Task 4 |
| ConcurrentLimiter | Task 5 |
| API分组Mixin | Task 6-7 |
| 中文README | 所有模块 |

---

Plan complete and saved to `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3a.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)**
2. **Inline Execution**

继续生成剩余plans？