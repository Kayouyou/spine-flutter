import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
{{#models}}
import 'package:api/src/models/{{snake}}.dart';
{{/models}}

part '{{domain}}_api.g.dart';

@RestApi(baseUrl: '')
abstract class {{domain.pascalCase}}Api {
  factory {{domain.pascalCase}}Api(Dio dio) = _{{domain.pascalCase}}Api;

{{#endpoints}}
{{#hasBody}}
  @{{method}}('{{{path}}}')
  Future<{{response}}> {{name}}(@Body() {{body}} body{{#params}},{{/params}}{{#params}} @Path('{{name}}') {{type}} {{name}}{{/params}});
{{/hasBody}}
{{^hasBody}}
{{#params}}
  @{{method}}('{{{path}}}')
  Future<{{response}}> {{name}}({{#params}}@Path('{{name}}') {{type}} {{name}}{{/params}});
{{/params}}
{{^params}}
  @{{method}}('{{{path}}}')
  Future<{{response}}> {{name}}();
{{/params}}
{{/hasBody}}
{{/endpoints}}
}
