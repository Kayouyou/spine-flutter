import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

/// InfraNetworkEnvironment 桥接测试
///
/// 验证 services/network 的 NetworkCubit 正确适配为 infra 的 NetworkEnvironment，
/// 且两个同名 NetworkQuality 枚举的映射为 1:1。
void main() {
  group('InfraNetworkEnvironment', () {
    late NetworkCubit networkCubit;

    setUp(() {
      networkCubit = NetworkCubit();
    });

    tearDown(() async {
      await networkCubit.close();
    });

    test('quality 与 currentQuality 一致', () {
      final env = InfraNetworkEnvironment(networkCubit);
      expect(env.quality.name, equals(networkCubit.currentQuality.name));
    });

    test('isConnected() 与 state.isConnected 一致', () async {
      final env = InfraNetworkEnvironment(networkCubit);
      expect(await env.isConnected(), equals(networkCubit.state.isConnected));
    });

    test('connectionChanges 在 emit 连通性变化后发出正确布尔值', () async {
      final env = InfraNetworkEnvironment(networkCubit);
      // 初始 state 为 disconnected（isConnected == false）
      final received = <bool>[];
      final sub = env.connectionChanges.listen(received.add);

      // 切换到 connected -> true
      networkCubit.emit(const NetworkState(status: NetworkStatus.connected));
      await Future<void>.delayed(Duration.zero);

      // 切回 disconnected -> false
      networkCubit.emit(const NetworkState(status: NetworkStatus.disconnected));
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(received, contains(true));
      expect(received, contains(false));
    });

    test('qualityStream 在 recordLatency 后发出映射后的 infra 枚举值（slow）',
        () async {
      final env = InfraNetworkEnvironment(networkCubit);
      final future = env.qualityStream.first;
      // median 500 -> slow（200 <= median < 1000）
      networkCubit.recordLatency(500);
      final q = await future;
      expect(q.name, equals('slow'));
    });

    test('qualityStream 映射正确性 good/poor', () async {
      final env = InfraNetworkEnvironment(networkCubit);
      final values = <String>[];
      final sub = env.qualityStream.listen((q) => values.add(q.name));

      // median 100 -> good
      networkCubit.recordLatency(100);
      // median 1500 -> poor（>= 1000）
      networkCubit.recordLatency(1500);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(values, contains('good'));
      expect(values, contains('poor'));
    });
  });
}
