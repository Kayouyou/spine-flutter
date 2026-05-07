import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('LoadingButton', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: false,
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows spinner when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: true,
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
      );

      expect(find.text('Submit'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('onPressed called when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: false,
            onPressed: () => tapped = true,
            child: const Text('Submit'),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('disabled when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: true,
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
