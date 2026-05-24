import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name}}_state.freezed.dart';

/// {{name.pascalCase()}} 状态
@freezed
sealed class {{name.pascalCase()}}State with _${{name.pascalCase()}}State {
  const factory {{name.pascalCase()}}State.initial() = {{name.pascalCase()}}Initial;
  const factory {{name.pascalCase()}}State.loading() = {{name.pascalCase()}}Loading;
  const factory {{name.pascalCase()}}State.loaded({required Map<String, dynamic> data}) = {{name.pascalCase()}}Loaded;
  const factory {{name.pascalCase()}}State.error({required String errorCode}) = {{name.pascalCase()}}Error;
}
