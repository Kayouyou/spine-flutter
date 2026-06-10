import 'package:flutter/material.dart';

/// 阴影 Token
///
/// 所有阴影使用黑色半透明，在 light/dark 主题下均可用
abstract class AppShadows {
  AppShadows._();

  /// 无阴影
  static const List<BoxShadow> none = [];

  /// 低阴影（卡片、输入框）
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// 中阴影（悬浮按钮、下拉菜单）
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// 高阴影（对话框、底部弹窗）
  static List<BoxShadow> get dialog => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}
