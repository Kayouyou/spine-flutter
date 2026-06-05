import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

void main() {
  group('LifecycleMixin', () {
    testWidgets('calls onPageEnter when page is pushed', (tester) async {
      int enterCount = 0;
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => _TestPage(onEnter: () => enterCount++),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(enterCount, equals(1));
    });

    testWidgets('subscribes and unsubscribes RouteObserver correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            observers: [AppRouteObserver.instance],
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const _TestPage(),
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

class _TestPage extends StatefulWidget {
  final VoidCallback? onEnter;
  const _TestPage({this.onEnter});
  @override
  State<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<_TestPage> with LifecycleMixin<_TestPage> {
  @override
  void onPageEnter() {
    widget.onEnter?.call();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Page')),
      body: const Center(child: Text('Test')),
    );
  }
}
