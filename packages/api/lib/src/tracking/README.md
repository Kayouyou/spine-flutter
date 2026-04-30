# 请求追踪模块

## 概述

本模块提供请求追踪功能，用于监控HTTP请求的执行过程和耗时。

## 核心组件

### RequestTracker

请求追踪器，记录请求的执行时间，便于性能分析和调试。

## 使用方法

```dart
// 请求开始时追踪
RequestTracker.instance.track('req-001', '/api/user/info', DateTime.now());

// 请求完成时结束追踪
RequestTracker.instance.complete('req-001');

// 查看未完成请求
final pending = RequestTracker.instance.pendingRequests;
final count = RequestTracker.instance.pendingCount;

// 清理所有追踪记录
RequestTracker.instance.clearAll();
```

## 设计原则

1. **单例模式**：全局唯一实例，方便统一管理
2. **轻量级**：仅记录基本信息，不影响性能
3. **调试友好**：使用debugPrint输出，仅在调试模式可见
4. **线程安全**：Map操作在单线程环境执行

## 适用场景

- 性能分析：查看请求耗时
- 调试排查：追踪未完成请求
- 问题定位：识别超时请求
