import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 设置页分组组件
///
/// 提供带标题的分组区域，适用于设置页面。
/// 颜色走 AppColors ThemeExtension，自动适配暗色主题。
///
/// 使用方式：
/// ```dart
/// AppSection(
///   title: '通用设置',
///   children: [
///     ListTile(title: Text('语言')),
///     ListTile(title: Text('通知')),
///   ],
/// )
/// ```
class AppSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
        ...children,
      ],
    );
  }
}
