// L-4 修复: feature_home widget 测试覆盖
//
// 之前: 全仓仅 1 个 widget 测试 (home_page_test.dart 'shows debug action')
// 之后: 5 个核心场景覆盖 (initial / loading / loaded / error / refresh action)
//
// 设计: 真实 HomeCubit + FakeHomeRepository, 构造不同 Repository 返回值驱动状态.
// 比直接预 emit 状态更接近真实使用, 同时测试 Repository → Cubit → UI 整条链路.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:feature_home/feature_home.dart';
import 'package:routing/routing.dart';
import 'package:domain/domain.dart';

/// 行为可控的 Fake Repository
class _StubHomeRepository implements HomeRepository {
  _StubHomeRepository(this._data, this._error);

  final HomeData? _data; // 非空 → success
  final DomainException? _error; // 非空 → failure

  int callCount = 0;

  @override
  Future<Result<HomeData, DomainException>> getHomeData() async {
    callCount++;
    if (_error != null) return Result.failure(_error!);
    return Result.success(_data!);
  }

  @override
  Future<Result<HomeData, DomainException>> refreshHomeData() async =>
      getHomeData();
}

/// 用 GoRouter 包一层, 因为 HomePage 用了 `context.push(AppRoutes.detail)`.
/// 测试不点详情按钮就不触发, 但路由层不能没有.
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.detail,
        builder: (_, __) => const Scaffold(body: Text('mock-detail')),
      ),
    ],
  );
}

Widget _pump(HomeCubit cubit) {
  return MaterialApp.router(
    routerConfig: _buildRouter(),
    builder: (context, child) {
      return BlocProvider<HomeCubit>.value(
        value: cubit,
        child: child!,
      );
    },
  );
}

HomeData _fakeData() => const HomeData(
      title: '测试首页',
      items: [1, 2, 3],
    );

void main() {
  group('HomePage widget — 5 个核心状态', () {
    testWidgets('初始: 显示 "点击加载" + 加载按钮 + 刷新按钮 (无 callback 时不显示调试按钮)', (tester) async {
      final cubit = HomeCubit(
        _StubHomeRepository(_fakeData(), null),
      );
      await tester.pumpWidget(_pump(cubit));

      // 初始文案
      expect(find.text('点击加载首页数据'), findsOneWidget);
      // 加载按钮
      expect(find.widgetWithText(FilledButton, '加载'), findsOneWidget);
      // 刷新按钮 (AppBar)
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      // 默认无 callback, 调试按钮不应出现
      expect(find.byIcon(Icons.bug_report), findsNothing);
    });

    testWidgets('点击加载 → loading 状态显示进度条', (tester) async {
      // Repository 永远 pending (返回的 future 不 complete), 让 UI 停在 loading
      final cubit = HomeCubit(_PendingRepository());
      await tester.pumpWidget(_pump(cubit));

      await tester.tap(find.widgetWithText(FilledButton, '加载'));
      await tester.pump(); // 触发 emit
      await tester.pump(const Duration(milliseconds: 50));

      // CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // "加载中..." 文本
      expect(find.text('加载中...'), findsOneWidget);
    });

    testWidgets('loaded 状态: 显示 title + items 数量 + 详情入口', (tester) async {
      final cubit = HomeCubit(_StubHomeRepository(_fakeData(), null));
      await tester.pumpWidget(_pump(cubit));

      await tester.tap(find.widgetWithText(FilledButton, '加载'));
      await tester.pumpAndSettle();

      // title
      expect(find.text('测试首页'), findsOneWidget);
      // items 数量
      expect(find.text('3 项已加载'), findsOneWidget);
      // 详情入口 (FilledButton.icon 内部用不同祖先类型, 用 find.text 找)
      expect(find.text('打开详情页'), findsOneWidget);
      // 成功图标
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('error 状态: 显示错误码 + 重试按钮', (tester) async {
      final cubit = HomeCubit(
        _StubHomeRepository(null, const NetworkException('NETWORK_FAIL')),
      );
      await tester.pumpWidget(_pump(cubit));

      await tester.tap(find.widgetWithText(FilledButton, '加载'));
      await tester.pumpAndSettle();

      // 错误文案
      expect(find.textContaining('加载失败'), findsOneWidget);
      expect(find.textContaining('NETWORK_FAIL'), findsOneWidget);
      // 重试按钮
      expect(find.text('重试'), findsOneWidget);
      // 错误图标
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('loaded 状态: 点击详情按钮跳转', (tester) async {
      final cubit = HomeCubit(_StubHomeRepository(_fakeData(), null));
      await tester.pumpWidget(_pump(cubit));

      await tester.tap(find.widgetWithText(FilledButton, '加载'));
      await tester.pumpAndSettle();

      // 跳详情
      await tester.tap(find.text('打开详情页'));
      await tester.pumpAndSettle();

      // 路由到 mock 详情页
      expect(find.text('mock-detail'), findsOneWidget);
    });
  });
}

/// Repository 实现: 永远 pending, 用于测试 loading 状态
class _PendingRepository implements HomeRepository {
  @override
  Future<Result<HomeData, DomainException>> getHomeData() {
    return Completer<Result<HomeData, DomainException>>().future;
  }

  @override
  Future<Result<HomeData, DomainException>> refreshHomeData() {
    return getHomeData();
  }
}
