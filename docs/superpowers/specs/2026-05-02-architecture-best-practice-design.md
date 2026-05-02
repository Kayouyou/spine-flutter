# Architecture Best Practice Upgrade — Design Spec

**Date**: 2026-05-02  
**Status**: Proposed  
**Target**: Flutter monorepo scaffold (2-5 person team)  
**Goal**: Elevate architecture from 7.5/10 to 8.5+/10 — best practice for small team Flutter projects

---

## 1. Problem Statement

Current architecture has correct skeleton (layered monorepo, strict dependency direction, comprehensive docs) but three gaps:

1. **Domain layer is thin** — only demo models and Hive adapters. README describes rich structure (models, repositories, usecases) that isn't implemented. Domain depends on Flutter via `flutter_bloc`.
2. **No dependency inversion** — Repository interfaces defined inside features, not in domain. API uses mixin pattern that couples all modules to one `Api` class.
3. **No enforcement** — Layer boundaries are convention-only. No tests, no CI, no lint constraints.

These would cause code rot as the project grows beyond 2-3 features.

---

## 2. Constraints

- **Tech stack fixed**: flutter_bloc (Cubit), get_it, GoRouter, Dio, Hive
- **Team size**: 2-5 people — avoid over-engineering
- **Must remain**: monorepo structure, package isolation, existing build tooling (make, fvm)
- **Breaking changes acceptable** within `packages/` — root `lib/` changes minimal

---

## 3. Layer Architecture (Revised)

```
┌─────────────────────────────────────────────┐
│  lib/core/  (Assembly only — depended by none)  │
│  ┌──────┐  ┌─────────┐  ┌──────┐               │
│  │  di/ │  │startup/ │  │ l10n/│               │
│  └──────┘  └─────────┘  └──────┘               │
│  depends on: everything                         │
└─────────────────────────────────────────────┘
                    ↓ assembles
┌─────────────────────────────────────────────┐
│  features/  (UI modules)                     │
│  ┌────────────┐  ┌──────────────┐            │
│  │feature_home│  │feature_detail│  ...        │
│  └────────────┘  └──────────────┘            │
│  depends on: services, domain, infra          │
│  rule: no cross-feature imports               │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  services/  (App services + global state)     │
│  ┌──────┐ ┌──────────┐ ┌──────────┐ ┌────────┐│
│  │ auth │ │data_sync │ │ locale   │ │network ││
│  └──────┘ └──────────┘ └──────────┘ └────────┘│
│  depends on: domain, infra                    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  domain/  (Pure Dart — no Flutter dependency) │
│  ┌────────┐ ┌──────────────┐ ┌──────────┐   │
│  │ models │ │ repositories │ │ usecases │    │
│  └────────┘ └──────────────┘ └──────────┘   │
│  depends on: infra (api types, kv_storage)    │
│  depends on: dart:* only                      │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  infrastructure/  (Pure tech — no business)   │
│  ┌─────┐ ┌─────────┐ ┌───────────┐           │
│  │ api │ │ routing │ │kv_storage │  ...      │
│  └─────┘ └─────────┘ └───────────┘          │
│  depends on: nothing except Flutter/Dart       │
└─────────────────────────────────────────────┘
```

### Key changes from current

| Before | After |
|--------|-------|
| `domain` depends on `flutter_bloc` | `domain` is pure Dart |
| `lib/core/global/` has NetworkCubit, LocaleCubit | Moved to `packages/services/` as `app_state/` |
| No Repository interfaces in domain | All Repository interfaces in `domain/repositories/` |
| API uses `class Api extends ApiBase with UserApiMixin` | API reduced to Dio config; RepoImpl uses Dio directly |

---

## 4. Dependency Injection Rules

### 4.1 Registration conventions

| Layer | Scope | Rationale |
|-------|-------|-----------|
| Repositories (domain interfaces) | Singleton | Stateless data access, shared across features |
| Services (AuthManager, DataSyncManager) | Singleton | App-lifespan, stateful |
| Global Cubits (Network, Locale) | Singleton | Cross-feature shared state |
| Feature Cubits | Factory | Page lifespan, destroyed on pop |
| UseCases (domain) | Factory | Stateless single-action |

### 4.2 Registration order in `setupDependencies()`

1. Infrastructure: `Dio`, `KeyValueStorage`, `AppLogger`
2. Domain repositories: `UserRepository`, etc. (depends on Dio)
3. Global state: `NetworkCubit`, `LocaleCubit`
4. Services: `AuthManager`, `DataSyncManager`
5. Features: `setupFeatureHome(sl)`, `setupFeatureDetail(sl)`

### 4.3 Fix: Use DI in Launcher

```dart
// Before (bypasses DI)
final authManager = AuthManager();
await authManager.handleLogin();

// After (uses DI)
await sl<AuthManager>().handleLogin();
```

---

## 5. Repository Pattern + API Decoupling

### 5.1 Interface in domain

```dart
// packages/domain/lib/src/repositories/user_repository.dart
abstract class UserRepository {
  Future<User> getCurrentUser();
  Future<void> updateProfile(ProfileData data);
}
```

### 5.2 Implementation in services/features

```dart
// packages/services/auth/lib/src/repository/auth_repository_impl.dart
class AuthRepositoryImpl implements UserRepository {
  final Dio _dio;
  AuthRepositoryImpl(this._dio);

  @override
  Future<User> getCurrentUser() async {
    try {
      final res = await _dio.get('/api/user/me');
      return User.fromJson(res.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  DomainException _mapDioError(DioException e) {
    if (e.response?.statusCode == 401) return const UnauthorizedException();
    if (e.response?.statusCode == 404) return const NotFoundException();
    return NetworkException(e.message ?? '网络错误', statusCode: e.response?.statusCode);
  }
}
```

### 5.3 DI binding

```dart
sl.registerSingleton<Dio>(_createDio());
sl.registerSingleton<UserRepository>(AuthRepositoryImpl(sl<Dio>()));
```

### 5.4 Why composition over mixin

| Factor | Mixin approach | Composition approach |
|--------|---------------|---------------------|
| Unit test | Must mock entire Api class | Inject `MockUserRepository` |
| Interface | No explicit contract | `abstract class UserRepository` |
| Multi-impl | Not supported | DI switch implementation |
| Api class growth | Linear growth per module | Api class stays small |
| Discoverability | grep `implements` | IDE "find implementations" |

---

## 6. Three-Layer Test Strategy

### 6.1 Test directory structure

```
test/
├── unit/                          # Pure Dart, zero Flutter dependency
│   ├── domain/models/             # fromJson/toJson, boundary values
│   ├── domain/usecases/           # Mock Repository interface
│   └── services/                  # Mock Dio, KeyValueStorage
│
├── bloc/                          # bloc_test — Cubit testing
│   ├── features/home/             # HomeCubitTest
│   └── global/                    # NetworkCubitTest, LocaleCubitTest
│
├── widget/                        # Widget test — mock Cubit
│   └── features/home/
│
└── golden/                        # Pixel-perfect screenshot diff
    └── components/
```

### 6.2 Coverage targets

| Layer | Target | Test type | What to mock |
|-------|--------|-----------|-------------|
| domain models | 100% | unit | Nothing |
| domain usecases | 100% | unit | Repository interface |
| services | 80% | unit | Dio, KeyValueStorage |
| feature cubit | 90% | bloc_test | Repository interface |
| feature widget | 60% | widget | Cubit |
| golden | Key components | golden | Nothing |

### 6.3 Why not 100% everywhere

Widget tests for a 2-5 person team have ROI inflection point around 60%. Core business logic (models, usecases, cubits) at 100% already catches most regressions. Golden tests cover visual drift for critical components. Type system handles the rest.

---

## 7. Dependency Enforcement

### 7.1 Physical isolation (first line)

Feature packages declare only their actual dependencies in `pubspec.yaml`. Feature A does NOT declare feature B — cross-feature navigation goes through `routing` package. Attempting `import 'package:feature_detail/...'` from `feature_home` causes compile error.

### 7.2 Lint rules

```yaml
# analysis_options.yaml additions
linter:
  rules:
    - close_sinks
    - no_leading_underscores_for_local_identifiers
    - prefer_const_constructors
    - unawaited_futures
    - use_build_context_synchronously
    - use_setters_to_change_properties
    - cancel_subscriptions

analyzer:
  errors:
    always_declare_return_types: error
    avoid_dynamic_calls: warning
```

### 7.3 Import sorting

```bash
# dev dependency
dart pub add --dev import_sorter
```

Configure import groupings: dart → flutter → infrastructure → domain → services → features → relative.

### 7.4 Pre-commit hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
set -e
flutter analyze --fatal-infos lib/ packages/
flutter test test/unit/ test/bloc/
```

### 7.5 CI pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter analyze --fatal-infos
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter test --coverage
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --debug
```

---

## 8. Error Handling

### 8.1 DomainException hierarchy

```dart
// packages/domain/lib/src/exceptions/domain_exception.dart
sealed class DomainException implements Exception {
  final String message;
  const DomainException(this.message);
}

class NetworkException extends DomainException {
  final int? statusCode;
  const NetworkException(super.message, {this.statusCode});
}

class UnauthorizedException extends DomainException {
  const UnauthorizedException() : super('认证已过期');
}

class NotFoundException extends DomainException {
  const NotFoundException() : super('请求的资源不存在');
}

class ValidationException extends DomainException {
  final Map<String, String> fieldErrors;
  const ValidationException(super.message, {this.fieldErrors = const {}});
}
```

### 8.2 Layer responsibilities

| Layer | Error duty |
|-------|-----------|
| RepoImpl | `DioException` → `DomainException` |
| Cubit | `catch DomainException` → emit `ErrorState` |
| UI | `BlocBuilder` → show `ErrorState` widget or SnackBar |

### 8.3 Global error boundary

```dart
class AppErrorHandler {
  void setup() {
    FlutterError.onError = (details) {
      sl<AppLogger>().error('FlutterError', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      sl<AppLogger>().error('UncaughtError', error, stack);
      return true;
    };
  }
}
```

---

## 9. Startup Sequence (Fixed)

### 9.1 Current problem

`SDKInitializer.initPlugins()` uses `.then()` callback — may fire AFTER `runApp()`. AuthManager and DataSyncManager bypass DI.

### 9.2 Corrected flow

```dart
static Future<void> launch(Widget app) async {
  // Phase 1: Core (must complete before everything else)
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandler().setup();
  setupDependencies();
  await SystemChrome.setPreferredOrientations([...]);
  
  // Phase 2: SDK init (parallel internally, but block until all done)
  await sl<SDKInitializer>().initPlugins();
  
  // Phase 3: Business init
  await sl<AuthManager>().handleLogin();
  sl<DataSyncManager>().sync();  // fire-and-forget
  
  // Phase 4: Launch UI
  runApp(app);
}
```

### 9.3 Phase timing

| Phase | Time budget | Blocking? |
|-------|------------|-----------|
| Core | < 50ms | Yes |
| SDK init | < 200ms | Yes |
| Auth | < 500ms | Yes |
| Data sync | N/A | No (fire-and-forget) |
| UI launch | < 16ms | Yes |

---

## 10. Before / After Scorecard

| Dimension | Before | After | Gain |
|-----------|--------|-------|------|
| Layer separation | 8 — correct direction, docs exist | 9 — pure Dart domain, enforced by physical isolation | +1 |
| Repository pattern | 5 — interfaces in features, no dependency inversion | 9 — interfaces in domain, composition injection | +4 |
| Testability | 2 — no tests, mixin coupling blocks mocking | 8 — three-layer test suite, DI-swappable implementations | +6 |
| Dependency enforcement | 3 — convention only | 8 — physical isolation + lint + CI | +5 |
| Error handling | 4 — scattered try-catch | 8 — sealed hierarchy, global boundary | +4 |
| Startup reliability | 6 — race condition exists | 9 — phased await, profiled | +3 |
| Docs quality | 9 — excellent decision trees | 9 — maintained | 0 |
| **Overall** | **7.5** | **8.5+** | **+1+** |

---

## 11. Implementation Phases (Preview)

| Phase | Scope | Est. effort |
|-------|-------|------------|
| 1. Foundation | domain pure-Dart, Repository interfaces, DomainException | 2 days |
| 2. Services | Move global Cubits, fix DI in launcher, AppErrorHandler | 1 day |
| 3. Features | Refactor RepoImpl to composition, add bloc tests | 2 days |
| 4. Enforcement | lint rules, pre-commit, CI, import sorter | 1 day |
| 5. Polish | Golden tests, startup profiling, docs sync | 1 day |

Total: ~7 days for 1 person.

---

## 12. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| Breaking existing feature code | High | Phase 3 does one feature at a time; keep old API working until tests pass |
| CI setup delays | Medium | Use GitHub Actions starter workflow; can defer to Phase 4 |
| Over-engineering for 2-5 people | Low | Each decision gated by "would a 5-person team maintain this?" test |
| Domain moving to pure Dart breaks existing imports | Medium | Phased: add pure Dart domain directory, migrate one model at a time |
