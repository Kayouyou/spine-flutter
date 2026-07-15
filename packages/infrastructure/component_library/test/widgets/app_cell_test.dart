import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppCell', () {
    Future<void> pumpCell(WidgetTester tester, Widget cell) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(home: Scaffold(body: cell)),
        ),
      );
    }

    testWidgets('renders title', (tester) async {
      await pumpCell(tester, const AppCell(title: '个人资料'));
      expect(find.text('个人资料'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await pumpCell(
        tester,
        const AppCell(title: '通知', subtitle: '接收新消息提醒'),
      );
      expect(find.text('通知'), findsOneWidget);
      expect(find.text('接收新消息提醒'), findsOneWidget);
    });

    testWidgets('renders leading icon', (tester) async {
      await pumpCell(
        tester,
        const AppCell(leadingIcon: Icons.person, title: '账户'),
      );
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows chevron when showArrow + onTap', (tester) async {
      await pumpCell(
        tester,
        AppCell(title: '关于', showArrow: true, onTap: () {}),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders custom trailing text', (tester) async {
      await pumpCell(
        tester,
        const AppCell(title: '版本', trailing: Text('1.0.0')),
      );
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('renders switch when trailingSwitch', (tester) async {
      await pumpCell(
        tester,
        AppCell(
          title: '通知',
          trailingSwitch: true,
          onSwitchChanged: (_) {},
        ),
      );
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await pumpCell(
        tester,
        AppCell(title: '点击进入', onTap: () => tapped = true),
      );
      await tester.tap(find.text('点击进入'));
      expect(tapped, isTrue);
    });

    testWidgets('calls onSwitchChanged when toggled', (tester) async {
      var changed = false;
      await pumpCell(
        tester,
        AppCell(
          title: '开关',
          trailingSwitch: true,
          onSwitchChanged: (v) => changed = v,
        ),
      );
      await tester.tap(find.byType(Switch));
      expect(changed, isTrue);
    });

    testWidgets('does not call onTap in switch mode', (tester) async {
      var tapped = false;
      await pumpCell(
        tester,
        AppCell(
          title: '开关',
          trailingSwitch: true,
          onSwitchChanged: (_) {},
          onTap: () => tapped = true,
        ),
      );
      await tester.tap(find.byType(Switch));
      expect(tapped, isFalse);
    });
  });
}
