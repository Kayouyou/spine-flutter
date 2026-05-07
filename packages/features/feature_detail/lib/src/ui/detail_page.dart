import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:component_library/component_library.dart';
import '../cubit/detail_cubit.dart';
import '../cubit/detail_state.dart';

/// 详情页
///
/// 职责：展示详情内容，响应加载状态
class DetailPage extends StatelessWidget {
  final String? id;

  const DetailPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DetailCubit>().loadData(id!);
      });
    }

    return AppScaffold(
      title: '详情页',
      body: BlocBuilder<DetailCubit, DetailState>(
        builder: (context, state) {
          return switch (state) {
            DetailInitial() => _buildInitial(context),
            DetailLoading() => _buildLoading(context),
            DetailLoaded(data: final data) => _buildLoaded(context, data),
            DetailError(errorCode: final errorCode) => _buildError(context, errorCode),
          };
        },
      ),
    );
  }

  Widget _buildInitial(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('详情页初始状态'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<DetailCubit>().loadData('1'),
            child: const Text('加载详情'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildLoaded(BuildContext context, Map<String, dynamic> data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            '详情页内容',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, errorCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: ${errorCode.name}'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.read<DetailCubit>().retry('1'),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}