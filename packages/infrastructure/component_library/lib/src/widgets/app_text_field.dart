import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/radius.dart';

/// 统一输入框组件
///
/// 支持 label、hint、error、密码模式、前缀/后缀图标。
/// 所有颜色走 AppColors ThemeExtension，自动适配暗色主题。
///
/// 使用方式：
/// ```dart
/// AppTextField(
///   label: '用户名',
///   hint: '请输入用户名',
///   onChanged: (v) => _username = v,
/// )
///
/// AppTextField(
///   label: '密码',
///   obscureText: true,
///   onChanged: (v) => _password = v,
/// )
///
/// AppTextField(
///   label: '邮箱',
///   errorText: '邮箱格式不正确',
///   onChanged: (v) {},
/// )
/// ```
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool enabled;
  final FocusNode? focusNode;
  final String? initialValue;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.focusNode,
    this.initialValue,
    this.textInputAction,
    this.contentPadding,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: hasError ? colors.error : colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: colors.textHint),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: colors.textHint)
                : null,
            suffixIcon: _buildSuffix(),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: colors.error, width: 1.5),
            ),
            filled: true,
            fillColor: widget.enabled
                ? colors.cardBackground
                : colors.divider,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(fontSize: 12, color: colors.error),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off : Icons.visibility,
          size: 20,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }
    return widget.suffix;
  }
}
