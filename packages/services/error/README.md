# error 包

全局错误处理服务 — 统一捕获、应用内业务上报、Sentry 转发。

## 内部结构

```
error/
├── lib/
│   ├── error.dart                  # 导出入口
│   └── src/
│       ├── error_handler.dart      # AppErrorHandler（全局错误处理 + 业务层上报入口）
│       ├── error_reporter.dart     # ErrorReporter 抽象 + ConsoleReporter（开发兜底）
│       └── sentry_reporter.dart    # SentryReporter（生产上报）
└── pubspec.yaml
```

## 职责

- 捕获 Flutter 未处理异常（`FlutterError.onError`）
- 捕获 Dart Zone / PlatformDispatcher 异步异常
- 暴露 `reportError` 公共方法给业务层主动上报
- LRU 去重（16 项 × 1 秒）防止短时间重复风暴
- 转发到注册的 `ErrorReporter`（生产 Sentry / 开发 Console）

## 使用

### 1. 启动初始化

```dart
import 'package:error/error.dart';

void main() {
  AppErrorHandler.setup();
  AppErrorHandler.instance.setReporter(SentryReporter());  // 生产
  // AppErrorHandler.instance.setReporter(ConsoleReporter());  // 开发兜底
  runApp(const SpineFlutter());
}
```

### 2. 业务层主动上报

供 Bloc / Repository / Interceptor 等任何模块调用，自动经过 LRU 去重后转发到 reporter：

```dart
AppErrorHandler.instance.reportError(
  error,
  stackTrace,
  isFatal: true,                              // Sentry 标记 fatal
  context: {                                  // 在 Sentry 里作为 tag/breadcrumb
    'source': 'bloc',                          // 'bloc' | 'dio' | 'custom'
    'bloc': bloc.runtimeType.toString(),
  },
);
```

LRU 行为：相同 `(runtimeType, toString, stack)` 在 1 秒内只上报一次；超过 16 条不同错误时按 FIFO 淘汰最旧的。

## 上报链路

```
┌─────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ Flutter 框架错误 │──▶│ AppErrorHandler  │──▶│ ErrorReporter    │
│ Cubit 异常       │   │  .reportError() │   │  .reportError() │
│ Dio 5xx/网络错  │   │  + LRU dedup    │   │  → Sentry/Console│
└─────────────────┘   └──────────────────┘   └──────────────────┘
       (3 个入口)          (去重中心)              (实现可换)
```

- **AppBlocObserver**（`lib/core/bloc/`）— 拦截 Cubit/Bloc 抛错，调用 `reportError`
- **ErrorInterceptor**（`packages/infrastructure/api/`）— 拦截 Dio 5xx/网络错，通过 `onDioError` 回调桥接
- **业务层直接调用** — 任何自定义错误（不抛异常的场景）也可走 `reportError`

### R3 守门

`packages/infrastructure/api` **不能** import services 包，所以 `ErrorInterceptor` 走 callback 注入模式（`createDio` 的 `onDioError` 参数），由 app shell 在 `lib/core/di/setup.dart` 负责把 callback 桥接到 `AppErrorHandler.instance.reportError`。

## 注册方式

- 无 DI 注册 — 通过静态方法 `AppErrorHandler.setup()` 初始化
- `AppErrorHandler.instance` 单例可全局访问

## 测试覆盖

- `error_handler_test.dart` — `reportError` 转发 / LRU 去重 / 1 秒窗口 / 不同错误即时上报
