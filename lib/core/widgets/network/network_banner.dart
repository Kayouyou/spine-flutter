import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../global/network/network_cubit.dart';
import '../../global/network/network_state.dart';

/// 网络状态Banner
class NetworkBanner extends StatelessWidget {
  final Widget child;

  const NetworkBanner({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (!state.isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildBanner(context),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Material(
      color: Colors.red.shade400,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('网络连接已断开', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}