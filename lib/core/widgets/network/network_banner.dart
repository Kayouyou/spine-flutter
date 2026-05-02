// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network/network.dart';

// Project imports:
import 'package:my_app/core/l10n/generated/app_localizations.dart';

/// 网络状态Banner
///
/// 包裹在应用根Widget外层，断网时自动显示顶部红色提示条
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
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n?.networkDisconnected ?? l10n?.networkError ?? '网络连接已断开',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
