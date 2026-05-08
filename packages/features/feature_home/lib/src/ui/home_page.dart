import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:component_library/component_library.dart';
import 'package:routing/routing.dart';
import 'package:upgrader/upgrader.dart';
import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// 首页
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        debugLogging: GetIt.instance<IAppConfig>().enableDebugLog,
      ),
      child: AppScaffold(
        title: '首页',
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HomeCubit>().refreshData(),
          ),
        ],
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            // 根据状态渲染不同UI
            return switch (state) {
              HomeInitial() => _buildInitial(context),
              HomeLoading() => _buildLoading(context),
              HomeLoaded(data: final data) => _buildLoaded(context, data),
              HomeError(errorCode: final errorCode) => _buildError(context, errorCode),
            };
          },
        ),
      ),
    );
  }

  /// 初始状态UI
  Widget _buildInitial(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('点击加载首页数据'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<HomeCubit>().loadData(),
            child: const Text('加载'),
          ),
        ],
      ),
    );
  }

  /// 加载中状态UI
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

  /// 加载成功状态UI
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
            '骨架搭建完成',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Bloc状态管理已集成'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.detail),
            icon: const Icon(Icons.open_in_new),
            label: const Text('打开详情页'),
          ),
        ],
      ),
    );
  }

  /// 错误状态UI
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
            '加载失败: ${errorCode.name}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.read<HomeCubit>().retry(),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}