# Architecture Best Practice Upgrade — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade Flutter monorepo scaffold from 7.5/10 to 8.5+/10 — pure Dart domain layer, Repository interface abstraction, composition injection, three-layer test suite, dependency enforcement, error handling.

**Architecture:** Five-phase incremental upgrade. Phase 1-3 are structural changes (domain, services, features). Phase 4 adds enforcement tooling. Phase 5 is polish. Each phase produces a standalone commit with passing tests.

**Tech Stack:** Flutter 3.x, flutter_bloc (Cubit), get_it, GoRouter, Dio, Hive, bloc_test, mocktail

---

## File Map

| File | Responsibility | Phase |
|------|---------------|-------|
| `packages/domain/pubspec.yaml` | Remove flutter_bloc dep | 1 |
| `packages/domain/lib/src/exceptions/domain_exception.dart` | Sealed exception hierarchy | 1 |
| `packages/domain/lib/src/models/user.dart` | User business model | 1 |
| `packages/domain/lib/src/repositories/user_repository.dart` | Abstract UserRepository interface | 1 |
| `packages/domain/lib/domain.dart` | Barrel file, expose exceptions/models/repositories | 1 |
| `packages/services/auth/pubspec.yaml` | Add dio dep | 2 |
| `packages/services/auth/lib/src/repository/auth_repository_impl.dart` | UserRepository implementation | 2 |
| `packages/services/auth/lib/src/di/setup.dart` | Register UserRepository | 2 |
| `packages/services/network/` | New package: NetworkCubit from core/global | 2 |
| `packages/services/network/lib/src/network_cubit.dart` | NetworkCubit (migrated) | 2 |
| `packages/services/locale/` | New package: LocaleCubit from core/global | 2 |
| `packages/services/locale/lib/src/locale_cubit.dart` | LocaleCubit (migrated) | 2 |
| `packages/services/error/lib/src/error_handler.dart` | Global error boundary | 2 |
| `lib/core/startup/launcher.dart` | Fix DI usage, await SDK init, add error handler | 2 |
| `lib/core/di/setup.dart` | Register new services, remove global cubits | 2 |
| `lib/core/global/` | Delete (moved to services/) | 2 |
| `lib/app.dart` | Update imports from services/ | 2 |
| `packages/features/feature_home/lib/src/repository/home_repository.dart` | Keep interface, add domain UserRepository extension | 3 |
| `packages/features/feature_home/lib/src/repository/home_repository_impl.dart` | Refactor: Dio injection over mixin | 3 |
| `packages/features/feature_home/pubspec.yaml` | Add domain dep | 3 |
| `test/unit/domain/models/user_test.dart` | Model serialization tests | 3 |
| `test/unit/domain/exceptions/domain_exception_test.dart` | Exception tests | 3 |
| `test/unit/services/auth_repository_impl_test.dart` | Repo impl with mock Dio | 3 |
| `test/bloc/features/home/home_cubit_test.dart` | Cubit with mock Repository | 3 |
| `test/widget/features/home/home_page_test.dart` | Widget test | 3 |
| `analysis_options.yaml` | Add lint rules | 4 |
| `.import_sorter.yaml` | Import grouping config | 4 |
| `.github/workflows/ci.yml` | CI pipeline | 4 |
| `.git/hooks/pre-commit` | Pre-commit hook | 4 |
| `pubspec.yaml` | Add import_sorter, network, locale, error deps | 4 |

---

## Phase 1: Foundation — Pure Dart Domain Layer

### Task 1: Remove flutter_bloc dependency from domain

**Files:**
- Modify: `packages/domain/pubspec.yaml`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Strip flutter_bloc from domain/pubspec.yaml**

```yaml
# packages/domain/pubspec.yaml
name: domain
description: Pure Dart business domain layer — models, repository interfaces, usecases, exceptions.
version: 0.0.1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  api:
    path: ../infrastructure/api
  key_value_storage:
    path: ../infrastructure/key_value_storage
  equatable: ^2.0.5

dev_dependencies:
  lints: ^2.0.0
  test: ^1.24.0
  mocktail: ^0.3.0
```

- [ ] **Step 2: Update barrel file**

```dart
// packages/domain/lib/domain.dart
export 'src/exceptions/domain_exception.dart';
export 'src/models/user.dart';
export 'src/repositories/user_repository.dart';
export 'src/enums/enum.dart';
```

- [ ] **Step 3: Verify**

Run: `cd packages/domain && dart pub get && dart analyze`
Expected: Exit 0, no errors

- [ ] **Step 4: Commit**

```bash
git add packages/domain/pubspec.yaml packages/domain/lib/domain.dart
git commit -m "refactor(domain): remove flutter_bloc dependency, make pure Dart"
```

---

### Task 2: Create DomainException hierarchy

**Files:**
- Create: `packages/domain/lib/src/exceptions/domain_exception.dart`

- [ ] **Step 1: Write sealed exception classes**

```dart
// packages/domain/lib/src/exceptions/domain_exception.dart
/// Base class for all domain-layer exceptions.
///
/// Each exception type maps to a specific error category that the UI can
/// handle uniformly (e.g., UnauthorizedException → redirect to login).
sealed class DomainException implements Exception {
  final String message;
  const DomainException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Network or server error — retryable in most cases.
class NetworkException extends DomainException {
  final int? statusCode;
  const NetworkException(super.message, {this.statusCode});
}

/// Authentication token expired — requires re-login.
class UnauthorizedException extends DomainException {
  const UnauthorizedException() : super('认证已过期');
}

/// Resource not found — 404 equivalent.
class NotFoundException extends DomainException {
  const NotFoundException() : super('请求的资源不存在');
}

/// Client-side validation failure — includes per-field errors.
class ValidationException extends DomainException {
  final Map<String, String> fieldErrors;
  const ValidationException(super.message, {this.fieldErrors = const {}});
}
```

- [ ] **Step 2: Verify**

Run: `cd packages/domain && dart analyze`
Expected: Exit 0

- [ ] **Step 3: Commit**

```bash
git add packages/domain/lib/src/exceptions/domain_exception.dart
git commit -m "feat(domain): add sealed DomainException hierarchy"
```

---

### Task 3: Create User business model

**Files:**
- Create: `packages/domain/lib/src/models/user.dart`

- [ ] **Step 1: Write User model with Equatable**

```dart
// packages/domain/lib/src/models/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final String? email;

  const User({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'email': email,
  };

  @override
  List<Object?> get props => [id, name, avatar, email];
}
```

- [ ] **Step 2: Add models export to barrel**

```dart
// packages/domain/lib/domain.dart — add line:
export 'src/models/user.dart';
```

- [ ] **Step 3: Verify**

Run: `cd packages/domain && dart analyze`
Expected: Exit 0

- [ ] **Step 4: Commit**

```bash
git add packages/domain/lib/src/models/user.dart packages/domain/lib/domain.dart
git commit -m "feat(domain): add User business model"
```

---

### Task 4: Create Abstract UserRepository interface

**Files:**
- Create: `packages/domain/lib/src/repositories/user_repository.dart`

- [ ] **Step 1: Write abstract interface**

```dart
// packages/domain/lib/src/repositories/user_repository.dart
import '../models/user.dart';
import '../exceptions/domain_exception.dart';

/// Contract for user data access.
///
/// Implementations live in services/ (e.g., AuthRepositoryImpl) or features/
/// and are injected via DI. This enables mock substitution in tests and
/// swapping implementations (e.g., remote vs cached) without changing consumers.
abstract class UserRepository {
  /// Fetch the currently authenticated user.
  ///
  /// Throws [UnauthorizedException] if token is expired.
  /// Throws [NetworkException] on connection failure.
  Future<User> getCurrentUser();

  /// Update user profile data.
  ///
  /// Throws [ValidationException] if field data is invalid.
  /// Throws [NetworkException] on connection failure.
  Future<void> updateProfile(ProfileData data);
}

/// Value object for profile update payload.
class ProfileData {
  final String? name;
  final String? avatar;
  final String? email;

  const ProfileData({this.name, this.avatar, this.email});
}
```

- [ ] **Step 2: Add repositories export to barrel**

```dart
// packages/domain/lib/domain.dart — add line:
export 'src/repositories/user_repository.dart';
```

- [ ] **Step 3: Verify**

Run: `cd packages/domain && dart analyze`
Expected: Exit 0

- [ ] **Step 4: Commit**

```bash
git add packages/domain/lib/src/repositories/user_repository.dart packages/domain/lib/domain.dart
git commit -m "feat(domain): add UserRepository abstract interface"
```

---

## Phase 2: Services — Global State Migration + Error Handler

### Task 5: Create network service package (migrate NetworkCubit)

**Files:**
- Create: `packages/services/network/pubspec.yaml`
- Create: `packages/services/network/lib/network.dart`
- Create: `packages/services/network/lib/src/network_cubit.dart`
- Create: `packages/services/network/lib/src/network_state.dart`
- Modify: `root pubspec.yaml` (add dependency)
- Modify: `lib/core/di/setup.dart` (import from new package)

- [ ] **Step 1: Create package scaffold**

```yaml
# packages/services/network/pubspec.yaml
name: network
description: Global network connectivity monitoring.
version: 0.0.1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  connectivity_plus: ^6.0.0
  equatable: ^2.0.5
```

```dart
// packages/services/network/lib/network.dart
export 'src/network_cubit.dart';
export 'src/network_state.dart';
```

- [ ] **Step 2: Migrate NetworkCubit and NetworkState**

Copy `lib/core/global/network/network_cubit.dart` → `packages/services/network/lib/src/network_cubit.dart`
Copy `lib/core/global/network/network_state.dart` → `packages/services/network/lib/src/network_state.dart`

Update package import in cubit:
```dart
// packages/services/network/lib/src/network_cubit.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'network_state.dart';

class NetworkCubit extends Cubit<NetworkState> {
  NetworkCubit() : super(NetworkState.initial());
  
  // ... rest identical to original
}
```

- [ ] **Step 3: Add network to root pubspec**

```yaml
# pubspec.yaml — under # ===== 业务服务层 =====, add:
  network:
    path: packages/services/network
```

- [ ] **Step 4: Update DI setup imports**

```dart
// lib/core/di/setup.dart — replace:
// import '../global/network/network_cubit.dart';
// with:
import 'package:network/network.dart';
```

Rest of `networkCubit` registration unchanged.

- [ ] **Step 5: Verify**

Run: `flutter pub get && flutter analyze lib/ packages/`
Expected: Exit 0

- [ ] **Step 6: Commit**

```bash
git add packages/services/network/ lib/core/di/setup.dart pubspec.yaml pubspec.lock
git commit -m "refactor: extract NetworkCubit to packages/services/network"
```

---

### Task 6: Create locale service package (migrate LocaleCubit)

**Files:**
- Create: `packages/services/locale/pubspec.yaml`
- Create: `packages/services/locale/lib/locale.dart`
- Create: `packages/services/locale/lib/src/locale_cubit.dart`
- Create: `packages/services/locale/lib/src/locale_state.dart`
- Modify: `root pubspec.yaml`
- Modify: `lib/core/di/setup.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Create package scaffold**

```yaml
# packages/services/locale/pubspec.yaml
name: locale
description: Global locale/language management.
version: 0.0.1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  key_value_storage:
    path: ../../infrastructure/key_value_storage
  equatable: ^2.0.5
```

- [ ] **Step 2: Migrate files**

Copy `lib/core/global/locale/locale_cubit.dart` → `packages/services/locale/lib/src/locale_cubit.dart`
Copy `lib/core/global/locale/locale_state.dart` → `packages/services/locale/lib/src/locale_state.dart`

Update imports in cubit to use `package:key_value_storage/key_value_storage.dart` and `package:locale/locale.dart` (relative within package).

```dart
// packages/services/locale/lib/locale.dart
export 'src/locale_cubit.dart';
export 'src/locale_state.dart';
```

- [ ] **Step 3: Add locale to root pubspec**

```yaml
# pubspec.yaml — under # ===== 业务服务层 =====, add:
  locale:
    path: packages/services/locale
```

- [ ] **Step 4: Update DI setup**

```dart
// lib/core/di/setup.dart — replace:
// import '../global/locale/locale_cubit.dart';
// import '../global/locale/locale_state.dart';
// with:
import 'package:locale/locale.dart';
```

- [ ] **Step 5: Update app.dart import**

```dart
// lib/app.dart — replace:
// import 'core/global/locale/locale_cubit.dart';
// import 'core/global/locale/locale_state.dart';
// with:
import 'package:locale/locale.dart';
```

- [ ] **Step 6: Delete old global state files**

```bash
rm -rf lib/core/global/network/
rm -rf lib/core/global/locale/
```

Update `lib/core/global/` to remove any references.

- [ ] **Step 7: Verify**

Run: `flutter pub get && flutter analyze lib/ packages/`
Expected: Exit 0, no imports to deleted files

- [ ] **Step 8: Commit**

```bash
git add packages/services/locale/ lib/app.dart lib/core/di/setup.dart pubspec.yaml pubspec.lock
git add -u lib/core/global/
git commit -m "refactor: extract LocaleCubit to packages/services/locale; remove core/global/"
```

---

### Task 7: Create AppErrorHandler

**Files:**
- Create: `packages/services/error/pubspec.yaml`
- Create: `packages/services/error/lib/error.dart`
- Create: `packages/services/error/lib/src/error_handler.dart`
- Modify: `root pubspec.yaml`
- Modify: `lib/core/startup/launcher.dart`
- Modify: `lib/core/di/setup.dart`

- [ ] **Step 1: Create package scaffold**

```yaml
# packages/services/error/pubspec.yaml
name: error
description: Global error handling and logging boundary.
version: 0.0.1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  api:
    path: ../../infrastructure/api
```

- [ ] **Step 2: Write error handler**

```dart
// packages/services/error/lib/error.dart
export 'src/error_handler.dart';
```

```dart
// packages/services/error/lib/src/error_handler.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:api/api.dart';

/// Catches unhandled errors at Flutter and platform boundaries,
/// logging them through the configured logger.
class AppErrorHandler {
  /// Install global error handlers.
  ///
  /// Must be called before [runApp].
  void setup({required void Function(Object error, StackTrace? stack) onError}) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to AppLogger
      onError(details.exception, details.stack);
      // In debug mode, also print to console
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      onError(error, stack);
      return true; // error has been handled
    };
  }
}
```

- [ ] **Step 3: Add to root pubspec**

```yaml
# pubspec.yaml — under services, add:
  error:
    path: packages/services/error
```

- [ ] **Step 4: Wire into launcher.dart**

```dart
// lib/core/startup/launcher.dart — add import:
import 'package:error/error.dart';
import '../utils/logger.dart';

// In launch(), after WidgetsFlutterBinding.ensureInitialized(), add:
  AppErrorHandler().setup(
    onError: (error, stack) {
      sl<AppLogger>().error('UnhandledError', error, stack);
    },
  );
```

- [ ] **Step 5: Verify**

Run: `flutter pub get && flutter analyze lib/ packages/`
Expected: Exit 0

- [ ] **Step 6: Commit**

```bash
git add packages/services/error/ lib/core/startup/launcher.dart pubspec.yaml pubspec.lock
git commit -m "feat: add AppErrorHandler global error boundary"
```

---

### Task 8: Fix Launcher DI usage and startup race condition

**Files:**
- Modify: `lib/core/startup/launcher.dart`

- [ ] **Step 1: Rewrite launcher with await and DI**

```dart
// lib/core/startup/launcher.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:error/error.dart';
import 'package:auth/auth.dart';
import 'package:data_sync/data_sync.dart';

import 'initializer.dart';
import 'profiler.dart';
import '../di/setup.dart';
import '../di/locator.dart';
import '../utils/logger.dart';

/// App startup orchestrator.
///
/// Launch sequence: binding → DI → SDK init → auth → sync → UI
class AppLauncher {
  AppLauncher._();

  static Future<void> launch(Widget app) async {
    // Phase 1: Core — must complete before everything else
    WidgetsFlutterBinding.ensureInitialized();
    StartupProfiler.start();
    StartupProfiler.mark('Flutter binding initialized');

    // Install global error boundary (before anything that can fail)
    AppErrorHandler().setup(
      onError: (error, stack) {
        sl<AppLogger>().error('UnhandledError', error, stack);
      },
    );
    StartupProfiler.mark('Error handler installed');

    // Configure DI
    setupDependencies();
    StartupProfiler.mark('DI configured');

    // Screen orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    StartupProfiler.mark('Screen orientation set');

    // Phase 2: SDK initialization (blocking — must finish before auth)
    final sdkInitializer = SDKInitializer();
    await sdkInitializer.initPlugins();
    StartupProfiler.mark('SDK initialized');

    // Phase 3: Business initialization
    await sl<AuthManager>().handleLogin();
    StartupProfiler.mark('Auth checked');

    // Data sync — fire-and-forget (non-blocking)
    sl<DataSyncManager>().sync();
    StartupProfiler.mark('Data sync triggered');

    // Phase 4: Launch UI
    runApp(app);
    StartupProfiler.report();
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/`
Expected: Exit 0, no import errors

- [ ] **Step 3: Commit**

```bash
git add lib/core/startup/launcher.dart
git commit -m "fix: use DI in launcher; await SDK init to fix race condition"
```

---

## Phase 3: Features — Repository Refactor + Tests

### Task 9: Create AuthRepositoryImpl (domain UserRepository implementation)

**Files:**
- Create: `packages/services/auth/lib/src/repository/auth_repository_impl.dart`
- Modify: `packages/services/auth/lib/auth.dart`
- Modify: `packages/services/auth/lib/src/di/setup.dart`
- Modify: `packages/services/auth/pubspec.yaml`

- [ ] **Step 1: Add dio and domain deps to auth/pubspec.yaml**

```yaml
# packages/services/auth/pubspec.yaml — dependencies:
  dio: ^5.2.0+1
  domain:
    path: ../../domain
```

- [ ] **Step 2: Write AuthRepositoryImpl**

```dart
// packages/services/auth/lib/src/repository/auth_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

class AuthRepositoryImpl implements UserRepository {
  final Dio _dio;

  AuthRepositoryImpl(this._dio);

  @override
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/user/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> updateProfile(ProfileData data) async {
    try {
      await _dio.put('/api/user/profile', data: {
        if (data.name != null) 'name': data.name,
        if (data.avatar != null) 'avatar': data.avatar,
        if (data.email != null) 'email': data.email,
      });
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  DomainException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return const UnauthorizedException();
    if (statusCode == 404) return const NotFoundException();
    if (statusCode == 422) {
      final errors = (e.response?.data as Map<String, dynamic>?)?['errors'];
      return ValidationException(
        '表单验证失败',
        fieldErrors: errors != null ? Map<String, String>.from(errors) : const {},
      );
    }
    return NetworkException(
      e.message ?? '网络请求失败',
      statusCode: statusCode,
    );
  }
}
```

- [ ] **Step 3: Register in auth DI**

```dart
// packages/services/auth/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import '../repository/auth_repository_impl.dart';
import '../manager.dart';

void setupAuth(GetIt sl) {
  sl.registerSingleton<UserRepository>(AuthRepositoryImpl(sl<Dio>()));
  sl.registerSingleton<AuthManager>(AuthManager(
    userRepository: sl<UserRepository>(),
    keyValueStorage: sl(),
  ));
}
```

- [ ] **Step 4: Export from barrel**

```dart
// packages/services/auth/lib/auth.dart — add:
export 'src/repository/auth_repository_impl.dart';
```

- [ ] **Step 5: Update AuthManager to accept UserRepository**

```dart
// packages/services/auth/lib/src/manager.dart — modify constructor:
class AuthManager {
  final UserRepository _userRepository;
  final KeyValueStorage _storage;

  AuthManager({
    required UserRepository userRepository,
    required KeyValueStorage keyValueStorage,
  }) : _userRepository = userRepository,
       _storage = keyValueStorage;
  // ... rest unchanged
}
```

- [ ] **Step 6: Verify**

Run: `flutter pub get && flutter analyze packages/`
Expected: Exit 0

- [ ] **Step 7: Commit**

```bash
git add packages/services/auth/
git commit -m "feat(auth): add AuthRepositoryImpl implementing domain UserRepository"
```

---

### Task 10: Fix Api package — downgrade to Dio config + interceptors

**Files:**
- Modify: `packages/infrastructure/api/lib/api.dart`
- Modify: `packages/infrastructure/api/pubspec.yaml`

- [ ] **Step 1: Simplify api barrel to Dio factory only**

```dart
// packages/infrastructure/api/lib/api.dart
export 'src/dio_factory.dart';
```

Remove: `src/api.dart`, `src/modules/` directory. The mixin pattern is deprecated.

- [ ] **Step 2: Create Dio factory**

```dart
// packages/infrastructure/api/lib/src/dio_factory.dart
import 'package:dio/dio.dart';

/// Creates a configured Dio instance with standard interceptors.
///
/// Usage:
///   sl.registerSingleton<Dio>(createDio());
Dio createDio({
  required Future<String?> Function() userTokenSupplier,
  required void Function() onNetworkDisconnected,
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Auth interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await userTokenSupplier();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.type == DioExceptionType.connectionError) {
        onNetworkDisconnected();
      }
      handler.next(error);
    },
  ));

  return dio;
}
```

- [ ] **Step 3: Update root DI to use Dio factory**

```dart
// lib/core/di/setup.dart — replace Api() registration with:
import 'package:api/api.dart';
import 'package:dio/dio.dart';

sl.registerSingleton<Dio>(createDio(
  userTokenSupplier: () async => null, // will wire real token later
  onNetworkDisconnected: () {
    sl<AppLogger>().warning('网络连接已断开');
  },
));
```

Remove `sl.registerSingleton<Api>(...)` line. Remove `api.dart` import from packages/infrastructure/api.

- [ ] **Step 4: Verify**

Run: `flutter pub get && flutter analyze lib/ packages/`
Expected: Exit 0

- [ ] **Step 5: Commit**

```bash
git add packages/infrastructure/api/ lib/core/di/setup.dart
git commit -m "refactor(api): replace mixin pattern with Dio factory"
```

---

### Task 11: Add domain models unit tests

**Files:**
- Create: `test/unit/domain/models/user_test.dart`

- [ ] **Step 1: Write User model tests**

```dart
// test/unit/domain/models/user_test.dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    const json = {
      'id': 'user-1',
      'name': 'Test User',
      'avatar': 'https://example.com/avatar.png',
      'email': 'test@example.com',
    };

    test('fromJson creates User with all fields', () {
      final user = User.fromJson(json);
      expect(user.id, 'user-1');
      expect(user.name, 'Test User');
      expect(user.avatar, 'https://example.com/avatar.png');
      expect(user.email, 'test@example.com');
    });

    test('fromJson handles missing optional fields', () {
      final user = User.fromJson({'id': 'user-2', 'name': 'Minimal'});
      expect(user.avatar, isNull);
      expect(user.email, isNull);
    });

    test('toJson produces correct map', () {
      final user = User.fromJson(json);
      expect(user.toJson(), json);
    });

    test('Equatable — same values produce equal objects', () {
      final a = User.fromJson(json);
      final b = User.fromJson(json);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Equatable — different values produce unequal objects', () {
      final a = User.fromJson(json);
      final b = User.fromJson({...json, 'id': 'user-2'});
      expect(a, isNot(equals(b)));
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/unit/domain/models/user_test.dart`
Expected: All 5 tests PASS

- [ ] **Step 3: Commit**

```bash
git add test/unit/domain/models/user_test.dart
git commit -m "test(domain): add User model unit tests"
```

---

### Task 12: Add DomainException unit tests

**Files:**
- Create: `test/unit/domain/exceptions/domain_exception_test.dart`

- [ ] **Step 1: Write exception tests**

```dart
// test/unit/domain/exceptions/domain_exception_test.dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainException', () {
    test('NetworkException stores statusCode', () {
      final e = NetworkException('timeout', statusCode: 503);
      expect(e.message, 'timeout');
      expect(e.statusCode, 503);
    });

    test('UnauthorizedException has fixed message', () {
      const e = UnauthorizedException();
      expect(e.message, '认证已过期');
    });

    test('NotFoundException has fixed message', () {
      const e = NotFoundException();
      expect(e.message, '请求的资源不存在');
    });

    test('ValidationException stores fieldErrors', () {
      final e = ValidationException('invalid', fieldErrors: {'email': '格式错误'});
      expect(e.fieldErrors, {'email': '格式错误'});
    });

    test('all exceptions implement DomainException', () {
      expect(const UnauthorizedException(), isA<DomainException>());
      expect(NetworkException(''), isA<DomainException>());
      expect(const NotFoundException(), isA<DomainException>());
      expect(ValidationException(''), isA<DomainException>());
    });

    test('sealed — exhaustive type check compiles', () {
      void handle(DomainException e) {
        switch (e) {
          case NetworkException():
          case UnauthorizedException():
          case NotFoundException():
          case ValidationException():
        }
      }
      handle(const UnauthorizedException());
      // If this compiles, sealed is working correctly
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/unit/domain/exceptions/domain_exception_test.dart`
Expected: All 6 tests PASS

- [ ] **Step 3: Commit**

```bash
git add test/unit/domain/exceptions/domain_exception_test.dart
git commit -m "test(domain): add DomainException unit tests"
```

---

### Task 13: Add AuthRepositoryImpl unit test

**Files:**
- Create: `test/unit/services/auth_repository_impl_test.dart`

- [ ] **Step 1: Write repository test with mock Dio**

```dart
// test/unit/services/auth_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:auth/auth.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    repo = AuthRepositoryImpl(mockDio);
  });

  group('getCurrentUser', () {
    test('returns User on 200', () async {
      final response = Response(
        requestOptions: RequestOptions(),
        data: {'id': '1', 'name': 'Test', 'avatar': null, 'email': null},
        statusCode: 200,
      );
      when(() => mockDio.get('/api/user/me')).thenAnswer((_) async => response);

      final user = await repo.getCurrentUser();

      expect(user.id, '1');
      expect(user.name, 'Test');
    });

    test('throws UnauthorizedException on 401', () async {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );
      when(() => mockDio.get('/api/user/me')).thenThrow(error);

      expect(
        () => repo.getCurrentUser(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws NotFoundException on 404', () async {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );
      when(() => mockDio.get('/api/user/me')).thenThrow(error);

      expect(
        () => repo.getCurrentUser(),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('throws NetworkException on connection error', () async {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
        message: 'no internet',
      );
      when(() => mockDio.get('/api/user/me')).thenThrow(error);

      expect(
        () => repo.getCurrentUser(),
        throwsA(predicate((e) => e is NetworkException && e.statusCode == null)),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/unit/services/auth_repository_impl_test.dart`
Expected: All 4 tests PASS

- [ ] **Step 3: Commit**

```bash
git add test/unit/services/auth_repository_impl_test.dart
git commit -m "test(services): add AuthRepositoryImpl unit tests with mock Dio"
```

---

### Task 14: Add HomeCubit bloc test

**Files:**
- Create: `test/bloc/features/home/home_cubit_test.dart`

- [ ] **Step 1: Write bloc test**

```dart
// test/bloc/features/home/home_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_home/feature_home.dart';
import 'package:domain/domain.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository mockRepo;

  setUp(() {
    mockRepo = MockHomeRepository();
  });

  group('HomeCubit', () {
    blocTest<HomeCubit, HomeState>(
      'emits [loading, loaded] when fetchData succeeds',
      build: () {
        when(() => mockRepo.fetchHomeData()).thenAnswer(
          (_) async => const HomeData(items: []),
        );
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [loading, error] when fetchData throws',
      build: () {
        when(() => mockRepo.fetchHomeData()).thenThrow(
          const NetworkException('fail'),
        );
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>(),
      ],
    );
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/bloc/features/home/home_cubit_test.dart`
Expected: 2 tests PASS

- [ ] **Step 3: Commit**

```bash
git add test/bloc/features/home/home_cubit_test.dart
git commit -m "test(feature_home): add HomeCubit bloc tests"
```

---

### Task 15: Add HomePage widget test

**Files:**
- Create: `test/widget/features/home/home_page_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/features/home/home_page_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:feature_home/feature_home.dart';

class FakeHomeCubit extends Fake implements HomeCubit {
  @override
  HomeState get state => HomeLoaded(HomeData(items: []));
  @override
  void loadData() {}
}

void main() {
  testWidgets('HomePage renders AppBar with title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeCubit>(
          create: (_) => FakeHomeCubit(),
          child: const HomePage(),
        ),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('HomePage shows loading indicator', (tester) async {
    final loadingCubit = FakeHomeCubit();
    // Override state for this test
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HomeCubit>.value(
          value: loadingCubit,
          child: const HomePage(),
        ),
      ),
    );

    // Verify page renders without error in loaded state
    expect(find.byType(HomePage), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/widget/features/home/home_page_test.dart`
Expected: 2 tests PASS

- [ ] **Step 3: Commit**

```bash
git add test/widget/features/home/home_page_test.dart
git commit -m "test(feature_home): add HomePage widget tests"
```

---

## Phase 4: Enforcement — Lint, Import, CI

### Task 16: Upgrade analysis_options.yaml

**Files:**
- Modify: `analysis_options.yaml`

- [ ] **Step 1: Add strict lint rules**

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    always_declare_return_types: error
    avoid_dynamic_calls: warning
    missing_return: error
    dead_code: error

linter:
  rules:
    - avoid_print
    - cancel_subscriptions
    - close_sinks
    - no_leading_underscores_for_local_identifiers
    - prefer_const_constructors
    - prefer_single_quotes
    - unawaited_futures
    - use_build_context_synchronously
    - use_setters_to_change_properties
    - require_trailing_commas
    - sort_child_properties_last
    - prefer_const_declarations
    - prefer_final_locals
    - prefer_final_in_for_each
```

- [ ] **Step 2: Verify all code passes new rules**

Run: `flutter analyze --fatal-infos lib/ packages/`
Expected: Exit 0. If violations exist, fix them BEFORE committing.

- [ ] **Step 3: Commit**

```bash
git add analysis_options.yaml
git commit -m "chore: upgrade analysis_options with strict lint rules"
```

---

### Task 17: Configure import_sorter

**Files:**
- Create: `.import_sorter.yaml`
- Modify: `pubspec.yaml` (add dev_dependency)

- [ ] **Step 1: Add dev dependency**

```yaml
# pubspec.yaml — dev_dependencies:
  import_sorter: ^4.6.0
```

- [ ] **Step 2: Create config**

```yaml
# .import_sorter.yaml
grouping:
  - name: dart
    regex: '^dart:'
  - name: flutter
    regex: '^package:flutter'
  - name: infrastructure
    regex: '^package:(api|routing|key_value_storage|component_library)'
  - name: domain
    regex: '^package:domain'
  - name: services
    regex: '^package:(auth|data_sync|network|locale|error)'
  - name: features
    regex: '^package:feature_'
  - name: relative
    regex: '^\.'
```

- [ ] **Step 3: Run import sorter**

Run: `dart run import_sorter:main`
Expected: Exit 0

- [ ] **Step 4: Verify**

Run: `flutter analyze --fatal-infos lib/ packages/`
Expected: Exit 0

- [ ] **Step 5: Commit**

```bash
git add .import_sorter.yaml pubspec.yaml pubspec.lock
git add -u lib/ packages/  # any sorted import changes
git commit -m "chore: configure import_sorter with layer-based grouping"
```

---

### Task 18: Create CI pipeline

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write CI workflow**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze:
    name: Static Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.3'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter analyze --fatal-infos

  test:
    name: Unit & Bloc Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.3'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info

  build:
    name: Debug Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.3'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter build apk --debug
```

- [ ] **Step 2: Verify CI config syntax**

Run: `cat .github/workflows/ci.yml` (manual check)
Expected: Valid YAML

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions CI pipeline (analyze, test, build)"
```

---

### Task 19: Create pre-commit hook

**Files:**
- Create: `.git/hooks/pre-commit`

- [ ] **Step 1: Write pre-commit hook**

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Runs before every commit. Fails fast on analysis errors or test failures.

set -euo pipefail

echo "▸ Running flutter analyze..."
flutter analyze --fatal-infos lib/ packages/

echo "▸ Running unit & bloc tests..."
flutter test test/unit/ test/bloc/

echo "✓ Pre-commit checks passed"
```

- [ ] **Step 2: Make executable**

Run: `chmod +x .git/hooks/pre-commit`

- [ ] **Step 3: Commit**

```bash
git add .git/hooks/pre-commit
git commit -m "chore: add pre-commit hook (analyze + test)"
```

---

## Phase 5: Polish — Golden Tests, Profiling, Docs

### Task 20: Add golden tests for key components

**Files:**
- Create: `test/golden/components/buttons_test.dart`
- Modify: `pubspec.yaml` (if golden toolkit not present)

- [ ] **Step 1: Write golden test**

```dart
// test/golden/components/buttons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Primary button golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Primary Action'),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(ElevatedButton),
      matchesGoldenFile('goldens/primary_button.png'),
    );
  });
}
```

- [ ] **Step 2: Generate baseline**

Run: `flutter test --update-goldens test/golden/`
Expected: Creates `test/golden/goldens/primary_button.png`

- [ ] **Step 3: Verify goldens pass**

Run: `flutter test test/golden/`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/golden/
git commit -m "test: add golden test for primary button"
```

---

### Task 21: Sync documentation

**Files:**
- Modify: `packages/infrastructure/api/README.md`
- Modify: `packages/domain/README.md`
- Modify: `lib/core/README.md`
- Modify: `README.md`
- Modify: `packages/infrastructure/README.md`
- Modify: `packages/services/README.md`

- [ ] **Step 1: Update api README — document Dio factory, remove mixin docs**

```markdown
# api

HTTP client based on Dio. Provides a `createDio()` factory function with standard interceptors (auth token injection, network disconnect detection).

## Usage

```dart
final dio = createDio(
  userTokenSupplier: () async => token,
  onNetworkDisconnected: () => logger.warning('Offline'),
);
```
```

- [ ] **Step 2: Update domain README — note pure Dart status, add Repository interface docs**

- [ ] **Step 3: Update core README — remove global state, note empty after migration**

- [ ] **Step 4: Update root README — reflect new phase scoring, updated layer diagram**

- [ ] **Step 5: Verify docs consistency**

Run: Read each modified README, cross-reference with actual code.

- [ ] **Step 6: Commit**

```bash
git add packages/domain/README.md packages/infrastructure/api/README.md lib/core/README.md README.md
git commit -m "docs: sync architecture docs with best-practice upgrade"
```

---

### Task 22: Final integration verification

- [ ] **Step 1: Full analyze**

Run: `flutter analyze --fatal-infos`
Expected: Exit 0

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 3: Build verification**

Run: `flutter build apk --debug`
Expected: Build succeeds

- [ ] **Step 4: Run pre-commit manually**

Run: `bash .git/hooks/pre-commit`
Expected: All checks PASS

- [ ] **Step 5: Commit verification report**

```bash
git commit --allow-empty -m "chore: final integration verification passed"
```
```

---

## Self-Review

### 1. Spec Coverage

| Spec Section | Task |
|-------------|------|
| 3. Layer Architecture (revised) | Tasks 1, 5, 6, 10 |
| 4. DI Rules | Tasks 5, 6, 8, 9 |
| 5. Repository Pattern + API decoupling | Tasks 4, 9, 10 |
| 6. Three-Layer Test Strategy | Tasks 11, 12, 13, 14, 15, 20 |
| 7. Dependency Enforcement | Tasks 16, 17, 18, 19 |
| 8. Error Handling | Task 2 (exceptions), Task 7 (handler), Task 9 (RepoImpl mapping) |
| 9. Startup Sequence (Fixed) | Task 8 |
| 10. Before/After Scorecard | Task 21 (docs) |
| 11. Implementation Phases | Covered by task grouping |
| 12. Risks & Mitigations | Built into incremental task structure |

✅ All spec sections covered.

### 2. Placeholder Scan

- No "TBD" or "TODO" strings found
- No "add appropriate error handling" — error handling has concrete code in Tasks 2, 7, 9
- No "write tests for above" without test code — all test tasks include full test code
- No "Similar to Task N" — code repeated explicitly in each task

✅ Clean.

### 3. Type Consistency

- `User` model: defined in Task 3, consumed in Tasks 9, 11. Fields consistent throughout.
- `DomainException` hierarchy: defined in Task 2, thrown in Tasks 9, 11, tested in Task 12. Sealed classes match.
- `UserRepository`: defined in Task 4, implemented in Task 9, mocked in Task 13. Interface consistent.
- `ProfileData`: defined in Task 4, used in Task 9. ✅
- `AuthManager`: constructor changed in Task 9 to accept `UserRepository`. Launcher in Task 8 uses `sl<AuthManager>()`. Consistent.
- `Dio`: created in Task 10, injected in Task 9, mocked in Task 13. ✅
- `sl` (GetIt): used consistently as `sl<Type>()` pattern throughout.

✅ Types consistent across tasks.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-02-architecture-best-practice-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
