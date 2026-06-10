import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/radius.dart';

/// 按钮尺寸
enum AppButtonSize { compact, medium, large, expanded }

/// 按钮变体
enum AppButtonVariant { filled, outlined, text, icon, fab }

/// 图标位置
enum AppButtonIconPosition { left, right, top, bottom }

/// 按钮宽度模式
enum AppButtonWidth {
  /// 根据内容自适应宽度
  flexible,

  /// 固定宽度（需要配合 width 参数）
  fixed,

  /// 撑满父容器
  expanded,

  /// 根据屏幕宽度自动调整（移动端/平板）
  responsive,
}

/// 统一按钮组件
///
/// 支持 5 种变体 × 4 种尺寸 × 4 种图标位置 × 自定义样式。
/// 所有颜色走 Theme，自动适配暗色主题。
///
/// 使用方式：
/// ```dart
/// // 基础用法
/// AppButton.primary(label: '提交', onPressed: _submit)
/// AppButton.secondary(label: '取消', onPressed: _cancel)
/// AppButton.danger(label: '删除', onPressed: _delete)
/// AppButton.text(label: '了解更多', onPressed: _learnMore)
///
/// // 图标位置
/// AppButton.primary(
///   label: '提交',
///   icon: Icons.check,
///   iconPosition: AppButtonIconPosition.right,
///   onPressed: _submit,
/// )
///
/// // 自定义样式
/// AppButton.custom(
///   label: '自定义',
///   backgroundColor: Colors.purple,
///   borderRadius: 20,
///   fontSize: 18,
///   onPressed: _custom,
/// )
///
/// // 渐变背景
/// AppButton.gradient(
///   label: '立即购买',
///   gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
///   onPressed: _buy,
/// )
///
/// // 响应式宽度
/// AppButton.primary(
///   label: '立即购买',
///   width: AppButtonWidth.responsive,
///   onPressed: _buy,
/// )
/// ```
class AppButton extends StatefulWidget {
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final IconData? icon;
  final AppButtonIconPosition iconPosition;
  final double? iconSize;
  final AppButtonWidth width;
  final double? widthValue;

  // 样式定制
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadow;

  // 交互增强
  final bool enableHapticFeedback;
  final Duration? debounceDuration;
  final VoidCallback? onLongPress;

  const AppButton._({
    super.key,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
    this.iconSize,
    this.width = AppButtonWidth.flexible,
    this.widthValue,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.gradient,
    this.borderColor,
    this.borderWidth,
    this.shadow,
    this.enableHapticFeedback = false,
    this.debounceDuration,
    this.onLongPress,
  });

  /// 主操作按钮（填充色）
  factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.left,
    AppButtonWidth width = AppButtonWidth.flexible,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.filled,
        isLoading: isLoading,
        size: size,
        icon: icon,
        iconPosition: iconPosition,
        width: width,
      );

  /// 次要操作按钮（描边）
  factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.left,
    AppButtonWidth width = AppButtonWidth.flexible,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.outlined,
        isLoading: isLoading,
        size: size,
        icon: icon,
        iconPosition: iconPosition,
        width: width,
      );

  /// 危险操作按钮（红色）
  factory AppButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.left,
    AppButtonWidth width = AppButtonWidth.flexible,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.filled,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        isLoading: isLoading,
        size: size,
        icon: icon,
        iconPosition: iconPosition,
        width: width,
      );

  /// 纯文本按钮
  factory AppButton.text({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.left,
    AppButtonWidth width = AppButtonWidth.flexible,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.text,
        isLoading: isLoading,
        size: size,
        icon: icon,
        iconPosition: iconPosition,
        width: width,
      );

  /// 渐变背景按钮
  factory AppButton.gradient({
    Key? key,
    required String label,
    required Gradient gradient,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.left,
    AppButtonWidth width = AppButtonWidth.flexible,
    Color? foregroundColor,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: AppButtonVariant.filled,
        gradient: gradient,
        foregroundColor: foregroundColor ?? Colors.white,
        isLoading: isLoading,
        size: size,
        icon: icon,
        iconPosition: iconPosition,
        width: width,
      );

  /// 完全自定义按钮
  factory AppButton.custom({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.left,
    AppButtonWidth width = AppButtonWidth.flexible,
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
    double? fontSize,
    FontWeight? fontWeight,
    EdgeInsets? padding,
    Gradient? gradient,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadow,
    bool enableHapticFeedback = false,
    Duration? debounceDuration,
    VoidCallback? onLongPress,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: backgroundColor != null
            ? AppButtonVariant.filled
            : borderColor != null
                ? AppButtonVariant.outlined
                : AppButtonVariant.text,
        isLoading: isLoading,
        size: size,
        icon: icon,
        iconPosition: iconPosition,
        width: width,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        borderRadius: borderRadius,
        fontSize: fontSize,
        fontWeight: fontWeight,
        padding: padding,
        gradient: gradient,
        borderColor: borderColor,
        borderWidth: borderWidth,
        shadow: shadow,
        enableHapticFeedback: enableHapticFeedback,
        debounceDuration: debounceDuration,
        onLongPress: onLongPress,
      );

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isDebouncing = false;

  double get _height {
    switch (widget.size) {
      case AppButtonSize.compact:
        return 32;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
      case AppButtonSize.expanded:
        return 56;
    }
  }

  double get _fontSize {
    if (widget.fontSize != null) return widget.fontSize!;
    switch (widget.size) {
      case AppButtonSize.compact:
        return 13;
      case AppButtonSize.medium:
        return 15;
      case AppButtonSize.large:
        return 17;
      case AppButtonSize.expanded:
        return 18;
    }
  }

  double get _iconSize {
    if (widget.iconSize != null) return widget.iconSize!;
    return _fontSize + 2;
  }

  EdgeInsets get _padding {
    if (widget.padding != null) return widget.padding!;
    switch (widget.size) {
      case AppButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: 12);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28);
      case AppButtonSize.expanded:
        return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  double get _borderRadius {
    if (widget.borderRadius != null) return widget.borderRadius!;
    return AppRadius.button;
  }

  void _handleTap() async {
    if (widget.isLoading || _isDebouncing || widget.onPressed == null) return;

    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    if (widget.debounceDuration != null) {
      setState(() => _isDebouncing = true);
      widget.onPressed!();
      await Future.delayed(widget.debounceDuration!);
      if (mounted) {
        setState(() => _isDebouncing = false);
      }
    } else {
      widget.onPressed!();
    }
  }

  void _handleLongPress() {
    if (widget.isLoading || _isDebouncing || widget.onLongPress == null) return;

    if (widget.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }

    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingOrDisabled =
        widget.isLoading || _isDebouncing || widget.onPressed == null;

    Widget child = _buildChild(isLoadingOrDisabled);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      side: widget.borderColor != null
          ? BorderSide(
              color: widget.borderColor!,
              width: widget.borderWidth ?? 1,
            )
          : BorderSide.none,
    );

    final buttonStyle = _buildButtonStyle(context, shape);

    Widget button;
    switch (widget.variant) {
      case AppButtonVariant.filled:
        if (widget.gradient != null) {
          button = _buildGradientButton(context, buttonStyle, child);
        } else {
          button = ElevatedButton(
            onPressed: isLoadingOrDisabled ? null : _handleTap,
            onLongPress: widget.onLongPress != null ? _handleLongPress : null,
            style: buttonStyle,
            child: child,
          );
        }
        break;
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoadingOrDisabled ? null : _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          style: buttonStyle,
          child: child,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoadingOrDisabled ? null : _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          style: buttonStyle,
          child: child,
        );
        break;
      case AppButtonVariant.icon:
        button = IconButton(
          onPressed: isLoadingOrDisabled ? null : _handleTap,
          icon: widget.icon != null
              ? Icon(widget.icon, size: _iconSize)
              : child,
        );
        break;
      case AppButtonVariant.fab:
        button = FloatingActionButton(
          onPressed: isLoadingOrDisabled ? null : _handleTap,
          child: child,
        );
        break;
    }

    return _applySizing(context, button);
  }

  Widget _buildChild(bool isLoadingOrDisabled) {
    if (widget.isLoading) {
      return SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _resolvedForegroundColor(context),
          ),
        ),
      );
    }

    final hasIcon = widget.icon != null;
    final hasLabel = widget.label != null && widget.label!.isNotEmpty;

    if (!hasIcon && !hasLabel) {
      return const SizedBox.shrink();
    }

    if (hasIcon && hasLabel) {
      final iconWidget = Icon(widget.icon, size: _iconSize);
      final labelWidget = Text(
        widget.label!,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: widget.fontWeight,
        ),
      );

      switch (widget.iconPosition) {
        case AppButtonIconPosition.left:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 8),
              labelWidget,
            ],
          );
        case AppButtonIconPosition.right:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              labelWidget,
              const SizedBox(width: 8),
              iconWidget,
            ],
          );
        case AppButtonIconPosition.top:
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 4),
              labelWidget,
            ],
          );
        case AppButtonIconPosition.bottom:
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              labelWidget,
              const SizedBox(height: 4),
              iconWidget,
            ],
          );
      }
    }

    if (hasIcon) {
      return Icon(widget.icon, size: _iconSize);
    }

    return Text(
      widget.label!,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: widget.fontWeight,
      ),
    );
  }

  ButtonStyle _buildButtonStyle(BuildContext context, RoundedRectangleBorder shape) {
    final bgColor = widget.backgroundColor;
    final fgColor = _resolvedForegroundColor(context);

    if (widget.variant == AppButtonVariant.filled) {
      return ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: _padding,
        shape: shape,
        elevation: widget.shadow != null ? 0 : null,
      );
    } else if (widget.variant == AppButtonVariant.outlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: fgColor,
        padding: _padding,
        shape: shape,
        side: widget.borderColor != null
            ? BorderSide(
                color: widget.borderColor!,
                width: widget.borderWidth ?? 1,
              )
            : null,
      );
    } else {
      return TextButton.styleFrom(
        foregroundColor: fgColor,
        padding: _padding,
        shape: shape,
      );
    }
  }

  Widget _buildGradientButton(
    BuildContext context,
    ButtonStyle buttonStyle,
    Widget child,
  ) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        gradient: widget.gradient,
        boxShadow: widget.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading || _isDebouncing ? null : _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _applySizing(BuildContext context, Widget button) {
    switch (widget.width) {
      case AppButtonWidth.flexible:
        return SizedBox(height: _height, child: button);
      case AppButtonWidth.fixed:
        return SizedBox(
          height: _height,
          width: widget.widthValue ?? 200,
          child: button,
        );
      case AppButtonWidth.expanded:
        return SizedBox(
          height: _height,
          width: double.infinity,
          child: button,
        );
      case AppButtonWidth.responsive:
        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final width = isTablet ? 400.0 : double.infinity;
            return SizedBox(
              height: _height,
              width: width,
              child: button,
            );
          },
        );
    }
  }

  Color _resolvedForegroundColor(BuildContext context) {
    if (widget.foregroundColor != null) return widget.foregroundColor!;

    switch (widget.variant) {
      case AppButtonVariant.filled:
        if (widget.backgroundColor == Colors.red) return Colors.white;
        return Theme.of(context).colorScheme.onPrimary;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return Theme.of(context).colorScheme.primary;
      case AppButtonVariant.icon:
      case AppButtonVariant.fab:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

