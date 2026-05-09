# API 自动生成设计文档

> **日期**: 2026-05-09  
> **范围**: 从 JSON 规范文件自动生成 Retrofit API 接口 + Freezed DTO + Hive 持久化模型  
> **方案**: 增强 Mason brick（方案 C），零新依赖，完全控制输出

---

## 1. 目标与范围

### 1.1 要解决的问题

| # | 痛点 | 当前 | 目标 |
|---|------|------|------|
| 1 | 手写端点路径 | 人肉敲 `@GET('/User/Profile')` | JSON spec → 自动生成 |
| 2 | 手写数据模型 | `Map<String, dynamic>` + 手写 `fromJson`/`toJson` | 强类型 DTO，编译期安全 |
| 3 | 模型重复定义 | DTO 和 HiveObject 分开发，容易不同步 | 一份 JSON 同时产出 DTO + CM |

### 1.2 范围

- **IN**: JSON spec → Retrofit 接口 + Freezed DTO + Hive 持久化模型（CM）+ barrel 追加
- **OUT**: RepositoryImpl 生成（含业务逻辑）、DI setup 生成（已足够简单）、OpenAPI 标准格式（不需要）
- **迁移**: 现有 5 个手写 API 文件（auth/home/detail/session/vehicle）全部迁移

---

## 2. JSON Spec 格式

### 2.1 完整示例

```jsonc
// packages/infrastructure/api/spec/auth.json
{
  "domain": "auth",
  "basePath": "/User",
  "models": {
    "LoginRequest": {
      "username": "String",
      "password": "String"
    },
    "LoginResponse": {
      "token": "String",
      "userId": "String",
      "username": "String"
    },
    "UserProfile": {
      "name": "String",
      "email": "String",
      "avatar": "String?",
      "hive": true,
      "hiveTypeId": 10
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
      "name": "getProfile",
      "method": "GET",
      "path": "/{username}",
      "params": { "username": "String" },
      "response": "UserProfile"
    }
  ]
}
```

### 2.2 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `domain` | string | ✅ | 业务域名，决定 Retrofit 接口类名 `{Domain}Api` |
| `basePath` | string | ✅ | HTTP 基础路径，拼接在 endpoint path 前 |
| `models` | object | ✅ | 数据模型定义，key 为模型名（PascalCase） |
| `models.{name}.hive` | bool | ❌ | `true` 时额外生成 CM 持久化模型 |
| `models.{name}.hiveTypeId` | int | ❌ | Hive TypeId，`hive:true` 时必填 |
| `endpoints` | array | ✅ | API 端点列表 |
| `endpoints[].name` | string | ✅ | 方法名（camelCase） |
| `endpoints[].method` | enum | ✅ | HTTP 方法: GET / POST / PUT / DELETE / PATCH |
| `endpoints[].path` | string | ✅ | 端点路径，支持 `{paramName}` 路径参数 |
| `endpoints[].body` | string | ❌ | 请求体模型名，引用 `models` 中的定义 |
| `endpoints[].params` | object | ❌ | 路径参数，key=参数名, value=类型 |
| `endpoints[].response` | string | ✅ | 响应模型名，引用 `models` 中的定义 |

### 2.3 支持的类型

| 类型 | Dart 映射 | 说明 |
|------|----------|------|
| `String` | `String` | 字符串 |
| `int` | `int` | 整数 |
| `double` | `double` | 浮点数 |
| `bool` | `bool` | 布尔值 |
| `T?` | `T?` | 可选字段（可空） |

> 暂不支持 `List<T>`、嵌套模型、`DateTime`。后续按需扩展。

---

## 3. 命名约定

| 角色 | 命名 | 示例 | 文件 |
|------|------|------|------|
| **API DTO** | 原名 | `UserProfile` | `user_profile.dart` |
| **持久化模型** | 原名 + `CM` | `UserProfileCM` | `user_profile.cm.dart` |
| **Retrofit 接口** | `{Domain}Api` | `AuthApi` | `auth_api.dart` |
| **JSON spec 文件** | `{domain}.json` | `auth.json` | `spec/auth.json` |

---

## 4. 目录结构

### 4.1 输入（手写）

```
packages/infrastructure/api/spec/
├── auth.json
├── home.json
├── detail.json
├── session.json
└── vehicle.json
```

### 4.2 输出（生成）

```
packages/infrastructure/api/lib/src/
├── models/                           # API DTO（全部生成）
│   ├── login_request.dart
│   ├── login_request.freezed.dart
│   ├── login_request.g.dart
│   ├── login_response.dart
│   ├── login_response.freezed.dart
│   ├── login_response.g.dart
│   ├── user_profile.dart
│   ├── user_profile.freezed.dart
│   ├── user_profile.g.dart
│   ├── user_profile.cm.dart          # hive:true 时生成
│   └── user_profile.cm.g.dart
│
└── api/                              # Retrofit 接口（覆盖）
    ├── auth_api.dart
    ├── auth_api.g.dart
    └── ...
```

### 4.3 Mason 砖块

```
bricks/
├── api/                    # 现有：单包创建
└── api_gen/                # 新增：从 JSON spec 批量生成
    ├── brick.yaml
    └── __brick__/
        ├── model.dart          # DTO 模板
        ├── model.cm.dart       # CM 持久化模板（hive:true 时）
        └── api.dart            # Retrofit 接口模板
```

---

## 5. 生成对照

### 5.1 DTO（model.dart 模板）

**输入** (`spec/auth.json` 中的 `UserProfile`)：
```json
{ "name": "String", "email": "String", "avatar": "String?" }
```

**输出** (`models/user_profile.dart`)：
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required String email,
    String? avatar,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

### 5.2 CM 持久化模型（model.cm.dart 模板）

**条件**: `"hive": true` 时生成。

**输出** (`models/user_profile.cm.dart`)：
```dart
import 'package:hive/hive.dart';
import 'package:api/src/models/user_profile.dart';

part 'user_profile.cm.g.dart';

@HiveType(typeId: 10)
class UserProfileCM extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String? avatar;

  UserProfile toDto() => UserProfile(
        name: name, email: email, avatar: avatar,
      );

  factory UserProfileCM.fromDto(UserProfile dto) => UserProfileCM()
    ..name = dto.name
    ..email = dto.email
    ..avatar = dto.avatar;
}
```

> **覆盖策略**: CM 文件首次生成后不再覆盖（`--on-conflict skip`），给开发者留修改空间。

### 5.3 Retrofit 接口（api.dart 模板）

**输出** (`api/auth_api.dart`)：
```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:api/src/models/login_request.dart';
import 'package:api/src/models/login_response.dart';
import 'package:api/src/models/user_profile.dart';

part 'auth_api.g.dart';

@RestApi(baseUrl: '')
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('/User/Login/Password')
  Future<LoginResponse> login(@Body() LoginRequest body);

  @GET('/User/{username}')
  Future<UserProfile> getProfile(@Path('username') String username);
}
```

> **覆盖策略**: Retrofit 接口文件每次都覆盖（`--on-conflict overwrite`），保证与 spec 一致。

---

## 6. 工作流

```
┌──────────────────────────────────────────────────────────┐
│ 1. 后端给了新的 Word 接口文档                                │
│    ↓                                                      │
│ 2. 开发者在 spec/{domain}.json 添加新 model + endpoint       │
│    ↓                                                      │
│ 3. make gen-api spec={domain}.json                        │
│    → 解析 JSON → 调用 mason make api_gen                   │
│    → 生成 model.dart / model.cm.dart / api.dart            │
│    → Barrel 自动追加 export                                │
│    → 更新 register.yaml（Hive TypeId）                     │
│    ↓                                                      │
│ 4. cd packages/infrastructure/api &&  \                   │
│    dart run build_runner build --delete-conflicting-outputs│
│    → 生成 .freezed.dart + .g.dart + .cm.g.dart             │
│    ↓                                                      │
│ 5. melos run validate  →  一切通过                          │
└──────────────────────────────────────────────────────────┘
```

### 6.1 Makefile 新增命令

```makefile
# 单文件生成
gen-api:
	@[ "${spec}" ] || ( echo "Usage: make gen-api spec=auth.json"; exit 1 )
	@echo "🚀 从 spec/${spec} 生成 API 代码..."
	dart run scripts/gen_api.dart --spec spec/${spec}

# 批量生成所有 spec
gen-all-apis:
	@for spec in packages/infrastructure/api/spec/*.json; do \
		dart run scripts/gen_api.dart --spec $$spec; \
	done
	@echo "✅ 所有 API spec 生成完成"

# 完整刷新: 生成 + build_runner + 校验
refresh-api:
	make gen-all-apis
	make get
	cd packages/infrastructure/api && dart run build_runner build --delete-conflicting-outputs
	melos run validate
```

### 6.2 gen_api.dart 脚本职责

1. 读取并解析 `spec/{domain}.json`
2. 遍历 `models`：为每个 model 调用 `mason make api_gen -c model.dart`
3. 如果 `hive: true`：调用 `mason make api_gen -c model.cm.dart`
4. 调用 `mason make api_gen -c api.dart`
5. 在 `api.dart` barrel 文件中追加 `export` 语句
6. 在 `register.yaml` 中注册新的 Hive TypeId

---

## 7. 现有 5 个 API 迁移策略

### 7.1 迁移顺序

| 顺序 | API | 端点数 | 模型数 | 理由 |
|------|-----|--------|--------|------|
| 1 | **auth** | 4 | 3 | 模型少、流程经典，最先验证 |
| 2 | **home** | 1 | 1 | 最简单 |
| 3 | **detail** | 1 | 1 | 最简单 |
| 4 | **session** | 2 | 1 | 无复杂嵌套 |
| 5 | **vehicle** | 3 | 2 | 列表响应可能嵌套，最后处理 |

### 7.2 每步操作

1. 写 `spec/{domain}.json`（对着现有手写文件翻译）
2. `make gen-api spec={domain}.json`
3. `dart run build_runner build --delete-conflicting-outputs`
4. 检查生成的 Retrofit 接口是否与手写原版一致
5. 更新对应的 RepositoryImpl（`Map` 访问 → 强类型属性访问）
6. `melos run validate` 通过

### 7.3 消费者改动示例

```dart
// ===== 之前 =====
final response = await _authApi.login(body);    // Map<String, dynamic>
final token = response['token'] as String;       // 手抠字段

// ===== 之后 =====
final response = await _authApi.login(body);     // LoginResponse
final token = response.token;                    // 编译期安全
```

---

## 8. 关键约束

| 约束 | 理由 |
|------|------|
| DTO 文件每次覆盖 | 保证与 spec 一致 |
| Retrofit 接口每次覆盖 | 保证与 spec 一致 |
| CM 文件首次生成后不覆盖 | 开发者可能添加自定义逻辑 |
| 不生成 RepositoryImpl | 包含业务逻辑，不适合模板 |
| 不生成 DI setup | 手动注册简单，生成反而过度 |
| 不生成 fromDto/toDto 实现细节 | 给开发者修改空间 |

---

## 9. 与现有系统的关系

| 组件 | 关系 |
|------|------|
| `bricks/api/`（现有 api 砖块） | **共存**。`api` 用于快速创建独立 API 包；`api_gen` 用于从 spec 批量生成 |
| `ApiEndpoints`（已 @Deprecated） | **不受影响**。Retrofit 接口直接定义端点 |
| `Result<T, E>` 模式 | **不受影响**。RepositoryImpl 中继续使用 `_api.xxx().toResult()` |
| `list_cache` | **不受影响**。RepositoryImpl 不变 |
| `DioFactory` / 拦截器链 | **不受影响**。Retrofit 使用同一个 Dio 实例 |
| `build_runner` | **增强**。新增 `api_gen` 砖块生成前置，`build_runner` 步骤不变 |

---

## 10. 后续扩展（暂不实现）

- 支持 `List<T>` 嵌套类型
- 支持模型嵌套（一个模型引用另一个）
- 支持 `DateTime` 类型
- 支持 Query 参数（`@Query`）
- 支持 `@Header` 自定义请求头
- 从现有 Retrofit 文件反向生成 JSON spec（迁移辅助工具）
