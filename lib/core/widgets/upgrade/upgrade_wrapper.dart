import 'package:flutter/material.dart';

/// 更新提示包装器
///
/// 当前为占位实现。后续可在此集成 [UpgradeAlert] 或自定义更新检查逻辑。
class UpgradeWrapper extends StatelessWidget {
  final Widget child;
  const UpgradeWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) => child;
}
