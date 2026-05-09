import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'detail_state.dart';

/// 详情页状态管理Cubit
///
/// 职责：管理详情页加载状态和数据
class DetailCubit extends Cubit<DetailState> {
  final DetailRepository _repository;

  DetailCubit(this._repository) : super(const DetailState.initial());

  /// 加载详情数据
  ///
  /// 根据ID获取详情内容
  Future<void> loadData(String id) async {
    emit(const DetailState.loading());
    
    // 获取数据（返回Result类型）
    final result = await _repository.getDetailData(id);
    // 穷尽匹配处理结果
    result.when(
      success: (data) => emit(DetailState.loaded(data: data)),
      failure: (error) => emit(DetailState.error(errorCode: error.message)),
    );
  }

  /// 重试加载
  Future<void> retry(String id) async {
    await loadData(id);
  }
}