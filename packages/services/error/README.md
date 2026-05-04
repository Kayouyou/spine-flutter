# error 包

全局错误处理服务 — 统一捕获和展示应用错误。

## 内部结构

```
error/
├── lib/
│   ├── error.dart                  # 导出入口
│   └── src/
│       └── error_handler.dart      # AppErrorHandler（全局错误处理）
└── pubspec.yaml
```

## 职责

- 捕获 Flutter 未处理异常
- 捕获 Dart Zone 异步异常
- 展示用户友好的错误提示
- 记录错误到日志

## 使用

```dart
import 'package:error/error.dart';

// 在应用启动时注册
void main() {
  AppErrorHandler.setup();
  runApp(const MyApp());
}
```

## 注册方式

- 无 DI 注册 — 通过静态方法 `AppErrorHandler.setup()` 初始化
