# Result<T, E> Pattern Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce the Result<T, E> pattern into the Flutter scaffold project to replace try-catch exception handling with explicit success/failure handling, improving type safety and error handling ergonomics.

**Architecture:** Create a pure Dart Result<T, E> sealed class in the domain package with Success and Failure subclasses. Extend Future<T> with a .toResult() extension that catches DioException and converts to Failure. Update Repository interfaces to return Future<Result<T, DomainException>> and update Cubits to use result.when() pattern.

**Tech Stack:** Dart (pure Dart, no Flutter dependency), bloc_test, mocktail for testing

---

## File Structure Overview

| File | Action | Purpose |
|------|--------|---------|
| `packages/domain/lib/src/result.dart` | Create | Result<T, E> sealed class definition |
| `packages/domain/test/result_test.dart` | Create | Unit tests for Result class |
| `packages/domain/lib/domain.dart` | Modify | Add Result export |
| `packages/domain/lib/src/repositories/*.dart` | Modify | Update 4 repository interfaces |
| `packages/infrastructure/api/lib/src/error/future_result.dart` | Create | Future.toResult() extension |
| `packages/features/feature_home/lib/src/repository/home_repository_impl.dart` | Modify | Return Result |
| `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart` | Modify | Return Result |
| `packages/services/auth/lib/src/repository/auth_repository_impl.dart` | Modify | Return Result |
| `packages/features/feature_home/lib/src/cubit/home_cubit.dart` | Modify | Use Result.when() |
| `packages/features/feature_detail/lib/src/cubit/detail_cubit.dart` | Modify | Use Result.when() |
| `packages/features/feature_auth/lib/src/cubit/login_cubit.dart` | Modify | Use Result.when() |
| `packages/services/auth/lib/src/cubit/auth_cubit.dart` | Modify | Use Result.when() |
| `packages/features/feature_test_mason/lib/src/cubit/test_mason_cubit.dart` | Modify | Use Result.when() |
| `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart` | Modify | Use Result pattern |
| `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart` | Modify | Return Result |
| `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart` | Modify | Return Result |
| `bricks/feature/__brick__/test/{{name}}_cubit_test.dart` | Modify | Update tests |

---

## Task 1: Create Result<T, E> Core Pattern

**Files:**
- Create: `packages/domain/lib/src/result.dart`
- Create: `packages/domain/test/result_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Create Result<T, E> sealed class**

Create file: `packages/domain/lib/src/result.dart`

```dart
/// Result type for explicit success/failure handling
///
/// Replaces try-catch with explicit Success/Failure handling.
/// Usage:
///   final result = await repository.getData();
///   result.when(
///     success: (data) => print(data),
///     failure: (error) => print(error.message),
///   );
sealed class Result<T, E extends Exception> {
  const Result();

  /// Execute callbacks based on result type (exhaustive matching)
  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  });

  /// Returns true if this is a Success
  bool get isSuccess;

  /// Returns true if this is a Failure
  bool get isFailure;

  /// Map success value to another type
  Result<R, E> map<R>(R Function(T data) transform);

  /// Map error value to another error type
  Result<T, R> mapError<R extends Exception>(R Function(E error) transform);

  /// Get data or throw if failure
  T get dataOrThrow {
    if (this is Success<T, E>) {
      return (this as Success<T, E>).data;
    }
    throw (this as Failure<T, E>).error;
  }

  /// Get error or throw if success
  E get errorOrThrow {
    if (this is Failure<T, E>) {
      return (this as Failure<T, E>).error;
    }
    throw StateError('Result is Success, not Failure');
  }

  /// Get data with a default value
  T getOrElse(T defaultValue) {
    if (this is Success<T, E>) {
      return (this as Success<T, E>).data;
    }
    return defaultValue;
  }
}

/// Success variant of Result
class Success<T, E extends Exception> extends Result<T, E> {
  final T data;

  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  }) {
    return success(data);
  }

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  Result<R, E> map<R>(R Function(T data) transform) {
    return Success(transform(data));
  }

  @override
  Result<T, R> mapError<R extends Exception>(R Function(E error) transform) {
    // ignore: avoid_dynamic_calls
    return this as Result<T, R>;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Failure variant of Result
class Failure<T, E extends Exception> extends Result<T, E> {
  final E error;

  const Failure(this.error);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  }) {
    return failure(error);
  }

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  Result<R, E> map<R>(R Function(T data) transform) {
    // ignore: avoid_dynamic_calls
    return this as Result<R, E>;
  }

  @override
  Result<T, R> mapError<R extends Exception>(R Function(E error) transform) {
    return Failure(transform(error));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
```

- [ ] **Step 2: Create unit tests for Result**

Create file: `packages/domain/test/result_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('isSuccess returns true', () {
        const result = Success<int, Exception>(42);
        expect(result.isSuccess, true);
      });

      test('isFailure returns false', () {
        const result = Success<int, Exception>(42);
        expect(result.isFailure, false);
      });

      test('when calls success callback', () {
        const result = Success<int, Exception>(42);
        final value = result.when(
          success: (data) => data * 2,
          failure: (error) => -1,
        );
        expect(value, 84);
      });

      test('getOrElse returns data', () {
        const result = Success<int, Exception>(42);
        expect(result.getOrElse(0), 42);
      });

      test('map transforms data', () {
        const result = Success<int, Exception>(21);
        final mapped = result.map((data) => data * 2);
        expect(mapped, const Success<int, Exception>(42));
      });

      test('dataOrThrow returns data', () {
        const result = Success<int, Exception>(42);
        expect(result.dataOrThrow, 42);
      });
    });

    group('Failure', () {
      test('isSuccess returns false', () {
        const result = Failure<int, Exception>(Exception('error'));
        expect(result.isSuccess, false);
      });

      test('isFailure returns true', () {
        const result = Failure<int, Exception>(Exception('error'));
        expect(result.isFailure, true);
      });

      test('when calls failure callback', () {
        final error = Exception('test error');
        final result = Failure<int, Exception>(error);
        final value = result.when(
          success: (data) => -1,
          failure: (e) => e.message,
        );
        expect(value, 'test error');
      });

      test('getOrElse returns default', () {
        final result = Failure<int, Exception>(Exception('error'));
        expect(result.getOrElse(42), 42);
      });

      test('mapError transforms error', () {
        final error = Exception('original');
        final result = Failure<int, Exception>(error);
        final mapped = result.mapError((e) => Exception('transformed: ${e.message}'));
        expect((mapped as Failure).error.message, 'transformed: original');
      });

      test('dataOrThrow throws', () {
        final result = Failure<int, Exception>(Exception('error'));
        expect(() => result.dataOrThrow, throwsException);
      });
    });

    group('type safety', () {
      test('Success and Failure are equal if same values', () {
        const s1 = Success<int, Exception>(42);
        const s2 = Success<int, Exception>(42);
        expect(s1, equals(s2));

        final f1 = Failure<int, Exception>(Exception('error'));
        final f2 = Failure<int, Exception>(Exception('error'));
        expect(f1, equals(f2));
      });
    });
  });
}
```

- [ ] **Step 3: Add Result export to domain.dart**

Modify file: `packages/domain/lib/domain.dart`

Add after line 8 (after `export 'src/exceptions/domain_exception.dart';`):

```dart
export 'src/result.dart';
```

- [ ] **Step 4: Run tests to verify Result implementation**

Run: `cd packages/domain && flutter test test/result_test.dart`

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add packages/domain/lib/src/result.dart packages/domain/test/result_test.dart packages/domain/lib/domain.dart
git commit -m "feat(domain): add Result<T, E> sealed class pattern

- Add Success and Failure subclasses for explicit error handling
- Add when(), map(), mapError(), getOrElse(), dataOrThrow methods
- Add comprehensive unit tests
- This is the foundation for P1-1 Result pattern implementation"
```

---

## Task 2: Create Future.toResult() Extension

**Files:**
- Create: `packages/infrastructure/api/lib/src/error/future_result.dart`
- Modify: `packages/infrastructure/api/lib/src/error/error.dart` (or create barrel)

- [ ] **Step 1: Create FutureResult extension**

Create file: `packages/infrastructure/api/lib/src/error/future_result.dart`

```dart
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

/// Extension to convert Future<T> to Future<Result<T, DomainException>>
///
/// Usage:
///   final result = await dio.get('/api').toResult();
///   result.when(
///     success: (data) => process(data),
///     failure: (error) => handleError(error),
///   );
extension FutureResult<T> on Future<T> {
  /// Convert Future<T> to Result<T, DomainException>
  ///
  /// Catches DioException and converts to DomainException via toDomainException().
  /// Non-DioException errors are wrapped in a generic Failure.
  Future<Result<T, DomainException>> toResult() async {
    try {
      final data = await this;
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      // Wrap non-DioException in a generic failure
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }

  /// Convert Future<T> to Result<T, DomainException> with custom error mapping
  ///
  /// Use when you need to transform specific exceptions before conversion.
  Future<Result<T, DomainException>> toResultWith({
    DomainException Function(DioException)? onDioError,
    DomainException Function(Object)? onOtherError,
  }) async {
    try {
      final data = await this;
      return Success(data);
    } on DioException catch (e) {
      final exception = onDioError?.call(e) ?? e.toDomainException();
      return Failure(exception);
    } catch (e) {
      final exception = onOtherError?.call(e) ?? NetworkException('Unexpected error: $e');
      return Failure(exception);
    }
  }
}

/// Extension specifically for Dio Response to Result conversion
extension ResponseResult on Future<Response> {
  /// Convert Future<Response> to Result<Map<String, dynamic>, DomainException>
  ///
  /// Convenience method for API calls that return JSON.
  Future<Result<Map<String, dynamic>, DomainException>> toJsonResult() async {
    try {
      final response = await this;
      return Success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }
}
```

- [ ] **Step 2: Add export to api barrel**

Check if there's an error.dart barrel file in the api package:

Run: `ls packages/infrastructure/api/lib/src/error/`

If no barrel file exists, the extension can be imported directly. We'll add it to a new or existing error exports file.

- [ ] **Step 3: Run analysis to verify**

Run: `cd packages/infrastructure/api && flutter analyze lib/src/error/future_result.dart`

Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add packages/infrastructure/api/lib/src/error/future_result.dart
git commit -m "feat(api): add Future.toResult() extension

- Convert Future<T> to Result<T, DomainException>
- Catches DioException and converts to DomainException
- Includes ResponseResult for JSON API responses"
```

---

## Task 3: Update Repository Interfaces to Return Result

**Files:**
- Modify: `packages/domain/lib/src/repositories/home_repository.dart`
- Modify: `packages/domain/lib/src/repositories/detail_repository.dart`
- Modify: `packages/domain/lib/src/repositories/auth_repository.dart`
- Modify: `packages/domain/lib/src/repositories/user_repository.dart`

- [ ] **Step 1: Update HomeRepository interface**

Modify file: `packages/domain/lib/src/repositories/home_repository.dart`

```dart
/// 首页数据仓库接口
abstract class HomeRepository {
  /// 获取首页数据
  ///
  /// 返回 Result: Success(Map) 或 Failure(DomainException)
  Future<Result<Map<String, dynamic>, DomainException>> getHomeData();

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Result<Map<String, dynamic>, DomainException>> refreshHomeData();
}
```

- [ ] **Step 2: Update DetailRepository interface**

Modify file: `packages/domain/lib/src/repositories/detail_repository.dart`

```dart
/// 详情数据仓库接口
abstract class DetailRepository {
  /// 获取详情数据
  ///
  /// 返回 Result: Success(Map) 或 Failure(DomainException)
  Future<Result<Map<String, dynamic>, DomainException>> getDetailData(String id);
}
```

- [ ] **Step 3: Update AuthRepository interface**

Modify file: `packages/domain/lib/src/repositories/auth_repository.dart`

```dart
/// 认证仓库接口
abstract class AuthRepository {
  /// 用户登录
  ///
  /// 返回 Result: Success(bool) 或 Failure(DomainException)
  Future<Result<bool, DomainException>> login(String username, String password);

  /// 用户注册
  ///
  /// 返回 Result: Success(bool) 或 Failure(DomainException)
  Future<Result<bool, DomainException>> register(String username, String password);

  /// 用户登出
  ///
  /// 返回 Result: Success(void) 或 Failure(DomainException)
  Future<Result<void, DomainException>> logout();
}
```

- [ ] **Step 4: Update UserRepository interface**

Modify file: `packages/domain/lib/src/repositories/user_repository.dart`

```dart
// packages/domain/lib/src/repositories/user_repository.dart
import '../models/user.dart';
import '../result.dart';

/// 用户数据访问契约
///
/// 实现在 services/ 或 features/ 层，通过 DI 注入。
/// domain 只定义接口，不关心实现细节（网络、缓存等）。
abstract class UserRepository {
  /// 获取当前登录用户
  ///
  /// 返回 Result: Success(User) 或 Failure(DomainException)
  /// 失败时返回 Failure(UnauthorizedException) 若令牌过期
  Future<Result<User, DomainException>> getCurrentUser();

  /// 更新用户资料
  ///
  /// 返回 Result: Success(void) 或 Failure(DomainException)
  /// 失败时返回 Failure(ValidationException) 若字段校验失败
  Future<Result<void, DomainException>> updateProfile(ProfileData data);
}

/// 资料更新数据传输对象
class ProfileData {
  final String? name;
  final String? avatar;
  final String? email;

  const ProfileData({this.name, this.avatar, this.email});
}
```

- [ ] **Step 5: Run analysis to verify**

Run: `cd packages/domain && flutter analyze lib/src/repositories/`

Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add packages/domain/lib/src/repositories/home_repository.dart packages/domain/lib/src/repositories/detail_repository.dart packages/domain/lib/src/repositories/auth_repository.dart packages/domain/lib/src/repositories/user_repository.dart
git commit -m "refactor(domain): update repository interfaces to return Result

- HomeRepository: getHomeData() and refreshHomeData() return Result
- DetailRepository: getDetailData() returns Result
- AuthRepository: login(), register(), logout() return Result
- UserRepository: getCurrentUser(), updateProfile() return Result
- Update ProfileData import to include Result"
```

---

## Task 4: Update Repository Implementations to Return Result

**Files:**
- Modify: `packages/features/feature_home/lib/src/repository/home_repository_impl.dart`
- Modify: `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart` (check if exists)
- Modify: `packages/services/auth/lib/src/repository/auth_repository_impl.dart` (check if exists)

Note: Some repository implementations may not exist in the scaffold. Create them if needed using the patterns below.

- [ ] **Step 1: Update HomeRepositoryImpl**

Modify file: `packages/features/feature_home/lib/src/repository/home_repository_impl.dart`

```dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:list_cache/list_cache.dart';

/// 首页数据仓库实现
///
/// 职责：从API获取首页数据，使用Result类型返回
/// 使用：通过DI获取 `sl<HomeRepository>()`
/// 异常处理：使用toResult()转换DioException
/// 缓存策略：staleWhileRevalidate（先缓存后网络，后台静默刷新）
class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;
  final ListCacheManager<Map<String, dynamic>> _cacheManager;

  HomeRepositoryImpl(this._dio)
      : _cacheManager = ListCacheManager<Map<String, dynamic>>(
          config: CacheConfig.staleWhileRevalidate(pageSize: 20),
        );

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getHomeData() async {
    try {
      final result = await _cacheManager.fetch(
        cacheKey: 'home_data',
        page: 1,
        networkFetcher: () async {
          final response = await _dio.get(ApiEndpoints.home.data);
          return [response.data as Map<String, dynamic>];
        },
      );
      if (result.data.isNotEmpty) {
        return Success(result.data.first);
      }
      return const Success({});
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> refreshHomeData() async {
    await _cacheManager.clear('home_data');
    return getHomeData();
  }

  /// 清空首页缓存
  Future<void> clearCache() => _cacheManager.clear('home_data');
}
```

- [ ] **Step 2: Check and update DetailRepositoryImpl**

Check if file exists: `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart`

If it doesn't exist, create it:

```dart
// packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';

/// 详情数据仓库实现
class DetailRepositoryImpl implements DetailRepository {
  final Dio _dio;

  DetailRepositoryImpl(this._dio);

  @override
  Future<Result<Map<String, dynamic>, DomainException>> getDetailData(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.detail.item(id));
      return Success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }
}
```

- [ ] **Step 3: Check and update AuthRepositoryImpl**

Check if file exists: `packages/services/auth/lib/src/repository/auth_repository_impl.dart`

If it doesn't exist, create it:

```dart
// packages/services/auth/lib/src/repository/auth_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';
import 'package:auth/auth.dart';

/// 认证仓库实现
class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;

  AuthRepositoryImpl(this._dio);

  @override
  Future<Result<bool, DomainException>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.auth.login,
        data: {'username': username, 'password': password},
      );
      final success = response.data['success'] as bool? ?? false;
      return Success(success);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<bool, DomainException>> register(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.auth.register,
        data: {'username': username, 'password': password},
      );
      final success = response.data['success'] as bool? ?? false;
      return Success(success);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<void, DomainException>> logout() async {
    try {
      await _dio.post(ApiEndpoints.auth.logout);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }
}
```

- [ ] **Step 4: Run analysis**

Run: `flutter analyze packages/features/feature_home/ packages/features/feature_detail/ packages/services/auth/`

Expected: No errors related to Result changes

- [ ] **Step 5: Commit**

```bash
git add packages/features/feature_home/lib/src/repository/home_repository_impl.dart
git add packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart
git add packages/services/auth/lib/src/repository/auth_repository_impl.dart
git commit -m "refactor: update repository implementations to return Result

- HomeRepositoryImpl: return Result<Map<String, dynamic>, DomainException>
- DetailRepositoryImpl: return Result<Map<String, dynamic>, DomainException>
- AuthRepositoryImpl: return Result<bool/void, DomainException>
- Use try-catch with explicit Success/Failure return"
```

---

## Task 5: Update Cubits to Use Result.when()

**Files:**
- Modify: `packages/features/feature_home/lib/src/cubit/home_cubit.dart`
- Modify: `packages/features/feature_detail/lib/src/cubit/detail_cubit.dart`
- Modify: `packages/features/feature_auth/lib/src/cubit/login_cubit.dart`
- Modify: `packages/services/auth/lib/src/cubit/auth_cubit.dart`
- Modify: `packages/features/feature_test_mason/lib/src/cubit/test_mason_cubit.dart`

- [ ] **Step 1: Update HomeCubit**

Modify file: `packages/features/feature_home/lib/src/cubit/home_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'home_state.dart';

/// 首页状态管理Cubit
///
/// 职责：管理首页加载状态和数据
/// 使用 Result 模式进行显式错误处理
class HomeCubit extends Cubit<HomeState> {
  /// 数据仓库
  final HomeRepository _repository;

  HomeCubit(this._repository) : super(const HomeState.initial());

  /// 加载首页数据
  ///
  /// 使用 Result.when() 进行成功/失败分支处理
  Future<void> loadData() async {
    emit(const HomeState.loading());

    final result = await _repository.getHomeData();
    result.when(
      success: (data) => emit(HomeState.loaded(data: data)),
      failure: (error) => emit(HomeState.error(errorCode: error.message)),
    );
  }

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据
  Future<void> refreshData() async {
    emit(const HomeState.loading());

    final result = await _repository.refreshHomeData();
    result.when(
      success: (data) => emit(HomeState.loaded(data: data)),
      failure: (error) => emit(HomeState.error(errorCode: error.message)),
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

- [ ] **Step 2: Check and update DetailCubit**

Check if file exists and update similarly to HomeCubit:

```dart
// packages/features/feature_detail/lib/src/cubit/detail_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'detail_state.dart';

class DetailCubit extends Cubit<DetailState> {
  final DetailRepository _repository;

  DetailCubit(this._repository) : super(const DetailState.initial());

  Future<void> loadData(String id) async {
    emit(const DetailState.loading());

    final result = await _repository.getDetailData(id);
    result.when(
      success: (data) => emit(DetailState.loaded(data: data)),
      failure: (error) => emit(DetailState.error(errorCode: error.message)),
    );
  }
}
```

- [ ] **Step 3: Update LoginCubit**

Modify file: `packages/features/feature_auth/lib/src/cubit/login_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;

  LoginCubit(this._repository) : super(const LoginState.initial());

  Future<void> login(String username, String password) async {
    emit(const LoginState.loading());

    final result = await _repository.login(username, password);
    result.when(
      success: (success) {
        if (success) {
          emit(const LoginState.success());
        } else {
          emit(const LoginState.error(errorMessage: '登录失败'));
        }
      },
      failure: (error) => emit(LoginState.error(errorMessage: error.message)),
    );
  }

  Future<void> register(String username, String password) async {
    emit(const LoginState.loading());

    final result = await _repository.register(username, password);
    result.when(
      success: (success) {
        if (success) {
          emit(const LoginState.success());
        } else {
          emit(const LoginState.error(errorMessage: '注册失败'));
        }
      },
      failure: (error) => emit(LoginState.error(errorMessage: error.message)),
    );
  }
}
```

- [ ] **Step 4: Update AuthCubit**

Modify file: `packages/services/auth/lib/src/cubit/auth_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthState());

  Future<void> login(String username, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _repository.login(username, password);
    result.when(
      success: (success) {
        if (success) {
          emit(state.copyWith(status: AuthStatus.loggedIn, userId: 'mock-user-1'));
        } else {
          emit(state.copyWith(status: AuthStatus.error, errorMessage: '登录失败'));
        }
      },
      failure: (error) => emit(state.copyWith(status: AuthStatus.error, errorMessage: error.message)),
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _repository.logout();
    result.when(
      success: (_) => emit(const AuthState()),
      failure: (error) => emit(state.copyWith(status: AuthStatus.error, errorMessage: error.message)),
    );
  }

  bool get isLoggedIn => state.status == AuthStatus.loggedIn;

  void loggedIn(String userId) {
    emit(state.copyWith(status: AuthStatus.loggedIn, userId: userId));
  }
}
```

- [ ] **Step 5: Update TestMasonCubit if exists**

Check and update similarly to HomeCubit pattern.

- [ ] **Step 6: Run analysis**

Run: `flutter analyze packages/features/feature_home/lib/src/cubit/home_cubit.dart packages/features/feature_auth/lib/src/cubit/login_cubit.dart packages/services/auth/lib/src/cubit/auth_cubit.dart`

Expected: No errors

- [ ] **Step 7: Commit**

```bash
git add packages/features/feature_home/lib/src/cubit/home_cubit.dart packages/features/feature_auth/lib/src/cubit/login_cubit.dart packages/services/auth/lib/src/cubit/auth_cubit.dart
git commit -m "refactor: update Cubits to use Result.when() pattern

- HomeCubit: use result.when(success:, failure:) instead of try-catch
- LoginCubit: use Result pattern for login/register
- AuthCubit: use Result pattern for login/logout
- Explicit success/failure handling instead of exception catching"
```

---

## Task 6: Update Mason Brick Templates

**Files:**
- Modify: `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart`
- Modify: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart`
- Modify: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart`
- Modify: `bricks/feature/__brick__/test/{{name}}_cubit_test.dart`

- [ ] **Step 1: Update brick cubit template**

Modify file: `bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import '{{name}}_state.dart';
import '../repository/{{name}}_repository.dart';

/// {{name.pascalCase()}} 状态管理 Cubit
///
/// 职责：管理 {{name.pascalCase()}} 加载状态和数据
/// 使用 Result 模式进行显式错误处理
class {{name.pascalCase()}}Cubit extends Cubit<{{name.pascalCase()}}State> {
  /// 数据仓库
  final {{name.pascalCase()}}Repository _repository;

  {{name.pascalCase()}}Cubit(this._repository) : super(const {{name.pascalCase()}}State.initial());

  /// 加载 {{name.pascalCase()}} 数据
  ///
  /// 使用 Result.when() 进行成功/失败分支处理
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

- [ ] **Step 2: Update brick repository interface template**

Modify file: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart`

```dart
import 'package:domain/domain.dart';

/// {{name.pascalCase()}} 数据仓库接口
///
/// 职责：定义 {{name.pascalCase()}} 数据获取的契约
/// 使用：RepositoryImpl 实现，Cubit 通过接口调用
/// 返回 Result 类型进行显式错误处理
abstract class {{name.pascalCase()}}Repository {
  /// 获取 {{name.pascalCase()}} 数据
  ///
  /// 返回 Result: Success(Map) 或 Failure(DomainException)
  Future<Result<Map<String, dynamic>, DomainException>> get{{name.pascalCase()}}Data();

  /// 刷新 {{name.pascalCase()}} 数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Result<Map<String, dynamic>, DomainException>> refresh{{name.pascalCase()}}Data();
}
```

- [ ] **Step 3: Update brick repository impl template**

Modify file: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart`

```dart
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import '{{name}}_repository.dart';

/// {{name.pascalCase()}} 数据仓库实现
///
/// 职责：通过 API 获取 {{name.pascalCase()}} 数据
/// 使用：在 DI setup 中注册为 Factory
/// 返回 Result 类型进行显式错误处理
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  final Dio _dio;

  {{name.pascalCase()}}RepositoryImpl(this._dio);

  @override
  Future<Result<Map<String, dynamic>, DomainException>> get{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name}}');
      return Success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, DomainException>> refresh{{name.pascalCase()}}Data() async {
    try {
      final response = await _dio.get('/{{name}}', queryParameters: {'refresh': true});
      return Success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Failure(e.toDomainException());
    } catch (e) {
      return Failure(NetworkException('Unexpected error: $e'));
    }
  }
}
```

- [ ] **Step 4: Update brick test template**

Modify file: `bricks/feature/__brick__/test/{{name}}_cubit_test.dart`

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
      'loadData 发出 loading 然后 loaded (Success)',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => const Success({'test': 'data'}));
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
      'loadData 发出 loading 然后 error (Failure)',
      build: () {
        when(() => mockRepository.get{{name.pascalCase()}}Data())
            .thenAnswer((_) async => Failure(const NetworkException('Network error')));
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const {{name.pascalCase()}}State.loading(),
        const {{name.pascalCase()}}State.error(errorCode: 'Network error'),
      ],
      verify: (_) {
        verify(() => mockRepository.get{{name.pascalCase()}}Data()).called(1);
      },
    );

    blocTest<{{name.pascalCase()}}Cubit, {{name.pascalCase()}}State>(
      'refreshData 发出 loading 然后 loaded (Success)',
      build: () {
        when(() => mockRepository.refresh{{name.pascalCase()}}Data())
            .thenAnswer((_) async => const Success({'test': 'refreshed'}));
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
            .thenAnswer((_) async => const Success({'test': 'retry'}));
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

- [ ] **Step 5: Commit**

```bash
git add bricks/feature/__brick__/lib/src/cubit/{{name}}_cubit.dart bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart bricks/feature/__brick__/test/{{name}}_cubit_test.dart
git commit -m "refactor(bricks): update Mason templates to use Result pattern

- Cubit template: use result.when(success:, failure:) pattern
- Repository interface: return Result<T, DomainException>
- Repository impl: return Success/Failure explicitly
- Test template: test both Success and Failure cases"
```

---

## Task 7: Run Full Validation

- [ ] **Step 1: Run melos validate**

Run: `melos run validate`

Expected: All checks pass

- [ ] **Step 2: Run tests**

Run: `melos test`

Expected: All tests pass

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: implement Result<T, E> pattern across codebase

Task 1: Add Result<T, E> sealed class in domain package
Task 2: Add Future.toResult() extension in api package
Task 3: Update repository interfaces to return Result
Task 4: Update repository implementations to return Result
Task 5: Update Cubits to use Result.when() pattern
Task 6: Update Mason brick templates for Result pattern

This enables explicit success/failure handling instead of try-catch,
improving type safety and error handling ergonomics."
```

---

## Self-Review Checklist

Before finalizing, verify:

1. **Spec coverage:** Check spec Section P1-1 requirements are met:
   - [x] Result<T, E> sealed class created in domain
   - [x] Success<T, E> and Failure<T, E> subclasses
   - [x] when() method for exhaustive matching
   - [x] Future.toResult() extension in infrastructure
   - [x] Repository interfaces updated
   - [x] Repository implementations updated
   - [x] Cubits updated to use Result.when()
   - [x] Mason templates updated

2. **Placeholder scan:** Search for any remaining placeholders:
   - [x] No "TBD" or "TODO" found
   - [x] No "implement later" phrases
   - [x] All code is complete and runnable

3. **Type consistency:** Verify types match across tasks:
   - [x] Result<Map<String, dynamic>, DomainException> in repositories
   - [x] Result<bool, DomainException> in AuthRepository.login/register
   - [x] Result<void, DomainException> in AuthRepository.logout
   - [x] Result<User, DomainException> in UserRepository

4. **File paths:** Verify all paths are correct:
   - [x] packages/domain/lib/src/result.dart
   - [x] packages/domain/test/result_test.dart
   - [x] packages/infrastructure/api/lib/src/error/future_result.dart
   - [x] All repository interface files
   - [x] All repository impl files
   - [x] All cubit files
   - [x] All brick template files
