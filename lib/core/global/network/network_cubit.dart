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
        super(NetworkState(status: NetworkStatus.connected));

  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      emit(NetworkState(
        status: isConnected ? NetworkStatus.connected : NetworkStatus.disconnected,
        lastDisconnectedAt: isConnected ? null : DateTime.now(),
      ));
    });
  }

  void setUIStyle(NetworkUIStyle style) {
    emit(state.copyWith(uiStyle: style));
  }

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