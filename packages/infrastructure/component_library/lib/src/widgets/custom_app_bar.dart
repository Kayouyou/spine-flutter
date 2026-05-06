import 'package:flutter/material.dart';

/// 统一导航栏 widget
///
/// 职责：提供统一的 AppBar 样式，所有页面复用
/// 实现 PreferredSizeWidget（AppBar 必需接口）
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;

  const CustomAppBar({
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.leading,
    this.elevation = 0,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      leading: leading ?? (showBackButton ? const BackButton() : null),
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
