import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_state.dart';
import 'network_quality_monitor.dart';

/// 网络状态管理Cubit
class NetworkCubit extends Cubit<NetworkState> {
  final Connectivity _connectivity;
  final NetworkQualityMonitor _qualityMonitor;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  StreamSubscription<NetworkQuality>? _qualitySubscription;

  NetworkCubit({
    Connectivity? connectivity,
    NetworkQualityMonitor? qualityMonitor,
  })  : _connectivity = connectivity ?? Connectivity(),
        _qualityMonitor = qualityMonitor ?? NetworkQualityMonitor(),
        super(const NetworkState(status: NetworkStatus.disconnected));

  /// 开始监听网络状态变化
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      emit(
        NetworkState(
          status: isConnected
              ? NetworkStatus.connected
              : NetworkStatus.disconnected,
          lastDisconnectedAt: isConnected ? null : DateTime.now(),
          quality: isConnected ? state.quality : NetworkQuality.disconnected,
        ),
      );
    });

    // 监听网络质量变化
    _qualitySubscription = _qualityMonitor.qualityStream.listen((quality) {
      if (state.isConnected) {
        emit(state.copyWith(quality: quality));
      }
    });
  }

  /// 记录请求延迟（供 Dio 拦截器调用）
  void recordLatency(int latencyMs) {
    _qualityMonitor.recordLatency(latencyMs);
  }

  /// 获取当前网络质量
  NetworkQuality get currentQuality => _qualityMonitor.currentQuality;

  /// 设置网络提示的UI样式
  void setUIStyle(NetworkUIStyle style) {
    emit(state.copyWith(uiStyle: style));
  }

  /// 立即检查当前网络状态
  Future<void> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected = !results.contains(ConnectivityResult.none);
      emit(NetworkState(
        status:
            isConnected ? NetworkStatus.connected : NetworkStatus.disconnected,
        quality: isConnected ? _qualityMonitor.currentQuality : NetworkQuality.disconnected,
      ),);
    } catch (e) {
      emit(NetworkState(
        status: NetworkStatus.disconnected,
        lastDisconnectedAt: DateTime.now(),
        quality: NetworkQuality.disconnected,
      ),);
    }
  }

  /// 获取断网持续时间
  Duration? get disconnectedDuration {
    if (state.isConnected || state.lastDisconnectedAt == null) return null;
    return DateTime.now().difference(state.lastDisconnectedAt!);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _qualitySubscription?.cancel();
    _qualityMonitor.dispose();
    return super.close();
  }
}
