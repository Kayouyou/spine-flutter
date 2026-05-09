import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name}}.freezed.dart';
part '{{name}}.g.dart';

/// {{name.pascalCase()}} 数据模型
@freezed
class {{name.pascalCase()}} with _${{name.pascalCase()}} {
  const factory {{name.pascalCase()}}({
    required String id,
    required String name,
    @Default('') String description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = __{{name.pascalCase()}};

  factory {{name.pascalCase()}}.fromJson(Map<String, dynamic> json) =>
      _${{name.pascalCase()}}FromJson(json);
}
