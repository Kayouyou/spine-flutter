import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:feature_settings/feature_settings.dart';

void main() {
  testWidgets('SettingsPage displays architecture info', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );

    // Verify title
    expect(find.text('Settings'), findsOneWidget);

    // Verify architecture info tiles
    expect(find.text('Framework'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Architecture'), findsOneWidget);
    expect(find.text('Clean Architecture + Feature-First'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);
    expect(find.text('flutter_bloc (Cubit)'), findsOneWidget);
  });
}