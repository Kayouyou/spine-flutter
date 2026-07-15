import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/spacing.dart';

/// 通用列表项组件（设置页 / 详情页高频）
///
/// 统一「左图标 + 标题/副标题 + 右侧操作」三段式布局，内部读令牌
/// （[AppColors] / [AppTextStyles] / [Spacing]），调用方只传业务内容、不传样式。
/// 与 [AppCard] / [AppSection] / [EmptyState] / [ErrorCard] 构成完整
/// 「列表 + 状态」组件族；一般放在 [AppCard] 或 [AppSection] 内使用。
///
/// 右侧支持三种互斥形态：
///  - 导航箭头：设 [showArrow]=true（且无自定义 [trailing]、非开关模式）时显示；
///  - 自定义 [trailing]：如交易摘要文本、Tag；
///  - 开关 [trailingSwitch]：配合 [switchValue] / [onSwitchChanged]，此时点击行不触发 [onTap]。
///
/// 使用方式：
/// ```dart
/// // 1) 导航项（箭头 + 点击进入下一级）
/// AppCell(
///   leadingIcon: Icons.person_outline,
///   title: '个人资料',
///   onTap: () => context.push('/profile'),
/// );
///
/// // 2) 副标题 + 开关
/// AppCell(
///   leadingIcon: Icons.notifications_outline,
///   title: '消息通知',
///   subtitle: '接收新消息提醒',
///   trailingSwitch: true,
///   switchValue: settings.notificationsEnabled,
///   onSwitchChanged: settings.setNotificationsEnabled,
/// );
///
/// // 3) 自定义右侧文本
/// AppCell(
///   title: '当前版本',
///   trailing: Text('1.0.0', style: context.textStyles.bodyMedium),
/// );
/// ```
class AppCell extends StatelessWidget {
  final IconData? leadingIcon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;
  final bool trailingSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final EdgeInsetsGeometry? padding;

  const AppCell({
    super.key,
    this.leadingIcon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showArrow = false,
    this.onTap,
    this.trailingSwitch = false,
    this.switchValue = false,
    this.onSwitchChanged,
    this.padding,
  }) : assert(
          leadingIcon == null || leading == null,
          'leadingIcon 与 leading 不能同时设置',
        );

  bool get _hasLeading => leading != null || leadingIcon != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final Widget leadingWidget = leading ??
        (leadingIcon != null
            ? Icon(leadingIcon, size: 22, color: colors.textSecondary)
            : const SizedBox.shrink());

    final bool arrowVisible = showArrow && trailing == null && !trailingSwitch;

    final Widget trailingWidget;
    if (trailingSwitch) {
      trailingWidget = Switch(
        value: switchValue,
        onChanged: onSwitchChanged,
        activeThumbColor: colors.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else if (trailing != null) {
      trailingWidget = trailing!;
    } else if (arrowVisible) {
      trailingWidget = Icon(Icons.chevron_right, size: 20, color: colors.textHint);
    } else {
      trailingWidget = const SizedBox.shrink();
    }

    final row = Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: Spacing.mediumLarge,
            vertical: Spacing.medium,
          ),
      child: Row(
        children: [
          if (_hasLeading) ...[
            leadingWidget,
            const SizedBox(width: Spacing.medium),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: textStyles.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: textStyles.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.small),
          trailingWidget,
        ],
      ),
    );

    // 开关模式下交互由 Switch 独占，点击行不再触发 onTap
    if (trailingSwitch) {
      return Material(color: Colors.transparent, child: row);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }
}
