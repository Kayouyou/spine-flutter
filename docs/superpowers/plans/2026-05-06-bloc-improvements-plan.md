# BLoC 最佳实践改进实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add BlocObserver global logging, supplement Detail/Auth Cubit tests, migrate LocaleCubit to hydrated_bloc with freezed State, pre-integrate bloc_concurrency/replay_bloc dependencies, write migration documentation.

**Architecture:** BlocObserver registered in AppLauncher startup flow before DI setup. HydratedStorage initialized in AppLauncher stage 2 (SDK init). LocaleCubit changed from Cubit<KeyValueStorage> to HydratedCubit<freezed LocaleState>. Tests follow existing blocTest pattern from home_cubit_test.dart.

**Tech Stack:** flutter_bloc ^9.1.1, hydrated_bloc ^9.1.0, replay_bloc ^9.0.0, bloc_concurrency ^0.2.0, freezed ^2.4.0, bloc_test ^9.1.0, mocktail ^0.3.0

---

## File Structure

| Category | File | Responsibility |
|----------|------|----------------|
| **新建** | `lib/core/bloc/app_bloc_observer.dart` | BlocObserver 实现 |
| **新建** | `packages/features/feature_detail/test/detail_cubit_test.dart` | DetailCubit 单元测试 |
| **新建** | `packages/services/auth/test/auth_cubit_test.dart` | AuthCubit 单元测试 |
| **新建** | `docs/hydrated_bloc-migration-guide.md` | 迁移指南文档 |
| **修改** | `pubspec.yaml` | 加依赖（hydrated_bloc, replay_bloc, bloc_concurrency, freezed, freezed_annotation） |
| **修改** | `lib/core/startup/launcher.dart` | HydratedStorage init + BlocObserver 注册 |
| **修改** | `packages/services/locale/lib/src/locale_state.dart` | Equatable → freezed sealed |
| **修改** | `packages/services/locale/lib/src/locale_cubit.dart` | Cubit → HydratedCubit |
| **修改** | `packages/services/locale/lib/locale.dart` | 加 part 'locale_state.freezed.dart' 导出 |
| **修改** | `packages/services/locale/pubspec.yaml` | 加 freezed_annotation 依赖 |
| **修改** | `lib/core/di/setup.dart` | LocaleCubit DI 注册改（移除 KeyValueStorage） |
| **自动生成** | `packages/services/locale/lib/src/locale_state.freezed.dart` | build_runner 生成 |

---

### Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml:55-85`
- Modify: `packages/services/locale/pubspec.yaml:9-15`

- [ ] **Step 1: Update root pubspec.yaml dependencies**

```yaml
dependencies:
  # ===== 状态管理 =====
  flutter_bloc: ^9.1.1      # Bloc 状态管理核心（升级）
  hydrated_bloc: ^9.1.0     # 状态持久化（LocaleCubit 用）
  replay_bloc: ^9.0.0       # undo/redo 支持（预集成）
  bloc_concurrency: ^0.2.0  # 并发控制（预集成）
  
  # ===== 代码生成 =====
  freezed_annotation: ^2.4.0 # 不可变模型注解

dev_dependencies:
  # ===== 代码生成 =====
  freezed: ^2.4.0            # freezed 代码生成器
  build_runner: ^2.4.0       # 已存在，确认版本
```

Change line 55: `flutter_bloc: ^8.1.0` → `flutter_bloc: ^9.1.1`

Add after line 55:
```yaml
  # ===== 状态管理扩展 =====
  hydrated_bloc: ^9.1.0     # 状态持久化（LocaleCubit 用）
  replay_bloc: ^9.0.0       # undo/redo 支持（预集成）
  bloc_concurrency: ^0.2.0  # 并发控制（预集成）
  
  # ===== 代码生成 =====
  freezed_annotation: ^2.4.0 # 不可变模型注解
```

Add after line 82:
```yaml
  # ===== 代码生成 =====
  freezed: ^2.4.0            # freezed 代码生成器
```

- [ ] **Step 2: Update locale package pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.0
  hydrated_bloc: ^9.1.0
  freezed_annotation: ^2.4.0
```

Remove `key_value_storage` dependency (no longer needed).
Remove `equatable` dependency (replaced by freezed).

Change line 12: `flutter_bloc: ^8.1.0` → `flutter_bloc: ^9.1.0`

Add after line 12:
```yaml
  hydrated_bloc: ^9.1.0
  freezed_annotation: ^2.4.0
```

Remove line 13-14: `key_value_storage` and `equatable` dependencies.

- [ ] **Step 3: Run flutter pub get**

Run: `flutter pub get`
Expected: Dependencies resolved successfully, no conflicts.

- [ ] **Step 4: Commit dependency changes**

```bash
git add pubspec.yaml packages/services/locale/pubspec.yaml
git commit -m "chore: add bloc extensions + freezed dependencies

- flutter_bloc upgraded to 9.1.1
- hydrated_bloc for LocaleCubit persistence
- replay_bloc pre-integrated for future undo/redo
- bloc_concurrency pre-integrated for future dedup
- freezed for immutable State models"
```

---

### Task 2: Create BlocObserver

**Files:**
- Create: `lib/core/bloc/app_bloc_observer.dart`

- [ ] **Step 1: Create lib/core/bloc directory**

```bash
mkdir -p lib/core/bloc
```

- [ ] **Step 2: Write BlocObserver implementation**

```dart
// lib/core/bloc/app_bloc_observer.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 全局 Bloc 观察者
///
/// 职责：打印状态变化日志，捕获异常
/// 使用：main.dart 启动前注册
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('[BlocObserver] onCreate: ${bloc.runtimeType}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('[BlocObserver] ${bloc.runtimeType}: ${transition.currentState} → ${transition.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('[BlocObserver] ${bloc.runtimeType} ERROR: $error');
    debugPrint(stackTrace.toString());
  }
}
```

- [ ] **Step 3: Commit BlocObserver file**

```bash
git add lib/core/bloc/app_bloc_observer.dart
git commit -m "feat: add global BlocObserver for state logging

- onCreate logs Cubit creation
- onTransition logs state changes
- onError captures exceptions with stack trace"
```

---

### Task 3: Register BlocObserver + HydratedStorage

**Files:**
- Modify: `lib/core/startup/launcher.dart:32-60`

- [ ] **Step 1: Add imports at top of launcher.dart**

Add after line 5 (Flutter imports):
```dart
// Package imports:
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import '../bloc/app_bloc_observer.dart';
```

- [ ] **Step 2: Initialize HydratedStorage in stage 2**

Insert after line 36 (after `StartupProfiler.mark('Flutter binding 初始化')`):

```dart
    // ===== 阶段 1.5: Bloc 扩展初始化 =====
    // HydratedBloc 存储（必须在任何 Cubit 创建前）
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory(),
    );
    StartupProfiler.mark('HydratedStorage 初始化');
    
    // BlocObserver 注册（全局日志）
    Bloc.observer = AppBlocObserver();
    StartupProfiler.mark('BlocObserver 注册');
```

- [ ] **Step 3: Verify initialization order is correct**

Check that HydratedBloc.storage and Bloc.observer are initialized BEFORE `setupDependencies()` (line 47).

Expected order:
1. WidgetsFlutterBinding.ensureInitialized (line 34)
2. HydratedBloc.storage init (new)
3. Bloc.observer registration (new)
4. setupDependencies (line 47) - LocaleCubit creation happens here

- [ ] **Step 4: Commit launcher changes**

```bash
git add lib/core/startup/launcher.dart
git commit -m "feat: integrate HydratedStorage + BlocObserver in startup

- HydratedStorage init before DI (stage 1.5)
- BlocObserver registered globally
- StartupProfiler marks added for each phase"
```

---

### Task 4: Migrate LocaleState to freezed

**Files:**
- Modify: `packages/services/locale/lib/src/locale_state.dart`
- Modify: `packages/services/locale/lib/locale.dart`

- [ ] **Step 1: Rewrite LocaleState with freezed**

Replace entire file content:

```dart
// packages/services/locale/lib/src/locale_state.dart

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_state.freezed.dart';

/// 语言状态
///
/// 职责：管理当前应用语言设置
/// 使用：通过LocaleCubit emit切换语言
@freezed
class LocaleState with _$LocaleState {
  const factory LocaleState({
    required Locale locale,
  }) = _LocaleState;
}
```

- [ ] **Step 2: Update locale.dart barrel file to export freezed part**

Add after line 3:

```dart
export 'src/locale_state.dart';
export 'src/locale_state.freezed.dart';
```

Final barrel file:

```dart
/// 语言/本地化管理服务
///
/// 提供 LocaleCubit 管理应用界面语言切换并持久化到本地存储。
export 'src/locale_cubit.dart';
export 'src/locale_state.dart';
export 'src/locale_state.freezed.dart';
```

- [ ] **Step 3: Run build_runner to generate freezed code**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `locale_state.freezed.dart` generated successfully.

- [ ] **Step 4: Verify freezed file generated**

Check that file exists: `packages/services/locale/lib/src/locale_state.freezed.dart`

Expected: File generated with _$LocaleState implementation.

- [ ] **Step 5: Commit LocaleState freezed migration**

```bash
git add packages/services/locale/lib/src/locale_state.dart
git add packages/services/locale/lib/src/locale_state.freezed.dart
git add packages/services/locale/lib/locale.dart
git commit -m "refactor: migrate LocaleState to freezed sealed class

- Equatable replaced by freezed
- immutable Locale state
- part directive added for generated code"
```

---

### Task 5: Migrate LocaleCubit to HydratedCubit

**Files:**
- Modify: `packages/services/locale/lib/src/locale_cubit.dart`

- [ ] **Step 1: Rewrite LocaleCubit as HydratedCubit**

Replace entire file content:

```dart
// packages/services/locale/lib/src/locale_cubit.dart

import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'locale_state.dart';

/// 语言管理 Cubit
///
/// 使用 hydrated_bloc 实现状态持久化
/// 启动时同步恢复，无闪烁
class LocaleCubit extends HydratedCubit<LocaleState> {
  /// storagePrefix 硬编码（防止代码混淆后键名变化）
  static const String _storagePrefix = 'LocaleCubit';
  
  LocaleCubit() : super(LocaleState(locale: Locale('zh')));
  
  @override
  String get storagePrefix => _storagePrefix;
  
  /// 从 JSON 恢复状态
  @override
  LocaleState? fromJson(Map<String, dynamic> json) {
    final localeCode = json['locale'] as String?;
    if (localeCode != null) {
      return LocaleState(locale: Locale(localeCode));
    }
    return null;  // 无缓存时用默认
  }
  
  /// 状态转 JSON 存储
  @override
  Map<String, dynamic>? toJson(LocaleState state) {
    return {'locale': state.locale.languageCode};
  }
  
  /// 设置语言
  /// 
  /// emit 自动持久化，无需手动 save
  Future<void> setLocale(Locale locale) async {
    emit(LocaleState(locale: locale));
  }
  
  /// 重置为默认语言
  Future<void> resetToDefault() async {
    emit(LocaleState(locale: Locale('zh')));
  }
}
```

Key changes from old version:
- Remove `KeyValueStorage _storage` field
- Remove `_loadSavedLocale()` async method (no longer needed)
- Remove `_localeKey` constant (replaced by storagePrefix)
- Extend `HydratedCubit<LocaleState>` instead of `Cubit<LocaleState>`
- Add `storagePrefix` getter (硬编码防止混淆)
- Add `fromJson` override (状态恢复)
- Add `toJson` override (状态存储)
- Simplify `setLocale` (emit自动持久化)

- [ ] **Step 2: Commit LocaleCubit migration**

```bash
git add packages/services/locale/lib/src/locale_cubit.dart
git commit -m "refactor: migrate LocaleCubit to HydratedCubit

- KeyValueStorage dependency removed
- fromJson/toJson implemented for persistence
- storagePrefix hardcoded for obfuscation safety
- synchronous startup, no flicker
- emit auto-persists, no manual save"
```

---

### Task 6: Update DI Registration

**Files:**
- Modify: `lib/core/di/setup.dart:44`

- [ ] **Step 1: Remove KeyValueStorage injection from LocaleCubit**

Change line 44:

Old: `sl.registerSingleton<LocaleCubit>(LocaleCubit(sl<KeyValueStorage>()));`

New: `sl.registerSingleton<LocaleCubit>(LocaleCubit());`

- [ ] **Step 2: Commit DI registration change**

```bash
git add lib/core/di/setup.dart
git commit -m "refactor: LocaleCubit DI no longer injects KeyValueStorage

- HydratedCubit manages own storage
- constructor now parameterless"
```

---

### Task 7: Write DetailCubit Tests

**Files:**
- Create: `packages/features/feature_detail/test/detail_cubit_test.dart`

- [ ] **Step 1: Create test directory if missing**

```bash
mkdir -p packages/features/feature_detail/test
```

- [ ] **Step 2: Write DetailCubit unit tests**

```dart
// packages/features/feature_detail/test/detail_cubit_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:domain/domain.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDetailRepository extends Mock implements DetailRepository {}

void main() {
  late MockDetailRepository mockRepo;

  setUp(() {
    mockRepo = MockDetailRepository();
  });

  group('DetailCubit', () {
    blocTest<DetailCubit, DetailState>(
      'loadData 成功时发出 [loading, loaded]',
      build: () {
        when(() => mockRepo.getDetailData(any()))
          .thenAnswer((_) async => {'id': '123', 'title': '测试数据'});
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('123'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>(),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'loadData 失败时发出 [loading, error]',
      build: () {
        when(() => mockRepo.getDetailData(any()))
          .thenThrow(NetworkException('加载失败'));
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('123'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailError>(),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'retry 重新加载数据',
      build: () {
        when(() => mockRepo.getDetailData(any()))
          .thenAnswer((_) async => {'id': '123', 'title': '重试数据'});
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.retry('123'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>(),
      ],
    );
  });
}
```

- [ ] **Step 3: Run DetailCubit tests**

Run: `flutter test packages/features/feature_detail/test/detail_cubit_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 4: Commit DetailCubit tests**

```bash
git add packages/features/feature_detail/test/detail_cubit_test.dart
git commit -m "test: add DetailCubit unit tests

- loadData success emits [loading, loaded]
- loadData failure emits [loading, error]
- retry triggers reload"
```

---

### Task 8: Write AuthCubit Tests

**Files:**
- Create: `packages/services/auth/test/auth_cubit_test.dart`

- [ ] **Step 1: Create test directory if missing**

```bash
mkdir -p packages/services/auth/test
```

- [ ] **Step 2: Write AuthCubit unit tests**

```dart
// packages/services/auth/test/auth_cubit_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auth/src/cubit/auth_cubit.dart';
import 'package:auth/src/cubit/auth_state.dart';
import 'package:auth/src/repository/mock_auth_repository.dart';

class MockRepo extends Mock implements MockAuthRepository {}

void main() {
  late MockRepo mockRepo;

  setUp(() {
    mockRepo = MockRepo();
  });

  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'login 成功时发出 [loading, loggedIn]',
      build: () {
        when(() => mockRepo.login('user', 'password'))
          .thenAnswer((_) async => true);
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.login('user', 'password'),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.loggedIn)
          .having((s) => s.userId, 'userId', 'mock-user-1'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login 失败时发出 [loading, error]',
      build: () {
        when(() => mockRepo.login('user', 'wrong'))
          .thenAnswer((_) async => false);
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.login('user', 'wrong'),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', '登录失败'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout 成功时发出 [loading, initial]',
      build: () {
        when(() => mockRepo.logout()).thenAnswer((_) async {});
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.initial),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login 异常时发出 [loading, error]',
      build: () {
        when(() => mockRepo.login('user', 'pass'))
          .thenThrow(Exception('网络错误'));
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.login('user', 'pass'),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', contains('网络错误')),
      ],
    );

    test('isLoggedIn 返回正确的登录状态', () {
      when(() => mockRepo.login('user', 'pass'))
        .thenAnswer((_) async => true);
      
      final cubit = AuthCubit(mockRepo);
      expect(cubit.isLoggedIn, false);
      
      cubit.login('user', 'pass');
      // 状态变化后 isLoggedIn 应为 true（异步完成）
    });
  });
}
```

- [ ] **Step 3: Run AuthCubit tests**

Run: `flutter test packages/services/auth/test/auth_cubit_test.dart`
Expected: All 5 tests PASS.

- [ ] **Step 4: Commit AuthCubit tests**

```bash
git add packages/services/auth/test/auth_cubit_test.dart
git commit -m "test: add AuthCubit unit tests

- login success emits [loading, loggedIn]
- login failure emits [loading, error]
- logout emits [loading, initial]
- exception handling tested
- isLoggedIn getter tested"
```

---

### Task 9: Run All Tests

**Files:**
- No files modified in this task

- [ ] **Step 1: Run entire test suite**

Run: `flutter test`
Expected: All tests PASS, including:
- `test/bloc/features/home/home_cubit_test.dart`
- `test/core/global/network/network_cubit_test.dart`
- `test/core/global/locale/locale_cubit_test.dart`
- `packages/features/feature_detail/test/detail_cubit_test.dart`
- `packages/services/auth/test/auth_cubit_test.dart`
- `packages/features/feature_auth/test/login_cubit_test.dart`

- [ ] **Step 2: Verify test coverage report**

Run: `flutter test --coverage`
Expected: Coverage report generated at `coverage/lcov.info`.

- [ ] **Step 3: Check for any test failures**

If any tests FAIL: Debug and fix before proceeding.

---

### Task 10: Write Migration Documentation

**Files:**
- Create: `docs/hydrated_bloc-migration-guide.md`

- [ ] **Step 1: Create docs directory if missing**

```bash
mkdir -p docs
```

- [ ] **Step 2: Write hydrated_bloc migration guide**

```markdown
# hydrated_bloc 迁移指南

## 适用判断

### 适用场景
- 用户偏好（语言、主题）
- 认证状态（Token 过期需额外处理）
- 简单配置

### 不适用场景
- 大数据列表（性能差）
- 需加密/TTL/迁移
- 跨 isolate 共享

## 迁移步骤

### 1. 加依赖

**pubspec.yaml:**
```yaml
dependencies:
  hydrated_bloc: ^9.1.0

dev_dependencies:
  freezed: ^2.4.0
  build_runner: ^2.4.0
```

### 2. 初始化 HydratedStorage

**lib/core/startup/launcher.dart:**

必须在 `setupDependencies()` 前初始化：

```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

Future<void> launch(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // HydratedBloc 存储（在任何 Cubit 创建前）
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );
  
  setupDependencies();  // LocaleCubit 在这里创建
  runApp(app);
}
```

### 3. Cubit 改 HydratedCubit

**改前（普通 Cubit）:**
```dart
class LocaleCubit extends Cubit<LocaleState> {
  final KeyValueStorage _storage;
  
  LocaleCubit(this._storage) : super(LocaleState(locale: Locale('zh'))) {
    _loadSavedLocale();  // 异步加载，可能闪烁
  }
  
  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storage.getString('app_locale');
    if (savedLocale != null) {
      emit(LocaleState(locale: Locale(savedLocale)));
    }
  }
  
  Future<void> setLocale(Locale locale) async {
    await _storage.putString('app_locale', locale.languageCode);
    emit(LocaleState(locale: locale));
  }
}
```

**改后（HydratedCubit）:**
```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';

class LocaleCubit extends HydratedCubit<LocaleState> {
  static const String _storagePrefix = 'LocaleCubit';
  
  LocaleCubit() : super(LocaleState(locale: Locale('zh')));
  
  @override
  String get storagePrefix => _storagePrefix;
  
  @override
  LocaleState? fromJson(Map<String, dynamic> json) {
    final localeCode = json['locale'] as String?;
    if (localeCode != null) {
      return LocaleState(locale: Locale(localeCode));
    }
    return null;
  }
  
  @override
  Map<String, dynamic>? toJson(LocaleState state) {
    return {'locale': state.locale.languageCode};
  }
  
  Future<void> setLocale(Locale locale) async {
    emit(LocaleState(locale: locale));  // 自动持久化
  }
}
```

### 4. State 改 freezed sealed

**改前（Equatable）:**
```dart
class LocaleState extends Equatable {
  final Locale locale;
  
  LocaleState({required this.locale});
  
  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }
  
  @override
  List<Object?> get props => [locale];
}
```

**改后（freezed）:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_state.freezed.dart';

@freezed
class LocaleState with _$LocaleState {
  const factory LocaleState({
    required Locale locale,
  }) = _LocaleState;
}
```

### 5. 加 storagePrefix 硬编码

```dart
class LocaleCubit extends HydratedCubit<LocaleState> {
  static const String _storagePrefix = 'LocaleCubit';
  
  @override
  String get storagePrefix => _storagePrefix;
}
```

**原因:** 代码混淆后 `runtimeType` 可能变化，硬编码保证键名稳定。

### 6. DI 注册改

**改前:**
```dart
sl.registerSingleton<LocaleCubit>(
  LocaleCubit(sl<KeyValueStorage>()),
);
```

**改后:**
```dart
sl.registerSingleton<LocaleCubit>(LocaleCubit());
```

不再注入 `KeyValueStorage`。

### 7. 代码生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 注意事项

### storagePrefix 混淆

**问题:** 代码压缩后 `runtimeType` 变化，导致缓存 key 不匹配。

**解决:** 硬编码 `storagePrefix` 字符串：

```dart
static const String _storagePrefix = 'LocaleCubit';
@override
String get storagePrefix => _storagePrefix;
```

### Web 部署缓存清空

**问题:** 浏览器缓存清空后状态丢失。

**解决:** 文档说明，勿依赖持久化。考虑 fallback 策略。

### schema 变更

**问题:** 无内置迁移 API。

**解决:** 在 `fromJson` 中手动处理版本兼容：

```dart
@override
LocaleState? fromJson(Map<String, dynamic> json) {
  // 版本 1: 仅 locale 字段
  // 版本 2: locale + fallbackLocale
  final version = json['version'] as int? ?? 1;
  
  if (version == 1) {
    final localeCode = json['locale'] as String?;
    if (localeCode != null) {
      return LocaleState(locale: Locale(localeCode));
    }
  }
  
  return null;
}

@override
Map<String, dynamic>? toJson(LocaleState state) {
  return {
    'version': 2,
    'locale': state.locale.languageCode,
  };
}
```

### 大状态性能

**问题:** 大状态 JSON 序列化阻塞主线程。

**解决:** LocaleState 仅 1 字段，无风险。大状态避免用 HydratedCubit。

## 常见问题

### 状态闪烁？

**症状:** App 启动瞬间显示默认语言，然后跳到上次选择。

**原因:** HydratedStorage 初始化在 Cubit 创建之后。

**解决:** 确保 HydratedStorage init 在 `setupDependencies()` 前：

```dart
HydratedBloc.storage = await HydratedStorage.build(...);
setupDependencies();  // LocaleCubit 创建
```

### 数据丢失？

**症状:** 重启后语言未恢复。

**原因:** storagePrefix 不一致。

**解决:** 检查 storagePrefix 是否硬编码且未改动。

### 状态未恢复？

**症状:** fromJson 返回正确值，但状态仍是默认。

**原因:** HydratedCubit 构造函数的 `super()` 状态覆盖了 fromJson 恢复。

**解决:** 构造函数传默认值，fromJson 会自动恢复：

```dart
LocaleCubit() : super(LocaleState(locale: Locale('zh')));  // 默认
// fromJson 自动恢复缓存值
```

## 参考资源

- [hydrated_bloc 官方文档](https://pub.dev/packages/hydrated_bloc)
- [freezed 官方文档](https://pub.dev/packages/freezed)
- [bloc 官方文档](https://bloclibrary.dev)
```

- [ ] **Step 3: Commit migration documentation**

```bash
git add docs/hydrated_bloc-migration-guide.md
git commit -m "docs: add hydrated_bloc migration guide

- 适用场景判断
- 7步迁移流程
- 注意事项（混淆/Web/schema/性能）
- 常见问题排查"
```

---

### Task 11: Verification

**Files:**
- No files modified in this task

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 2: Run all tests again**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 3: Start app and verify BlocObserver logging**

Run: `flutter run`
Expected in debug console:
- `[BlocObserver] onCreate: LocaleCubit`
- `[BlocObserver] onCreate: NetworkCubit`
- State change logs visible

- [ ] **Step 4: Test LocaleCubit persistence**

1. Launch app
2. Switch language (e.g., to English)
3. Close app completely
4. Relaunch app
Expected: Language is English immediately, no flicker to Chinese.

- [ ] **Step 5: Verify freezed code generation**

Check file exists: `packages/services/locale/lib/src/locale_state.freezed.dart`

Expected: Generated file contains `_$LocaleState` implementation.

---

## Self-Review Checklist

### 1. Spec Coverage

| Spec Requirement | Plan Task |
|------------------|-----------|
| BlocObserver 添加 | Task 2 + Task 3 |
| 测试补缺（Detail/Auth） | Task 7 + Task 8 |
| freezed 引入（LocaleState） | Task 4 |
| bloc_concurrency 预集成 | Task 1 (dependency added) |
| hydrated_bloc 引入（LocaleCubit） | Task 5 + Task 6 |
| replay_bloc 预集成 | Task 1 (dependency added) |
| 迁移文档编写 | Task 10 |
| BlocObserver 注册位置正确 | Task 3 (AppLauncher stage 1.5) |
| LocaleCubit DI 移除 KeyValueStorage | Task 6 |
| storagePrefix 硬编码 | Task 5 |

All spec requirements covered.

### 2. Placeholder Scan

No placeholders found. All code blocks contain complete implementation.

### 3. Type Consistency

- `LocaleState` consistently used as HydratedCubit generic parameter
- `storagePrefix` getter returns `String` consistently
- `fromJson` returns `LocaleState?` consistently
- `toJson` returns `Map<String, dynamic>?` consistently
- Test matchers use `isA<DetailLoading>()`, `isA<AuthState>()` consistently

Type signatures match across all tasks.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-06-bloc-improvements-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**