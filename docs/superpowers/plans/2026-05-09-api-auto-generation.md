# API 自动生成实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从 JSON 规范文件自动生成 Retrofit API 接口 + Freezed DTO + Hive CM 持久化模型，消除手写端点路径和数据模型。

**Architecture:** 新增 `bricks/api_gen/` Mason 砖块（3 个模板） + `scripts/gen_api.dart` 脚本（读取 JSON → 调用 Mason → 更新 barrel + register.yaml）。JSON spec 放在 `packages/infrastructure/api/spec/`。

**Tech Stack:** Dart, Mason (Mustache templates), freezed, json_serializable, retrofit, hive

---

### Task 1: Create api_gen Mason brick metadata

**Files:**
- Create: `bricks/api_gen/brick.yaml`

- [ ] **Step 1: Create brick.yaml**

```yaml
name: api_gen
description: 从 JSON spec 生成 Retrofit API 接口 + Freezed DTO + Hive CM 持久化模型
version: 1.0.0
vars:
  domain:
    type: string
    description: 业务域名（如 auth）
  modelName:
    type: string
    description: 模型名称（PascalCase）
  fields:
    type: string
    description: 字段定义 JSON 数组字符串
  hive:
    type: boolean
    description: 是否生成 CM 持久化模型
    default: false
  hiveTypeId:
    type: number
    description: Hive TypeId
    default: 0
  endpoints:
    type: string
    description: 端点定义 JSON 字符串
```

- [ ] **Step 2: Verify**

Run: `mason ls`
Expected: `api_gen` brick appears in the list

- [ ] **Step 3: Commit**

```bash
git add bricks/api_gen/brick.yaml
git commit -m "feat: add api_gen Mason brick metadata"
```

---

### Task 2: Create model.dart template (DTO)

**Files:**
- Create: `bricks/api_gen/__brick__/model.dart`

- [ ] **Step 1: Create model.dart template**

This template generates a single `@freezed` DTO from Mason variables. The `fields` variable is a JSON string like `[{"name":"username","type":"String"},{"name":"password","type":"String"}]`.

```dart
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
```

- [ ] **Step 2: Verify template syntax**

Run: `mason make api_gen --modelName TestModel --domain test --fields '[{"name":"id","type":"String"}]' --hive false --endpoints "[]" -c model.dart -o /tmp/test_output`
Expected: `/tmp/test_output/model.dart` created with `@freezed class TestModel`

- [ ] **Step 3: Commit**

```bash
git add bricks/api_gen/__brick__/model.dart
git commit -m "feat: add DTO template to api_gen brick"
```

---

### Task 3: Create model.cm.dart template (CM persistence)

**Files:**
- Create: `bricks/api_gen/__brick__/model.cm.dart`

- [ ] **Step 1: Create model.cm.dart template**

This template generates a `@HiveType` CM class. Only invoked when `hive: true`.

```dart
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
```

- [ ] **Step 2: Verify template syntax**

Run: `mason make api_gen --modelName TestModel --domain test --fields '[{"name":"name","type":"String","index":0}]' --hive true --hiveTypeId 10 --endpoints "[]" -c model.cm.dart -o /tmp/test_output`
Expected: `/tmp/test_output/model.cm.dart` created with `@HiveType(typeId: 10) class TestModelCM`

- [ ] **Step 3: Commit**

```bash
git add bricks/api_gen/__brick__/model.cm.dart
git commit -m "feat: add CM persistence template to api_gen brick"
```

---

### Task 4: Create api.dart template (Retrofit interface)

**Files:**
- Create: `bricks/api_gen/__brick__/api.dart`

- [ ] **Step 1: Create api.dart template**

The `endpoints` variable is a JSON string with endpoint definitions. The `models` variable lists model names for imports.

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
{{#models}}
import 'package:api/src/models/{{name.snakeCase}}.dart';
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
```

- [ ] **Step 2: Verify template syntax**

Run: `mason make api_gen --domain test --modelName Skip --fields "[]" --hive false --endpoints '[{"name":"getData","method":"GET","path":"/test","response":"Map"}]' --models '[{"name":"TestModel"}]' -c api.dart -o /tmp/test_output`
Expected: `/tmp/test_output/api.dart` with `@RestApi` class `TestApi`

- [ ] **Step 3: Commit**

```bash
git add bricks/api_gen/__brick__/api.dart
git commit -m "feat: add Retrofit interface template to api_gen brick"
```

---

### Task 5: Create gen_api.dart orchestrator script

**Files:**
- Create: `scripts/gen_api.dart`

This script reads a JSON spec and orchestrates Mason invocations.

- [ ] **Step 1: Create gen_api.dart**

```dart
import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final specArg = arguments.firstWhere(
    (a) => a.startsWith('--spec='),
    orElse: () => throw ArgumentError('Usage: dart run scripts/gen_api.dart --spec=spec/auth.json'),
  );
  final specPath = specArg.split('=')[1];
  final spec = jsonDecode(File(specPath).readAsStringSync()) as Map<String, dynamic>;
  final domain = spec['domain'] as String;
  final models = spec['models'] as Map<String, dynamic>;
  final endpoints = spec['endpoints'] as List<dynamic>;

  final apiPackagePath = 'packages/infrastructure/api';
  final modelsDir = '$apiPackagePath/lib/src/models';

  // Ensure models directory exists
  Directory(modelsDir).createSync(recursive: true);

  // Process each model
  final modelNames = <String>[];
  var fieldIndex = 0;
  for (final entry in models.entries) {
    final modelName = entry.key;
    final modelDef = entry.value as Map<String, dynamic>;
    modelNames.add(modelName);

    final fields = <Map<String, dynamic>>[];
    for (final fieldEntry in (modelDef['fields'] as Map<String, dynamic>?)?.entries ?? []) {
      final type = fieldEntry.value as String;
      final isOptional = type.endsWith('?');
      fields.add({
        'name': fieldEntry.key,
        'type': type,
        'required': !isOptional,
        'index': fieldIndex++,
      });
    }

    final fieldsJson = jsonEncode(fields);

    // Generate DTO
    runMason(
      'model.dart',
      modelName,
      domain,
      fieldsJson: fieldsJson,
      hive: false,
      hiveTypeId: 0,
      endpoints: [],
    );

    // Generate CM if needed
    if (modelDef['hive'] == true) {
      runMason(
        'model.cm.dart',
        modelName,
        domain,
        fieldsJson: fieldsJson,
        hive: true,
        hiveTypeId: modelDef['hiveTypeId'] ?? 0,
        endpoints: [],
      );
    }
  }

  // Generate Retrofit interface
  final apiEndpoints = <Map<String, dynamic>>[];
  for (final ep in endpoints) {
    final epMap = ep as Map<String, dynamic>;
    apiEndpoints.add({
      'name': epMap['name'],
      'method': epMap['method'],
      'path': '${spec['basePath']}${epMap['path']}',
      'response': epMap['response'],
      'body': epMap['body'],
      'hasBody': epMap.containsKey('body'),
      'params': (epMap['params'] as Map<String, dynamic>?)
          ?.entries
          .map((e) => {'name': e.key, 'type': e.value})
          .toList(),
    });
  }

  final modelsRefs = modelNames.map((n) => {'name': n}).toList();

  runMason(
    'api.dart',
    domain, // used as "modelName" for the api.dart template but represents domain
    domain,
    fieldsJson: '[]',
    hive: false,
    hiveTypeId: 0,
    endpoints: apiEndpoints,
    models: modelsRefs,
  );

  // Update barrel file (api.dart)
  final barrelPath = '$apiPackagePath/lib/api.dart';
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
      .where((e) => (e.value as Map)['hive'] == true)
      .toList();
  if (hiveModels.isNotEmpty) {
    _updateHiveRegistrar(hiveModels);
    _updateRegisterYaml(hiveModels);
  }

  print('✅ All API code generated for domain: $domain');
}

void runMason(
  String templateFile,
  String modelName,
  String domain, {
  required String fieldsJson,
  required bool hive,
  required int hiveTypeId,
  required List<dynamic> endpoints,
  List<Map<String, dynamic>>? models,
}) {
  final endpointJson = jsonEncode(endpoints);
  final modelsJson = models != null ? jsonEncode(models) : '[]';

  final outputDir = templateFile.contains('.cm.')
      ? 'packages/infrastructure/api/lib/src/models'
      : templateFile == 'api.dart'
          ? 'packages/infrastructure/api/lib/src/api'
          : 'packages/infrastructure/api/lib/src/models';

  final conflictFlag = templateFile.contains('.cm.') ? 'skip' : 'overwrite';

  final result = Process.runSync(
    'mason',
    [
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
      '--on-conflict', conflictFlag,
    ],
  );

  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    throw Exception('Mason failed for $templateFile');
  }
  print('  ✅ Generated: $templateFile → $outputDir');
}

String _toSnakeCase(String pascal) {
  return pascal.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '${m.start > 0 ? '_' : ''}${m.group(0)!.toLowerCase()}',
  );
}

void _updateHiveRegistrar(List<MapEntry<String, dynamic>> models) {
  final path = 'packages/infrastructure/key_value_storage/lib/src/hive_registrar.dart';
  var content = File(path).readAsStringSync();

  for (final entry in models) {
    final name = entry.key;
    final snake = _toSnakeCase(name);
    final cmClass = '${name}CM';
    final importLine = "import 'package:api/src/models/${snake}.cm.dart';";
    final registerLine = '    Hive.registerAdapter(${cmClass}Adapter());';

    if (!content.contains(importLine)) {
      content = importLine + '\n' + content;
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

void _updateRegisterYaml(List<MapEntry<String, dynamic>> models) {
  final path = 'register.yaml';
  var content = File(path).readAsStringSync();

  for (final entry in models) {
    final model = entry.value as Map<String, dynamic>;
    final typeId = model['hiveTypeId'] as int;
    final name = entry.key;

    if (!content.contains('$name CM')) {
      content = content.replaceFirst(
        'nextTypeId:',
        'nextTypeId: ${typeId + 1}',
      );
      content += '  - id: $typeId\n'
          '    model: ${name}CM\n'
          '    package: infrastructure/api\n'
          '    description: ${name} CM 持久化模型\n';
    }
  }

  File(path).writeAsStringSync(content);
  print('✅ register.yaml: updated with CM typeIds');
}
```

- [ ] **Step 2: Verify script parses a test JSON**

Create a temporary test file at `/tmp/test_spec.json`:

```json
{
  "domain": "test",
  "basePath": "/api",
  "models": {
    "TestData": {
      "fields": {
        "id": "String",
        "name": "String"
      }
    }
  },
  "endpoints": [
    {
      "name": "getData",
      "method": "GET",
      "path": "/data",
      "response": "TestData"
    }
  ]
}
```

Run: `dart run scripts/gen_api.dart --spec=/tmp/test_spec.json`
Expected: prints success messages, generates files in `packages/infrastructure/api/lib/src/models/` and `packages/infrastructure/api/lib/src/api/`

- [ ] **Step 3: Commit**

```bash
git add scripts/gen_api.dart
git commit -m "feat: add gen_api.dart orchestrator script"
```

---

### Task 6: Create spec directory and Makefile entries

**Files:**
- Create: `packages/infrastructure/api/spec/.gitkeep`
- Modify: `makefile`

- [ ] **Step 1: Create spec directory**

```bash
mkdir -p packages/infrastructure/api/spec
touch packages/infrastructure/api/spec/.gitkeep
```

- [ ] **Step 2: Add Makefile entries**

Append after the existing `create-hive-model` target (after line 149):

```makefile
# ============================================================================
# API 代码生成（从 JSON spec）
# ============================================================================

# 单文件生成
gen-api:
	@if [ -z "$(spec)" ]; then echo "用法: make gen-api spec=auth.json [files=auth]"; exit 1; fi
	@echo "🚀 从 spec/$(spec) 生成 API 代码..."
	@cd packages/infrastructure/api && dart run ../../scripts/gen_api.dart --spec=spec/$(spec)

# 批量生成所有 spec
gen-all-apis:
	@for f in packages/infrastructure/api/spec/*.json; do \
		echo "📄 $$(basename $$f)"; \
		dart run scripts/gen_api.dart --spec=$$f; \
	done
	@echo "✅ 所有 API spec 生成完成"

# 完整刷新: 生成 + build_runner + 校验
refresh-api:
	@make gen-all-apis
	@make get
	@cd packages/infrastructure/api && dart run build_runner build --delete-conflicting-outputs
	@cd packages/infrastructure/key_value_storage && dart run build_runner build --delete-conflicting-outputs
	@melos analyze
```

- [ ] **Step 3: Commit**

```bash
git add packages/infrastructure/api/spec/.gitkeep makefile
git commit -m "feat: add spec directory and api-gen Makefile commands"
```

---

### Task 7: Write auth.json spec + generate

**Files:**
- Create: `packages/infrastructure/api/spec/auth.json`
- Overwrite: `packages/infrastructure/api/lib/src/api/auth_api.dart` (generated)
- Create: `packages/infrastructure/api/lib/src/models/login_request.dart`
- Create: `packages/infrastructure/api/lib/src/models/login_response.dart`
- Create: `packages/infrastructure/api/lib/src/models/user_profile.dart`

Migrating from existing hand-written `auth_api.dart` (4 endpoints: login, register, getProfile, forgotPassword).

- [ ] **Step 1: Write auth.json**

```json
{
  "domain": "auth",
  "basePath": "/User",
  "models": {
    "LoginRequest": {
      "fields": {
        "username": "String",
        "password": "String"
      }
    },
    "LoginResponse": {
      "fields": {
        "token": "String",
        "userId": "String",
        "username": "String"
      }
    },
    "UserProfile": {
      "fields": {
        "name": "String",
        "email": "String",
        "avatar": "String?"
      }
    }
  },
  "endpoints": [
    {
      "name": "login",
      "method": "POST",
      "path": "/Login/Password",
      "body": "LoginRequest",
      "response": "LoginResponse"
    },
    {
      "name": "register",
      "method": "POST",
      "path": "/Register",
      "body": "LoginRequest",
      "response": "LoginResponse"
    },
    {
      "name": "getProfile",
      "method": "GET",
      "path": "/{username}",
      "params": { "username": "String" },
      "response": "UserProfile"
    },
    {
      "name": "forgotPassword",
      "method": "POST",
      "path": "/forgot_password",
      "body": "LoginRequest",
      "response": "LoginResponse"
    }
  ]
}
```

- [ ] **Step 2: Generate**

Run: `make gen-api spec=auth.json`

- [ ] **Step 3: Run build_runner**

Run: `cd packages/infrastructure/api && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Verify generated files**

Check generated `auth_api.dart` has 4 endpoints with typed models (NO `Map<String, dynamic>`):
- `Future<LoginResponse> login(@Body() LoginRequest body)`
- `Future<LoginResponse> register(@Body() LoginRequest body)`
- `Future<UserProfile> getProfile(@Path('username') String username)`
- `Future<LoginResponse> forgotPassword(@Body() LoginRequest body)`

Check `login_request.dart`, `login_response.dart`, `user_profile.dart` have `@freezed` class with `fromJson`.

- [ ] **Step 5: Verify barrel**

Run: `grep "export 'src/models/login_request.dart'" packages/infrastructure/api/lib/api.dart`
Expected: line exists

- [ ] **Step 6: Run analyze**

Run: `cd packages/infrastructure/api && dart analyze`
Expected: no errors

- [ ] **Step 7: Commit**

```bash
git add packages/infrastructure/api/spec/auth.json \
        packages/infrastructure/api/lib/src/api/auth_api.dart \
        packages/infrastructure/api/lib/src/models/login_request.dart \
        packages/infrastructure/api/lib/src/models/login_response.dart \
        packages/infrastructure/api/lib/src/models/user_profile.dart \
        packages/infrastructure/api/lib/api.dart \
        packages/infrastructure/api/lib/src/api/auth_api.g.dart
git add packages/infrastructure/api/lib/src/models/*.freezed.dart packages/infrastructure/api/lib/src/models/*.g.dart
git commit -m "feat: migrate auth API to JSON spec generation"
```

---

### Task 8: Write home.json spec + generate

**Files:**
- Create: `packages/infrastructure/api/spec/home.json`
- Create: `packages/infrastructure/api/lib/src/models/home_data.dart`

Migrating 1 endpoint: `getHomeData` GET /home/data.

- [ ] **Step 1: Write home.json**

```json
{
  "domain": "home",
  "basePath": "",
  "models": {
    "HomeData": {
      "fields": {
        "title": "String",
        "banner": "String?",
        "sections": "String"
      }
    }
  },
  "endpoints": [
    {
      "name": "getHomeData",
      "method": "GET",
      "path": "/home/data",
      "response": "HomeData"
    }
  ]
}
```

- [ ] **Step 2: Generate + build_runner + verify**

Run: `make gen-api spec=home.json`
Run: `cd packages/infrastructure/api && dart run build_runner build --delete-conflicting-outputs`
Verify: `home_api.dart` uses `Future<HomeData>` instead of `Map<String, dynamic>`

- [ ] **Step 3: Commit**

```bash
git add packages/infrastructure/api/spec/home.json \
        packages/infrastructure/api/lib/src/api/home_api.dart \
        packages/infrastructure/api/lib/src/models/home_data.dart \
        packages/infrastructure/api/lib/api.dart
git add packages/infrastructure/api/lib/src/models/*.freezed.dart packages/infrastructure/api/lib/src/models/*.g.dart
git commit -m "feat: migrate home API to JSON spec generation"
```

---

### Task 9: Write detail.json spec + generate

**Files:**
- Create: `packages/infrastructure/api/spec/detail.json`
- Create: `packages/infrastructure/api/lib/src/models/detail_data.dart`

Migrating 1 endpoint: `getDetailData` GET /detail/{id}.

- [ ] **Step 1: Write detail.json**

```json
{
  "domain": "detail",
  "basePath": "",
  "models": {
    "DetailData": {
      "fields": {
        "id": "String",
        "title": "String",
        "content": "String",
        "imageUrl": "String?"
      }
    }
  },
  "endpoints": [
    {
      "name": "getDetailData",
      "method": "GET",
      "path": "/detail/{id}",
      "params": { "id": "String" },
      "response": "DetailData"
    }
  ]
}
```

- [ ] **Step 2: Generate + verify + commit**

Same workflow as Task 8. Generated `detail_api.dart` must have `Future<DetailData> getDetailData(@Path('id') String id)`.

```bash
git add packages/infrastructure/api/spec/detail.json \
        packages/infrastructure/api/lib/src/api/detail_api.dart \
        packages/infrastructure/api/lib/src/models/detail_data.dart \
        packages/infrastructure/api/lib/api.dart
git add packages/infrastructure/api/lib/src/models/*.freezed.dart packages/infrastructure/api/lib/src/models/*.g.dart
git commit -m "feat: migrate detail API to JSON spec generation"
```

---

### Task 10: Write session.json spec + generate

**Files:**
- Create: `packages/infrastructure/api/spec/session.json`
- Create: `packages/infrastructure/api/lib/src/models/session_result.dart`

Migrating 2 endpoints: signIn POST /session, signOut DELETE /session.

- [ ] **Step 1: Write session.json**

```json
{
  "domain": "session",
  "basePath": "",
  "models": {
    "SignInRequest": {
      "fields": {
        "username": "String",
        "password": "String"
      }
    },
    "SessionResult": {
      "fields": {
        "success": "bool",
        "message": "String?"
      }
    }
  },
  "endpoints": [
    {
      "name": "signIn",
      "method": "POST",
      "path": "/session",
      "body": "SignInRequest",
      "response": "SessionResult"
    },
    {
      "name": "signOut",
      "method": "DELETE",
      "path": "/session",
      "response": "SessionResult"
    }
  ]
}
```

- [ ] **Step 2: Generate + verify + commit**

Generated `session_api.dart` must use typed `SignInRequest` body and `SessionResult` response.

```bash
git add packages/infrastructure/api/spec/session.json \
        packages/infrastructure/api/lib/src/api/session_api.dart \
        packages/infrastructure/api/lib/src/models/sign_in_request.dart \
        packages/infrastructure/api/lib/src/models/session_result.dart \
        packages/infrastructure/api/lib/api.dart
git add packages/infrastructure/api/lib/src/models/*.freezed.dart packages/infrastructure/api/lib/src/models/*.g.dart
git commit -m "feat: migrate session API to JSON spec generation"
```

---

### Task 11: Write vehicle.json spec + generate

**Files:**
- Create: `packages/infrastructure/api/spec/vehicle.json`
- Create: `packages/infrastructure/api/lib/src/models/vehicle_data.dart`

Migrating 3 endpoints (no body params, no path params — simplest case).

- [ ] **Step 1: Write vehicle.json**

```json
{
  "domain": "vehicle",
  "basePath": "",
  "models": {
    "VehicleData": {
      "fields": {
        "id": "String",
        "name": "String",
        "plate": "String",
        "status": "String",
        "type": "String?"
      }
    }
  },
  "endpoints": [
    {
      "name": "getVehicleList",
      "method": "GET",
      "path": "/Vehicle/List",
      "response": "VehicleData"
    },
    {
      "name": "getVehicleDetail",
      "method": "GET",
      "path": "/Vehicle/Detail/Info",
      "response": "VehicleData"
    },
    {
      "name": "getVehicleRanking",
      "method": "GET",
      "path": "/Vehicle/Ranking/Query/Top/Info",
      "response": "VehicleData"
    }
  ]
}
```

- [ ] **Step 2: Generate + verify + commit**

```bash
git add packages/infrastructure/api/spec/vehicle.json \
        packages/infrastructure/api/lib/src/api/vehicle_api.dart \
        packages/infrastructure/api/lib/src/models/vehicle_data.dart \
        packages/infrastructure/api/lib/api.dart
git add packages/infrastructure/api/lib/src/models/*.freezed.dart packages/infrastructure/api/lib/src/models/*.g.dart
git commit -m "feat: migrate vehicle API to JSON spec generation"
```

---

### Task 12: Update consumer RepositoryImpl files

**Files:**
- Modify: `packages/features/feature_home/lib/src/repository/home_repository_impl.dart`
- Modify: `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart`
- Modify: `packages/services/auth/lib/src/repository/auth_repository_impl.dart`

Replace `Map<String, dynamic>` field access with typed model property access.

- [ ] **Step 1: Update HomeRepositoryImpl**

Find and read the current file first. Replace any `response['key'] as Type` with `response.key` for the new `HomeData` type.

Example change:
```dart
// Before
final response = await _homeApi.getHomeData();
final title = response['title'] as String;

// After
final response = await _homeApi.getHomeData(); // HomeData
final title = response.title;
```

Use `make analyze` after change to verify no type errors.

- [ ] **Step 2: Update DetailRepositoryImpl**

Same pattern — replace `Map<String, dynamic>` access with `DetailData` property access.

- [ ] **Step 3: Update AuthRepositoryImpl**

Replace all `Map<String, dynamic>` access with `LoginResponse`/`UserProfile` typed access.

- [ ] **Step 4: Run full analyze**

Run: `melos analyze`
Expected: no errors from the changed files

- [ ] **Step 5: Commit**

```bash
git add packages/features/feature_home/lib/src/repository/home_repository_impl.dart \
        packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart \
        packages/services/auth/lib/src/repository/auth_repository_impl.dart
git commit -m "refactor: update consumers to use typed API DTOs"
```

---

### Task 13: Full integration validation

**Files:**
- (no new files, just verification)

- [ ] **Step 1: Clean and regenerate everything**

Run: `make refresh-api`
Expected: all specs regenerated, build_runner passes, melos analyze passes

- [ ] **Step 2: Run full test suite**

Run: `melos test`
Expected: all existing tests pass (no regression from type changes)

- [ ] **Step 3: Verify no Map<String,dynamic> in generated APIs**

Run: `grep -r "Map<String, dynamic>" packages/infrastructure/api/lib/src/api/`
Expected: **no results** (all migrated to typed models)

- [ ] **Step 4: Verify barrel exports are complete**

Run: `grep "export 'src/models/" packages/infrastructure/api/lib/api.dart`
Expected: at least 9 model exports (LoginRequest, LoginResponse, UserProfile, HomeData, DetailData, SignInRequest, SessionResult, VehicleData)

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore: final validation - all APIs migrated to JSON spec"
```

---

## Completion Checklist

- [ ] `bricks/api_gen/` exists with brick.yaml + 3 templates
- [ ] `scripts/gen_api.dart` orchestrator works
- [ ] 5 JSON spec files in `packages/infrastructure/api/spec/`
- [ ] All 5 Retrofit API files return typed models (zero `Map<String, dynamic>`)
- [ ] All generated DTOs have `@freezed` + `fromJson`
- [ ] Barrel file (`api.dart`) has all model exports
- [ ] `make get` passes
- [ ] `melos analyze` passes
- [ ] `melos test` passes
- [ ] `make gen-api spec=auth.json` works end-to-end
