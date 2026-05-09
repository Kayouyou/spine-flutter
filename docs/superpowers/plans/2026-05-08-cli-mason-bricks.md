# CLI Tools Enhancement + Mason Bricks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增强现有 feature brick（Result<T> 模式 + 路由提示），新增 api/model/hive_model 三个 Mason 模板，更新 mason.yaml 和 makefile 支持一键生成

**Architecture:** 在现有 feature brick 基础上引入 Result<T> 错误处理模式（Plan 1 依赖 domain 的 result.dart），新增三个独立 brick 分别处理 API 调用场景、纯模型场景、本地存储场景

**Tech Stack:** mason_cli, mustache 模板语法, freezed, retrofit, hive

---

## 文件结构

| 文件 | 类型 | 职责 |
|------|------|------|
| `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart` | 修改 | 使用 Result.when() 处理状态 |
| `bricks/feature/__brick__/lib/src/cubit/{{name}}_state.dart` | 修改 | 适配 Result<T> 模式 |
| `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart` | 修改 | 返回 Result<T> |
| `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart` | 修改 | 使用 .toResult() 扩展 |
| `bricks/feature/__brick__/lib/src/ui/{{name}}_page.dart` | 修改 | 添加路由注册提示注释 |
| `bricks/feature/__brick__/test/{{name}}_cubit_test.dart` | 修改 | 测试 Result 模式 |
| `bricks/api/brick.yaml` | 新增 | API brick 配置 |
| `bricks/api/__brick__/pubspec.yaml` | 新增 | 包含 retrofit/freezed |
| `bricks/api/__brick__/lib/src/api/{{name}}_api.dart` | 新增 | Retrofit 接口定义 |
| `bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart` | 新增 | Repository 实现 |
| `bricks/api/__brick__/lib/src/di/setup.dart` | 新增 | DI 注册 |
| `bricks/model/brick.yaml` | 新增 | Model brick 配置 |
| `bricks/model/__brick__/lib/src/models/{{name}}.dart` | 新增 | @freezed 模型模板 |
| `bricks/hive_model/brick.yaml` | 新增 | HiveModel brick 配置 |
| `bricks/hive_model/__brick__/lib/src/models/{{name}}.dart` | 新增 | @HiveType 模型模板 |
| `bricks/hive_model/__brick__/lib/src/migrations/{{name}}_migration.dart` | 新增 | Migration 骨架 |
| `mason.yaml` | 修改 | 注册所有新 bricks |
| `makefile` | 修改 | 添加 create-api/create-model/create-hive-model 命令 |

---

### Task 1: 修改 Feature Brick - Repository 接口（返回 Result<T>）

**Files:**
- Modify: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart`
- Test: 通过 melos analyze 验证生成的代码

- [ ] **Step 1: 修改 Repository 接口返回 Result<T>**

修改 `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart`：

```dart
import 'package:domain/domain.dart';

/// {{name.pascalCase()}} 数据仓库接口
///
/// 职责：定义 {{name.pascalCase()}} 数据获取的契约
/// 使用：RepositoryImpl 实现，Cubit 通过接口调用
/// 好处：便于测试 Mock 和未来替换实现
abstract class {{name.pascalCase()}}Repository {
  /// 获取 {{name.pascalCase()}} 数据
  ///
  /// 返回 {{name.pascalCase()}} 展示所需的数据
  /// 使用 Result<T> 模式：success(data) 或 failure(error)
  Future<Result<Map<String, dynamic>>> get{{name.pascalCase()}}Data();

  /// 刷新 {{name.pascalCase()}} 数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Result<Map<String, dynamic>>> refresh{{name.pascalCase()}}Data();
}
```

- [ ] **Step 2: 验证模板语法**

检查 mustache 语法 `{{name.pascalCase()}}` 正确性

---

### Task 2: 修改 Feature Brick - RepositoryImpl（使用 .toResult() 扩展）

**Files:**
- Modify: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart`

- [ ] **Step 1: 修改 RepositoryImpl 使用 .toResult() 扩展**

修改 `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart`：

```dart
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import '{{name}}_repository.dart';

/// {{name.pascalCase()}} 数据仓库实现
///
/// 职责：通过 API 获取 {{name.pascalCase()}} 数据
/// 使用：在 DI setup 中注册为 Factory
/// 错误处理：使用 .toResult() 扩展将 DioException 转为 Result
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  final Dio _dio;

  {{name.pascalCase()}}RepositoryImpl(this._dio);

  @override
  Future<Result<Map<String, dynamic>>> get{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name}}');
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> refresh{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name}}', queryParameters: {'refresh': true});
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }
}
```

- [ ] **Step 2: 添加注释说明错误转换**

确保代码包含对 `toDomainException()` 扩展方法的依赖说明

---

### Task 3: 修改 Feature Brick - Cubit（使用 Result.when() 模式）

**Files:**
- Modify: `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart`

- [ ] **Step 1: 修改 Cubit 使用 Result.when() 处理状态**

修改 `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart`：

```dart
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
/// 错误处理：使用 Result<T>.when() 模式替代 try-catch
class {{name.pascalCase()}}Cubit extends Cubit<{{name.pascalCase()}}State> {
  /// 数据仓库
  final {{name.pascalCase()}}Repository _repository;

  {{name.pascalCase()}}Cubit(this._repository) : super(const {{name.pascalCase()}}State.initial());

  /// 加载 {{name.pascalCase()}} 数据
  ///
  /// 从 Repository 获取数据，使用 Result.when() 处理
  /// 状态流转：Initial/Error → Loading → Loaded/Error
  Future<void> loadData() async {
    emit(const {{name.pascalCase()}}State.loading());

    final result = await _repository.get{{name.pascalCase()}}Data();
    result.when(
      success: (data) => emit({{name.pascalCase()}}State.loaded(data: data)),
      failure: (error) => emit({{name.pascalCase()}}State.error(errorCode: error.message)),
    );
  }

  /// 刷新 {{name.pascalCase()}} 数据
  ///
  /// 强制从服务器获取最新数据
  Future<void> refreshData() async {
    emit(const {{name.pascalCase()}}State.loading());

    final result = await _repository.refresh{{name.pascalCase()}}Data();
    result.when(
      success: (data) => emit({{name.pascalCase()}}State.loaded(data: data)),
      failure: (error) => emit({{name.pascalCase()}}State.error(errorCode: error.message)),
    );
  }

  /// 重试加载
  ///
  /// 错误状态下点击重试按钮触发
  Future<void> retry() async {
    await loadData();
  }
}
```

- [ ] **Step 2: 验证代码完整性**

确认 import 语句和类型引用正确

---

### Task 4: 修改 Feature Brick - State（保持现有结构）

**Files:**
- Modify: `bricks/feature/__brick__/lib/src/cubit/{{name}}_state.dart`

- [ ] **Step 1: 检查 State 文件是否需要修改**

当前 State 使用 @freezed sealed class，error 状态已有 errorCode 字段，与 Result 模式兼容。无需修改：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name}}_state.freezed.dart';

/// {{name.pascalCase()}} 状态
///
/// 职责：定义 {{name.pascalCase()}} 页面的所有可能状态
/// 使用：BlocBuilder 响应状态更新 UI
/// 状态流转：Initial → Loading → Loaded/Error
@freezed
sealed class {{name.pascalCase()}}State with _${{name.pascalCase()}}State {
  const factory {{name.pascalCase()}}State.initial() = {{name.pascalCase()}}Initial;
  const factory {{name.pascalCase()}}State.loading() = {{name.pascalCase()}}Loading;
  const factory {{name.pascalCase()}}State.loaded({required Map<String, dynamic> data}) = {{name.pascalCase()}}Loaded;
  const factory {{name.pascalCase()}}State.error({required String errorCode}) = {{name.pascalCase()}}Error;
}
```

- [ ] **Step 2: 确认状态与 Result 模式兼容**

State.error 接收 String errorCode，Cubit 中 error.message 作为参数传入，兼容

---

### Task 5: 修改 Feature Brick - Page（添加路由注册提示）

**Files:**
- Modify: `bricks/feature/__brick__/lib/src/ui/{{name}}_page.dart`

- [ ] **Step 1: 在 Page 文件顶部添加路由注册提示注释**

修改 `bricks/feature/__brick__/lib/src/ui/{{name}}_page.dart`，在 import 之后添加：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:component_library/component_library.dart';
import '../cubit/{{name}}_cubit.dart';
import '../cubit/{{name}}_state.dart';

// =============================================================================
// 路由注册提示
// =============================================================================
// 生成后需要在以下位置添加路由：
//
// 1. packages/infrastructure/routing/lib/src/app_router.dart:
//
//    GoRoute(
//      path: '/{{name}}',
//      builder: (context, state) => BlocProvider(
//        create: (context) => sl<{{name.pascalCase()}}Cubit>()..loadData(),
//        child: const {{name.pascalCase()}}Page(),
//      ),
//    ),
//
// 2. lib/core/di/setup.dart:
//
//    void setupDependencies() {
//      ...
//      setupFeature{{name.pascalCase()}}(sl);
//    }
//
// =============================================================================

/// {{name.pascalCase()}} 页面
///
/// 职责：展示 {{name.pascalCase()}} 内容，响应加载状态
/// 使用：BlocProvider 包装，BlocBuilder 响应状态
class {{name.pascalCase()}}Page extends StatelessWidget {
  const {{name.pascalCase()}}Page({super.key});
```

- [ ] **Step 2: 验证注释格式**

确认注释清晰且符合项目文档风格

---

### Task 6: 修改 Feature Brick - Test（适配 Result 模式）

**Files:**
- Modify: `bricks/feature/__brick__/test/{{name}}_cubit_test.dart`

- [ ] **Step 1: 修改测试文件适配 Result 模式**

修改 `bricks/feature/__brick__/test/{{name}}_cubit_test.dart`：

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:feature_{{name}}/feature_{{name}}.dart';

class Mock{{name.pascalCase()}}Repository extends Mock implements {{name.pascalCase()}}Repository {}

void main() {
  group('{{name.pascalCase()}}Cubit', () {
    late {{name.pascalCase()}}Cubit cubit;
    late Mock{{name.pascalCase()}}Repository mockRepository;

    setUp(() {
      mockRepository = Mock{{name.pascalCase()}}Repository();
      cubit = {{name.pascalCase()}}Cubit(mockRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('初始状态是 {{name.pascalCase()}}Initial', () {
      expect(cubit.state, const {{name.pascalCase()}}State.initial());
    });

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'loadData 发出 loading 然后 loaded（成功）',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => Result.success({'test': 'data'}));
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(data: {'test': 'data'}),
      ],
      verify: (_) {
        verify(() => mockRepository.get{{name.pascalCase()}}Data()).called(1);
      },
    );

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'loadData 发出 loading 然后 error（失败）',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => Result.failure(NetworkException('网络错误')));
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.error(errorCode: '网络错误'),
      ],
      verify: (_) {
        verify(() => mockRepository.get{{name.pascalCase()}}Data()).called(1);
      },
    );

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'refreshData 发出 loading 然后 loaded',
      build: () {
        when(() => mockRepository.refresh{{name.pascalCase()}}Data())
            .thenAnswer((_) async => Result.success({'test': 'refreshed'}));
        return cubit;
      },
      act: (cubit) => cubit.refreshData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(data: {'test': 'refreshed'}),
      ],
      verify: (_) {
        verify(() => mockRepository.refresh{{name.pascalCase()}}Data()).called(1);
      },
    );

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'retry 调用 loadData',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => Result.success({'test': 'retry'}));
        return cubit;
      },
      act: (cubit) => cubit.retry(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.loaded(data: {'test': 'retry'}),
      ],
      verify: (_) {
        verify(() => mockRepository.get{{name.pascalCase()}}Data()).called(1);
      },
    );
  });
}
```

- [ ] **Step 2: 验证 Mock 设置正确**

确认 when().thenAnswer() 模式正确返回 Result

---

### Task 7: 创建 API Brick - brick.yaml

**Files:**
- Create: `bricks/api/brick.yaml`
- Create: `bricks/api/__brick__/`

- [ ] **Step 1: 创建 API brick 目录结构**

```bash
mkdir -p bricks/api/__brick__/lib/src/api
mkdir -p bricks/api/__brick__/lib/src/repository
mkdir -p bricks/api/__brick__/lib/src/di
```

- [ ] **Step 2: 创建 brick.yaml**

创建 `bricks/api/brick.yaml`：

```yaml
name: api
description: 一键创建 API 调用模块（含 Retrofit 接口、RepositoryImpl、DI 注册）
version: 1.0.0
vars:
  name:
    type: string
    description: API 模块名称（蛇形命名，如 'user'）
    prompt: API 模块名称是什么？
  baseUrl:
    type: string
    description: API 基础 URL（如 '/api/v1'）
    prompt: API 基础路径是什么？（如 /api/v1）
```

---

### Task 8: 创建 API Brick - pubspec.yaml

**Files:**
- Create: `bricks/api/__brick__/pubspec.yaml`

- [ ] **Step 1: 创建 pubspec.yaml**

创建 `bricks/api/__brick__/pubspec.yaml`：

```yaml
name: api_{{name}}
description: {{name.pascalCase()}} API 调用模块
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  retrofit: ^4.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  domain:
    path: ../../domain

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  retrofit_generator: ^8.0.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

---

### Task 9: 创建 API Brick - Retrofit 接口

**Files:**
- Create: `bricks/api/__brick__/lib/src/api/{{name}}_api.dart`

- [ ] **Step 1: 创建 Retrofit 接口模板**

创建 `bricks/api/__brick__/lib/src/api/{{name}}_api.dart`：

```dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part '{{name}}_api.g.dart';

/// {{name.pascalCase()}} API 接口
///
/// 职责：定义 {{name.pascalCase()}} 相关的 API 端点
/// 使用：RepositoryImpl 中注入并调用
/// 生成：运行 dart run build_runner build 自动生成 .g.dart
@RestApi()
abstract class {{name.pascalCase()}}Api {
  factory {{name.pascalCase()}}Api(Dio dio, {String baseUrl}) = __{{name.pascalCase()}}Api;

  /// 获取 {{name.pascalCase()}} 列表
  @GET('{{baseUrl}}')
  Future<List<dynamic>> get{{name.pascalCase()}}List();

  /// 获取单个 {{name.pascalCase()}}
  @GET('{{baseUrl}}/{id}')
  Future<Map<String, dynamic>> get{{name.pascalCase()}}ById(@Path('id') String id);

  /// 创建 {{name.pascalCase()}}
  @POST('{{baseUrl}}')
  Future<Map<String, dynamic>> create{{name.pascalCase()}}(
    @Body() Map<String, dynamic> data,
  );

  /// 更新 {{name.pascalCase()}}
  @PUT('{{baseUrl}}/{id}')
  Future<Map<String, dynamic>> update{{name.pascalCase()}}(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  /// 删除 {{name.pascalCase()}}
  @DELETE('{{baseUrl}}/{id}')
  Future<void> delete{{name.pascalCase()}}(@Path('id') String id);
}
```

---

### Task 10: 创建 API Brick - RepositoryImpl

**Files:**
- Create: `bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart`

- [ ] **Step 1: 创建 RepositoryImpl 模板**

创建 `bricks/api/__brick__/lib/src/repository/{{name}}_repository_impl.dart`：

```dart
import 'package:domain/domain.dart';
import '../api/{{name}}_api.dart';

/// {{name.pascalCase()}} 数据仓库实现
///
/// 职责：通过 Retrofit API 获取 {{name.pascalCase()}} 数据
/// 使用：在 DI setup 中注册为 Factory
/// 错误处理：使用 Result<T> 模式
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  final {{name.pascalCase()}}Api _api;

  {{name.pascalCase()}}RepositoryImpl(this._api);

  @override
  Future<Result<List<dynamic>>> get{{name.pascalCase()}}List() async {
    try {
      final response = await _api.get{{name.pascalCase()}}List();
      return Result.success(response);
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> get{{name.pascalCase()}}ById(String id) async {
    try {
      final response = await _api.get{{name.pascalCase()}}ById(id);
      return Result.success(response);
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> create{{name.pascalCase()}}(Map<String, dynamic> data) async {
    try {
      final response = await _api.create{{name.pascalCase()}}(data);
      return Result.success(response);
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> update{{name.pascalCase()}}(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.update{{name.pascalCase()}}(id, data);
      return Result.success(response);
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete{{name.pascalCase()}}(String id) async {
    try {
      await _api.delete{{name.pascalCase()}}(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(UnknownException(e.toString()));
    }
  }
}

// Domain Repository 接口声明（在 domain 包中）
abstract class {{name.pascalCase()}}Repository {
  Future<Result<List<dynamic>>> get{{name.pascalCase()}}List();
  Future<Result<Map<String, dynamic>>> get{{name.pascalCase()}}ById(String id);
  Future<Result<Map<String, dynamic>>> create{{name.pascalCase()}}(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> update{{name.pascalCase()}}(String id, Map<String, dynamic> data);
  Future<Result<void>> delete{{name.pascalCase()}}(String id);
}
```

---

### Task 11: 创建 API Brick - DI Setup

**Files:**
- Create: `bricks/api/__brick__/lib/src/di/setup.dart`

- [ ] **Step 1: 创建 DI Setup 模板**

创建 `bricks/api/__brick__/lib/src/di/setup.dart`：

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../api/{{name}}_api.dart';
import '../repository/{{name}}_repository_impl.dart';

/// 注册 {{name.pascalCase()}} API 模块的依赖注入
///
/// 职责：在 GetIt 中注册 API、Repository
/// 使用：在 app 启动时调用 setupApi{{name.pascalCase()}}(sl, baseUrl)
void setupApi{{name.pascalCase()}}(GetIt sl, String baseUrl) {
  // 注册 Dio（如果需要自定义配置）
  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton<Dio>(() => Dio());
  }

  // 注册 API
  sl.registerFactory<{{name.pascalCase()}}Api>(
    () => {{name.pascalCase()}}Api(sl<Dio>(), baseUrl: baseUrl),
  );

  // 注册 Repository
  sl.registerFactory<{{name.pascalCase()}}Repository>(
    () => {{name.pascalCase()}}RepositoryImpl(sl<{{name.pascalCase()}}Api>()),
  );
}
```

---

### Task 12: 创建 Model Brick - brick.yaml

**Files:**
- Create: `bricks/model/brick.yaml`
- Create: `bricks/model/__brick__/lib/src/models/`

- [ ] **Step 1: 创建 Model brick 目录和配置**

```bash
mkdir -p bricks/model/__brick__/lib/src/models
```

创建 `bricks/model/brick.yaml`：

```yaml
name: model
description: 一键创建 @freezed 数据模型（自动 JSON 序列化）
version: 1.0.0
vars:
  name:
    type: string
    description: Model 名称（蛇形命名，如 'user_profile'）
    prompt: Model 名称是什么？
```

---

### Task 13: 创建 Model Brick - @freezed 模型模板

**Files:**
- Create: `bricks/model/__brick__/lib/src/models/{{name}}.dart`

- [ ] **Step 1: 创建 @freezed 模型模板**

创建 `bricks/model/__brick__/lib/src/models/{{name}}.dart`：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name}}.freezed.dart';
part '{{name}}.g.dart';

/// {{name.pascalCase()}} 模型
///
/// 职责：定义 {{name.pascalCase()}} 数据结构
/// 使用：API 响应转换、业务层数据传输
/// 特性：@freezed 提供 copyWith、==、toString、fromJson/toJson
/// 生成：运行 dart run build_runner build 自动生成 .freezed.dart 和 .g.dart
@freezed
class {{name.pascalCase()}} with _${{name.pascalCase()}} {
  const factory {{name.pascalCase()}}({
    required String id,
    required String name,
    @Default('') String description,
    @Default(DateTime.now()) DateTime createdAt,
    DateTime? updatedAt,
  }) = __{{name.pascalCase()}};

  factory {{name.pascalCase()}}.fromJson(Map<String, dynamic> json) =>
      _${{name.pascalCase()}}FromJson(json);
}
```

- [ ] **Step 2: 创建模型的示例用法注释**

在模板中添加注释说明如何添加字段

---

### Task 14: 创建 HiveModel Brick - brick.yaml

**Files:**
- Create: `bricks/hive_model/brick.yaml`
- Create: `bricks/hive_model/__brick__/lib/src/models/`
- Create: `bricks/hive_model/__brick__/lib/src/migrations/`

- [ ] **Step 1: 创建 HiveModel brick 目录和配置**

```bash
mkdir -p bricks/hive_model/__brick__/lib/src/models
mkdir -p bricks/hive_model/__brick__/lib/src/migrations
```

创建 `bricks/hive_model/brick.yaml`：

```yaml
name: hive_model
description: 一键创建 @HiveType 本地存储模型（含 Adapter、Migration 骨架）
version: 1.0.0
vars:
  name:
    type: string
    description: Model 名称（蛇形命名，如 'user_settings'）
    prompt: Model 名称是什么？
  typeId:
    type: number
    description: Hive Type ID（0-255）
    prompt: Type ID 是什么？（建议 50-100 避免冲突）
```

---

### Task 15: 创建 HiveModel Brick - @HiveType 模型模板

**Files:**
- Create: `bricks/hive_model/__brick__/lib/src/models/{{name}}.dart`

- [ ] **Step 1: 创建 @HiveType 模型模板**

创建 `bricks/hive_model/__brick__/lib/src/models/{{name}}.dart`：

```dart
import 'package:hive/hive.dart';

part '{{name}}.g.dart';

/// {{name.pascalCase()}} Hive 模型
///
/// 职责：定义 {{name.pascalCase()}} 本地存储结构
/// 使用：KeyValueStorage 存取、离线数据缓存
/// 生成：运行 dart run build_runner build 自动生成 .g.dart
/// 注意：修改字段后需要更新 typeId 或创建 Migration
@HiveType(typeId: {{typeId}})
class {{name.pascalCase()}} extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? updatedAt;

  {{name.pascalCase()}}({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  /// 创建副本（支持不可变修改）
  {{name.pascalCase()}} copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {{name.pascalCase()}}(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 转换为 Map（用于 JSON 序列化）
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// 从 Map 创建（用于 JSON 反序列化）
  factory {{name.pascalCase()}}.fromJson(Map<String, dynamic> json) {
    return {{name.pascalCase()}}(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
```

---

### Task 16: 创建 HiveModel Brick - Migration 骨架

**Files:**
- Create: `bricks/hive_model/__brick__/lib/src/migrations/{{name}}_migration.dart`

- [ ] **Step 1: 创建 Migration 骨架模板**

创建 `bricks/hive_model/__brick__/lib/src/migrations/{{name}}_migration.dart`：

```dart
import 'package:hive/hive.dart';
import '../models/{{name}}.dart';

/// {{name.pascalCase()}} 数据迁移
///
/// 职责：处理 {{name.pascalCase()}} 模型的结构变更
/// 使用：在 App 启动时调用 migrate{{name.pascalCase()}}()
///
/// 迁移策略：
/// 1. 读取旧版本数据
/// 2. 转换为新版本结构
/// 3. 写入新版本数据
/// 4. 删除旧版本数据（如需要）
///
/// 重要：每次发布新版本前，需要创建对应的 Migration
class {{name.pascalCase()}}Migration {
  /// 执行迁移
  ///
  /// [oldVersion] 当前数据库版本
  /// [newVersion] 目标数据库版本
  static Future<void> migrate({
    required Box<{{name.pascalCase()}}> box,
    required int oldVersion,
    required int newVersion,
  }) async {
    // V1 -> V2: 添加 description 字段
    if (oldVersion < 2) {
      await _migrateV1ToV2(box);
    }

    // V2 -> V3: 添加 updatedAt 字段
    if (oldVersion < 3) {
      await _migrateV2ToV3(box);
    }
  }

  /// V1 -> V2 迁移
  static Future<void> _migrateV1ToV2(Box<{{name.pascalCase()}}> box) async {
    // V1 没有 description 字段，需要添加默认值
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item.description == null) {
        final updated = item.copyWith(description: '');
        await box.put(key, updated);
      }
    }
  }

  /// V2 -> V3 迁移
  static Future<void> _migrateV2ToV3(Box<{{name.pascalCase()}}> box) {
    // V3 添加 updatedAt 字段
    // 由于 copyWith 已经处理，直接返回即可
    // 如果有更复杂的逻辑，在这里实现
    return Future.value();
  }

  /// 获取当前数据版本
  ///
  /// 在实际项目中，建议使用单独的 box 存储版本号
  static int getCurrentVersion() {
    // TODO: 实现版本号读取逻辑
    // 例如：读取 preference 或单独的 metadata box
    return 3;
  }

  /// 设置数据版本
  static Future<void> setVersion(int version) async {
    // TODO: 实现版本号写入逻辑
  }
}
```

---

### Task 17: 更新 mason.yaml 注册所有 Bricks

**Files:**
- Modify: `mason.yaml`

- [ ] **Step 1: 更新 mason.yaml 添加新 bricks**

修改 `mason.yaml`：

```yaml
bricks:
  feature:
    path: bricks/feature
  api:
    path: bricks/api
  model:
    path: bricks/model
  hive_model:
    path: bricks/hive_model
```

- [ ] **Step 2: 验证 mason.yaml 语法**

```bash
mason get
# 应成功注册所有 4 个 bricks
```

---

### Task 18: 更新 makefile 添加新命令

**Files:**
- Modify: `makefile`

- [ ] **Step 1: 添加 create-api 命令**

在 makefile 中添加：

```makefile
create-api:
	@if [ -z "$(name)" ]; then \
		echo "用法: make create-api name=user baseUrl=/api/v1"; \
		exit 1; \
	fi
	@if [ -z "$(baseUrl)" ]; then \
		echo "错误: 请提供 baseUrl 参数"; \
		echo "用法: make create-api name=user baseUrl=/api/v1"; \
		exit 1; \
	fi
	@echo "=== 1/3 生成 API 模块 ==="
	mason make api --name $(name) --base-url $(baseUrl) --output-dir packages/apis/api_$(name)
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 生成 retrofit 代码 ==="
	cd packages/apis/api_$(name) && dart run build_runner build --delete-conflicting-outputs
	@echo ""
	@echo "=== ✅ 完成！后续手动步骤 ==="
	@echo "1. 在 domain 包添加 Repository 接口"
	@echo "2. 在 lib/core/di/setup.dart 调用 setupApiXxx(sl, baseUrl)"
```

- [ ] **Step 2: 添加 create-model 命令**

```makefile
create-model:
	@if [ -z "$(name)" ]; then \
		echo "用法: make create-model name=user_profile"; \
		exit 1; \
	fi
	@echo "=== 1/3 生成 Model ==="
	mason make model --name $(name) --output-dir packages/models/model_$(name)
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 生成 freezed 代码 ==="
	cd packages/models/model_$(name) && dart run build_runner build --delete-conflicting-outputs
	@echo ""
	@echo "=== ✅ 完成！"
```

- [ ] **Step 3: 添加 create-hive-model 命令**

```makefile
create-hive-model:
	@if [ -z "$(name)" ]; then \
		echo "用法: make create-hive-model name=user_settings typeId=50"; \
		exit 1; \
	fi
	@if [ -z "$(typeId)" ]; then \
		echo "错误: 请提供 typeId 参数（0-255）"; \
		echo "用法: make create-hive-model name=user_settings typeId=50"; \
		exit 1; \
	fi
	@echo "=== 1/3 生成 HiveModel ==="
	mason make hive_model --name $(name) --type-id $(typeId) --output-dir packages/models/hive_model_$(name)
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 生成 Hive Adapter 代码 ==="
	cd packages/models/hive_model_$(name) && dart run build_runner build --delete-conflicting-outputs
	@echo ""
	@echo "=== ✅ 完成！后续手动步骤 ==="
	@echo "1. 在 Hive 初始化时注册 Adapter"
	@echo "2. 在 lib/core/di/setup.dart 调用 Migration.migrate()"
```

- [ ] **Step 4: 验证 makefile 语法**

```bash
make -n create-api name=user baseUrl=/api/v1
make -n create-model name=test
make -n create-hive-model name=test typeId=50
# 应显示将要执行的命令，不实际运行
```

---

### Task 19: 全量验证

- [ ] **Step 1: 验证 mason 可以列出所有 bricks**

```bash
mason list
# 应显示：api, feature, hive_model, model
```

- [ ] **Step 2: 测试生成 feature brick（Result 模式）**

```bash
mason make feature --name test_result --output-dir /tmp/test_feature
# 检查生成的代码是否使用 Result<T>.when() 模式
head -50 /tmp/test_feature/lib/src/cubit/test_result_cubit.dart
```

- [ ] **Step 3: 测试生成 api brick**

```bash
mason make api --name user --base-url /api/v1 --output-dir /tmp/test_api
# 检查生成的代码是否包含 Retrofit 接口
ls /tmp/test_api/lib/src/api/
```

- [ ] **Step 4: 测试生成 model brick**

```bash
mason make model --name user_profile --output-dir /tmp/test_model
# 检查生成的代码是否包含 @freezed
head -20 /tmp/test_model/lib/src/models/user_profile.dart
```

- [ ] **Step 5: 测试生成 hive_model brick**

```bash
mason make hive_model --name settings --type-id 50 --output-dir /tmp/test_hive
# 检查生成的代码是否包含 @HiveType
head -20 /tmp/test_hive/lib/src/models/settings.dart
```

- [ ] **Step 6: 运行分析**

```bash
melos analyze
# 应零 error（mason 配置文件不参与分析）
```

---

### Task 20: 提交

**Files:**
- Modify: 多个文件（见 Task 1-19）

- [ ] **Step 1: 添加所有更改**

```bash
git add bricks/ mason.yaml makefile
```

- [ ] **Step 2: 提交更改**

```bash
git commit -m "feat: enhance feature brick with Result<T> pattern and add api/model/hive_model bricks

- Feature brick: Result<T> pattern (repository returns Result, cubit uses .when())
- Feature brick: Add route registration hint comments in page
- Feature brick: Update tests for Result pattern
- API brick: Generate Retrofit interface + RepositoryImpl + DI setup
- Model brick: Generate @freezed model with JSON serialization
- HiveModel brick: Generate @HiveType model + Migration skeleton
- mason.yaml: Register all 4 bricks
- makefile: Add create-api, create-model, create-hive-model commands"
```

---

## 执行方式

**Plan complete and saved to `docs/superpowers/plans/2026-05-08-cli-mason-bricks.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
