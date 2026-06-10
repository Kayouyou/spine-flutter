import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/radius.dart';

/// 统一对话框组件
///
/// 提供确认/提示对话框的便捷 API。
/// 颜色走 AppColors ThemeExtension，自动适配暗色主题。
///
/// 使用方式：
/// ```dart
/// AppDialog.confirm(
///   context: context,
///   title: '确认退出',
///   content: '确定要退出登录吗？',
///   onConfirm: () => auth.logout(),
/// )
/// ```
abstract class AppDialog {
  AppDialog._();

  /// 弹出确认对话框
  ///
  /// [onConfirm] 点击确定后调用，调用后自动关闭对话框。
  /// [onCancel] 点击取消后调用（可选），调用后自动关闭对话框。
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = '确定',
    String cancelLabel = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = context.colors;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          backgroundColor: colors.cardBackground,
          title: Text(
            title,
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            content,
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
                onCancel?.call();
              },
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
                onConfirm?.call();
              },
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: isDestructive ? colors.error : colors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// 弹出提示对话框（只有一个确定按钮）
  static Future<void> alert({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = '确定',
    VoidCallback? onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = context.colors;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          backgroundColor: colors.cardBackground,
          title: Text(
            title,
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            content,
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm?.call();
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }
}
