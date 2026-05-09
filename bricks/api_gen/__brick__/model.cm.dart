import 'package:hive/hive.dart';
import 'package:api/src/models/{{modelName.snakeCase}}.dart';

part '{{modelName.snakeCase}}.cm.g.dart';

@HiveType(typeId: {{hiveTypeId}})
class {{modelName.pascalCase}}CM extends HiveObject {
{{#fields}}
  @HiveField({{index}})
  {{type}} {{name}};
{{/fields}}

  {{modelName.pascalCase}} toDto() => {{modelName.pascalCase}}(
{{#fields}}
        {{name}}: {{name}},
{{/fields}}
      );

  factory {{modelName.pascalCase}}CM.fromDto({{modelName.pascalCase}} dto) =>
      {{modelName.pascalCase}}CM()
{{#fields}}
        ..{{name}} = dto.{{name}}
{{/fields}};
}
