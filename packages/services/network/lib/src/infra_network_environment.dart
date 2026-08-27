import 'dart:async';

// 以 api 前缀引用 infra 的抽象与枚举，避免与 services 的同名 NetworkQuality 冲突
import 'package:api/api.dart' as api;
import 'package:network/network.dart';

/// [api.NetworkEnvironment] 的桥接实现
///
/// 将 services/network 的 [NetworkCubit] 适配为 infra/api 所需的抽象，
/// 从而在不破坏 R3 的前提下，为后续弱网优化拦截器提供网络质量/连通性信号。
///
/// 注意：infra 的 [api.NetworkQuality] 与 services 的 [NetworkQuality]
/// 同名但属于两个不同库，此处做 1:1 映射。
class InfraNetworkEnvironment implements api.NetworkEnvironment {
  final NetworkCubit _cubit;

  InfraNetworkEnvironment(this._cubit);

  @override
  api.NetworkQuality get quality => _map(_cubit.currentQuality);

  @override
  Stream<api.NetworkQuality> get qualityStream => _cubit.qualityStream.map(_map);

  @override
  Future<bool> isConnected() async => _cubit.state.isConnected;

  @override
  Stream<bool> get connectionChanges =>
      _cubit.stream.map((s) => s.isConnected).distinct();

  api.NetworkQuality _map(NetworkQuality q) {
    switch (q) {
      case NetworkQuality.good:
        return api.NetworkQuality.good;
      case NetworkQuality.slow:
        return api.NetworkQuality.slow;
      case NetworkQuality.poor:
        return api.NetworkQuality.poor;
      case NetworkQuality.disconnected:
        return api.NetworkQuality.disconnected;
    }
  }
}
