import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_settings/feature_settings.dart';

void main() {
  testWidgets('SettingsPage 渲染基本内容', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage()),
    );

    expect(find.text('设置'), findsOneWidget);
  });
}
