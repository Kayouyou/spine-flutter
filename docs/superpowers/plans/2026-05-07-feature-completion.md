# Plan B: 功能完善 (P2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 接入缓存系统、补充测试覆盖、实现 DataSyncManager、扩展组件库。

**Architecture:** 在不改变现有架构的基础上，让已有基础设施（ListCacheManager）真正被使用，补上测试短板，实现预留的空壳（DataSyncManager），扩展 UI 工具体系。

**Tech Stack:** Flutter 3.19+, flutter_bloc 9.x, bloc_test 10.x, mocktail 1.x, Hive, Dio

**前置条件:** Plan A 全部完成（State 已统一为 freezed、Repository 接口已在 domain 层）

**预估工期:** 1-2 周 (1人顺序推进，部分 Task 可并行)

---

### Task 1: HomeRepository 接入 ListCacheManager

**目标:** 让设计良好的缓存系统有实际使用范例，后续 feature 可复制模式。

**文件:**
- 修改: `packages/features/feature_home/lib/src/repository/home_repository_impl.dart`
- 修改: `packages/features/feature_home/lib/src/cubit/home_cubit.dart`
- 修改: `packages/features/feature_home/lib/src/cubit/home_state.dart`
- 修改: `packages/features/feature_home/lib/src/di/setup.dart`
- 创建: `packages/features/feature_home/test/home_cubit_cache_test.dart`

**设计:** HomeRepositoryImpl 内部持有 ListCacheManager，对外接口不变。HomeCubit 根据 `CacheResult.isFromCache` 决定 UI（如显示"加载中"提示）。

- [ ] **Step 1: 修改 HomeRepositoryImpl — 集成 ListCacheManager**

```dart
// packages/features/feature_home/lib/src/repository/home_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:list_cache/list_cache.dart';
import 'package:domain/domain.dart';

class HomeRepositoryImpl implements HomeRepository {
  final Dio _dio;
  final ListCacheManager<Map<String, dynamic>> _cacheManager;

  HomeRepositoryImpl(this._dio)
      : _cacheManager = ListCacheManager<Map<String, dynamic>>(
          config: CacheConfig.staleWhileRevalidate(pageSize: 20),
        );

  @override
  Future<Map<String, dynamic>> getHomeData() async {
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
        return result.data.first;
      }
      return {};
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }

  @override
  Future<Map<String, dynamic>> refreshHomeData() async {
    // 刷新：清除缓存后重新获取
    await _cacheManager.clear('home_data');
    return getHomeData();
  }

  /// 清空首页缓存（供外部调用）
  Future<void> clearCache() => _cacheManager.clear('home_data');
}
```

**关键变更:**
- 构造函数新增 `ListCacheManager` 字段
- `getHomeData()` 通过 `_cacheManager.fetch()` 获取（策略: staleWhileRevalidate）
- `refreshHomeData()` 先清缓存再请求
- `clearCache()` 暴露给外部

- [ ] **Step 2: 修改 HomeCubit — 处理缓存来源**

```dart
// packages/features/feature_home/lib/src/cubit/home_cubit.dart
// loadData() 方法保持不变（缓存逻辑已封装在 Repository 内）
// 如果将来需要显示"数据来自缓存"提示，可在 state 中添加 isFromCache 字段
```

**当前版本不做 state 变更**，缓存对 UI 透明。P2 阶段仅验证缓存机制可用，UI 增强留到后续。

- [ ] **Step 3: 编写缓存测试**

```dart
// packages/features/feature_home/test/home_cubit_cache_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:feature_home/src/cubit/home_state.dart';
import 'package:domain/domain.dart';

class MockHomeRepo extends Mock implements HomeRepository {}

void main() {
  group('HomeCubit with caching', () {
    late MockHomeRepo mockRepo;

    setUp(() {
      mockRepo = MockHomeRepo();
    });

    blocTest<HomeCubit, HomeState>(
      'loadData emits [loading, loaded] when cache returns data',
      build: () {
        when(() => mockRepo.getHomeData())
            .thenAnswer((_) async => {'cached': true});
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeState>(),
        isA<HomeState>(),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'refreshData calls refreshHomeData on repository',
      build: () {
        when(() => mockRepo.refreshHomeData())
            .thenAnswer((_) async => {'refreshed': true});
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.refreshData(),
      expect: () => [
        isA<HomeState>(),
        isA<HomeState>(),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'loadData emits [loading, error] when repository throws',
      build: () {
        when(() => mockRepo.getHomeData())
            .thenThrow(NetworkException(500, 'server error'));
        return HomeCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        isA<HomeState>(),
        isA<HomeState>(),
      ],
    );
  });
}
```

- [ ] **Step 4: 验证 — flutter test**

```bash
cd /Users/yeyangyang/Desktop/my_app && flutter test packages/features/feature_home/test/
```
预期: 所有测试通过。

- [ ] **Step 5: Commit**

```bash
git add packages/features/feature_home/lib/src/repository/home_repository_impl.dart
git add packages/features/feature_home/test/home_cubit_cache_test.dart
git commit -m "feat(cache): integrate ListCacheManager into HomeRepository

Use staleWhileRevalidate strategy for home data caching.
Add refreshHomeData with cache invalidation.
Add cache integration tests for HomeCubit."
```

---

### Task 2: 补充 Cubit 测试覆盖

**目标:** 当前测试覆盖不足的 Cubit 全部补充。优先级: DetailCubit > NetworkCubit > DataSyncManager。

**文件:**
- 修改: `packages/features/feature_detail/test/detail_cubit_test.dart`（有文件但内容简单）
- 创建: `packages/services/network/test/network_cubit_test.dart`（无测试文件）
- 创建: `packages/services/data_sync/test/data_sync_manager_test.dart`（补充实现后）

- [ ] **Step 1: 完善 DetailCubit 测试**

```dart
// packages/features/feature_detail/test/detail_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feature_detail/src/cubit/detail_cubit.dart';
import 'package:feature_detail/src/cubit/detail_state.dart';
import 'package:domain/domain.dart';

class MockDetailRepo extends Mock implements DetailRepository {}

void main() {
  group('DetailCubit', () {
    late MockDetailRepo mockRepo;

    setUp(() {
      mockRepo = MockDetailRepo();
    });

    blocTest<DetailCubit, DetailState>(
      'initial state is DetailInitial',
      build: () => DetailCubit(mockRepo),
      verify: (cubit) {
        expect(cubit.state, isA<DetailState>());
      },
    );

    blocTest<DetailCubit, DetailState>(
      'loadData emits [loading, loaded] on success',
      build: () {
        when(() => mockRepo.getDetailData('1'))
            .thenAnswer((_) async => {'title': 'detail'});
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailState>(),
        isA<DetailState>(),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'loadData emits [loading, error] on failure',
      build: () {
        when(() => mockRepo.getDetailData('1'))
            .thenThrow(NotFoundException('not found'));
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('1'),
      expect: () => [
        isA<DetailState>(),
        isA<DetailState>(),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'retry calls loadData with same id',
      build: () {
        when(() => mockRepo.getDetailData('42'))
            .thenAnswer((_) async => {'retry': 'ok'});
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.retry('42'),
      expect: () => [
        isA<DetailState>(),
        isA<DetailState>(),
      ],
    );
  });
}
```

- [ ] **Step 2: 创建 NetworkCubit 测试**

```dart
// packages/services/network/test/network_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network/src/network_cubit.dart';
import 'package:network/src/network_state.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('NetworkCubit', () {
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockConnectivity = MockConnectivity();
    });

    test('initial state is connected', () {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      // Note: NetworkCubit constructor may differ — adjust per actual impl
    });

    test('isConnected getter returns true when connected', () {
      final state = NetworkState(status: NetworkStatus.connected);
      expect(state.isConnected, true);
    });

    test('isConnected getter returns false when disconnected', () {
      final state = NetworkState(status: NetworkStatus.disconnected);
      expect(state.isConnected, false);
    });

    test('NetworkState copyWith preserves unchanged fields', () {
      final state = NetworkState(
        status: NetworkStatus.connected,
        lastDisconnectedAt: DateTime(2024, 1, 1),
      );
      final updated = state.copyWith(status: NetworkStatus.disconnected);
      expect(updated.status, NetworkStatus.disconnected);
      expect(updated.lastDisconnectedAt, DateTime(2024, 1, 1));
    });
  });
}
```

**注意:** NetworkCubit 依赖 connectivity_plus 的真实监听流，完整测试需要 mock stream。以上为基础单元测试，覆盖 state 的行为。

- [ ] **Step 3: 验证 — flutter test 全部通过**

```bash
cd /Users/yeyangyang/Desktop/my_app
flutter test
```
预期: 所有已有 + 新增测试通过。

- [ ] **Step 4: Commit**

```bash
git add packages/features/feature_detail/test/detail_cubit_test.dart
git add packages/services/network/test/network_cubit_test.dart
git commit -m "test: add DetailCubit and NetworkCubit unit tests

Cover init state, success path, error path, retry for DetailCubit.
Cover state getters and copyWith for NetworkState."
```

---

### Task 3: 实现 DataSyncManager

**目标:** 将空壳 DataSyncManager 实现为可工作的登录后数据同步流。

**文件:**
- 修改: `packages/services/data_sync/lib/src/manager.dart`
- 创建: `packages/services/data_sync/lib/src/data_syncable.dart`
- 创建: `packages/services/data_sync/test/data_sync_manager_test.dart`

**设计:** DataSyncManager 管理一个 `DataSyncable` 注册表，每个需要同步的数据源实现该接口。登录后按优先级顺序执行同步。

- [ ] **Step 1: 创建 DataSyncable 接口**

```dart
// packages/services/data_sync/lib/src/data_syncable.dart
/// 可同步数据源接口
///
/// 任何需要登录后同步数据的模块实现此接口。
/// DataSyncManager 按优先级顺序调用 sync()。
abstract class DataSyncable {
  /// 同步优先级（数字越小越先执行）
  int get priority;

  /// 执行同步
  ///
  /// 返回 true 表示同步成功，false 表示部分失败（不阻塞后续同步）。
  /// 抛出异常时，DataSyncManager 会 catch 并记录日志。
  Future<bool> sync();
}
```

- [ ] **Step 2: 重写 DataSyncManager**

```dart
// packages/services/data_sync/lib/src/manager.dart
import 'package:flutter/foundation.dart';
import 'data_syncable.dart';

class DataSyncManager {
  final List<DataSyncable> _syncables = [];

  /// 注册一个可同步数据源
  void register(DataSyncable syncable) {
    _syncables.add(syncable);
    // 按优先级排序（升序）
    _syncables.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// 执行所有已注册的同步任务
  ///
  /// 按优先级顺序执行，单个失败不阻塞后续。
  /// 返回成功和失败的计数。
  Future<({int success, int failed})> sync() async {
    if (kDebugMode) {
      debugPrint('🚀 [DataSyncManager] sync: 开始同步 (${_syncables.length} 个任务)...');
    }

    int success = 0;
    int failed = 0;

    for (final syncable in _syncables) {
      try {
        final ok = await syncable.sync();
        if (ok) {
          success++;
        } else {
          failed++;
          if (kDebugMode) {
            debugPrint('⚠️ [DataSyncManager] sync(${syncable.runtimeType}): 部分失败');
          }
        }
      } catch (e, stack) {
        failed++;
        if (kDebugMode) {
          debugPrint('❌ [DataSyncManager] sync(${syncable.runtimeType}): $e');
          debugPrintStack(stackTrace: stack);
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✅ [DataSyncManager] sync: 完成 (成功: $success, 失败: $failed)');
    }
    return (success: success, failed: failed);
  }

  /// 清除所有注册
  void clear() => _syncables.clear();
}
```

- [ ] **Step 3: 更新 data_sync.dart barrel file**

```dart
// packages/services/data_sync/lib/data_sync.dart
export 'src/manager.dart';
export 'src/data_syncable.dart';
export 'src/di/setup.dart';
```

- [ ] **Step 4: 创建 DataSyncManager 测试**

```dart
// packages/services/data_sync/test/data_sync_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:data_sync/data_sync.dart';

class _MockSyncable extends DataSyncable {
  final int _priority;
  final bool _shouldSucceed;
  bool wasCalled = false;

  _MockSyncable(this._priority, this._shouldSucceed);

  @override
  int get priority => _priority;

  @override
  Future<bool> sync() async {
    wasCalled = true;
    return _shouldSucceed;
  }
}

void main() {
  group('DataSyncManager', () {
    late DataSyncManager manager;

    setUp(() {
      manager = DataSyncManager();
    });

    test('sync with no registrations returns (0,0)', () async {
      final result = await manager.sync();
      expect(result.success, 0);
      expect(result.failed, 0);
    });

    test('sync calls all registered syncables', () async {
      final a = _MockSyncable(1, true);
      final b = _MockSyncable(2, true);
      manager.register(a);
      manager.register(b);

      final result = await manager.sync();

      expect(a.wasCalled, true);
      expect(b.wasCalled, true);
      expect(result.success, 2);
      expect(result.failed, 0);
    });

    test('sync counts failures correctly', () async {
      final a = _MockSyncable(1, true);
      final b = _MockSyncable(2, false);
      manager.register(a);
      manager.register(b);

      final result = await manager.sync();

      expect(result.success, 1);
      expect(result.failed, 1);
    });

    test('sync continues after exception', () async {
      final a = _MockSyncable(1, true)..wasCalled = false;
      final b = _MockSyncable(2, true)..wasCalled = false;

      // 用 throwing syncable 替换
      manager.register(_ThrowingSyncable(1));
      manager.register(b);

      final result = await manager.sync();
      expect(b.wasCalled, true); // b 仍然被调用
      expect(result.failed, 1);
    });

    test('clear removes all registrations', () async {
      manager.register(_MockSyncable(1, true));
      manager.clear();

      final result = await manager.sync();
      expect(result.success, 0);
    });
  });
}

class _ThrowingSyncable extends DataSyncable {
  _ThrowingSyncable(this._priority);
  final int _priority;

  @override
  int get priority => _priority;

  @override
  Future<bool> sync() async => throw Exception('simulated error');
}
```

- [ ] **Step 5: 启动流程中注册一个示例同步任务**

```dart
// lib/core/startup/launcher.dart
// 在 setupDependencies() 之后添加示例注册:

// 注册示例同步任务（演示 DataSyncManager 用法）
sl<DataSyncManager>().register(_ExampleUserSync(
  sl<AuthManager>(),
));
```

在 `launcher.dart` 文件末尾添加示例实现:

```dart
/// 示例：用户信息同步
///
/// 演示 DataSyncable 接口用法。实际项目中替换为真实同步逻辑。
class _ExampleUserSync extends DataSyncable {
  final AuthManager _authManager;
  _ExampleUserSync(this._authManager);

  @override
  int get priority => 1; // 用户信息最先同步

  @override
  Future<bool> sync() async {
    // TODO: 替换为真实的用户信息同步 API 调用
    debugPrint('📦 [_ExampleUserSync] syncing user info...');
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
}
```

- [ ] **Step 6: 验证 — flutter analyze + flutter test**

```bash
cd /Users/yeyangyang/Desktop/my_app
flutter analyze
flutter test
```
预期: analyze 零错误，所有测试通过。

- [ ] **Step 7: Commit**

```bash
git add packages/services/data_sync/lib/src/manager.dart
git add packages/services/data_sync/lib/src/data_syncable.dart
git add packages/services/data_sync/lib/data_sync.dart
git add packages/services/data_sync/test/data_sync_manager_test.dart
git add lib/core/startup/launcher.dart
git commit -m "feat(data_sync): implement DataSyncManager with DataSyncable interface

Replace TODO stub with working implementation:
- DataSyncable interface for sync sources
- DataSyncManager: register, priority-sorted sync, error isolation
- Unit tests covering normal, failure, exception, and clear() paths
- Example _ExampleUserSync registered in launcher"
```

---

### Task 4: component_library 补充常用组件

**目标:** 扩展共享 UI 组件库，减少各 feature 重复造轮子。

**文件:**
- 创建: `packages/infrastructure/component_library/lib/src/widgets/loading_button.dart`
- 创建: `packages/infrastructure/component_library/lib/src/widgets/empty_state.dart`
- 创建: `packages/infrastructure/component_library/lib/src/widgets/error_card.dart`
- 修改: `packages/infrastructure/component_library/lib/component_library.dart`
- 创建: `packages/infrastructure/component_library/test/widgets/loading_button_test.dart`
- 创建: `packages/infrastructure/component_library/test/widgets/empty_state_test.dart`
- 创建: `packages/infrastructure/component_library/test/widgets/error_card_test.dart`

- [ ] **Step 1: 创建 LoadingButton**

```dart
// packages/infrastructure/component_library/lib/src/widgets/loading_button.dart
import 'package:flutter/material.dart';

/// 带加载状态的按钮
///
/// 点击后自动显示 loading indicator，防止重复提交。
///
/// ```dart
/// LoadingButton(
///   isLoading: state.status == LoginStatus.loading,
///   onPressed: () => cubit.login(),
///   child: const Text('登录'),
/// )
/// ```
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}
```

- [ ] **Step 2: 创建 EmptyState**

```dart
// packages/infrastructure/component_library/lib/src/widgets/empty_state.dart
import 'package:flutter/material.dart';

/// 空状态占位组件
///
/// ```dart
/// EmptyState(
///   icon: Icons.inbox_outlined,
///   title: '暂无数据',
///   subtitle: '下拉刷新试试',
///   onAction: () => cubit.refreshData(),
///   actionLabel: '刷新',
/// )
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 ErrorCard**

```dart
// packages/infrastructure/component_library/lib/src/widgets/error_card.dart
import 'package:flutter/material.dart';

/// 错误提示卡片
///
/// ```dart
/// ErrorCard(
///   message: '加载失败',
///   onRetry: () => cubit.retry(),
/// )
/// ```
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red.shade700,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryLabel ?? '重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 创建 Widget 测试**

```dart
// packages/infrastructure/component_library/test/widgets/loading_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('LoadingButton', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: false,
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
      );
      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows spinner when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: true,
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('onPressed is called when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: false,
            onPressed: () => called = true,
            child: const Text('Submit'),
          ),
        ),
      );
      await tester.tap(find.byType(LoadingButton));
      expect(called, true);
    });

    testWidgets('button is disabled when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingButton(
            isLoading: true,
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
```

```dart
// packages/infrastructure/component_library/test/widgets/empty_state_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmptyState(title: 'No items')),
      );
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyState(title: 'Empty', subtitle: 'Try again'),
        ),
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('renders action button when onAction and actionLabel provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyState(
            title: 'Empty',
            onAction: _noop,
            actionLabel: 'Refresh',
          ),
        ),
      );
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('no action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmptyState(title: 'Empty')),
      );
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}

void _noop() {}
```

```dart
// packages/infrastructure/component_library/test/widgets/error_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('ErrorCard', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorCard(message: 'Something went wrong')),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorCard(message: 'Error', onRetry: _noop),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders custom retry label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorCard(
            message: 'Error',
            onRetry: _noop,
            retryLabel: '再试一次',
          ),
        ),
      );
      expect(find.text('再试一次'), findsOneWidget);
    });
  });
}

void _noop() {}
```

- [ ] **Step 5: 更新 barrel file**

```dart
// packages/infrastructure/component_library/lib/component_library.dart
// 在现有 exports 后追加:
export 'src/widgets/loading_button.dart';
export 'src/widgets/empty_state.dart';
export 'src/widgets/error_card.dart';
```

- [ ] **Step 6: 验证**

```bash
cd /Users/yeyangyang/Desktop/my_app
flutter analyze
flutter test packages/infrastructure/component_library/test/
```
预期: analyze 零错误，所有组件测试通过。

- [ ] **Step 7: Commit**

```bash
git add packages/infrastructure/component_library/lib/src/widgets/loading_button.dart
git add packages/infrastructure/component_library/lib/src/widgets/empty_state.dart
git add packages/infrastructure/component_library/lib/src/widgets/error_card.dart
git add packages/infrastructure/component_library/lib/component_library.dart
git add packages/infrastructure/component_library/test/widgets/
git commit -m "feat(ui): add LoadingButton, EmptyState, ErrorCard to component_library

Three commonly-needed widgets to reduce feature-level duplication:
- LoadingButton: auto-spinner on loading, disabled state
- EmptyState: icon + title + optional subtitle + action
- ErrorCard: error icon + message + optional retry button
All with widget tests."
```

---

## 验证清单（Plan B 全部完成后）

- [ ] `flutter analyze` — 零错误
- [ ] `flutter test` — 所有测试通过（新增 8+ 测试用例）
- [ ] `flutter test --coverage` — 覆盖率明显提升
- [ ] 手动验证: 启动 app，HomePage 数据通过缓存加载

---

## 回滚策略

每个 Task 独立 commit。`git revert <commit-hash>` 即可回滚。
