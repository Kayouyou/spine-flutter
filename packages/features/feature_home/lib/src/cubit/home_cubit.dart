import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'home_state.dart';

/// 首页状态管理Cubit
///
/// 职责：管理首页加载状态和数据
/// 使用：
///   - BlocProvider包装页面
///   - BlocBuilder响应状态更新UI
///   - context.read<HomeCubit>().loadData()触发加载
/// 状态流转：Initial → Loading → Loaded/Error
class HomeCubit extends Cubit<HomeState> {
  /// 数据仓库
  final HomeRepository _repository;

  HomeCubit(this._repository) : super(const HomeState.initial());

  /// 加载首页数据
  ///
  /// 从Repository获取数据，更新状态
  /// 状态流转：Initial/Error → Loading → Loaded/Error
  Future<void> loadData() async {
    // 开始加载
    emit(const HomeState.loading());

    // 获取数据（返回Result类型）
    final result = await _repository.getHomeData();
    // 穷尽匹配处理结果
    result.when(
      success: (data) => emit(HomeState.loaded(data: data)),
      failure: (error) => emit(HomeState.error(errorCode: error.message)),
    );
  }

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据
  Future<void> refreshData() async {
    emit(const HomeState.loading());
    
    // 获取数据（返回Result类型）
    final result = await _repository.refreshHomeData();
    // 穷尽匹配处理结果
    result.when(
      success: (data) => emit(HomeState.loaded(data: data)),
      failure: (error) => emit(HomeState.error(errorCode: error.message)),
    );
  }

  /// 重试加载
  ///
  /// 错误状态下点击重试按钮触发
  Future<void> retry() async {
    await loadData();
  }
}