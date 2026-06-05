// Flutter imports:
import 'package:flutter/material.dart';
import 'package:domain/domain.dart';

// Package imports:
import 'package:feature_home/feature_home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// HomeCubit 的 fake 实现，用于 widget 测试
class FakeHomeCubit extends Fake implements HomeCubit {
  static const _state = HomeState.loaded(data: HomeData(title: ''));

  @override
  HomeState get state => _state;

  @override
  Future<void> loadData() async {}

  @override
  Stream<HomeState> get stream => const Stream.empty();

  @override
  Future<void> close() async {}
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

    // 等待异步操作完成
    await tester.pump(const Duration(seconds: 3));

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

    // 等待 UpgradeAlert 的异步初始化
    await tester.pump(const Duration(seconds: 3));

    // 验证页面至少能渲染出来不报错
    expect(find.byType(HomePage), findsOneWidget);
  });
}
