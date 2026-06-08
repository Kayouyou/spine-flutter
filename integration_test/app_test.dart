// integration_test/app_test.dart
//
// 冒烟集成测试: 启动完整 App, 验证核心路由可达。
// 运行: flutter test integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spine_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App 冒烟测试', () {
    testWidgets('App 启动并渲染首页', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
