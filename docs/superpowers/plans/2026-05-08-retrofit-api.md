# P0-2: API Integration - Retrofit Code Generation

**Plan Date:** 2026-05-08  
**Owner:** Infrastructure Team  
**Priority:** P0-2  
**Status:** Ready for Implementation  
**Dependencies:** None (can be implemented independently or after P1-1 Result pattern)

---

## 1. Overview

This plan adds Retrofit code generation to the Flutter scaffold project's API layer. Retrofit is a **code-generation layer ON TOP of Dio**, not a replacement. The goal is to:

1. Add Retrofit dependencies to the API package
2. Create type-safe Retrofit API interfaces for each business domain
3. Migrate RepositoryImpl files to use Retrofit-generated API classes
4. Deprecate `ApiEndpoints` class (keep `ApiBase.tokenRenewal` for infrastructure)
5. Preserve the existing interceptor chain (AutoCancel → TokenRenewal → AuthHeader → Log)

**Key Principle:** All existing interceptors from `createDio()` are preserved. Retrofit reuses the same Dio instance.

---

## 2. Current State

### ApiEndpoints Business Domains (5 groups + 1 shared)

| Group | Accessor | Paths |
|-------|----------|-------|
| `_Home` | `ApiEndpoints.home` | `data` → `/home/data` |
| `_Detail` | `ApiEndpoints.detail` | `item(String id)` → `/detail/$id` |
| `_Auth` | `ApiEndpoints.auth` | `login` → `/User/Login/Password`, `register` → `/User/Register`, `profile(username)` → `/User/$username`, `forgotPassword` → `/User/forgot_password` |
| `_Session` | `ApiEndpoints.session` | `signIn` → `/session`, `signOut` → `/session` |
| `_Vehicle` | `ApiEndpoints.vehicle` | `list` → `/Vehicle/List`, `detail` → `/Vehicle/Detail/Info`, `ranking` → `/Vehicle/Ranking/Query/Top/Info` |
| `ApiBase` | `ApiEndpoints.tokenRenewal` | `/User/Token/Renewal` (shared infrastructure) |

### RepositoryImpl Files Using Dio + ApiEndpoints

| RepositoryImpl | Package | Current Pattern |
|---------------|---------|-----------------|
| `HomeRepositoryImpl` | `feature_home` | `Dio.get(ApiEndpoints.home.data)` + ListCacheManager |
| `DetailRepositoryImpl` | `feature_detail` | `Dio.get(ApiEndpoints.detail.item(id))` |
| `AuthRepositoryImpl` | `services/auth` | Hardcoded `/api/user/me`, `/api/user/profile` |

### Interceptor Chain (Preserved)

```
Request Direction:
[0] AutoCancelInterceptor     → Generates CancelToken from page tag
[1] TokenRenewalInterceptor    → Detects code=1000102, performs token renewal
[2] InterceptorsWrapper        → Injects Authorization header
[3] LogInterceptor             → Logs request/response (Debug only)
```

---

## 3. Implementation Tasks

### Task 1: Add Retrofit Dependencies to API Package

**File:** `packages/infrastructure/api/pubspec.yaml`

Add the following dependencies:

```yaml
dependencies:
  # ... existing dependencies ...
  retrofit: ^4.1.0
  dio: ^5.2.0+1

dev_dependencies:
  # ... existing dev dependencies ...
  retrofit_generator: ^8.1.0
  build_runner: ^2.4.9
  json_serializable: ^6.7.1
```

**Verification:** Run `make get` to install dependencies.

---

### Task 2: Create API Constants File (Token Renewal Path)

**File:** `packages/infrastructure/api/lib/src/constants/api_constants.dart`

```dart
/// API 常量（基础设施级别，不属于业务域）
///
/// Token Renewal 路径保留在这里，因为它是基础设施共享端点，
/// 不属于任何业务域的 Retrofit 接口。
library;

abstract final class ApiConstants {
  /// Token 续期路径（基础设施共享端点）
  static const String tokenRenewal = '/User/Token/Renewal';
}
```

---

### Task 3: Create Home API Interface

**File:** `packages/infrastructure/api/lib/src/api/home_api.dart`

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'home_api.g.dart';

/// 首页业务域 API 接口
///
/// 使用 @RestApi(baseUrl: '') 让运行时使用 dio.options.baseUrl
/// 路径定义在注解中：@GET('/home/data')
@RestApi(baseUrl: '')
abstract class HomeApi {
  /// 创建 HomeApi 实例
  ///
  /// [dio] 必须是已经配置好拦截器的 Dio 实例
  /// （包含 AutoCancelInterceptor, TokenRenewalInterceptor, 
  ///  Authorization header injection, LogInterceptor）
  factory HomeApi(Dio dio) = _HomeApi;

  /// 获取首页数据
  @GET('/home/data')
  Future<Map<String, dynamic>> getHomeData();
}
```

---

### Task 4: Create Detail API Interface

**File:** `packages/infrastructure/api/lib/src/api/detail_api.dart`

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'detail_api.g.dart';

/// 详情页业务域 API 接口
@RestApi(baseUrl: '')
abstract class DetailApi {
  factory DetailApi(Dio dio) = _DetailApi;

  /// 获取详情数据
  ///
  /// [id] 详情项 ID
  @GET('/detail/{id}')
  Future<Map<String, dynamic>> getDetailData(@Path('id') String id);
}
```

---

### Task 5: Create Auth API Interface

**File:** `packages/infrastructure/api/lib/src/api/auth_api.dart`

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

/// 认证业务域 API 接口
@RestApi(baseUrl: '')
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  /// 用户登录
  @POST('/User/Login/Password')
  Future<Map<String, dynamic>> login(@Body() Map<String, dynamic> body);

  /// 用户注册
  @POST('/User/Register')
  Future<Map<String, dynamic>> register(@Body() Map<String, dynamic> body);

  /// 获取用户资料
  @GET('/User/{username}')
  Future<Map<String, dynamic>> getProfile(@Path('username') String username);

  /// 忘记密码
  @POST('/User/forgot_password')
  Future<Map<String, dynamic>> forgotPassword(@Body() Map<String, dynamic> body);
}
```

---

### Task 6: Create Session API Interface

**File:** `packages/infrastructure/api/lib/src/api/session_api.dart`

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'session_api.g.dart';

/// Session 业务域 API 接口
@RestApi(baseUrl: '')
abstract class SessionApi {
  factory SessionApi(Dio dio) = _SessionApi;

  /// 签到（Session 登录）
  @POST('/session')
  Future<Map<String, dynamic>> signIn(@Body() Map<String, dynamic> body);

  /// 签退（Session 登出）
  @DELETE('/session')
  Future<Map<String, dynamic>> signOut();
}
```

---

### Task 7: Create Vehicle API Interface

**File:** `packages/infrastructure/api/lib/src/api/vehicle_api.dart`

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'vehicle_api.g.dart';

/// 车辆业务域 API 接口
@RestApi(baseUrl: '')
abstract class VehicleApi {
  factory VehicleApi(Dio dio) = _VehicleApi;

  /// 获取车辆列表
  @GET('/Vehicle/List')
  Future<Map<String, dynamic>> getVehicleList();

  /// 获取车辆详情
  @GET('/Vehicle/Detail/Info')
  Future<Map<String, dynamic>> getVehicleDetail();

  /// 获取车辆排行榜
  @GET('/Vehicle/Ranking/Query/Top/Info')
  Future<Map<String, dynamic>> getVehicleRanking();
}
```

---

### Task 8: Run Retrofit Code Generation

```bash
cd packages/infrastructure/api
dart run build_runner build --delete-conflicting-outputs
```

This generates the following files:
- `lib/src/api/home_api.g.dart`
- `lib/src/api/detail_api.g.dart`
- `lib/src/api/auth_api.g.dart`
- `lib/src/api/session_api.g.dart`
- `lib/src/api/vehicle_api.g.dart`

---

### Task 9: Update API Export File

**File:** `packages/infrastructure/api/lib/api.dart`

Add exports for the new API files (keep existing exports):

```dart
/// API 基础设施包
///
/// 提供 Dio 工厂函数和标准拦截器，不含业务 API 方法。
/// 业务 API 调用由各 RepositoryImpl 直接使用 Dio 完成。
export 'src/dio_factory.dart';
export 'src/http/http_event_bus.dart';
export 'src/http/http_constant.dart';
export 'src/http/token_supplier.dart';
// Phase 2新增：错误处理
export 'src/error/dio_mapper.dart';
// Phase 3.1新增：请求取消管理
export 'src/cancel/cancel_manager.dart';
export 'src/cancel/auto_cancel_interceptor.dart';
export 'src/dio/renewal_token_intercaptor.dart';  // Phase x: Token 续期拦截器
// Phase 3d新增：日志接口
export 'src/http/app_logger.dart';
export 'src/endpoints/api_endpoints.dart';
// P0-2: Retrofit 新增
export 'src/constants/api_constants.dart';
export 'src/api/home_api.dart';
export 'src/api/detail_api.dart';
export 'src/api/auth_api.dart';
export 'src/api/session_api.dart';
export 'src/api/vehicle_api.dart';
```

---

### Task 10: Deprecate ApiEndpoints Class

**File:** `packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart`

Add deprecation notice while keeping `ApiBase` for `tokenRenewal` path:

```dart
/// API 端点注册表
///
/// ⚠️ 已弃用：请使用 Retrofit API 接口替代
///
/// 原有的静态端点常量已迁移到对应的 @RestApi 接口：
/// - ApiEndpoints.home → HomeApi.getHomeData()
/// - ApiEndpoints.detail → DetailApi.getDetailData(id)
/// - ApiEndpoints.auth → AuthApi.login(), AuthApi.register() 等
/// - ApiEndpoints.session → SessionApi.signIn(), SessionApi.signOut()
/// - ApiEndpoints.vehicle → VehicleApi.getVehicleList() 等
///
/// 保留 ApiBase.tokenRenewal 因为它是基础设施端点（非业务域）。
///
/// 迁移示例：
/// ```dart
/// // Before
/// final response = await _dio.get(ApiEndpoints.home.data);
/// 
/// // After
/// final homeApi = HomeApi(_dio);  // _dio 已在 DI 中配置好拦截器
/// final response = await homeApi.getHomeData();
/// ```
@Deprecated('Use Retrofit API interfaces instead. See migration guide above.')
abstract final class ApiEndpoints {
  // ... existing code remains but marked deprecated ...
}

/// 基础配置（保留）
///
/// ⚠️ tokenRenewal 路径保留在 ApiBase，因为它是基础设施共享端点，
/// 不属于任何业务域的 Retrofit 接口。
abstract final class ApiBase {
  /// 基础 URL（引用 HttpConstant 的环境感知逻辑）
  static String get baseUrl =>
      'http${HttpConstant.IsRelease ? 's' : ''}://${HttpConstant.Http_Host}';

  /// Token 续期路径（基础设施共享端点，不属于任何业务域）
  @Deprecated('Use ApiConstants.tokenRenewal instead')
  static const String tokenRenewal = '/User/Token/Renewal';
}
```

---

### Task 11: Migrate HomeRepositoryImpl

**File:** `packages/features/feature_home/lib/src/repository/home_repository_impl.dart`

```dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:list_cache/list_cache.dart';

/// 首页数据仓库实现
///
/// 职责：从API获取首页数据，处理异常转换，使用缓存优先策略
/// 使用：通过DI获取 `sl<HomeRepository>()`
/// 异常处理：DioException转换为DomainException
/// 缓存策略：staleWhileRevalidate（先缓存后网络，后台静默刷新）
/// 
/// P0-2 迁移：使用 HomeApi 替代直接 Dio 调用
class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;
  final ListCacheManager<Map<String, dynamic>> _cacheManager;
  late final HomeApi _homeApi;

  HomeRepositoryImpl(this._dio)
      : _cacheManager = ListCacheManager<Map<String, dynamic>>(
          config: CacheConfig.staleWhileRevalidate(pageSize: 20),
        ) {
    // P0-2: 使用同一个 Dio 实例，Retrofit 会继承所有拦截器
    _homeApi = HomeApi(_dio);
  }

  @override
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final result = await _cacheManager.fetch(
        cacheKey: 'home_data',
        page: 1,
        networkFetcher: () async {
          // P0-2: 使用 Retrofit 生成的 HomeApi
          final response = await _homeApi.getHomeData();
          return [response];
        },
      );
      if (result.data.isNotEmpty) {
        return result.data.first;
      }
      return {};
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }

  @override
  Future<Map<String, dynamic>> refreshHomeData() async {
    await _cacheManager.clear('home_data');
    return getHomeData();
  }

  /// 清空首页缓存
  Future<void> clearCache() => _cacheManager.clear('home_data');
}
```

---

### Task 12: Migrate DetailRepositoryImpl

**File:** `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart`

```dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';

/// 详情数据仓库实现
///
/// 职责：从API获取详情数据
/// 
/// P0-2 迁移：使用 DetailApi 替代直接 Dio 调用
class DetailRepositoryImpl implements DetailRepository {
  final Dio _dio;
  late final DetailApi _detailApi;

  DetailRepositoryImpl(this._dio) {
    // P0-2: 使用同一个 Dio 实例，Retrofit 会继承所有拦截器
    _detailApi = DetailApi(_dio);
  }

  @override
  Future<Map<String, dynamic>> getDetailData(String id) async {
    try {
      // P0-2: 使用 Retrofit 生成的 DetailApi
      final response = await _detailApi.getDetailData(id);
      return response;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }
}
```

---

### Task 13: Migrate AuthRepositoryImpl

**File:** `packages/services/auth/lib/src/repository/auth_repository_impl.dart`

```dart
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

/// UserRepository 的远程实现
///
/// 通过 Dio 访问后端 API，将 DioException 映射为 DomainException。
/// 
/// P0-2 迁移：使用 AuthApi 替代硬编码路径
class AuthRepositoryImpl implements UserRepository {
  final Dio _dio;
  late final AuthApi _authApi;

  AuthRepositoryImpl(this._dio) {
    // P0-2: 使用同一个 Dio 实例，Retrofit 会继承所有拦截器
    _authApi = AuthApi(_dio);
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      // P0-2: 从硬编码 '/api/user/me' 迁移到 AuthApi
      // 注意：AuthApi 使用 @GET('/User/{username}')，需要传入 username
      // 这里需要从 TokenStorage 或其他方式获取当前用户名
      // 假设已有方式获取用户名，或使用固定端点
      final response = await _dio.get('/api/user/me'); // TODO: 迁移到 AuthApi
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> updateProfile(ProfileData data) async {
    try {
      // P0-2: 从硬编码 '/api/user/profile' 迁移到 AuthApi
      await _dio.put('/api/user/profile', data: {
        if (data.name != null) 'name': data.name,
        if (data.avatar != null) 'avatar': data.avatar,
        if (data.email != null) 'email': data.email,
      });
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// 将 DioException 映射为 DomainException
  DomainException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return const UnauthorizedException();
    if (statusCode == 404) return const NotFoundException();
    if (statusCode == 422) {
      final errors = (e.response?.data as Map<String, dynamic>?)?['errors'];
      return ValidationException(
        '表单验证失败',
        fieldErrors: errors != null
            ? Map<String, String>.from(errors)
            : const {},
      );
    }
    return NetworkException(
      e.message ?? '网络请求失败',
      statusCode: statusCode,
    );
  }
}
```

**Note:** The `auth_repository_impl.dart` currently uses hardcoded paths (`/api/user/me`, `/api/user/profile`) that don't match the ApiEndpoints patterns. These should be reviewed against the actual backend API and migrated appropriately. The migration above preserves the current behavior for now.

---

## 4. Verification Steps

### Step 4.1: Dependencies Installation

```bash
make get
```

**Expected:** All packages install without errors.

### Step 4.2: Code Generation

```bash
cd packages/infrastructure/api
dart run build_runner build --delete-conflicting-outputs
```

**Expected:** Generate `.g.dart` files for all API interfaces.

### Step 4.3: Analysis

```bash
make lint
```

**Expected:** No errors in the modified packages.

### Step 4.4: Tests

```bash
make test
```

**Expected:** All tests pass.

---

## 5. DI Registration (If Needed)

If additional DI registration is needed for Retrofit API classes, update the DI setup:

**File:** `lib/core/di/setup.dart`

```dart
// P0-2: No additional DI registration needed
// Retrofit API classes are created in RepositoryImpl constructors:
//   _homeApi = HomeApi(_dio);
// The same Dio instance (with all interceptors) is reused.
```

---

## 6. Rollout Strategy

### Option A: Big Bang (All at Once)

1. Complete all tasks
2. Run full test suite
3. Deploy

### Option B: Incremental (Recommended)

1. Add Retrofit dependencies + create API interfaces
2. Run code generation
3. Test one RepositoryImpl (e.g., HomeRepositoryImpl)
4. Deploy partial: HomeRepositoryImpl uses Retrofit
5. Continue with next RepositoryImpl
6. Full deprecation of ApiEndpoints in a follow-up PR

**Recommendation:** Option B - Migrate one RepositoryImpl at a time for easier rollback.

---

## 7. Post-Migration

After full migration:

1. **Remove** `@Deprecated` annotations after team migrates all usages (in a follow-up PR)
2. **Update** documentation: Replace `ApiEndpoints` examples with Retrofit examples
3. **Consider** adding more type-safe request/response models (future enhancement)

---

## 8. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `@RestApi(baseUrl: '')` | Runtime uses `dio.options.baseUrl`, matches current `ApiBase.baseUrl` behavior |
| Reuse same Dio instance | Preserves all 4 interceptors: AutoCancel → TokenRenewal → AuthHeader → Log |
| Keep `ApiBase.tokenRenewal` in constants | Infrastructure endpoint, not business domain |
| Factory constructor `factory HomeApi(Dio dio) = _HomeApi` | Standard Retrofit pattern, allows runtime injection |
| Deprecate ApiEndpoints, keep code | Allows gradual migration, easy rollback |

---

## 9. Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Breaking existing functionality | Keep old code alongside new, test thoroughly |
| Interceptor chain broken | Verify Dio instance is the same one from `createDio()` |
| Build time increase | Only run code generation when API interfaces change |
| Team adoption | Provide migration examples, incremental rollout |

---

## 10. Dependencies on Other Plans

| Plan | Relationship |
|------|--------------|
| P1-1 (Result\<T\> pattern) | Independent - can deploy before or after |
| P2-x (Future enhancements) | Post-migration - add type-safe models |

**Note:** When P1-1 is implemented, simply change return types from `Future<T>` to `Future<Result<T, DomainException>>` and add `.toResult()` to Retrofit calls.
