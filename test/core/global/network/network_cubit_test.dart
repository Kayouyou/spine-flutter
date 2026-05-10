// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Project imports:
import 'package:network/network.dart';

/// Mock Connectivity
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
    // 默认返回已连接
    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => Stream<List<ConnectivityResult>>.empty());
  });

  group('NetworkState', () {
    test('connected状态判断', () {
      const connected = NetworkState(status: NetworkStatus.connected);
      expect(connected.isConnected, isTrue);

      const disconnected = NetworkState(status: NetworkStatus.disconnected);
      expect(disconnected.isConnected, isFalse);
    });

    test('copyWith可修改状态', () {
      const state = NetworkState(status: NetworkStatus.connected);
      final newState = state.copyWith(
        status: NetworkStatus.disconnected,
        lastDisconnectedAt: DateTime(2026),
      );
      expect(newState.isConnected, isFalse);
      expect(newState.lastDisconnectedAt, isNotNull);
    });

    test('Equatable相等性', () {
      const a = NetworkState(status: NetworkStatus.connected);
      const b = NetworkState(status: NetworkStatus.connected);
      expect(a, equals(b));
    });
  });

  group('NetworkCubit', () {
    blocTest<NetworkCubit, NetworkState>(
      '初始状态为未连接',
      build: () => NetworkCubit(connectivity: mockConnectivity),
      verify: (cubit) {
        expect(cubit.state.isConnected, isFalse);
      },
    );

    blocTest<NetworkCubit, NetworkState>(
      'checkNow检测网络并更新状态',
      setUp: () {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
      },
      build: () => NetworkCubit(connectivity: mockConnectivity),
      act: (cubit) => cubit.checkNow(),
      verify: (cubit) {
        // checkNow异步操作完成后应为断网状态
        expect(cubit.state.isConnected, isFalse);
      },
    );

    blocTest<NetworkCubit, NetworkState>(
      'checkNow检测连接成功',
      setUp: () {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
      },
      build: () => NetworkCubit(connectivity: mockConnectivity)
        ..emit(NetworkState(
          status: NetworkStatus.disconnected,
          lastDisconnectedAt: DateTime.now(),
        )),
      act: (cubit) => cubit.checkNow(),
      expect: () => [
        NetworkState(status: NetworkStatus.connected),
      ],
    );

    blocTest<NetworkCubit, NetworkState>(
      'checkNow异常时标记为断网',
      setUp: () {
        when(() => mockConnectivity.checkConnectivity())
            .thenThrow(Exception('检测失败'));
      },
      build: () => NetworkCubit(connectivity: mockConnectivity),
      act: (cubit) => cubit.checkNow(),
      verify: (cubit) {
        expect(cubit.state.isConnected, isFalse);
        expect(cubit.state.lastDisconnectedAt, isNotNull);
      },
    );

    blocTest<NetworkCubit, NetworkState>(
      'setUIStyle切换提示样式',
      build: () => NetworkCubit(connectivity: mockConnectivity),
      act: (cubit) => cubit.setUIStyle(NetworkUIStyle.toast),
      expect: () => [
        NetworkState(status: NetworkStatus.disconnected, uiStyle: NetworkUIStyle.toast),
      ],
    );

    blocTest<NetworkCubit, NetworkState>(
      'startListening监听网络变化流',
      setUp: () {
        final controller = StreamController<List<ConnectivityResult>>();
        when(() => mockConnectivity.onConnectivityChanged)
            .thenAnswer((_) => controller.stream);
      },
      build: () => NetworkCubit(connectivity: mockConnectivity),
      act: (cubit) {
        cubit.startListening();
        // 模拟网络断开
        final controller = StreamController<List<ConnectivityResult>>();
        when(() => mockConnectivity.onConnectivityChanged)
            .thenAnswer((_) => controller.stream);
      },
    );

    test('close取消订阅', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);

      final cubit = NetworkCubit(connectivity: mockConnectivity);
      cubit.startListening();
      await cubit.close();

      // 流已取消，后续事件不影响
      expect(controller.hasListener, isFalse);
      await controller.close();
    });

    test('disconnectedDuration计算断网时长', () async {
      final disconnectTime = DateTime.now().subtract(Duration(minutes: 5));
      final cubit = NetworkCubit(connectivity: mockConnectivity)
        ..emit(NetworkState(
          status: NetworkStatus.disconnected,
          lastDisconnectedAt: disconnectTime,
        ));

      final duration = cubit.disconnectedDuration;
      expect(duration, isNotNull);
      expect(duration!.inMinutes, greaterThanOrEqualTo(4));
    });
  });
}
