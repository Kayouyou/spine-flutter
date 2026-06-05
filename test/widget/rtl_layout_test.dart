import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('RTL Layout', () {
    Widget wrapRTL(Widget child) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      );
    }

    testWidgets('AppScaffold renders in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        const AppScaffold(title: 'اختبار', body: Center(child: Text('محتوى'))),
      ),);
      expect(find.text('اختبار'), findsOneWidget);
      expect(find.text('محتوى'), findsOneWidget);
    });

    testWidgets('CustomAppBar back button shows in RTL when canPop', (tester) async {
      await tester.pumpWidget(wrapRTL(
        Navigator(
          // ignore: deprecated_member_use
          onPopPage: (route, result) => route.didPop(result),
          pages: const [
            MaterialPage(child: SizedBox()),
            MaterialPage(
              child: Scaffold(
                appBar: CustomAppBar(title: 'عنوان'),
                body: SizedBox(),
              ),
            ),
          ],
        ),
      ),);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('LoadingButton renders in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        LoadingButton(isLoading: false, onPressed: () {}, child: const Text('إرسال')),
      ),);
      expect(find.text('إرسال'), findsOneWidget);
    });

    testWidgets('EmptyState renders in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        const EmptyState(title: 'لا توجد بيانات', subtitle: 'اسحب للتحديث', onAction: _noop, actionLabel: 'تحديث'),
      ),);
      expect(find.text('لا توجد بيانات'), findsOneWidget);
      expect(find.text('اسحب للتحديث'), findsOneWidget);
      expect(find.text('تحديث'), findsOneWidget);
    });

    testWidgets('ErrorCard renders in RTL', (tester) async {
      await tester.pumpWidget(wrapRTL(
        const ErrorCard(message: 'حدث خطأ', onRetry: _noop, retryLabel: 'إعادة المحاولة'),
      ),);
      expect(find.text('حدث خطأ'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });
}

void _noop() {}
