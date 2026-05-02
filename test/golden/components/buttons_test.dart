import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('主按钮 golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('主要操作'),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(ElevatedButton),
      matchesGoldenFile('goldens/primary_button.png'),
    );
  });
}
