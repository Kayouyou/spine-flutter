import 'package:flutter_easyloading/flutter_easyloading.dart';

/// Toast / Loading 统一封装
///
/// 基于 flutter_easyloading，提供简洁的 API。
/// 需要在 MaterialApp.builder 中配置 `EasyLoading.init()`。
///
/// 使用方式：
/// ```dart
/// AppToast.show('加载中...');
/// AppToast.success('操作成功');
/// AppToast.error('网络错误');
/// AppToast.dismiss();
/// ```
abstract class AppToast {
  AppToast._();

  /// 显示 Loading（带遮罩）
  static void show(String message, {bool dismissOnTap = false}) {
    EasyLoading.show(
      status: message,
      maskType: dismissOnTap
          ? EasyLoadingMaskType.none
          : EasyLoadingMaskType.black,
      dismissOnTap: dismissOnTap,
    );
  }

  /// 显示成功提示（1.5 秒后自动关闭）
  static void success(String message) {
    EasyLoading.showSuccess(message);
  }

  /// 显示错误提示（1.5 秒后自动关闭）
  static void error(String message) {
    EasyLoading.showError(message);
  }

  /// 显示信息提示（1.5 秒后自动关闭）
  static void info(String message) {
    EasyLoading.showInfo(message);
  }

  /// 关闭 Toast/Loading
  static void dismiss() {
    EasyLoading.dismiss();
  }

  /// 当前是否正在显示
  static bool get isShow => EasyLoading.isShow;
}
