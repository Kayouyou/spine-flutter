import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'test_mason_state.dart';
import '../repository/test_mason_repository.dart';

/// TestMason 状态管理 Cubit
///
/// 职责：管理 TestMason 加载状态和数据
/// 使用：
///   - BlocProvider 包装页面
///   - BlocBuilder 响应状态更新 UI
///   - context.read<TestMasonCubit>().loadData() 触发加载
/// 状态流转：Initial → Loading → Loaded/Error
class TestMasonCubit extends Cubit<TestMasonState> {
  /// 数据仓库
  final TestMasonRepository _repository;

  TestMasonCubit(this._repository) : super(const TestMasonState.initial());

  /// 加载 TestMason 数据
  ///
  /// 从 Repository 获取数据，更新状态
  /// 状态流转：Initial/Error → Loading → Loaded/Error
  Future<void> loadData() async {
    // 开始加载
    emit(const TestMasonState.loading());

    try {
      // 获取数据
      final data = await _repository.getTestMasonData();
      // 加载成功
      emit(TestMasonState.loaded(data: data));
    } on DomainException catch (e) {
      // 加载失败，传递 ErrorCode 用于国际化
      emit(TestMasonState.error(errorCode: e.message));
    }
  }

  /// 刷新 TestMason 数据
  ///
  /// 强制从服务器获取最新数据
  Future<void> refreshData() async {
    emit(const TestMasonState.loading());
    try {
      final data = await _repository.refreshTestMasonData();
      emit(TestMasonState.loaded(data: data));
    } on DomainException catch (e) {
      emit(TestMasonState.error(errorCode: e.message));
    }
  }

  /// 重试加载
  ///
  /// 错误状态下点击重试按钮触发
  Future<void> retry() async {
    await loadData();
  }
}