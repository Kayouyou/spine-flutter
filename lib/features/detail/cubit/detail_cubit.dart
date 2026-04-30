import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain_models/domain_models.dart';
import '../repository/detail_repository.dart';
import 'detail_state.dart';

/// 详情页状态管理Cubit
///
/// 职责：管理详情页加载状态和数据
class DetailCubit extends Cubit<DetailState> {
  final DetailRepository _repository;

  DetailCubit(this._repository) : super(DetailInitial());

  /// 加载详情数据
  ///
  /// 根据ID获取详情内容
  Future<void> loadData(String id) async {
    emit(DetailLoading());
    try {
      final data = await _repository.getDetailData(id);
      emit(DetailLoaded(data));
    } on DomainException catch (e) {
      emit(DetailError(e.errorCode));
    }
  }

  /// 重试加载
  Future<void> retry(String id) async {
    await loadData(id);
  }
}