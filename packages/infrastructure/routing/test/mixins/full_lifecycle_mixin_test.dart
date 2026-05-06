import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

void main() {
  group('FullLifecycleMixin', () {
    testWidgets('calls both onPageEnter and registers WidgetsBindingObserver',
        (tester) async {
      int enterCount = 0;
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    _TestFullLifecyclePage(onEnter: () => enterCount++),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(enterCount, equals(1));
    });

    testWidgets('calls onAppPaused when app lifecycle changes',
        (tester) async {
      int pausedCount = 0;
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestFullLifecyclePage(
                    onAppPaused: () => pausedCount++),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(_TestFullLifecyclePage))
          as _TestFullLifecyclePageState;
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(pausedCount, equals(1));
    });

    testWidgets('removes both observers in dispose', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestFullLifecyclePage(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}

class _TestFullLifecyclePage extends StatefulWidget {
  final VoidCallback? onEnter;
  final VoidCallback? onAppPaused;
  const _TestFullLifecyclePage({this.onEnter, this.onAppPaused});
  @override
  State<_TestFullLifecyclePage> createState() =>
      _TestFullLifecyclePageState();
}

class _TestFullLifecyclePageState extends State<_TestFullLifecyclePage>
    with FullLifecycleMixin<_TestFullLifecyclePage> {
  @override
  void onPageEnter() {
    widget.onEnter?.call();
  }

  @override
  void onAppPaused() {
    widget.onAppPaused?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: const Center(child: Text('Test')),
    );
  }
}
