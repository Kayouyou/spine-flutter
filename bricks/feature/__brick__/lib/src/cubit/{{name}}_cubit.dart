import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import '{{name}}_state.dart';
import '../repository/{{name}}_repository.dart';

/// {{name.pascalCase()}} 状态管理 Cubit
///
/// 职责：管理 {{name.pascalCase()}} 加载状态和数据
/// 使用：
///   - BlocProvider 包装页面
///   - BlocBuilder 响应状态更新 UI
///   - context.read<{{name.pascalCase()}}Cubit>().loadData() 触发加载
/// 状态流转：Initial → Loading → Loaded/Error
class {{name.pascalCase()}}Cubit extends Cubit<{{name.pascalCase()}}State> {
  /// 数据仓库
  final {{name.pascalCase()}}Repository _repository;

  {{name.pascalCase()}}Cubit(this._repository) : super(const {{name.pascalCase()}}State.initial());

  /// 加载 {{name.pascalCase()}} 数据
  ///
  /// 从 Repository 获取数据，更新状态
  /// 状态流转：Initial/Error → Loading → Loaded/Error
  Future<void> loadData() async {
    // 开始加载
    emit(const {{name.pascalCase()}}State.loading());

    try {
      // 获取数据
      final data = await _repository.get{{name.pascalCase()}}Data();
      // 加载成功
      emit({{name.pascalCase()}}State.loaded(data: data));
    } on DomainException catch (e) {
      // 加载失败，传递 ErrorCode 用于国际化
      emit({{name.pascalCase()}}State.error(errorCode: e.message));
    }
  }

  /// 刷新 {{name.pascalCase()}} 数据
  ///
  /// 强制从服务器获取最新数据
  Future<void> refreshData() async {
    emit(const {{name.pascalCase()}}State.loading());
    try {
      final data = await _repository.refresh{{name.pascalCase()}}Data();
      emit({{name.pascalCase()}}State.loaded(data: data));
    } on DomainException catch (e) {
      emit({{name.pascalCase()}}State.error(errorCode: e.message));
    }
  }

  /// 重试加载
  ///
  /// 错误状态下点击重试按钮触发
  Future<void> retry() async {
    await loadData();
  }
}