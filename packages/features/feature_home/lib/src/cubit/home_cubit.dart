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

    try {
      // 获取数据
      final data = await _repository.getHomeData();
      // 加载成功
      emit(HomeState.loaded(data: data));
    } on DomainException catch (e) {
      // 加载失败，传递ErrorCode用于国际化
      emit(HomeState.error(errorCode: e.message));
    }
  }

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据
  Future<void> refreshData() async {
    emit(const HomeState.loading());
    try {
      final data = await _repository.refreshHomeData();
      emit(HomeState.loaded(data: data));
    } on DomainException catch (e) {
      emit(HomeState.error(errorCode: e.message));
    }
  }

  /// 重试加载
  ///
  /// 错误状态下点击重试按钮触发
  Future<void> retry() async {
    await loadData();
  }
}