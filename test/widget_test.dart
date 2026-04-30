import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This is a basic smoke test to verify the app can be instantiated.
    // Full integration tests require proper DI setup.
    await tester.pumpWidget(const MyApp());

    // Verify app loads without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}