import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:component_library/component_library.dart';
import '../cubit/{{name}}_cubit.dart';
import '../cubit/{{name}}_state.dart';

/// {{name.pascalCase()}} 页面
///
/// 职责：展示 {{name.pascalCase()}} 内容，响应加载状态
/// 使用：BlocProvider 包装，BlocBuilder 响应状态
class {{name.pascalCase()}}Page extends StatelessWidget {
  const {{name.pascalCase()}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '{{name.pascalCase()}}',
      actions: [
        // 刷新按钮
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<{{name.pascalCase()}}Cubit>().refreshData(),
        ),
      ],
      body: BlocBuilder<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
        builder: (context, state) {
          // 根据状态渲染不同 UI
          return switch (state) {
            {{name.pascalCase()}}Initial() => _buildInitial(context),
            {{name.pascalCase()}}Loading() => _buildLoading(context),
            {{name.pascalCase()}}Loaded(data: final data) => _buildLoaded(context, data),
            {{name.pascalCase()}}Error(errorCode: final errorCode) => _buildError(context, errorCode),
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
          const Text('点击加载 {{name.pascalCase()}} 数据'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<{{name.pascalCase()}}Cubit>().loadData(),
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
            '{{name.pascalCase()}} 数据已加载',
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
            onPressed: () => context.read<{{name.pascalCase()}}Cubit>().retry(),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}