import 'package:equatable/equatable.dart';

/// 网络状态
enum NetworkStatus { connected, disconnected }

/// 网络UI提示样式
enum NetworkUIStyle { banner, toast, snackbar, dialog, none }

/// 网络状态数据类
class NetworkState extends Equatable {
  final NetworkStatus status;
  final DateTime? lastDisconnectedAt;
  final NetworkUIStyle uiStyle;

  const NetworkState({
    required this.status,
    this.lastDisconnectedAt,
    this.uiStyle = NetworkUIStyle.banner,
  });

  bool get isConnected => status == NetworkStatus.connected;

  NetworkState copyWith({
    NetworkStatus? status,
    DateTime? lastDisconnectedAt,
    NetworkUIStyle? uiStyle,
  }) {
    return NetworkState(
      status: status ?? this.status,
      lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
      uiStyle: uiStyle ?? this.uiStyle,
    );
  }

  @override
  List<Object?> get props => [status, lastDisconnectedAt, uiStyle];
}