import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final specPath = _resolveSpecPath(arguments);
  final spec = jsonDecode(File(specPath).readAsStringSync()) as Map<String, dynamic>;

  final domain = spec['domain'] as String;
  final models = spec['models'] as Map<String, dynamic>;
  final endpoints = (spec['endpoints'] as List).cast<Map<String, dynamic>>();

  final apiDir = _findApiDir();
  final modelsDir = '$apiDir/lib/src/models';
  final apiFileDir = '$apiDir/lib/src/api';
  Directory(modelsDir).createSync(recursive: true);
  Directory(apiFileDir).createSync(recursive: true);

  // Step 1: Generate DTOs
  final modelNames = <String>[];
  for (final entry in models.entries) {
    final name = entry.key;
    final def = entry.value as Map<String, dynamic>;
    modelNames.add(name);
    _writeModel(modelsDir, name, def);
    if (def['hive'] == true) {
      _writeHiveModel(modelsDir, name, def);
    }
  }

  // Step 2: Generate Retrofit API
  _writeApi(apiFileDir, domain, spec, models, endpoints);

  // Step 3: Update barrel
  _updateBarrel(apiDir, modelNames, domain);

  print('✅ Generated ${modelNames.length} DTOs + ${domain}Api for $domain');
}

String _resolveSpecPath(List<String> args) {
  final arg = args.firstWhere(
    (a) => a.startsWith('--spec='),
    orElse: () => throw ArgumentError('Usage: dart run scripts/gen_api.dart --spec=PATH'),
  );
  final specPath = arg.split('=')[1];

  // Support relative path from packages/infrastructure/api/
  String resolvedPath;
  if (!File(specPath).existsSync() && Directory('packages/infrastructure/api').existsSync()) {
    resolvedPath = 'packages/infrastructure/api/$specPath';
  } else {
    resolvedPath = specPath;
  }

  if (!File(resolvedPath).existsSync()) {
    stderr.writeln('ERROR: Spec file not found: $resolvedPath');
    exit(1);
  }
  return resolvedPath;
}

String _findApiDir() {
  final candidates = [
    'packages/infrastructure/api',
    '../packages/infrastructure/api',
    '../../packages/infrastructure/api',
  ];
  for (final d in candidates) {
    if (Directory(d).existsSync()) return d;
  }
  throw Exception('api package not found');
}

void _writeModel(String dir, String name, Map<String, dynamic> def) {
  final snake = _toSnake(name);
  final fieldsMap = def['fields'] as Map<String, dynamic>? ?? {};
  final fields = fieldsMap.entries.map((e) {
    final type = e.value as String;
    final optional = type.endsWith('?');
    return {'name': e.key, 'type': type, 'optional': optional};
  }).toList();

  final buffer = StringBuffer();
  buffer.writeln("import 'package:freezed_annotation/freezed_annotation.dart';");
  buffer.writeln();
  buffer.writeln("part '$snake.freezed.dart';");
  buffer.writeln("part '$snake.g.dart';");
  buffer.writeln();
  buffer.writeln('@freezed');
  buffer.writeln('class $name with _\$$name {');
  buffer.writeln('  const factory $name({');
  for (final f in fields) {
    final req = f['optional'] == true ? '' : 'required ';
    buffer.writeln('    $req${f['type']} ${f['name']},');
  }
  buffer.writeln('  }) = _$name;');
  buffer.writeln();
  buffer.writeln('  factory $name.fromJson(Map<String, dynamic> json) => _\$${name}FromJson(json);');
  buffer.writeln('}');

  File('$dir/$snake.dart').writeAsStringSync(buffer.toString());
  print('  📝 $snake.dart');
}

void _writeHiveModel(String dir, String name, Map<String, dynamic> def) {
  final snake = _toSnake(name);
  final typeId = def['hiveTypeId'] ?? 0;
  final fieldsMap = def['fields'] as Map<String, dynamic>? ?? {};
  final fields = fieldsMap.entries.toList();

  final buffer = StringBuffer();
  buffer.writeln("import 'package:hive/hive.dart';");
  buffer.writeln("import 'package:api/src/models/$snake.dart';");
  buffer.writeln();
  buffer.writeln("part '$snake.cm.g.dart';");
  buffer.writeln();
  buffer.writeln('@HiveType(typeId: $typeId)');
  buffer.writeln('class ${name}CM extends HiveObject {');
  for (var i = 0; i < fields.length; i++) {
    buffer.writeln('  @HiveField($i)');
    buffer.writeln('  ${fields[i].value} ${fields[i].key};');
  }
  buffer.writeln();
  buffer.writeln('  $name toDto() => $name(');
  for (final f in fields) {
    buffer.writeln('    ${f.key}: ${f.key},');
  }
  buffer.writeln('  );');
  buffer.writeln();
  buffer.writeln('  factory ${name}CM.fromDto($name dto) => ${name}CM()');
  for (final f in fields) {
    buffer.writeln('    ..${f.key} = dto.${f.key}');
  }
  buffer.writeln('  ;');
  buffer.writeln('}');

  File('$dir/$snake.cm.dart').writeAsStringSync(buffer.toString());
  print('  📦 $snake.cm.dart');
}

void _writeApi(String dir, String domain, Map<String, dynamic> spec, Map<String, dynamic> models, List<Map<String, dynamic>> endpoints) {
  final buffer = StringBuffer();
  buffer.writeln("import 'package:dio/dio.dart';");
  buffer.writeln("import 'package:retrofit/retrofit.dart';");
  buffer.writeln();

  // Import used models
  final usedModels = <String>{};
  for (final ep in endpoints) {
    if (ep['response'] != null) usedModels.add(ep['response'] as String);
    if (ep['body'] != null) usedModels.add(ep['body'] as String);
  }
  for (final m in usedModels) {
    if (models.containsKey(m)) {
      buffer.writeln("import 'package:api/src/models/${_toSnake(m)}.dart';");
    }
  }
  buffer.writeln();
  buffer.writeln("part '${domain}_api.g.dart';");
  buffer.writeln();
  buffer.writeln("@RestApi(baseUrl: '')");
  buffer.writeln('abstract class ${_capitalize(domain)}Api {');
  buffer.writeln('  factory ${_capitalize(domain)}Api(Dio dio) = _${_capitalize(domain)}Api;');
  buffer.writeln();

  final basePath = spec['basePath'] as String? ?? '';
  for (final ep in endpoints) {
    final name = ep['name'] as String;
    final method = ep['method'] as String;
    final path = '$basePath${ep['path']}';
    final response = ep['response'] as String? ?? 'void';
    final body = ep['body'];
    final params = ep['params'] as Map<String, dynamic>?;

    buffer.writeln('  @$method(\'$path\')');
    if (body != null) {
      final paramParts = <String>['@Body() $body body'];
      if (params != null && params.isNotEmpty) {
        for (final p in params.entries) {
          paramParts.add("@Path('${p.key}') ${p.value} ${p.key}");
        }
      }
      buffer.writeln('  Future<$response> $name(${paramParts.join(', ')});');
    } else if (params != null && params.isNotEmpty) {
      final paramParts = params.entries.map((p) => "@Path('${p.key}') ${p.value} ${p.key}").toList();
      buffer.writeln('  Future<$response> $name(${paramParts.join(', ')});');
    } else {
      buffer.writeln('  Future<$response> $name();');
    }
    buffer.writeln();
  }
  buffer.writeln('}');

  File('$dir/${domain}_api.dart').writeAsStringSync(buffer.toString());
  print('  🔌 ${domain}_api.dart');
}

void _updateBarrel(String apiDir, List<String> modelNames, String domain) {
  final barrelPath = '$apiDir/lib/api.dart';
  final barrel = File(barrelPath).readAsStringSync();
  final newExports = <String>[];
  
  // Add model exports
  for (final name in modelNames) {
    final snake = _toSnake(name);
    final line = "export 'src/models/$snake.dart';";
    if (!barrel.contains(line)) {
      newExports.add(line);
    }
  }
  
  // Add API export
  final apiLine = "export 'src/api/${domain}_api.dart';";
  if (!barrel.contains(apiLine)) {
    newExports.add(apiLine);
  }
  
  if (newExports.isNotEmpty) {
    File(barrelPath).writeAsStringSync('${barrel.trimRight()}\n${newExports.join('\n')}\n');
    print('✅ Barrel: +${newExports.length} exports');
  }
}

String _toSnake(String pascal) {
  return pascal.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '${m.start > 0 ? '_' : ''}${m.group(0)!.toLowerCase()}',
  );
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
