import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:feature_home/feature_home.dart';

/// HomeCubit 的 fake 实现，用于 widget 测试
class FakeHomeCubit extends Fake implements HomeCubit {
  @override
  HomeState get state => HomeLoaded(<String, dynamic>{});
}

void main() {
  testWidgets('HomePage 渲染 AppBar 和标题', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeCubit>(
          create: (_) => FakeHomeCubit()..loadData(),
          child: const HomePage(),
        ),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('HomePage 在 loaded 状态正常渲染', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeCubit>.value(
          value: FakeHomeCubit()..loadData(),
          child: const HomePage(),
        ),
      ),
    );

    // 验证页面至少能渲染出来不报错
    expect(find.byType(HomePage), findsOneWidget);
  });
}
