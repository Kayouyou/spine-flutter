# P0-3 Login Token Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix login token persistence bug — ensure token is saved to TokenStorage and AuthCubit state is updated after successful login, so AuthGuard allows navigation to protected routes.

**Architecture:** LoginCubit will call AuthManager.handleLoginSuccess(LoginResult) after successful login/register. AuthManager will save token to TokenStorage and update AuthCubit state. AuthCubit.login()/logout() dead code will be removed.

**Tech Stack:** Flutter, flutter_bloc, GetIt (DI), mocktail (testing)

**Spec:** `docs/superpowers/specs/2026-06-16-p0-3-login-token-persistence-design.md`

---

## File Structure

### Files to Create
- `packages/services/auth/test/manager_handle_login_success_test.dart` — Test AuthManager.handleLoginSuccess
- `packages/features/feature_auth/test/cubit/login_cubit_auth_manager_test.dart` — Test LoginCubit integration with AuthManager

### Files to Modify
- `packages/services/auth/lib/src/manager.dart:60-77` — Add handleLoginSuccess method
- `packages/services/auth/lib/src/cubit/auth_cubit.dart:10-34` — Delete login()/logout(), simplify constructor
- `packages/services/auth/lib/src/di/setup.dart:42-48` — Update AuthCubit registration
- `packages/features/feature_auth/lib/src/cubit/login_cubit.dart:1-50` — Inject AuthManager, call handleLoginSuccess
- `packages/features/feature_auth/lib/src/di/setup.dart:8` — Update LoginCubit registration
- `packages/services/auth/test/auth_cubit_test.dart` — Delete login/logout tests
- `packages/features/feature_auth/test/cubit/login_cubit_test.dart` — Update to mock AuthManager

---

## Task 1: AuthManager.handleLoginSuccess — TDD

**Files:**
- Test: `packages/services/auth/test/manager_handle_login_success_test.dart`
- Modify: `packages/services/auth/lib/src/manager.dart`

### Step 1.1: Write failing test for handleLoginSuccess

Create test file:

```dart
// packages/services/auth/test/manager_handle_login_success_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:auth/src/manager.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockTokenStorage extends Mock implements TokenStorage {}
class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late AuthManager manager;
  late MockUserRepository mockUserRepo;
  late MockTokenStorage mockTokenStorage;
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockTokenStorage = MockTokenStorage();
    mockAuthCubit = MockAuthCubit();
    manager = AuthManager(
      userRepository: mockUserRepo,
      tokenStorage: mockTokenStorage,
      authCubit: mockAuthCubit,
    );
  });

  group('AuthManager.handleLoginSuccess', () {
    test('saves token to TokenStorage', () async {
      final loginResult = LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verify(() => mockTokenStorage.setToken('token-abc')).called(1);
    });

    test('saves userId to TokenStorage', () async {
      final loginResult = LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verify(() => mockTokenStorage.setUserId('user-123')).called(1);
    });

    test('updates AuthCubit state to loggedIn', () async {
      final loginResult = LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verify(() => mockAuthCubit.setAuthState(
        any(that: isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.loggedIn)
          .having((s) => s.userId, 'userId', 'user-123')),
      )).called(1);
    });

    test('calls saveToken and setUserId in correct order', () async {
      final loginResult = LoginResult(
        userId: 'user-123',
        token: 'token-abc',
      );

      await manager.handleLoginSuccess(loginResult);

      verifyInOrder([
        () => mockTokenStorage.setToken('token-abc'),
        () => mockTokenStorage.setUserId('user-123'),
        () => mockAuthCubit.setAuthState(any()),
      ]);
    });
  });
}
```

### Step 1.2: Run test to verify it fails

```bash
cd packages/services/auth
flutter test test/manager_handle_login_success_test.dart
```

Expected: FAIL — `The method 'handleLoginSuccess' isn't defined for class 'AuthManager'`

### Step 1.3: Implement handleLoginSuccess

Add to `packages/services/auth/lib/src/manager.dart` (after line 63):

```dart
  /// 处理登录成功后的状态更新
  ///
  /// 职责：
  /// 1. 保存 token 到 TokenStorage
  /// 2. 保存 userId 到 TokenStorage
  /// 3. 触发 AuthCubit 状态变化（AuthStatus.loggedIn）
  ///
  /// 由 LoginCubit 在 login/register 成功后调用。
  Future<void> handleLoginSuccess(LoginResult loginResult) async {
    await saveToken(loginResult.token, loginResult.userId);
    _authCubit.setAuthState(
      AuthState(status: AuthStatus.loggedIn, userId: loginResult.userId),
    );
    if (kDebugMode) {
      debugPrint('✅ [AuthManager] handleLoginSuccess: userId=${loginResult.userId}');
    }
  }
```

### Step 1.4: Run test to verify it passes

```bash
cd packages/services/auth
flutter test test/manager_handle_login_success_test.dart
```

Expected: PASS — All 4 tests pass

### Step 1.5: Commit

```bash
git add packages/services/auth/lib/src/manager.dart packages/services/auth/test/manager_handle_login_success_test.dart
git commit -m "feat(auth): add AuthManager.handleLoginSuccess for token persistence

- Saves token and userId to TokenStorage
- Updates AuthCubit state to loggedIn
- Called by LoginCubit after successful login/register
- Includes unit tests with mocktail"
```

---

## Task 2: LoginCubit Integration with AuthManager

**Files:**
- Test: `packages/features/feature_auth/test/cubit/login_cubit_auth_manager_test.dart`
- Modify: `packages/features/feature_auth/lib/src/cubit/login_cubit.dart`
- Modify: `packages/features/feature_auth/lib/src/di/setup.dart`

### Step 2.1: Write failing test for LoginCubit with AuthManager

Create test file:

```dart
// packages/features/feature_auth/test/cubit/login_cubit_auth_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:domain/domain.dart';
import 'package:feature_auth/src/cubit/login_cubit.dart';
import 'package:feature_auth/src/cubit/login_state.dart';
import 'package:auth/src/manager.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthManager extends Mock implements AuthManager {}

void main() {
  late MockAuthRepository mockRepository;
  late MockAuthManager mockAuthManager;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockAuthManager = MockAuthManager();
  });

  group('LoginCubit with AuthManager', () {
    test('constructor requires AuthManager', () {
      expect(
        () => LoginCubit(
          repository: mockRepository,
          authManager: mockAuthManager,
        ),
        returnsNormally,
      );
    });

    blocTest<LoginCubit, LoginState>(
      'login calls handleLoginSuccess on success',
      setUp: () {
        when(() => mockRepository.login(any(), any())).thenAnswer(
          (_) async => Result.success(
            LoginResult(userId: 'user-1', token: 'token-xyz'),
          ),
        );
      },
      build: () => LoginCubit(
        repository: mockRepository,
        authManager: mockAuthManager,
      ),
      act: (cubit) async {
        cubit.setUsername('testuser');
        cubit.setPassword('testpass');
        await cubit.login();
      },
      expect: () => [
        const LoginState(
          status: LoginStatus.loading,
          username: 'testuser',
          password: 'testpass',
        ),
        const LoginState(
          status: LoginStatus.success,
          username: 'testuser',
          password: 'testpass',
        ),
      ],
      verify: (_) {
        verify(() => mockAuthManager.handleLoginSuccess(
          any(that: isA<LoginResult>()
            .having((r) => r.userId, 'userId', 'user-1')
            .having((r) => r.token, 'token', 'token-xyz')),
        )).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'register calls handleLoginSuccess on success',
      setUp: () {
        when(() => mockRepository.register(any(), any())).thenAnswer(
          (_) async => Result.success(
            LoginResult(userId: 'user-2', token: 'token-abc', isNewUser: true),
          ),
        );
      },
      build: () => LoginCubit(
        repository: mockRepository,
        authManager: mockAuthManager,
      ),
      act: (cubit) async {
        cubit.setUsername('newuser');
        cubit.setPassword('newpass');
        await cubit.register();
      },
      expect: () => [
        const LoginState(
          status: LoginStatus.loading,
          username: 'newuser',
          password: 'newpass',
        ),
        const LoginState(
          status: LoginStatus.success,
          username: 'newuser',
          password: 'newpass',
        ),
      ],
      verify: (_) {
        verify(() => mockAuthManager.handleLoginSuccess(
          any(that: isA<LoginResult>()
            .having((r) => r.userId, 'userId', 'user-2')
            .having((r) => r.token, 'token', 'token-abc')),
        )).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'login does NOT call handleLoginSuccess on failure',
      setUp: () {
        when(() => mockRepository.login(any(), any())).thenAnswer(
          (_) async => Result.failure(
            const NetworkException('Invalid credentials'),
          ),
        );
      },
      build: () => LoginCubit(
        repository: mockRepository,
        authManager: mockAuthManager,
      ),
      act: (cubit) async {
        cubit.setUsername('baduser');
        cubit.setPassword('badpass');
        await cubit.login();
      },
      expect: () => [
        const LoginState(
          status: LoginStatus.loading,
          username: 'baduser',
          password: 'badpass',
        ),
        LoginState(
          status: LoginStatus.error,
          username: 'baduser',
          password: 'badpass',
          errorMessage: 'Invalid credentials',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockAuthManager.handleLoginSuccess(any()));
      },
    );
  });
}
```

### Step 2.2: Run test to verify it fails

```bash
cd packages/features/feature_auth
flutter test test/cubit/login_cubit_auth_manager_test.dart
```

Expected: FAIL — `The named parameter 'authManager' isn't defined`

### Step 2.3: Update LoginCubit to inject and use AuthManager

Replace `packages/features/feature_auth/lib/src/cubit/login_cubit.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'package:auth/src/manager.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;
  final AuthManager _authManager;

  LoginCubit({
    required AuthRepository repository,
    required AuthManager authManager,
  })  : _repository = repository,
        _authManager = authManager,
        super(const LoginState());

  void setUsername(String value) {
    emit(state.copyWith(username: value));
  }

  void setPassword(String value) {
    emit(state.copyWith(password: value));
  }

  Future<void> login() async {
    emit(state.copyWith(status: LoginStatus.loading));

    final result = await _repository.login(state.username, state.password);
    await result.when(
      success: (loginResult) async {
        await _authManager.handleLoginSuccess(loginResult);
        emit(state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
        ),);
      },
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      ),),
    );
  }

  Future<void> register() async {
    emit(state.copyWith(status: LoginStatus.loading));

    final result = await _repository.register(state.username, state.password);
    await result.when(
      success: (loginResult) async {
        await _authManager.handleLoginSuccess(loginResult);
        emit(state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
        ),);
      },
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      ),),
    );
  }

  void reset() {
    emit(const LoginState());
  }
}
```

### Step 2.4: Update DI registration

Modify `packages/features/feature_auth/lib/src/di/setup.dart` line 8:

```dart
void setupFeatureAuth(GetIt sl) {
  sl.registerFactory<LoginCubit>(() => LoginCubit(
    repository: sl<AuthRepository>(),
    authManager: sl<AuthManager>(),
  ));

  RouteModuleRegistry.instance.register(
    'feature_auth',
    (ctx) => AuthRouteModule(
      ctx,
      createCubit: () => sl<LoginCubit>(),
    ),
  );
}
```

### Step 2.5: Run test to verify it passes

```bash
cd packages/features/feature_auth
flutter test test/cubit/login_cubit_auth_manager_test.dart
```

Expected: PASS — All 3 tests pass

### Step 2.6: Update existing login_cubit_test.dart

Read existing test file and update to use new constructor:

```bash
cd packages/features/feature_auth
cat test/cubit/login_cubit_test.dart
```

Update all test setups to include `authManager: MockAuthManager()`.

### Step 2.7: Run all LoginCubit tests

```bash
cd packages/features/feature_auth
flutter test test/cubit/login_cubit_test.dart test/cubit/login_cubit_auth_manager_test.dart
```

Expected: PASS — All tests pass

### Step 2.8: Commit

```bash
git add packages/features/feature_auth/
git commit -m "feat(feature_auth): inject AuthManager into LoginCubit

- LoginCubit now requires AuthManager dependency
- login() and register() call handleLoginSuccess on success
- Ensures token is saved and AuthCubit state is updated
- DI registration updated
- Includes integration tests with mocktail"
```

---

## Task 3: Clean up AuthCubit dead code (P1-5)

**Files:**
- Modify: `packages/services/auth/lib/src/cubit/auth_cubit.dart`
- Modify: `packages/services/auth/lib/src/di/setup.dart`
- Modify: `packages/services/auth/test/auth_cubit_test.dart`

### Step 3.1: Remove login() and logout() from AuthCubit

Replace `packages/services/auth/lib/src/cubit/auth_cubit.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  bool get isLoggedIn => state.status == AuthStatus.loggedIn;

  /// 外部唯一写入入口：仅 AuthManager 可调
  ///
  /// 旧的 loggedIn(userId) public mutator 已删除 — 它允许任意模块
  /// 直接 emit, 制造 AuthCubit 与 AuthManager 双真相源.
  /// 所有状态变化必须经 AuthManager 流过来.
  void setAuthState(AuthState newState) => emit(newState);

  /// 登出 — 重置状态
  void logout() => emit(const AuthState());
}
```

### Step 3.2: Update AuthCubit DI registration

Modify `packages/services/auth/lib/src/di/setup.dart` line 45:

```dart
sl.registerLazySingleton<AuthCubit>(() => AuthCubit());
```

Remove the `authRepository: sl<AuthRepository>()` parameter.

### Step 3.3: Update auth_cubit_test.dart

Delete all `blocTest<AuthCubit, AuthState>` tests that test `login()` or `logout()`. Keep tests for:
- `isLoggedIn` getter
- `setAuthState` method
- Constructor and initial state

### Step 3.4: Run AuthCubit tests

```bash
cd packages/services/auth
flutter test test/auth_cubit_test.dart
```

Expected: PASS — Remaining tests pass

### Step 3.5: Commit

```bash
git add packages/services/auth/
git commit -m "refactor(auth): remove AuthCubit.login/logout dead code

- Remove login() and logout() methods (no production callers)
- Simplify AuthCubit constructor (no AuthRepository dependency)
- Keep setAuthState() as single entry point
- Update DI registration and tests
- Reduces AuthCubit responsibility to state management only"
```

---

## Task 4: End-to-End Verification

**Files:** None (verification only)

### Step 4.1: Run melos analyze

```bash
cd /Users/yeyangyang/Desktop/my_app
melos analyze
```

Expected: No errors, no warnings (may have pre-existing infos)

### Step 4.2: Run melos test:affected

```bash
melos test:affected
```

Expected: All affected packages pass tests

### Step 4.3: Run full test suite

```bash
melos test
```

Expected: All tests pass

### Step 4.4: Manual verification (optional)

If you want to manually test the login flow:

```bash
flutter run --dart-define=ENV=dev
```

1. Open app → redirected to /login
2. Enter username/password → click "登录"
3. Should navigate to /home (not redirected back to /login)
4. Restart app → should auto-login (skip login page)

### Step 4.5: Commit final changes

```bash
git add .
git commit -m "chore: verify P0-3 login token persistence fix

- All tests pass
- melos analyze clean
- Ready for PR"
```

---

## Acceptance Criteria Checklist

- [ ] LoginCubit calls AuthManager.handleLoginSuccess on successful login
- [ ] LoginCubit calls AuthManager.handleLoginSuccess on successful register
- [ ] AuthManager.saveToken is called with correct token
- [ ] AuthManager.saveUserId is called with correct userId
- [ ] AuthCubit state is updated to loggedIn
- [ ] AuthGuard allows navigation to protected routes after login
- [ ] App restart preserves login state (auto-login works)
- [ ] All unit tests pass
- [ ] AuthCubit.login()/logout() dead code removed
- [ ] `melos analyze` passes
- [ ] `melos test` passes

---

## Rollback Plan

If issues arise after deployment:

1. Revert the 4 commits:
```bash
git revert HEAD~4..HEAD
```

2. Push revert:
```bash
git push
```

3. Investigate and fix in a new branch

---

**Estimated time:** 2 hours
**Risk level:** Low (feature → service dependency allowed by R4)
**Breaking changes:** None (backward compatible)
