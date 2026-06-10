import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/radius.dart';
import '../theme/shadows.dart';

/// 统一卡片容器
///
/// 提供带圆角、阴影、内边距的卡片样式。
/// 颜色走 AppColors ThemeExtension，自动适配暗色主题。
///
/// 使用方式：
/// ```dart
/// AppCard(
///   child: ListTile(title: Text('项目')),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: showShadow ? AppShadows.card : AppShadows.none,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
