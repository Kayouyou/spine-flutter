import 'package:freezed_annotation/freezed_annotation.dart';

part '{{modelName.snakeCase}}.freezed.dart';
part '{{modelName.snakeCase}}.g.dart';

@freezed
class {{modelName.pascalCase}} with _${{modelName.pascalCase}} {
  const factory {{modelName.pascalCase}}({
{{#fields}}
    {{#required}}required {{/required}}{{type}} {{name}},
{{/fields}}
  }) = _{{modelName.pascalCase}};

  factory {{modelName.pascalCase}}.fromJson(Map<String, dynamic> json) =>
      _${{modelName.pascalCase}}FromJson(json);
}
