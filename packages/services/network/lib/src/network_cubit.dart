import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_state.dart';

/// 网络状态管理Cubit
class NetworkCubit extends Cubit<NetworkState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const NetworkState(status: NetworkStatus.connected));

  /// 开始监听网络状态变化
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      emit(NetworkState(
        status: isConnected ? NetworkStatus.connected : NetworkStatus.disconnected,
        lastDisconnectedAt: isConnected ? null : DateTime.now(),
      ));
    });
  }

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
        status: isConnected ? NetworkStatus.connected : NetworkStatus.disconnected,
      ));
    } catch (e) {
      emit(NetworkState(
        status: NetworkStatus.disconnected,
        lastDisconnectedAt: DateTime.now(),
      ));
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
    return super.close();
  }
}
