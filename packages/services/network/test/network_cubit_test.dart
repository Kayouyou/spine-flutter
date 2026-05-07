import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/network_state.dart';

void main() {
  group('NetworkState', () {
    test('isConnected returns true when connected', () {
      final state = NetworkState(status: NetworkStatus.connected);
      expect(state.isConnected, true);
    });

    test('isConnected returns false when disconnected', () {
      final state = NetworkState(status: NetworkStatus.disconnected);
      expect(state.isConnected, false);
    });

    test('copyWith preserves unchanged fields', () {
      final state = NetworkState(
        status: NetworkStatus.connected,
        lastDisconnectedAt: DateTime(2024, 1, 1),
      );
      final updated = state.copyWith(status: NetworkStatus.disconnected);
      expect(updated.status, NetworkStatus.disconnected);
      expect(updated.lastDisconnectedAt, DateTime(2024, 1, 1));
    });

    test('default uiStyle is banner', () {
      final state = NetworkState(status: NetworkStatus.connected);
      expect(state.uiStyle, NetworkUIStyle.banner);
    });
  });
}
