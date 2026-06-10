import 'package:flutter/material.dart';
import '../theme/radius.dart';

/// 按钮尺寸
enum AppButtonSize { small, medium, large }

/// 按钮变体
enum AppButtonVariant { primary, secondary, danger, ghost }

/// 统一按钮组件
///
/// 支持 4 种变体 × 3 种尺寸 × loading/disabled 状态。
/// 所有颜色走 Theme，自动适配暗色主题。
///
/// 使用方式：
/// ```dart
/// AppButton.primary(label: '提交', onPressed: _submit)
/// AppButton.secondary(label: '取消', onPressed: _cancel)
/// AppButton.danger(label: '删除', onPressed: _delete)
/// AppButton.ghost(label: '更多', onPressed: _more)
/// AppButton.primary(label: '提交', isLoading: true, onPressed: _submit)
/// AppButton.primary(label: '小号', size: AppButtonSize.small, onPressed: _fn)
/// ```
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  const AppButton._({
    super.key,
    required this.label,
    required this.onPressed,
    required this.variant,
    this.isLoading = false,
    this.size = AppButtonSize.medium,
    this.icon,
    this.expand = true,
  });

  /// 主操作按钮（填充色）
  factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.primary,
        isLoading: isLoading,
        size: size,
        icon: icon,
        expand: expand,
      );

  /// 次要操作按钮（描边）
  factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.secondary,
        isLoading: isLoading,
        size: size,
        icon: icon,
        expand: expand,
      );

  /// 危险操作按钮（红色）
  factory AppButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = true,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.danger,
        isLoading: isLoading,
        size: size,
        icon: icon,
        expand: expand,
      );

  /// 幽灵按钮（纯文字）
  factory AppButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = false,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.ghost,
        isLoading: isLoading,
        size: size,
        icon: icon,
        expand: expand,
      );

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 15;
      case AppButtonSize.large:
        return 17;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingOrDisabled = isLoading || onPressed == null;

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _resolvedForegroundColor(context),
          ),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _fontSize + 2),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: _fontSize)),
        ],
      );
    } else {
      child = Text(label, style: TextStyle(fontSize: _fontSize));
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          height: _height,
          width: expand ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isLoadingOrDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              padding: _padding,
              shape: shape,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.secondary:
        return SizedBox(
          height: _height,
          width: expand ? double.infinity : null,
          child: OutlinedButton(
            onPressed: isLoadingOrDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              padding: _padding,
              shape: shape,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.danger:
        return SizedBox(
          height: _height,
          width: expand ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isLoadingOrDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: _padding,
              shape: shape,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.ghost:
        return SizedBox(
          height: _height,
          width: expand ? double.infinity : null,
          child: TextButton(
            onPressed: isLoadingOrDisabled ? null : onPressed,
            style: TextButton.styleFrom(
              padding: _padding,
              shape: shape,
            ),
            child: child,
          ),
        );
    }
  }

  Color _resolvedForegroundColor(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
