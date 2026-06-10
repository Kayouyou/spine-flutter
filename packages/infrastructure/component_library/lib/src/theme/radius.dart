import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 圆角 Token
///
/// 使用方式：`BorderRadius.circular(AppRadius.card)`
/// 所有值通过 ScreenUtil 自动适配
abstract class AppRadius {
  AppRadius._();

  /// 无圆角
  static double get none => 0.r;

  /// 小圆角（按钮、输入框）
  static double get button => 8.r;

  /// 中圆角（卡片）
  static double get card => 12.r;

  /// 大圆角（对话框、底部弹窗）
  static double get dialog => 16.r;

  /// 超大圆角（芯片、标签）
  static double get chip => 20.r;

  /// 全圆角（圆形头像、FAB）
  static double get circle => 999.r;
}
