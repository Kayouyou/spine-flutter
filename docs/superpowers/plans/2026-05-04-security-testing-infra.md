# Security Testing Infra Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add auth route guard with environment control, Login/Register example pages, Domain usecases 100% test coverage, CI coverage dual-track reporting.

**Architecture:** Route guard whitelist pattern, AuthCubit state management, mock repository for scaffold demo, mocktail for domain tests, codecov + artifact for CI.

**Tech Stack:** Flutter, GoRouter, get_it, mocktail, bloc_test, codecov, lcov

---

## File Structure

### New Files Created

| File | Responsibility |
|------|----------------|
| `packages/infrastructure/routing/lib/src/guards/auth_guard.dart` | Route guard redirect logic |
| `packages/infrastructure/routing/lib/src/guards/public_routes.dart` | Whitelist route set |
| `packages/services/auth/lib/src/cubit/auth_cubit.dart` | Auth state management |
| `packages/services/auth/lib/src/cubit/auth_state.dart` | Auth state definition |
| `packages/services/auth/lib/src/repository/mock_auth_repository.dart` | Mock auth for scaffold demo |
| `packages/features/feature_auth/lib/feature_auth.dart` | Auth feature barrel file |
| `packages/features/feature_auth/lib/src/di/setup.dart` | Auth feature DI setup |
| `packages/features/feature_auth/lib/src/cubit/auth_cubit.dart` | Login/Register cubit (feature-level) |
| `packages/features/feature_auth/lib/src/cubit/auth_state.dart` | Login/Register state |
| `packages/features/feature_auth/lib/src/repository/auth_repository.dart` | Auth repository interface |
| `packages/features/feature_auth/lib/src/repository/mock_auth_repository.dart` | Mock implementation |
| `packages/features/feature_auth/lib/src/ui/login_page.dart` | Login page |
| `packages/features/feature_auth/lib/src/ui/register_page.dart` | Register page |
| `packages/features/feature_auth/pubspec.yaml` | Feature dependencies |
| `packages/features/feature_auth/test/auth_cubit_test.dart` | AuthCubit tests |
| `test/unit/domain/usecases/get_user_usecase_test.dart` | GetUserUseCase tests |
| `test/unit/domain/models/user_test.dart` | User model tests (Phase 2) |
| `test/unit/domain/exceptions/domain_exception_test.dart` | Exception tests (Phase 2) |
| `.github/workflows/coverage.yml` | CI coverage workflow |
| `scripts/coverage_local.sh` | Local HTML coverage script |
| `docs/auth-route-guard.md` | Route guard documentation |
| `docs/domain-testing-guide.md` | Domain testing documentation |
| `docs/coverage-guide.md` | Coverage guide documentation |

### Modified Files

| File | Changes |
|------|---------|
| `lib/config.dart` | Add `enableAuthGuardOverride` config |
| `packages/services/auth/lib/src/manager.dart` | Add `isLoggedIn` getter + Cubit pattern |
| `packages/services/auth/lib/src/di/setup.dart` | Register AuthCubit |
| `packages/services/auth/lib/auth.dart` | Export new exports |
| `packages/infrastructure/routing/lib/src/routes/router.dart` | Add `redirect` + `enableAuthGuard` param |
| `packages/infrastructure/routing/lib/src/routes/route_context.dart` | Add `AuthManager` dependency |
| `packages/infrastructure/routing/lib/routing.dart` | Export guards |
| `lib/core/di/setup.dart` | Register feature_auth + AuthCubit |
| `lib/app.dart` | Pass AuthManager to router |
| `pubspec.yaml` | Add feature_auth dependency |
| `README.md` | Add auth/testing sections |
| `makefile` | Add `coverage-local` command |

---

## Task 1: AuthManager isLoggedIn + AuthCubit

**Files:**
- Modify: `packages/services/auth/lib/src/manager.dart`
- Create: `packages/services/auth/lib/src/cubit/auth_cubit.dart`
- Create: `packages/services/auth/lib/src/cubit/auth_state.dart`
- Modify: `packages/services/auth/lib/src/di/setup.dart`
- Modify: `packages/services/auth/lib/auth.dart`
- Test: `packages/services/auth/test/auth_cubit_test.dart`

- [ ] **Step 1: Write AuthState**

```dart
// packages/services/auth/lib/src/cubit/auth_state.dart
import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, loggedIn, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? userId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, userId, errorMessage];
}
```

- [ ] **Step 2: Write AuthCubit**

```dart
// packages/services/auth/lib/src/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../repository/mock_auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final MockAuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthState());

  Future<void> login(String username, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final success = await _repository.login(username, password);
      if (success) {
        emit(state.copyWith(status: AuthStatus.loggedIn, userId: 'mock-user-1'));
      } else {
        emit(state.copyWith(status: AuthStatus.error, errorMessage: '登录失败'));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _repository.logout();
    emit(const AuthState());
  }

  bool get isLoggedIn => state.status == AuthStatus.loggedIn;
}
```

- [ ] **Step 3: Write MockAuthRepository**

```dart
// packages/services/auth/lib/src/repository/mock_auth_repository.dart
abstract class AuthRepository {
  Future<bool> login(String username, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
}

class MockAuthRepository implements AuthRepository {
  bool _loggedIn = false;

  @override
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = username.isNotEmpty && password.isNotEmpty;
    return _loggedIn;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loggedIn = false;
  }

  @override
  Future<bool> isLoggedIn() async => _loggedIn;
}
```

- [ ] **Step 4: Update AuthManager**

```dart
// packages/services/auth/lib/src/manager.dart (modify)
import 'package:flutter/foundation.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'cubit/auth_cubit.dart';

class AuthManager {
  final UserRepository _userRepository;
  final KeyValueStorage _keyValueStorage;
  final AuthCubit _authCubit;

  AuthManager({
    required UserRepository userRepository,
    required KeyValueStorage keyValueStorage,
    required AuthCubit authCubit,
  })  : _userRepository = userRepository,
        _keyValueStorage = keyValueStorage,
        _authCubit = authCubit;

  bool get isLoggedIn => _authCubit.isLoggedIn;

  Future<void> handleLogin() async {
    if (kDebugMode) {
      debugPrint('🚀 [AuthManager] handleLogin: 检查Token...');
    }
  }

  void dispose() {}
}
```

- [ ] **Step 5: Update DI setup**

```dart
// packages/services/auth/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'cubit/auth_cubit.dart';
import 'repository/mock_auth_repository.dart';
import 'manager.dart';

void setupAuth(GetIt sl) {
  sl.registerFactory<MockAuthRepository>(() => MockAuthRepository());
  sl.registerSingleton<AuthCubit>(AuthCubit(sl<MockAuthRepository>()));
  sl.registerSingleton<AuthManager>(AuthManager(
    userRepository: sl<UserRepository>(),
    keyValueStorage: sl<KeyValueStorage>(),
    authCubit: sl<AuthCubit>(),
  ));
}
```

- [ ] **Step 6: Update barrel file**

```dart
// packages/services/auth/lib/auth.dart
export 'src/manager.dart';
export 'src/di/setup.dart';
export 'src/cubit/auth_cubit.dart';
export 'src/cubit/auth_state.dart';
export 'src/repository/mock_auth_repository.dart';
```

- [ ] **Step 7: Write AuthCubit test**

```dart
// packages/services/auth/test/auth_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';
import 'package:auth/src/repository/mock_auth_repository.dart';

class MockAuthRepository extends Mock implements MockAuthRepository {}

void main() {
  group('AuthCubit', () {
    late AuthCubit cubit;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
      cubit = AuthCubit(mockRepo);
    });

    tearDown(() => cubit.close());

    test('initial state is AuthStatus.initial', () {
      expect(cubit.state.status, AuthStatus.initial);
    });

    test('login success changes state to loggedIn', () async {
      when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => true);
      await cubit.login('user', 'pass');
      expect(cubit.state.status, AuthStatus.loggedIn);
      expect(cubit.isLoggedIn, true);
    });

    test('login failure changes state to error', () async {
      when(() => mockRepo.login('', '')).thenAnswer((_) async => false);
      await cubit.login('', '');
      expect(cubit.state.status, AuthStatus.error);
    });

    test('logout resets state', () async {
      when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => true);
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      await cubit.login('user', 'pass');
      await cubit.logout();
      expect(cubit.state.status, AuthStatus.initial);
      expect(cubit.isLoggedIn, false);
    });
  });
}
```

- [ ] **Step 8: Run test**

Run: `fvm flutter test packages/services/auth/test/auth_cubit_test.dart`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add packages/services/auth/
git commit -m "feat(auth): add AuthCubit with state management"
```

---

## Task 2: Route Guard Infrastructure

**Files:**
- Create: `packages/infrastructure/routing/lib/src/guards/public_routes.dart`
- Create: `packages/infrastructure/routing/lib/src/guards/auth_guard.dart`
- Modify: `lib/config.dart`
- Modify: `packages/infrastructure/routing/lib/src/routes/route_context.dart`
- Modify: `packages/infrastructure/routing/lib/src/routes/router.dart`
- Modify: `packages/infrastructure/routing/lib/routing.dart`
- Test: `test/unit/routing/auth_guard_test.dart`

- [ ] **Step 1: Add config override**

```dart
// lib/config.dart (add after line 53)
/// 是否启用路由守卫覆盖
static bool get enableAuthGuardOverride {
  return const bool.fromEnvironment('ENABLE_AUTH_GUARD', defaultValue: true);
}

/// 是否启用路由守卫
static bool get enableAuthGuard {
  if (isProd) {
    return enableAuthGuardOverride;
  }
  return true; // debug/staging 默认启用
}
```

- [ ] **Step 2: Create public_routes.dart**

```dart
// packages/infrastructure/routing/lib/src/guards/public_routes.dart
/// 公开路由白名单
///
/// 不需要登录即可访问的路由路径集合
const publicRoutes = {'/', '/home', '/login', '/register'};
```

- [ ] **Step 3: Create auth_guard.dart**

```dart
// packages/infrastructure/routing/lib/src/guards/auth_guard.dart
import 'package:go_router/go_router.dart';
import 'public_routes.dart';
import 'package:auth/auth.dart';

/// 路由守卫
///
/// 检查用户认证状态，未登录用户访问非白名单路由时重定向到登录页
class AuthGuard {
  /// 检查路由是否需要重定向
  ///
  /// 返回 null 表示允许访问
  /// 返回 String 表示重定向目标
  static String? check(String location, AuthManager auth) {
    if (!auth.isLoggedIn && !publicRoutes.contains(location)) {
      return '/login?redirect=$location';
    }
    return null;
  }
}
```

- [ ] **Step 4: Update RouteContext**

```dart
// packages/infrastructure/routing/lib/src/routes/route_context.dart
import 'package:flutter/material.dart';
import 'package:auth/auth.dart';

/// RouteContext bundles dependencies for route modules.
class RouteContext {
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthManager? authManager;
  final bool enableAuthGuard;

  const RouteContext({
    required this.navigatorKey,
    this.authManager,
    this.enableAuthGuard = true,
  });
}
```

- [ ] **Step 5: Update router.dart**

```dart
// packages/infrastructure/routing/lib/src/routes/router.dart (modify)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_context.dart';
import 'module_a.dart';
import 'module_b.dart';
import '../guards/auth_guard.dart';
import '../../../config.dart' show EnvironmentConfig;

class AppRouter {
  static late GoRouter router;

  static GoRouter getRouter({required RouteContext ctx}) {
    router = GoRouter(
      initialLocation: '/home',
      redirect: ctx.enableAuthGuard && ctx.authManager != null
          ? (context, state) {
              final location = state.matchedLocation;
              return AuthGuard.check(location, ctx.authManager!);
            }
          : null,
      routes: [
        StatefulShellRoute.indexedStack(
          pageBuilder: (context, state, navigationShell) {
            return NoTransitionPage(
              key: state.pageKey,
              child: _MainShell(navigationShell: navigationShell),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [...ModuleARouteModule(ctx).build()],
            ),
            StatefulShellBranch(
              routes: [...ModuleBRouteModule(ctx).build()],
            ),
          ],
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: Text('Detail')),
            body: Center(child: Text('This is a detail page')),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found')),
      ),
    );
    return router;
  }
}

// ... _MainShell unchanged
```

- [ ] **Step 6: Update routing.dart barrel file**

```dart
// packages/infrastructure/routing/lib/routing.dart
export 'src/routes/router.dart';
export 'src/routes/route_context.dart';
export 'src/routes/routes.dart';
export 'src/routes/app_routes.dart';
export 'src/routes/route_module.dart';
export 'src/guards/auth_guard.dart';
export 'src/guards/public_routes.dart';
```

- [ ] **Step 7: Write auth_guard test**

```dart
// test/unit/routing/auth_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routing/src/guards/auth_guard.dart';
import 'package:routing/src/guards/public_routes.dart';
import 'package:auth/auth.dart';

class MockAuthManager extends Mock implements AuthManager {}

void main() {
  group('AuthGuard', () {
    late MockAuthManager mockAuth;

    setUp(() {
      mockAuth = MockAuthManager();
    });

    test('whitelist routes return null', () {
      when(() => mockAuth.isLoggedIn).thenReturn(false);
      for (final route in publicRoutes) {
        expect(AuthGuard.check(route, mockAuth), null);
      }
    });

    test('logged in user no redirect', () {
      when(() => mockAuth.isLoggedIn).thenReturn(true);
      expect(AuthGuard.check('/profile', mockAuth), null);
    });

    test('not logged in non-whitelist redirect to login', () {
      when(() => mockAuth.isLoggedIn).thenReturn(false);
      final result = AuthGuard.check('/profile', mockAuth);
      expect(result, '/login?redirect=/profile');
    });

    test('redirect preserves original path', () {
      when(() => mockAuth.isLoggedIn).thenReturn(false);
      final result = AuthGuard.check('/settings/theme', mockAuth);
      expect(result, contains('/login?redirect=/settings/theme'));
    });
  });
}
```

- [ ] **Step 8: Run test**

Run: `fvm flutter test test/unit/routing/auth_guard_test.dart`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add packages/infrastructure/routing/ test/unit/routing/ lib/config.dart
git commit -m "feat(routing): add auth guard with whitelist pattern"
```

---

## Task 3: Login/Register Feature

**Files:**
- Create: `packages/features/feature_auth/pubspec.yaml`
- Create: `packages/features/feature_auth/lib/feature_auth.dart`
- Create: `packages/features/feature_auth/lib/src/di/setup.dart`
- Create: `packages/features/feature_auth/lib/src/cubit/login_cubit.dart`
- Create: `packages/features/feature_auth/lib/src/cubit/login_state.dart`
- Create: `packages/features/feature_auth/lib/src/repository/auth_repository.dart`
- Create: `packages/features/feature_auth/lib/src/repository/mock_auth_repository.dart`
- Create: `packages/features/feature_auth/lib/src/ui/login_page.dart`
- Create: `packages/features/feature_auth/lib/src/ui/register_page.dart`
- Test: `packages/features/feature_auth/test/login_cubit_test.dart`

- [ ] **Step 1: Create pubspec.yaml**

```yaml
# packages/features/feature_auth/pubspec.yaml
name: feature_auth
description: Login/Register feature module (scaffold demo)
version: 0.0.1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  equatable: ^2.0.5
  component_library:
    path: ../../infrastructure/component_library
  routing:
    path: ../../infrastructure/routing
  go_router: ^14.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
```

- [ ] **Step 2: Create LoginState**

```dart
// packages/features/feature_auth/lib/src/cubit/login_state.dart
import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, error }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({this.status = LoginStatus.initial, this.errorMessage});

  LoginState copyWith({LoginStatus? status, String? errorMessage}) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
```

- [ ] **Step 3: Create LoginCubit**

```dart
// packages/features/feature_auth/lib/src/cubit/login_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_state.dart';
import '../repository/mock_auth_repository.dart';

class LoginCubit extends Cubit<LoginState> {
  final MockAuthRepository _repository;

  LoginCubit(this._repository) : super(const LoginState());

  Future<void> login(String username, String password) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final success = await _repository.login(username, password);
      emit(state.copyWith(
        status: success ? LoginStatus.success : LoginStatus.error,
        errorMessage: success ? null : '用户名或密码错误',
      ));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.error, errorMessage: e.toString()));
    }
  }

  void reset() {
    emit(const LoginState());
  }
}
```

- [ ] **Step 4: Create AuthRepository interface**

```dart
// packages/features/feature_auth/lib/src/repository/auth_repository.dart
abstract class AuthRepository {
  Future<bool> login(String username, String password);
  Future<bool> register(String username, String password);
  Future<void> logout();
}
```

- [ ] **Step 5: Create MockAuthRepository**

```dart
// packages/features/feature_auth/lib/src/repository/mock_auth_repository.dart
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return username.isNotEmpty && password.length >= 6;
  }

  @override
  Future<bool> register(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return username.isNotEmpty && password.length >= 6;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
```

- [ ] **Step 6: Create LoginPage**

```dart
// packages/features/feature_auth/lib/src/ui/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/login_cubit.dart';
import '../repository/mock_auth_repository.dart';

class LoginPage extends StatelessWidget {
  final String? redirect;

  const LoginPage({super.key, this.redirect});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(MockAuthRepository()),
      child: Scaffold(
        appBar: AppBar(title: const Text('登录')),
        body: BlocConsumer<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state.status == LoginStatus.success) {
              final target = redirect ?? '/home';
              context.go(target);
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: '用户名'),
                    onChanged: (v) => context.read<LoginCubit>().username = v,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: '密码'),
                    obscureText: true,
                    onChanged: (v) => context.read<LoginCubit>().password = v,
                  ),
                  const SizedBox(height: 24),
                  if (state.status == LoginStatus.loading)
                    const CircularProgressIndicator(),
                  if (state.status == LoginStatus.error)
                    Text(state.errorMessage ?? '登录失败', style: TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: state.status == LoginStatus.loading
                        ? null
                        : () => context.read<LoginCubit>().login(
                              context.read<LoginCubit>().username,
                              context.read<LoginCubit>().password,
                            ),
                    child: const Text('登录'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register?redirect=$redirect'),
                    child: const Text('没有账号？注册'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Create RegisterPage**

```dart
// packages/features/feature_auth/lib/src/ui/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/login_cubit.dart';
import '../repository/mock_auth_repository.dart';

class RegisterPage extends StatelessWidget {
  final String? redirect;

  const RegisterPage({super.key, this.redirect});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(MockAuthRepository()),
      child: Scaffold(
        appBar: AppBar(title: const Text('注册')),
        body: BlocConsumer<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state.status == LoginStatus.success) {
              final target = redirect ?? '/home';
              context.go(target);
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: '用户名'),
                    onChanged: (v) => context.read<LoginCubit>().username = v,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: '密码'),
                    obscureText: true,
                    onChanged: (v) => context.read<LoginCubit>().password = v,
                  ),
                  const SizedBox(height: 24),
                  if (state.status == LoginStatus.loading)
                    const CircularProgressIndicator(),
                  if (state.status == LoginStatus.error)
                    Text(state.errorMessage ?? '注册失败', style: TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: state.status == LoginStatus.loading
                        ? null
                        : () => context.read<LoginCubit>().login(
                              context.read<LoginCubit>().username,
                              context.read<LoginCubit>().password,
                            ),
                    child: const Text('注册'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login?redirect=$redirect'),
                    child: const Text('已有账号？登录'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Create DI setup**

```dart
// packages/features/feature_auth/lib/src/di/setup.dart
import 'package:get_it/get_it.dart';
import 'cubit/login_cubit.dart';
import 'repository/mock_auth_repository.dart';

void setupFeatureAuth(GetIt sl) {
  sl.registerFactory<MockAuthRepository>(() => MockAuthRepository());
  sl.registerFactory<LoginCubit>(() => LoginCubit(sl<MockAuthRepository>()));
}
```

- [ ] **Step 9: Create barrel file**

```dart
// packages/features/feature_auth/lib/feature_auth.dart
export 'src/di/setup.dart';
export 'src/cubit/login_cubit.dart';
export 'src/cubit/login_state.dart';
export 'src/ui/login_page.dart';
export 'src/ui/register_page.dart';
```

- [ ] **Step 10: Write LoginCubit test**

```dart
// packages/features/feature_auth/test/login_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_auth/src/cubit/login_cubit.dart';
import 'package:feature_auth/src/cubit/login_state.dart';
import 'package:feature_auth/src/repository/mock_auth_repository.dart';

void main() {
  group('LoginCubit', () {
    late LoginCubit cubit;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
      cubit = LoginCubit(mockRepo);
    });

    tearDown(() => cubit.close());

    test('initial state is initial', () {
      expect(cubit.state.status, LoginStatus.initial);
    });

    test('login success changes state to success', () async {
      await cubit.login('user', 'password123');
      expect(cubit.state.status, LoginStatus.success);
    });

    test('login with short password changes state to error', () async {
      await cubit.login('user', 'short');
      expect(cubit.state.status, LoginStatus.error);
    });

    test('reset returns to initial state', () async {
      await cubit.login('user', 'password123');
      cubit.reset();
      expect(cubit.state.status, LoginStatus.initial);
    });
  });
}
```

- [ ] **Step 11: Run test**

Run: `cd packages/features/feature_auth && fvm flutter test test/login_cubit_test.dart`
Expected: PASS

- [ ] **Step 12: Commit**

```bash
git add packages/features/feature_auth/
git commit -m "feat(auth): add login/register pages with mock repository"
```

---

## Task 4: Register Routes + DI Integration

**Files:**
- Modify: `packages/infrastructure/routing/lib/src/routes/module_b.dart`
- Modify: `lib/core/di/setup.dart`
- Modify: `lib/app.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add login/register routes**

```dart
// packages/infrastructure/routing/lib/src/routes/module_b.dart (modify)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_module.dart';
import 'route_context.dart';
import 'package:feature_auth/feature_auth.dart';

class ModuleBRouteModule extends RouteModule {
  ModuleBRouteModule(RouteContext ctx) : super(ctx);

  @override
  List<RouteBase> build() {
    return [
      GoRoute(
        path: '/settings',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text('Settings')),
          body: Center(child: Text('Settings Page')),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return LoginPage(redirect: redirect);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return RegisterPage(redirect: redirect);
        },
      ),
    ];
  }
}
```

- [ ] **Step 2: Update DI setup**

```dart
// lib/core/di/setup.dart (add after line 52)
import 'package:feature_auth/feature_auth.dart';

void setupDependencies() {
  // ... existing code ...
  
  // ===== Step 5: 业务功能层 =====
  setupFeatureHome(sl);
  setupFeatureDetail(sl);
  setupFeatureAuth(sl);  // NEW
  
  configureEasyLoading();
}
```

- [ ] **Step 3: Update app.dart**

```dart
// lib/app.dart (modify to pass AuthManager)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routing/routing.dart';
import 'package:auth/auth.dart';
import 'package:locale/locale.dart';
import 'package:network/network.dart';
import 'core/di/locator.dart';
import 'config.dart';

class SpineFlutter extends StatelessWidget {
  const SpineFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    final authManager = sl<AuthManager>();
    
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<LocaleCubit>()),
        BlocProvider.value(value: sl<NetworkCubit>()),
        BlocProvider.value(value: sl<AuthCubit>()),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter.getRouter(
          ctx: RouteContext(
            navigatorKey: GlobalKey<NavigatorState>(),
            authManager: authManager,
            enableAuthGuard: EnvironmentConfig.enableAuthGuard,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add pubspec dependency**

```yaml
# pubspec.yaml (add in dependencies)
feature_auth:
  path: packages/features/feature_auth
```

- [ ] **Step 5: Run pub get**

Run: `make get`
Expected: No errors

- [ ] **Step 6: Manual verification**

Run: `make debug-simulator`
Manual: Navigate to `/login`, verify page shows. Navigate to `/settings` (non-whitelist), verify redirect to `/login?redirect=/settings`.

- [ ] **Step 7: Commit**

```bash
git add lib/ packages/infrastructure/routing/ pubspec.yaml
git commit -m "feat: integrate auth routes and guard into app"
```

---

## Task 5: Domain Tests Phase 1 (Usecases)

**Files:**
- Create: `test/unit/domain/usecases/get_user_usecase_test.dart`

- [ ] **Step 1: Write GetUserUseCase test**

```dart
// test/unit/domain/usecases/get_user_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('GetUserUseCase', () {
    late GetUserUseCase usecase;
    late MockUserRepository mockRepo;

    setUp(() {
      mockRepo = MockUserRepository();
      usecase = GetUserUseCase(mockRepo);
    });

    test('execute returns User from repository', () async {
      final expectedUser = User(id: '1', name: 'Test User', email: 'test@example.com');
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => expectedUser);

      final result = await usecase.execute();

      expect(result.id, '1');
      expect(result.name, 'Test User');
      expect(result.email, 'test@example.com');
      verify(() => mockRepo.getCurrentUser()).called(1);
    });

    test('execute throws UnauthorizedException when repo throws', () async {
      when(() => mockRepo.getCurrentUser()).thenThrow(UnauthorizedException());

      expect(
        () => usecase.execute(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('execute throws NetworkException when repo throws', () async {
      when(() => mockRepo.getCurrentUser()).thenThrow(NetworkException('Network failed'));

      expect(
        () => usecase.execute(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run test**

Run: `fvm flutter test test/unit/domain/usecases/get_user_usecase_test.dart`
Expected: PASS

- [ ] **Step 3: Run coverage**

Run: `fvm flutter test --coverage`
Expected: coverage/lcov.info generated

- [ ] **Step 4: Check coverage**

Run: `lcov --summary coverage/lcov.info | grep domain/usecases`
Expected: usecases coverage 100%

- [ ] **Step 5: Commit**

```bash
git add test/unit/domain/
git commit -m "test(domain): add GetUserUseCase tests with 100% coverage"
```

---

## Task 6: Domain Tests Phase 2 (Models/Exceptions)

**Files:**
- Create: `test/unit/domain/models/user_test.dart`
- Create: `test/unit/domain/exceptions/domain_exception_test.dart`

- [ ] **Step 1: Write User model test**

```dart
// test/unit/domain/models/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

void main() {
  group('User', () {
    test('fromJson creates User correctly', () {
      final json = {'id': '1', 'name': 'Test', 'avatar': 'url', 'email': 'test@example.com'};
      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.name, 'Test');
      expect(user.avatar, 'url');
      expect(user.email, 'test@example.com');
    });

    test('toJson produces correct map', () {
      final user = User(id: '1', name: 'Test', avatar: 'url', email: 'test@example.com');
      final json = user.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Test');
      expect(json['avatar'], 'url');
      expect(json['email'], 'test@example.com');
    });

    test('equality works correctly', () {
      final user1 = User(id: '1', name: 'Test');
      final user2 = User(id: '1', name: 'Test');
      final user3 = User(id: '2', name: 'Other');

      expect(user1, user2);
      expect(user1, isNot(user3));
    });

    test('props includes all fields', () {
      final user = User(id: '1', name: 'Test', avatar: 'url', email: 'test@example.com');
      expect(user.props, ['1', 'Test', 'url', 'test@example.com']);
    });
  });
}
```

- [ ] **Step 2: Write exception test**

```dart
// test/unit/domain/exceptions/domain_exception_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

void main() {
  group('DomainException', () {
    test('NetworkException carries statusCode', () {
      final ex = NetworkException('Failed', statusCode: 500);
      expect(ex.message, 'Failed');
      expect(ex.statusCode, 500);
    });

    test('UnauthorizedException has default message', () {
      final ex = UnauthorizedException();
      expect(ex.message, '认证已过期');
    });

    test('NotFoundException has default message', () {
      final ex = NotFoundException();
      expect(ex.message, '请求的资源不存在');
    });

    test('ValidationException carries field errors', () {
      final ex = ValidationException('Invalid', fieldErrors: {'email': '格式错误'});
      expect(ex.fieldErrors['email'], '格式错误');
    });

    test('sealed class allows exhaustive matching', () {
      final exceptions = [
        NetworkException('net'),
        UnauthorizedException(),
        NotFoundException(),
        ValidationException('val'),
      ];

      for (final ex in exceptions) {
        final result = switch (ex) {
          NetworkException() => 'network',
          UnauthorizedException() => 'unauthorized',
          NotFoundException() => 'notfound',
          ValidationException() => 'validation',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
```

- [ ] **Step 3: Run tests**

Run: `fvm flutter test test/unit/domain/`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add test/unit/domain/
git commit -m "test(domain): add models and exceptions tests"
```

---

## Task 7: CI Coverage Workflow

**Files:**
- Create: `.github/workflows/coverage.yml`
- Create: `scripts/coverage_local.sh`
- Modify: `makefile`

- [ ] **Step 1: Create coverage workflow**

```yaml
# .github/workflows/coverage.yml
name: Coverage

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  coverage:
    name: 测试覆盖率报告
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.3'
          channel: 'stable'
      - name: Install dependencies
        run: flutter pub get
      - name: Run tests with coverage
        run: flutter test --coverage
      - name: Upload to codecov
        uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
          fail_ci_if_error: false
          verbose: true
        env:
          CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/lcov.info
          retention-days: 7
```

- [ ] **Step 2: Create local coverage script**

```bash
# scripts/coverage_local.sh
#!/bin/bash
set -e

echo "Running tests with coverage..."
fvm flutter test --coverage

echo "Generating HTML report..."
if ! command -v lcov &> /dev/null; then
    echo "lcov not found. Install with:"
    echo "  macOS: brew install lcov"
    echo "  Linux: sudo apt-get install lcov"
    exit 1
fi

# Filter to relevant files only
lcov --remove coverage/lcov.info \
  '*/test/*' \
  '*/.pub-cache/*' \
  '*/build/*' \
  -o coverage/lcov_filtered.info

# Generate HTML
genhtml coverage/lcov_filtered.info -o coverage/html --title "Spine Flutter Coverage"

echo "Opening coverage report..."
open coverage/html/index.html || xdg-open coverage/html/index.html

echo "Done! Report at coverage/html/index.html"
```

- [ ] **Step 3: Add makefile command**

```makefile
# makefile (add after line 83)
coverage-local:
	@chmod +x scripts/coverage_local.sh
	@./scripts/coverage_local.sh
```

- [ ] **Step 4: Set CODECOV_TOKEN secret**

Manual: Go to GitHub repo Settings → Secrets → Add `CODECOV_TOKEN` from codecov.io

- [ ] **Step 5: Manual test**

Run: `./scripts/coverage_local.sh`
Expected: HTML report opens in browser

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/coverage.yml scripts/coverage_local.sh makefile
git commit -m "feat(ci): add dual-track coverage reporting"
```

---

## Task 8: Documentation

**Files:**
- Create: `docs/auth-route-guard.md`
- Create: `docs/domain-testing-guide.md`
- Create: `docs/coverage-guide.md`
- Modify: `README.md`

- [ ] **Step 1: Write auth-route-guard.md**

```markdown
# Auth Route Guard

## 概述

路由守卫保护需要登录的路由，未登录用户访问时自动重定向到登录页。

## 启用控制

| 环境 | 默认启用 |
|------|----------|
| debug | ✓ |
| staging | ✓ |
| prod | 可配置（`--dart-define=ENABLE_AUTH_GUARD=false`） |

## 白名单路由

```dart
const publicRoutes = {'/', '/home', '/login', '/register'};
```

无需登录即可访问。

## Redirect 处理

访问 `/profile` 未登录 → `/login?redirect=/profile`

登录成功后自动跳转回原路径。

## 自定义白名单

编辑 `packages/infrastructure/routing/lib/src/guards/public_routes.dart`。

## 测试

```bash
fvm flutter test test/unit/routing/auth_guard_test.dart
```
```

- [ ] **Step 2: Write domain-testing-guide.md**

```markdown
# Domain Testing Guide

## 分层测试策略

| Phase | 覆盖范围 | 目标 |
|-------|----------|------|
| Phase 1 | usecases | 100% |
| Phase 2 | models + exceptions | 按实际 |
| Phase 3 | enums | ROI低，延后 |

## 测试位置

```
test/unit/domain/
├── usecases/     # Phase 1
├── models/       # Phase 2
├── exceptions/   # Phase 2
└── enums/        # Phase 3（延后）
```

## Mock 框架

使用 mocktail：

```dart
class MockUserRepository extends Mock implements UserRepository {}

when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => User(id: '1'));
```

## 运行命令

```bash
# 运行 domain 测试
fvm flutter test test/unit/domain/

# 带覆盖率
fvm flutter test --coverage
```

## 命名规范

`<class>_test.dart`，如 `get_user_usecase_test.dart`。
```

- [ ] **Step 3: Write coverage-guide.md**

```markdown
# Coverage Guide

## 双轨报告

| 方式 | 用途 |
|------|------|
| codecov.io | CI 自动，PR 可见 |
| 本地 HTML | 无网络依赖 |

## CI 使用

PR 自动触发 `.github/workflows/coverage.yml`，结果：
- codecov 评论显示覆盖率变化
- artifact 可下载 HTML

## 本地生成

```bash
make coverage-local
# 或
./scripts/coverage_local.sh
```

## 覆盖率目标

- Phase 1: usecases 100%
- Phase 2: models/exceptions 按实际
- 全项目: 逐步提升

## 安装 lcov

macOS: `brew install lcov`
Linux: `sudo apt-get install lcov`
```

- [ ] **Step 4: Update README.md**

```markdown
# README.md (add after line 80)

## 路由守卫

环境自动启用（debug/staging）。白名单：`/`, `/home`, `/login`, `/register`。

详细指南：[docs/auth-route-guard.md](docs/auth-route-guard.md)

## Domain 测试

按风险优先覆盖。Phase 1：usecases 100%。

详细指南：[docs/domain-testing-guide.md](docs/domain-testing-guide.md)

## Login/Register 示例

脚手架示例页面，无真实 API。位于 `packages/features/feature_auth/`。

## 测试覆盖率

双轨报告：CI codecov + 本地 HTML。

详细指南：[docs/coverage-guide.md](docs/coverage-guide.md)
```

- [ ] **Step 5: Commit**

```bash
git add docs/ README.md
git commit -m "docs: add auth guard, testing, coverage guides"
```

---

## Self-Review

### 1. Spec Coverage

| Spec Requirement | Task |
|------------------|------|
| 路由守卫环境控制 | Task 2 |
| 白名单模式 | Task 2 |
| Domain 测试 Phase 1 | Task 5 |
| Domain 测试 Phase 2 | Task 6 |
| CI codecov + artifact | Task 7 |
| 本地 HTML | Task 7 |
| Login/Register 页面 | Task 3 |
| redirect 参数 | Task 3, Task 4 |
| AuthManager isLoggedIn | Task 1 |
| 文档更新 | Task 8 |

All covered ✓

### 2. Placeholder Scan

No TBD, TODO, "implement later", vague descriptions found. All code complete.

### 3. Type Consistency

- `AuthManager.isLoggedIn` (bool getter) → used consistently in Task 2
- `AuthState.status` (AuthStatus enum) → used consistently
- `LoginState.status` (LoginStatus enum) → used consistently
- `MockAuthRepository.login()` → returns `Future<bool>` consistently

All consistent ✓

---

Plan complete. Saved to `docs/superpowers/plans/2026-05-04-security-testing-infra.md`.

Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?