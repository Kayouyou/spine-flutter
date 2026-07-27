import 'dart:async';

/// 网络环境抽象——打破 infra 对 services/network 的反向依赖（R3 合规）
///
/// 由 services/network 的 [InfraNetworkEnvironment] 实现并工厂注入。
/// infra/api 内部只依赖本抽象，绝不直接 import `package:services/...`
/// 或 `package:network/...`，从而遵守 R3 架构规则。
abstract class NetworkEnvironment {
  /// 当前网络质量（good / slow / poor / disconnected）
  NetworkQuality get quality;

  /// 质量变化流（用于动态超时）
  Stream<NetworkQuality> get qualityStream;

  /// 当前是否已连接
  Future<bool> isConnected();

  /// 连通性变化流（离线入队 / 恢复重发）
  Stream<bool> get connectionChanges;
}

/// 网络质量枚举（与 services/network 的 NetworkQuality 对齐，定义在 infra 内以遵守 R3）
///
/// 注意：这是 infra 自己定义的枚举，与 services/network 中的同名枚举
/// 属于两个不同类型，桥接层负责二者之间的 1:1 映射。
enum NetworkQuality { good, slow, poor, disconnected }
