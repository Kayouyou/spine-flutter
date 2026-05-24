import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/{{name}}_repository.dart';
import '{{name}}_state.dart';

/// {{name.pascalCase()}} 状态管理 Cubit
class {{name.pascalCase()}}Cubit extends Cubit<{{name.pascalCase()}}State> {
  final {{name.pascalCase()}}Repository _repository;

  {{name.pascalCase()}}Cubit(this._repository) : super(const {{name.pascalCase()}}State.initial());

  Future<void> loadData() async {
    emit(const {{name.pascalCase()}}State.loading());

    final result = await _repository.get{{name.pascalCase()}}Data();
    result.when(
      success: (data) => emit({{name.pascalCase()}}State.loaded(data: data)),
      failure: (error) => emit({{name.pascalCase()}}State.error(errorCode: error.message)),
    );
  }

  Future<void> refreshData() async {
    emit(const {{name.pascalCase()}}State.loading());

    final result = await _repository.refresh{{name.pascalCase()}}Data();
    result.when(
      success: (data) => emit({{name.pascalCase()}}State.loaded(data: data)),
      failure: (error) => emit({{name.pascalCase()}}State.error(errorCode: error.message)),
    );
  }

  Future<void> retry() async {
    await loadData();
  }
}
