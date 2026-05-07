import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyState(title: 'No items found'),
        ),
      );

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyState(
            title: 'No items',
            subtitle: 'Add some items to get started',
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('renders action button when onAction and actionLabel set',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmptyState(
            title: 'No items',
            onAction: () {},
            actionLabel: 'Add Item',
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('no button when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyState(title: 'No items'),
        ),
      );

      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
