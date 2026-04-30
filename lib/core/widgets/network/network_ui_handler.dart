import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../global/network/network_cubit.dart';
import '../../global/network/network_state.dart';

/// 网络状态UI处理器
///
/// 根据NetworkCubit配置的uiStyle，在断网时弹出对应提示（snackbar/dialog）
class NetworkUIHandler extends StatelessWidget {
  final Widget? child;

  const NetworkUIHandler({this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.isConnected) return;
        final l10n = AppLocalizations.of(context);
        switch (state.uiStyle) {
          case NetworkUIStyle.snackbar:
            _showSnackbar(context, l10n);
            break;
          case NetworkUIStyle.dialog:
            _showDialog(context, l10n);
            break;
          default:
            break;
        }
      },
      child: child ?? const SizedBox.shrink(),
    );
  }

  void _showSnackbar(BuildContext context, AppLocalizations? l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.networkDisconnected ?? l10n?.networkError ?? '网络连接已断开'),
        action: SnackBarAction(
          label: l10n?.retry ?? '重试',
          onPressed: () => context.read<NetworkCubit>().checkNow(),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, AppLocalizations? l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n?.networkDisconnected ?? l10n?.networkError ?? '网络连接已断开'),
        content: Text(l10n?.checkingNetwork ?? '请检查网络连接后点击重试'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NetworkCubit>().checkNow();
            },
            child: Text(l10n?.retry ?? '重试'),
          ),
        ],
      ),
    );
  }
}
