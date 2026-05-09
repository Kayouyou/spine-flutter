import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final specArg = arguments.firstWhere(
    (a) => a.startsWith('--spec='),
    orElse: () => throw ArgumentError('Usage: dart run scripts/gen_api.dart --spec=spec/auth.json'),
  );
  final specPath = specArg.split('=')[1];

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

  final spec = jsonDecode(File(resolvedPath).readAsStringSync()) as Map<String, dynamic>;
  final domain = spec['domain'] as String;
  final models = spec['models'] as Map<String, dynamic>;
  final endpoints = (spec['endpoints'] as List<dynamic>).cast<Map<String, dynamic>>();

  // Ensure output directories exist
  final apiPackageDir = _findApiPackageDir();
  Directory('$apiPackageDir/lib/src/models').createSync(recursive: true);
  Directory('$apiPackageDir/lib/src/api').createSync(recursive: true);

  // Process each model
  final modelNames = <String>[];
  var fieldIndex = 0;
  for (final entry in models.entries) {
    final modelName = entry.key;
    final modelDef = entry.value as Map<String, dynamic>;
    modelNames.add(modelName);

    final fields = <Map<String, dynamic>>[];
    final fieldMap = modelDef['fields'] as Map<String, dynamic>? ?? {};
    for (final fieldEntry in fieldMap.entries) {
      final type = fieldEntry.value as String;
      final isOptional = type.endsWith('?');
      final baseType = isOptional ? type.substring(0, type.length - 1) : type;
      fields.add({
        'name': fieldEntry.key,
        'type': type,
        'baseType': baseType,
        'required': !isOptional,
        'index': fieldIndex++,
      });
    }

    final fieldsJson = jsonEncode(fields);

    // Generate DTO
    _runMason(
      'model.dart',
      modelName,
      domain,
      fieldsJson: fieldsJson,
      hive: false,
      hiveTypeId: 0,
      endpoints: [],
      outputDir: '$apiPackageDir/lib/src/models',
      onConflict: 'overwrite',
    );

    // Generate CM if needed
    if (modelDef['hive'] == true) {
      _runMason(
        'model.cm.dart',
        modelName,
        domain,
        fieldsJson: fieldsJson,
        hive: true,
        hiveTypeId: modelDef['hiveTypeId'] ?? 0,
        endpoints: [],
        outputDir: '$apiPackageDir/lib/src/models',
        onConflict: 'skip',
      );
    }
  }

  // Generate Retrofit interface
  final apiEndpoints = <Map<String, dynamic>>[];
  for (final ep in endpoints) {
    final params = <Map<String, String>>[];
    final paramsMap = ep['params'] as Map<String, dynamic>?;
    if (paramsMap != null) {
      for (final pe in paramsMap.entries) {
        params.add({'name': pe.key, 'type': pe.value as String});
      }
    }

    apiEndpoints.add({
      'name': ep['name'],
      'method': ep['method'],
      'path': '${spec['basePath']}${ep['path']}',
      'response': ep['response'],
      'body': ep['body'],
      'hasBody': ep.containsKey('body'),
      'params': params,
    });
  }

  final modelsRefs = modelNames.map((n) => {'name': n}).toList();

  _runMason(
    'api.dart',
    domain, // reuse modelName slot for domain in api template
    domain,
    fieldsJson: '[]',
    hive: false,
    hiveTypeId: 0,
    endpoints: apiEndpoints,
    models: modelsRefs,
    outputDir: '$apiPackageDir/lib/src/api',
    onConflict: 'overwrite',
  );

  // Update barrel file
  final barrelPath = '$apiPackageDir/lib/api.dart';
  final barrel = File(barrelPath).readAsStringSync();
  final newExports = <String>[];
  for (final name in modelNames) {
    final snake = _toSnakeCase(name);
    final exportLine = "export 'src/models/$snake.dart';";
    if (!barrel.contains(exportLine)) {
      newExports.add(exportLine);
    }
  }
  if (newExports.isNotEmpty) {
    final updated = barrel.trimRight() + '\n' + newExports.join('\n') + '\n';
    File(barrelPath).writeAsStringSync(updated);
    print('✅ Barrel: added ${newExports.length} model exports');
  }

  // Update Hive registrar if CM models were generated
  final hiveModels = models.entries
      .where((e) => (e.value as Map<String, dynamic>)['hive'] == true)
      .toList();
  if (hiveModels.isNotEmpty) {
    _updateHiveRegistrar(hiveModels);
    _updateRegisterYaml(hiveModels);
  }

  print('✅ All API code generated for domain: $domain');
  print('   Models: ${modelNames.length} DTOs${hiveModels.isNotEmpty ? " (${hiveModels.length} CM)" : ""}');
  print('   Endpoints: ${endpoints.length}');
}

String _findApiPackageDir() {
  // Try common locations
  final candidates = [
    'packages/infrastructure/api',
    '../packages/infrastructure/api',
    '../../packages/infrastructure/api',
  ];
  for (final dir in candidates) {
    if (Directory(dir).existsSync()) return dir;
  }
  return 'packages/infrastructure/api'; // default
}

void _runMason(
  String templateFile,
  String modelName,
  String domain, {
  required String fieldsJson,
  required bool hive,
  required int hiveTypeId,
  required List<dynamic> endpoints,
  List<Map<String, dynamic>>? models,
  required String outputDir,
  required String onConflict,
}) {
  final endpointJson = jsonEncode(endpoints);
  final modelsJson = models != null ? jsonEncode(models) : '[]';

  final args = [
    'make',
    'api_gen',
    '--modelName', modelName,
    '--domain', domain,
    '--fields', fieldsJson,
    '--hive', hive.toString(),
    '--hiveTypeId', hiveTypeId.toString(),
    '--endpoints', endpointJson,
    '--models', modelsJson,
    '-c', templateFile,
    '-o', outputDir,
    '--on-conflict', onConflict,
  ];

  print('  🧱 mason ${args.join(' ')}');
  final result = Process.runSync('mason', args);

  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    throw Exception('Mason failed for $templateFile: ${result.stderr}');
  }
  print('     ✅ $templateFile → $outputDir');
}

String _toSnakeCase(String pascal) {
  return pascal.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '${m.start > 0 ? '_' : ''}${m.group(0)!.toLowerCase()}',
  );
}

void _updateHiveRegistrar(List<MapEntry<String, dynamic>> models) {
  final kvPath = _findKvStorageDir();
  final path = '$kvPath/lib/src/hive_registrar.dart';
  if (!File(path).existsSync()) {
    print('⚠️  HiveRegistrar not found at $path, skipping adapter registration');
    return;
  }

  var content = File(path).readAsStringSync();

  for (final entry in models) {
    final name = entry.key;
    final snake = _toSnakeCase(name);
    final cmClass = '${name}CM';
    final importLine = "import 'package:api/src/models/${snake}.cm.dart';";
    final registerLine = '    Hive.registerAdapter(${cmClass}Adapter());';

    if (!content.contains(importLine)) {
      content = '$importLine\n$content';
    }
    if (!content.contains(registerLine)) {
      content = content.replaceFirst(
        '_registered = true;',
        '_registered = true;\n$registerLine',
      );
    }
  }

  File(path).writeAsStringSync(content);
  print('✅ HiveRegistrar: registered CM adapters');
}

String _findKvStorageDir() {
  final candidates = [
    'packages/infrastructure/key_value_storage',
    '../packages/infrastructure/key_value_storage',
    '../../packages/infrastructure/key_value_storage',
  ];
  for (final dir in candidates) {
    if (Directory(dir).existsSync()) return dir;
  }
  return 'packages/infrastructure/key_value_storage';
}

void _updateRegisterYaml(List<MapEntry<String, dynamic>> models) {
  final path = 'register.yaml';
  if (!File(path).existsSync()) {
    print('⚠️  register.yaml not found, skipping');
    return;
  }

  var content = File(path).readAsStringSync();

  // Find current nextTypeId
  final nextMatch = RegExp(r'nextTypeId:\s*(\d+)').firstMatch(content);
  var nextTypeId = nextMatch != null ? int.parse(nextMatch.group(1)!) : 1;

  for (final entry in models) {
    final model = entry.value as Map<String, dynamic>;
    final typeId = model['hiveTypeId'] as int;
    final name = entry.key;

    if (!content.contains('$name CM')) {
      // Update nextTypeId
      if (typeId >= nextTypeId) {
        final newNext = typeId + 1;
        content = content.replaceFirst(
          RegExp(r'nextTypeId:\s*\d+'),
          'nextTypeId: $newNext',
        );
        nextTypeId = newNext;
      }

      // Append new typeId entry
      content += '  - id: $typeId\n'
          '    model: ${name}CM\n'
          '    package: infrastructure/api\n'
          '    description: ${name} CM 持久化模型\n';
    }
  }

  File(path).writeAsStringSync(content);
  print('✅ register.yaml: updated with CM typeIds');
}
