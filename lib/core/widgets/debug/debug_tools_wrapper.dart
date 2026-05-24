import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 调试工具包装器
///
/// 仅在 [kDebugMode] 为 true 时显示调试指示器。
/// Alice HTTP Inspector 已通过摇一摇/通知方式激活，本 Widget 提供视觉提示。
class DebugToolsWrapper extends StatelessWidget {
  final Widget child;
  const DebugToolsWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          Positioned(
            right: 0,
            top: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.orange,
                child: const Text(
                  'DEBUG',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
