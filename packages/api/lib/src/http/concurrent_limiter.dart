import 'dart:async';
import 'dart:collection';
import 'package:domain_models/domain_models.dart';

/// 并发请求限制器
///
/// 职责：限制同时执行的请求数量，管理请求队列
/// 使用：
///   - 设置maxConcurrent控制最大并发数
///   - 使用execute方法包装请求，自动排队执行
///   - 使用priority设置请求优先级
///   - 使用tag标记请求，便于批量取消
/// 特性：
///   - 队列优先级排序
///   - tag批量取消
///   - 运行状态统计
class ConcurrentLimiter {
  /// 最大并发数
  final int maxConcurrent;

  /// 待执行请求队列
  final Queue<_PendingRequest> _queue = Queue();

  /// 当前运行中的请求数量
  int _currentRunning = 0;

  /// 构造并发限制器
  ///
  /// 参数：
  /// - maxConcurrent: 最大并发数（默认5）
  ConcurrentLimiter({this.maxConcurrent = 5});

  /// 执行请求（带队列管理）
  ///
  /// 参数：
  /// - request: 请求执行函数
  /// - priority: 优先级（默认0，数值越大优先级越高）
  /// - tag: 请求标签（用于批量取消）
  ///
  /// 返回：请求执行结果Future
  Future<T> execute<T>(
    Future<T> Function() request,
    {int priority = 0, String? tag}
  ) async {
    // 当前并发数未达上限，直接执行
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
    _sortQueue();
    return pending.completer.future;
  }

  /// 运行请求（内部方法）
  ///
  /// 执行请求并管理并发计数
  Future<T> _runRequest<T>(Future<T> Function() request) async {
    _currentRunning++;
    try {
      return await request();
    } finally {
      _currentRunning--;
      _processNext();
    }
  }

  /// 处理队列中的下一个请求
  void _processNext() {
    // 队列空或并发已满，不处理
    if (_queue.isEmpty || _currentRunning >= maxConcurrent) return;

    // 取出下一个请求执行
    final pending = _queue.removeFirst();
    _runRequest(pending.request).then((result) {
      pending.completer.complete(result);
    }).catchError((error) {
      pending.completer.completeError(error);
    });
  }

  /// 对队列按优先级排序
  ///
  /// 高优先级请求排在队列前端
  void _sortQueue() {
    final sorted = _queue.toList();
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    _queue.clear();
    _queue.addAll(sorted);
  }

  /// 取消指定tag的所有请求
  ///
  /// 参数：
  /// - tag: 请求标签
  ///
  /// 注意：仅取消队列中等待的请求，不影响正在执行的请求
  void cancelTag(String tag) {
    final toCancel = _queue.where((p) => p.tag == tag).toList();
    for (final pending in toCancel) {
      pending.completer.completeError(DomainException(ErrorCode.requestCancelled));
      _queue.remove(pending);
    }
  }

  /// 获取队列长度（等待中的请求数）
  int get queueLength => _queue.length;

  /// 获取当前运行中的请求数
  int get currentRunning => _currentRunning;
}

/// 待执行请求内部类
class _PendingRequest<T> {
  /// 请求执行函数
  final Future<T> Function() request;

  /// 请求优先级
  final int priority;

  /// 请求标签
  final String? tag;

  /// 结果Completer
  final Completer<T> completer = Completer<T>();

  _PendingRequest({
    required this.request,
    required this.priority,
    this.tag,
  });
}

/// 并发限制器集合
///
/// 预定义的并发限制器实例，按场景分类
/// 使用：
///   - upload: 上传场景，限制3并发
///   - standard: 标准场景，限制5并发
///   - sync: 同步场景，限制2并发
class ConcurrentLimiters {
  ConcurrentLimiters._();

  /// 上传场景限制器
  ///
  /// 最大3并发，适合文件上传等资源密集场景
  static final upload = ConcurrentLimiter(maxConcurrent: 3);

  /// 标准场景限制器
  ///
  /// 最大5并发，适合一般API请求
  static final standard = ConcurrentLimiter(maxConcurrent: 5);

  /// 同步场景限制器
  ///
  /// 最大2并发，适合数据同步等低频场景
  static final sync = ConcurrentLimiter(maxConcurrent: 2);
}