import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:component_library/component_library.dart';
import '../cubit/test_mason_cubit.dart';
import '../cubit/test_mason_state.dart';

/// TestMason 页面
///
/// 职责：展示 TestMason 内容，响应加载状态
/// 使用：BlocProvider 包装，BlocBuilder 响应状态
class TestMasonPage extends StatelessWidget {
  const TestMasonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'TestMason',
      actions: [
        // 刷新按钮
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<TestMasonCubit>().refreshData(),
        ),
      ],
      body: BlocBuilder<TestMasonCubit, TestMasonState>(
        builder: (context, state) {
          // 根据状态渲染不同 UI
          return switch (state) {
            TestMasonInitial() => _buildInitial(context),
            TestMasonLoading() => _buildLoading(context),
            TestMasonLoaded(data: final data) => _buildLoaded(context, data),
            TestMasonError(errorCode: final errorCode) => _buildError(context, errorCode),
          };
        },
      ),
    );
  }

  /// 初始状态 UI
  Widget _buildInitial(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('点击加载 TestMason 数据'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<TestMasonCubit>().loadData(),
            child: const Text('加载'),
          ),
        ],
      ),
    );
  }

  /// 加载中状态 UI
  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载中...'),
        ],
      ),
    );
  }

  /// 加载成功状态 UI
  Widget _buildLoaded(BuildContext context, Map<String, dynamic> data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'TestMason 数据已加载',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('功能模块已通过 Mason brick 生成'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
            label: const Text('返回首页'),
          ),
        ],
      ),
    );
  }

  /// 错误状态 UI
  Widget _buildError(BuildContext context, errorCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败: $errorCode',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.read<TestMasonCubit>().retry(),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}