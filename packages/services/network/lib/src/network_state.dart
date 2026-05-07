import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_state.freezed.dart';

@freezed
class NetworkState with _$NetworkState {
  const factory NetworkState({
    required NetworkStatus status,
    DateTime? lastDisconnectedAt,
    @Default(NetworkUIStyle.banner) NetworkUIStyle uiStyle,
  }) = _NetworkState;

  const NetworkState._();

  bool get isConnected => status == NetworkStatus.connected;
}

enum NetworkStatus { connected, disconnected }
enum NetworkUIStyle { banner, toast, snackbar, dialog, none }