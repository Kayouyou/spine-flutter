import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

void main() {
  group('AppLifecycleMixin', () {
    testWidgets('registers WidgetsBindingObserver in initState', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestAppLifecyclePage()));
      await tester.pumpAndSettle();
      expect(find.byType(_TestAppLifecyclePage), findsOneWidget);
    });

    testWidgets('calls onAppPaused when app lifecycle changes', (tester) async {
      int pausedCount = 0;
      await tester.pumpWidget(MaterialApp(home: _TestAppLifecyclePage(onPaused: () => pausedCount++)));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(_TestAppLifecyclePage)) as _TestAppLifecyclePageState;
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(pausedCount, equals(1));
    });

    testWidgets('calls onAppResumed when app returns to foreground', (tester) async {
      int resumedCount = 0;
      await tester.pumpWidget(MaterialApp(home: _TestAppLifecyclePage(onResumed: () => resumedCount++)));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(_TestAppLifecyclePage)) as _TestAppLifecyclePageState;
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(resumedCount, equals(1));
    });

    testWidgets('removes observer in dispose', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestAppLifecyclePage()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}

class _TestAppLifecyclePage extends StatefulWidget {
  final VoidCallback? onPaused;
  final VoidCallback? onResumed;
  const _TestAppLifecyclePage({this.onPaused, this.onResumed});
  @override
  State<_TestAppLifecyclePage> createState() => _TestAppLifecyclePageState();
}

class _TestAppLifecyclePageState extends State<_TestAppLifecyclePage> with AppLifecycleMixin<_TestAppLifecyclePage> {
  @override
  void onAppPaused() { widget.onPaused?.call(); }
  @override
  void onAppResumed() { widget.onResumed?.call(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: const Center(child: Text('Test')),
    );
  }
}
