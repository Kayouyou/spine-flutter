# network 包

网络状态监控服务 — 实时检测网络连接状态，并基于请求延迟评估网络质量（NetworkQuality）。

## 内部结构

```
network/
├── lib/
│   ├── network.dart                  # 导出入口
│   └── src/
│       ├── network_cubit.dart             # NetworkCubit（连接状态 + 网络质量）
│       ├── network_state.dart             # NetworkState / NetworkQuality / NetworkStatus
│       ├── network_quality_monitor.dart   # NetworkQualityMonitor（延迟采样 → 质量评估）
│       └── infra_network_environment.dart # InfraNetworkEnvironment（桥接 api.NetworkEnvironment，守 R3）
└── pubspec.yaml
```

## 职责

- 监听设备网络连接变化（connectivity_plus）
- 通过 NetworkCubit 广播连接状态
- 基于真实请求延迟评估网络质量（good / slow / poor），断网时覆盖为 disconnected
- NetworkBanner 在 UI 层展示网络断开提示
- 通过 InfraNetworkEnvironment 把质量 / 连通性信号适配给 infra/api 的弱网优化拦截器

## 网络质量评估（NetworkQuality）

`NetworkQuality` 回答"当前网络到底好不好"，它驱动 infra/api 的重试上限、动态超时、离线入队等弱网优化。

### 判断依据：请求延迟，不是信号格

评估网络好坏的**唯一依据**是 HTTP 请求的**往返耗时（latency）**——从请求发出到收到响应的时间。它不看信号强度、不看网速、不看丢包率，只看"每次请求卡了多久"。

延迟由 Dio 的 `LatencyMonitor` 拦截器在每次请求完成后自动记录（请求发出即开表，响应回来即停表），并通过 `NetworkCubit.recordLatency(int)` 转发给 `NetworkQualityMonitor`。业务侧通常无需手动调用。

### 算法：最近 5 次延迟的中位数

单次延迟容易抖动（某次撞上服务器卡顿会突然飙高），直接用平均值会被带偏。所以 `NetworkQualityMonitor` 的做法是：

1. **滑动窗口**：只保留最近 `windowSize`（默认 5）次请求的延迟，更早的丢弃，始终反映"当下"状态。
2. **取中位数**：把窗口内的延迟从小到大排序，取正中间那个值。中位数比平均值更抗抖动——个别尖峰影响不到它。

### 阈值映射

拿到中位数后，按以下阈值定档（单位：毫秒）：

| 中位数延迟 | 判定 | 含义 |
| --- | --- | --- |
| `< 200ms` | `good` | 流畅 |
| `200ms ~ 1000ms` | `slow` | 偏慢 |
| `≥ 1000ms` | `poor` | 很差 |
| 连不上网 | `disconnected` | 由连通性判断，不走延迟 |

> `disconnected` 不属于延迟评估：当 `connectivity_plus` 检测到设备根本无网时，由 `NetworkCubit` 在状态融合时强制把 `quality` 覆盖为 `disconnected`。延迟评估只产出 `good` / `slow` / `poor` 三档。

### 数据流（谁产生、谁融合、谁消费）

```
Dio LatencyMonitor ──recordLatency(latencyMs)──► NetworkQualityMonitor
                                                    │ 滑动窗口中位数 → good/slow/poor
                                                    │ qualityStream (broadcast)
                                                    ▼
                                              NetworkCubit
                                               ├─ 融合 Connectivity：断网强制 disconnected
                                               ├─ qualityStream（转发 Monitor 流）
                                               └─ connectionChanges（isConnected 变化）
                                                    │
                                                    ▼
                                          InfraNetworkEnvironment
                                           （services.NetworkQuality ↔ api.NetworkQuality 1:1 映射，守 R3）
                                                    │ api.NetworkEnvironment 抽象
                                                    ▼
                                    infra/api 拦截器：RetryInterceptor / 动态超时 / NetworkStatusInterceptor
```

### 读取与订阅

```dart
import 'package:network/network.dart';

// 当前质量（点值）
final NetworkQuality q = networkCubit.currentQuality;

// 订阅质量变化流（broadcast，可多次订阅）
networkCubit.qualityStream.listen((q) {
  // q 为 NetworkQuality.good / .slow / .poor / .disconnected
});
```

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
