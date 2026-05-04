# data_sync 包

数据同步服务 — 协调全局数据同步流程。

## 内部结构

```
data_sync/
├── lib/
│   ├── data_sync.dart           # 导出入口
│   └── src/
│       ├── manager.dart         # DataSyncManager（同步编排）
│       └── di/
│           └── setup.dart       # DI 注册
└── pubspec.yaml
```

## 职责

- 在 AuthManager.login() 成功后触发数据同步
- 协调多个 Repository 的数据拉取
- 保证同步顺序和错误处理

## 使用

```dart
import 'package:data_sync/data_sync.dart';

// 在主 DI 设置中调用
setupDataSync(sl);

// 触发同步（通常在登录成功后）
await sl<DataSyncManager>().sync();
```

## 注册方式

- DataSyncManager: **Singleton**（全局唯一，app 生命周期）