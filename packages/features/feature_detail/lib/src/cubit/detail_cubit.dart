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
    try {
      final data = await _repository.getDetailData(id);
      emit(DetailState.loaded(data: data));
    } on DomainException catch (e) {
      emit(DetailState.error(errorCode: e.message));
    }
  }

  /// 重试加载
  Future<void> retry(String id) async {
    await loadData(id);
  }
}