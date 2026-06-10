# Component Library 升级实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 component_library 从 5 个基础组件升级为完整的 Design System，支持暗色主题、ScreenUtil 动态适配、EasyLoading 封装，并补充高频业务组件。

**Architecture:** 三层架构：Design Token（颜色/间距/圆角/阴影）→ 原子组件（TextField/Button/Dialog/Toast/Card）→ 业务模板（未来扩展）。所有颜色通过 `AppColors` ThemeExtension 实现 light/dark 自动切换，所有尺寸通过 ScreenUtil 扩展自动适配。

**Tech Stack:** Flutter 3.38.10, flutter_screenutil 5.9.0, flutter_easyloading 3.0.5, Material 3

---

## File Structure

```
packages/infrastructure/component_library/
├── pubspec.yaml                                    ← 修改：添加 flutter_easyloading 依赖
├── lib/
│   ├── component_library.dart                      ← 修改：更新 barrel 导出
│   └── src/
│       ├── theme/
│       │   ├── app_colors.dart                     ← 新建：从 lib/src/theme/ 迁移
│       │   ├── spacing.dart                        ← 修改：添加 .w/.h 说明
│       │   ├── font_size.dart                      ← 保留：已有 .sp
│       │   ├── screen_util_ext.dart                ← 新建：num 扩展 .sp/.w/.h/.r
│       │   ├── radius.dart                         ← 新建：圆角 Token
│       │   └── shadows.dart                        ← 新建：阴影 Token
│       └── widgets/
│           ├── app_scaffold.dart                   ← 保留：不变
│           ├── custom_app_bar.dart                 ← 保留：不变
│           ├── empty_state.dart                    ← 修改：暗色主题适配
│           ├── error_card.dart                     ← 修改：暗色主题适配
│           ├── loading_button.dart                 ← 修改：增加样式变体
│           ├── app_text_field.dart                 ← 新建：统一输入框
│           ├── app_button.dart                     ← 新建：按钮系统
│           ├── app_dialog.dart                     ← 新建：确认对话框
│           ├── app_card.dart                       ← 新建：卡片容器
│           ├── app_section.dart                    ← 新建：设置页分组
│           └── app_toast.dart                      ← 新建：EasyLoading 封装
└── test/
    ├── component_library_test.dart                 ← 修改：替换为实际测试
    └── widgets/
        ├── app_button_test.dart                    ← 新建
        ├── app_text_field_test.dart                ← 新建
        ├── app_toast_test.dart                     ← 新建
        └── app_dialog_test.dart                    ← 新建

lib/src/theme/
├── app_colors.dart                                 ← 修改：改为 re-export
├── app_theme.dart                                  ← 修改：import 路径更新
```

---

## Task 1: 添加 EasyLoading 依赖 + 迁移 AppColors

**Files:**
- Modify: `packages/infrastructure/component_library/pubspec.yaml`
- Create: `packages/infrastructure/component_library/lib/src/theme/app_colors.dart`
- Modify: `lib/src/theme/app_colors.dart` (改为 re-export)
- Modify: `lib/src/theme/app_theme.dart`

- [ ] **Step 1: 更新 component_library pubspec.yaml 添加 flutter_easyloading**

```yaml
name: component_library
description: Shared widgets, theme, and utilities
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.0
  flutter_screenutil: ^5.9.0
  flutter_easyloading: ^3.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

- [ ] **Step 2: 创建 component_library 中的 app_colors.dart**

将 `lib/src/theme/app_colors.dart` 的完整内容复制到 `packages/infrastructure/component_library/lib/src/theme/app_colors.dart`，内容完全不变（123 行，包含 AppColors ThemeExtension + BuildContext 扩展）。

```dart
import 'package:flutter/material.dart';

/// 应用颜色主题扩展
///
/// 使用：context.colors.primary
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color cardBackground;
  final Color scaffoldBackground;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.cardBackground,
    required this.scaffoldBackground,
  });

  /// 亮色主题颜色
  static const AppColors light = AppColors(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF26A69A),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF9800),
    error: Color(0xFFF44336),
    info: Color(0xFF2196F3),
    backgroundLight: Color(0xFFF5F5F5),
    backgroundDark: Color(0xFF121212),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    textHint: Color(0xFF9E9E9E),
    border: Color(0xFFE0E0E0),
    divider: Color(0xFFEEEEEE),
    cardBackground: Color(0xFFFFFFFF),
    scaffoldBackground: Color(0xFFF5F5F5),
  );

  /// 深色主题颜色
  static const AppColors dark = AppColors(
    primary: Color(0xFF42A5F5),
    secondary: Color(0xFF4DB6AC),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFE57373),
    info: Color(0xFF64B5F6),
    backgroundLight: Color(0xFF1E1E1E),
    backgroundDark: Color(0xFF000000),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF9E9E9E),
    textHint: Color(0xFF616161),
    border: Color(0xFF424242),
    divider: Color(0xFF303030),
    cardBackground: Color(0xFF2C2C2C),
    scaffoldBackground: Color(0xFF121212),
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? cardBackground,
    Color? scaffoldBackground,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      cardBackground: cardBackground ?? this.cardBackground,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
    );
  }
}

/// BuildContext 扩展，便捷访问颜色主题
extension AppColorsExtension on BuildContext {
  /// 获取当前主题颜色
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
```

- [ ] **Step 3: 将原 lib/src/theme/app_colors.dart 改为 re-export**

替换 `lib/src/theme/app_colors.dart` 全部内容为：

```dart
// Re-export from component_library to avoid duplication.
// All code should import from component_library directly.
export 'package:component_library/src/theme/app_colors.dart';
```

- [ ] **Step 4: 运行 melos bs 验证依赖**

Run: `melos bs`
Expected: SUCCESS, 16 packages bootstrapped

- [ ] **Step 5: 运行 flutter analyze 验证迁移无错**

Run: `fvm flutter analyze lib/ --no-fatal-infos --no-fatal-warnings`
Expected: 0 errors

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(component-library): migrate AppColors to component_library + add dark theme fields"
```

---

## Task 2: ScreenUtil 扩展 + Radius/Shadows Token

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/theme/screen_util_ext.dart`
- Create: `packages/infrastructure/component_library/lib/src/theme/radius.dart`
- Create: `packages/infrastructure/component_library/lib/src/theme/shadows.dart`

- [ ] **Step 1: 创建 screen_util_ext.dart**

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ScreenUtil 便捷扩展
///
/// 使用方式：
/// ```dart
/// 14.sp    // 字号适配
/// 16.w     // 宽度适配
/// 16.h     // 高度适配
/// 8.r      // 半径适配
/// ```
extension NumScreenUtil on num {
  /// 字号适配（跟随系统字体大小设置）
  double get sp => this.sp;

  /// 宽度适配（跟随屏幕宽度缩放）
  double get w => this.w;

  /// 高度适配（跟随屏幕高度缩放）
  double get h => this.h;

  /// 半径适配（宽高平均值缩放）
  double get r => this.r;
}
```

- [ ] **Step 2: 创建 radius.dart**

```dart
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
```

- [ ] **Step 3: 创建 shadows.dart**

```dart
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
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(component-library): add ScreenUtil extension, Radius/Shadows tokens"
```

---

## Task 3: AppToast (EasyLoading 封装)

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/widgets/app_toast.dart`
- Create: `packages/infrastructure/component_library/test/widgets/app_toast_test.dart`

- [ ] **Step 1: 创建 app_toast_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppToast', () {
    testWidgets('show 调用 EasyLoading.show', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppToast.show('加载中...'),
                child: const Text('Show'),
              ),
            ),
          ),
          builder: EasyLoading.init(),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(EasyLoading.isShow, isTrue);

      AppToast.dismiss();
      await tester.pump();
    });

    testWidgets('dismiss 关闭 loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Container()),
          builder: EasyLoading.init(),
        ),
      );

      AppToast.show('test');
      await tester.pump();
      expect(EasyLoading.isShow, isTrue);

      AppToast.dismiss();
      await tester.pumpAndSettle();
      expect(EasyLoading.isShow, isFalse);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_toast_test.dart`
Expected: FAIL (AppToast 未定义)

- [ ] **Step 3: 创建 app_toast.dart**

```dart
import 'package:flutter/material.dart';
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
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_toast_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(component-library): add AppToast (EasyLoading wrapper)"
```

---

## Task 4: AppButton (多変体按钮系统)

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/widgets/app_button.dart`
- Create: `packages/infrastructure/component_library/test/widgets/app_button_test.dart`

- [ ] **Step 1: 创建 app_button_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppButton', () {
    testWidgets('primary 按钮渲染正确', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: AppButton.primary(
              label: '提交',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('提交'), findsOneWidget);
      await tester.tap(find.text('提交'));
      expect(tapped, isTrue);
    });

    testWidgets('loading 状态禁用点击', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: AppButton.primary(
              label: '提交',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(tapped, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled 状态禁用点击', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: AppButton.primary(
              label: '提交',
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_button_test.dart`
Expected: FAIL (AppButton 未定义)

- [ ] **Step 3: 创建 app_button.dart**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/radius.dart';

/// 按钮尺寸
enum AppButtonSize { small, medium, large }

/// 统一按钮组件
///
/// 支持 4 种变体 × 3 种尺寸 × loading/disabled 状态。
/// 所有颜色走 AppColors ThemeExtension，自动适配暗色主题。
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
  final IconData? icon;
  final bool expand;

  /// 内部样式参数
  final ButtonStyle _style;

  const AppButton._({
    super.key,
    required this.label,
    required this.onPressed,
    required ButtonStyle style,
    this.isLoading = false,
    this.size = AppButtonSize.medium,
    this.icon,
    this.expand = true,
  }) : _style = style;

  /// 主操作按钮（填充色）
  factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = true,
  }) {
    return AppButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      expand: expand,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.grey.shade300;
          return null; // 使用 colorScheme.primary
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.grey.shade500;
          return Colors.white;
        }),
      ),
    );
  }

  /// 次要操作按钮（描边）
  factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = true,
  }) {
    return AppButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      expand: expand,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(width: 1),
      ),
    );
  }

  /// 危险操作按钮（红色）
  factory AppButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = true,
  }) {
    return AppButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      expand: expand,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.grey.shade300;
          return Colors.red;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.grey.shade500;
          return Colors.white;
        }),
      ),
    );
  }

  /// 幽灵按钮（纯文字）
  factory AppButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool expand = false,
  }) {
    return AppButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      icon: icon,
      expand: expand,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

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
            _style.foregroundColor?.resolve({}) ?? Colors.white,
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

    // 根据样式类型选择不同的底层按钮
    if (_style is OutlinedButtonStyle) {
      return SizedBox(
        height: _height,
        width: expand ? double.infinity : null,
        child: OutlinedButton(
          onPressed: isLoadingOrDisabled ? null : onPressed,
          style: _style.copyWith(
            minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : 0, _height)),
            padding: WidgetStatePropertyAll(_padding),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
          ),
          child: child,
        ),
      );
    }

    // ElevatedButton (primary / danger)
    return SizedBox(
      height: _height,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoadingOrDisabled ? null : onPressed,
        style: _style.copyWith(
          minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : 0, _height)),
          padding: WidgetStatePropertyAll(_padding),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 内部标记类，用于区分 OutlinedButton 样式
class OutlinedButtonStyle extends ButtonStyle {
  const OutlinedButtonStyle({super.side});
}
```

Wait — the `ButtonStyle` subclass approach is fragile. Let me use a cleaner enum-based approach instead.

- [ ] **Step 3 (revised): 创建 app_button.dart（clean version）**

```dart
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
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_button_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(component-library): add AppButton with 4 variants and 3 sizes"
```

---

## Task 5: AppTextField (统一输入框)

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/widgets/app_text_field.dart`
- Create: `packages/infrastructure/component_library/test/widgets/app_text_field_test.dart`

- [ ] **Step 1: 创建 app_text_field_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppTextField', () {
    testWidgets('渲染 label 和 hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: AppTextField(
              label: '用户名',
              hint: '请输入用户名',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('用户名'), findsOneWidget);
    });

    testWidgets('密码模式隐藏文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: AppTextField(
              label: '密码',
              obscureText: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pump();

      // obscureText 模式下有 toggle 图标
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('error 状态显示错误文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: AppTextField(
              label: '邮箱',
              errorText: '邮箱格式不正确',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('邮箱格式不正确'), findsOneWidget);
    });

    testWidgets('onChanged 回调触发', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: AppTextField(
              label: '输入',
              onChanged: (v) => changedValue = v,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      expect(changedValue, 'hello');
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_text_field_test.dart`
Expected: FAIL (AppTextField 未定义)

- [ ] **Step 3: 创建 app_text_field.dart**

```dart
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
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_text_field_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(component-library): add AppTextField with dark theme support"
```

---

## Task 6: AppDialog + AppCard + AppSection

**Files:**
- Create: `packages/infrastructure/component_library/lib/src/widgets/app_dialog.dart`
- Create: `packages/infrastructure/component_library/lib/src/widgets/app_card.dart`
- Create: `packages/infrastructure/component_library/lib/src/widgets/app_section.dart`
- Create: `packages/infrastructure/component_library/test/widgets/app_dialog_test.dart`

- [ ] **Step 1: 创建 app_dialog_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppDialog', () {
    testWidgets('confirm 弹出确认对话框', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialog.confirm(
                  context: context,
                  title: '确认退出',
                  content: '确定要退出登录吗？',
                  confirmLabel: '确定',
                  cancelLabel: '取消',
                  onConfirm: () => confirmed = true,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('确认退出'), findsOneWidget);
      expect(find.text('确定要退出登录吗？'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('cancel 关闭对话框不调用 onConfirm', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppDialog.confirm(
                  context: context,
                  title: '确认',
                  content: '测试',
                  onConfirm: () => confirmed = true,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_dialog_test.dart`
Expected: FAIL

- [ ] **Step 3: 创建 app_dialog.dart**

```dart
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
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd packages/infrastructure/component_library && fvm flutter test test/widgets/app_dialog_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: 创建 app_card.dart**

```dart
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
```

- [ ] **Step 6: 创建 app_section.dart**

```dart
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
```

- [ ] **Step 7: 运行全量测试**

Run: `cd packages/infrastructure/component_library && fvm flutter test`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat(component-library): add AppDialog, AppCard, AppSection"
```

---

## Task 7: 修复现有组件暗色主题 + 更新 barrel 导出

**Files:**
- Modify: `packages/infrastructure/component_library/lib/src/widgets/empty_state.dart`
- Modify: `packages/infrastructure/component_library/lib/src/widgets/error_card.dart`
- Modify: `packages/infrastructure/component_library/lib/src/widgets/loading_button.dart`
- Modify: `packages/infrastructure/component_library/lib/component_library.dart`

- [ ] **Step 1: 更新 empty_state.dart 使用 Theme 颜色**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textHint),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 更新 error_card.dart 使用 Theme 颜色**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 8),
                    Text(retryLabel ?? '重试'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 更新 loading_button.dart 使用 Theme 颜色**

```dart
import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}
```

- [ ] **Step 4: 更新 component_library.dart barrel 导出**

```dart
// Component Library - Design System
//
// Token
export 'src/theme/app_colors.dart';
export 'src/theme/font_size.dart';
export 'src/theme/spacing.dart';
export 'src/theme/screen_util_ext.dart';
export 'src/theme/radius.dart';
export 'src/theme/shadows.dart';

// Constants
export 'src/constants/app_constants.dart';
export 'src/constants/cache_constants.dart';

// Widgets
export 'src/widgets/app_scaffold.dart';
export 'src/widgets/custom_app_bar.dart';
export 'src/widgets/loading_button.dart';
export 'src/widgets/empty_state.dart';
export 'src/widgets/error_card.dart';
export 'src/widgets/app_text_field.dart';
export 'src/widgets/app_button.dart';
export 'src/widgets/app_dialog.dart';
export 'src/widgets/app_card.dart';
export 'src/widgets/app_section.dart';
export 'src/widgets/app_toast.dart';
```

- [ ] **Step 5: 运行 melos bs + analyze**

Run: `melos bs && fvm flutter analyze packages/infrastructure/component_library/ --no-fatal-infos --no-fatal-warnings`
Expected: 0 errors

- [ ] **Step 6: 运行全量测试**

Run: `cd packages/infrastructure/component_library && fvm flutter test`
Expected: PASS (all tests)

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(component-library): fix dark theme for existing widgets + update barrel exports"
```

---

## Task 8: 集成验证 + 最终清理

**Files:**
- Modify: `lib/core/di/setup.dart` (EasyLoading 配置增加更多样式)

- [ ] **Step 1: 运行全项目守门检查**

```bash
./scripts/check_deps.sh
dart run scripts/check_workspace_versions.dart
./scripts/check_l10n.sh
melos bs
fvm flutter analyze lib/ packages/ --no-fatal-infos --no-fatal-warnings
melos test:affected
```

Expected: 全部通过

- [ ] **Step 2: 最终 Commit**

```bash
git add -A && git commit -m "feat(component-library): complete design system with dark theme + ScreenUtil + EasyLoading"
```
