import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppScaffold', () {
    testWidgets('renders with title (simple mode)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppScaffold(
            title: '首页',
            body: Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('内容'), findsOneWidget);
      expect(find.byType(CustomAppBar), findsOneWidget);
    });

    testWidgets('renders with custom appBar (advanced mode)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppScaffold(
            appBar: CustomAppBar(title: '自定义标题'),
            body: Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.text('自定义标题'), findsOneWidget);
      expect(find.byType(CustomAppBar), findsOneWidget);
    });

    testWidgets('renders actions correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            title: '首页',
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
            ],
            body: const Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renders floatingActionButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            title: '首页',
            body: const Center(child: Text('内容')),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('asserts title or appBar is provided', (tester) async {
      expect(
        () => AppScaffold(body: const Center(child: Text('内容'))),
        throwsAssertionError,
      );
    });

    testWidgets('hides back button when showBackButton is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppScaffold(
            title: '首页',
            showBackButton: false,
            body: Center(child: Text('内容')),
          ),
        ),
      );

      expect(find.byType(BackButton), findsNothing);
    });
  });
}
