import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../global/network/network_cubit.dart';
import '../../global/network/network_state.dart';

/// 网络状态UI处理器
class NetworkUIHandler extends StatelessWidget {
  final Widget? child;

  const NetworkUIHandler({this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.isConnected) return;
        switch (state.uiStyle) {
          case NetworkUIStyle.snackbar:
            _showSnackbar(context);
            break;
          case NetworkUIStyle.dialog:
            _showDialog(context);
            break;
          default:
            break;
        }
      },
      child: child ?? const SizedBox.shrink(),
    );
  }

  void _showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('网络连接已断开'),
        action: SnackBarAction(
          label: '重试',
          onPressed: () => context.read<NetworkCubit>().checkNow(),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('网络连接已断开'),
        content: const Text('请检查网络连接后点击重试'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NetworkCubit>().checkNow();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}