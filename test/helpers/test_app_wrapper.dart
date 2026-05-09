import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试应用包装器
///
/// 提供统一的测试环境，包裹 MaterialApp
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final ThemeData? theme;

  const TestAppWrapper({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true, brightness: Brightness.light),
      home: Scaffold(body: child),
    );
  }
}

/// WidgetTester 扩展，提供便捷的 pumpApp 方法
extension WidgetTesterExtension on WidgetTester {
  /// 挂载应用并等待渲染完成
  ///
  /// 使用：
  /// ```dart
  /// await tester.pumpApp(MyWidget());
  /// ```
  Future<void> pumpApp(Widget child, {ThemeData? theme}) async {
    await pumpWidget(TestAppWrapper(child: child, theme: theme));
    await pumpAndSettle();
  }
}