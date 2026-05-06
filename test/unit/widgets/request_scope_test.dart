// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:api/api.dart';

// Project imports:
import 'package:my_app/core/middleware/request_context.dart';
import 'package:my_app/core/widgets/request_scope.dart';

void main() {
  group('RequestScope', () {
    tearDown(() {
      CancelTokenManager.instance.clearAll();
      RequestContext.clear();
    });

    testWidgets('sets RequestContext.currentTag on initState', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const RequestScope(child: SizedBox())),
      );

      expect(RequestContext.currentTag, isNotNull);
    });

    testWidgets('uses overrideTag when provided', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const RequestScope(overrideTag: 'my_dialog', child: SizedBox()),
        ),
      );

      expect(RequestContext.currentTag, 'my_dialog');
    });

    testWidgets('clears RequestContext and cleans up on dispose',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const RequestScope(child: SizedBox())),
      );

      final tagBefore = RequestContext.currentTag;
      expect(tagBefore, isNotNull);

      // Remove RequestScope from tree → triggers dispose
      await tester.pumpWidget(
        _buildTestApp(const SizedBox()),
      );
      await tester.pumpAndSettle();

      expect(RequestContext.currentTag, isNull);
    });
  });
}

Widget _buildTestApp(Widget child) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, __) => child),
      ],
    ),
  );
}
