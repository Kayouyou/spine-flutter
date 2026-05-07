import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('ErrorCard', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorCard(message: 'Something went wrong'),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorCard(
            message: 'Error',
            onRetry: () {},
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('no retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorCard(message: 'Error'),
        ),
      );

      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('uses custom retry label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorCard(
            message: 'Error',
            onRetry: () {},
            retryLabel: 'Try Again',
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
