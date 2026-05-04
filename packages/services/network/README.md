# network 包

网络状态监控服务 — 实时检测网络连接状态。

## 内部结构

```
network/
├── lib/
│   ├── network.dart               # 导出入口
│   └── src/
│       ├── network_cubit.dart     # NetworkCubit（状态管理）
│       └── network_state.dart     # NetworkState（connected/disconnected）
└── pubspec.yaml
```

## 职责

- 监听设备网络连接变化
- 通过 `NetworkCubit` 广播连接状态
- `NetworkBanner` 在 UI 层展示网络断开提示

## 使用

```dart
import 'package:network/network.dart';

// 在主 DI 设置中调用
setupNetwork(sl);

// 监听网络状态
BlocBuilder<NetworkCubit, NetworkState>(
  builder: (context, state) {
    if (state.isDisconnected) {
      return Text('网络已断开');
    }
    return child;
  },
);
```

## 注册方式

- NetworkCubit: **Singleton**（全局唯一，app 生命周期）
