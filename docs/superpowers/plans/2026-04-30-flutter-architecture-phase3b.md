# Flutter架构重构 - Phase 3.2: Hive缓存扩展 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 扩展Hive缓存功能，实现BoxManager统一管理、BoxService封装、CacheData过期机制、Hive Adapter注册

**Architecture:** 在现有key_value_storage包基础上扩展，新增BoxManager管理Box实例，BoxService封装CRUD操作，CacheData支持TTL过期。

**Tech Stack:** Hive, hive_generator ^2.0.0, build_runner ^2.4.0

---

## 文件结构概览

**创建的新文件：**

```
packages/key_value_storage/
  src/
    box_manager.dart          # BoxManager
    box_service.dart          # BoxService<T>
    cache_data.dart           # CacheData过期数据
    hive_registrar.dart       # Hive Adapter注册
    README.md

packages/domain_models/
  src/
    hive/
      registrar.dart          # Domain Hive Adapter注册
      user_adapter.dart       # User Adapter示例
```

**依赖Phase 1完成项：**
- packages/key_value_storage现有架构
- lib/core/constants/cache_constants.dart

---

### Task 1: 创建BoxManager

**Files:**
- Create: `packages/key_value_storage/src/box_manager.dart`

- [ ] **Step 1: 创建BoxManager**

```dart
import 'package:hive/hive.dart';

/// Box管理器
///
/// 职责：统一管理Hive Box实例，避免重复打开
/// 使用：通过BoxService间接使用，或直接调用getBox
/// 好处：
///   - 避免重复openBox调用
///   - 统一管理Box生命周期
///   - 支持closeAll批量关闭
class BoxManager {
  /// 单例实例
  static final instance = BoxManager._();

  BoxManager._();

  /// 已打开的Box映射表
  ///
  /// key: boxName（Box名称）
  /// value: Box实例
  final Map<String, Box> _openedBoxes = {};

  /// 获取Box实例
  ///
  /// 如果Box已打开，直接返回实例
  /// 如果未打开，先打开Box再返回
  ///
  /// 参数：
  /// - boxName: Box名称
  ///
  /// 返回：Box<T>实例
  ///
  /// 注意：T类型需注册Hive Adapter
  Future<Box<T>> getBox<T>(String boxName) async {
    // 已打开，直接返回
    if (_openedBoxes.containsKey(boxName)) {
      return _openedBoxes[boxName] as Box<T>;
    }

    // 未打开，先打开Box
    final box = await Hive.openBox<T>(boxName);
    _openedBoxes[boxName] = box;
    return box;
  }

  /// 关闭所有Box
  ///
  /// App退出时调用，释放资源
  /// 注意：关闭后需要重新打开才能使用
  Future<void> closeAll() async {
    for (final box in _openedBoxes.values) {
      await box.close();
    }
    _openedBoxes.clear();
  }

  /// 关闭指定Box
  ///
  /// 参数：
  /// - boxName: Box名称
  Future<void> close(String boxName) async {
    final box = _openedBoxes[boxName];
    if (box != null) {
      await box.close();
      _openedBoxes.remove(boxName);
    }
  }

  /// 删除指定Box
  ///
  /// 删除Box及其所有数据
  /// 注意：此操作不可恢复
  Future<void> deleteBox(String boxName) async {
    await close(boxName);
    await Hive.deleteBoxFromDisk(boxName);
  }

  /// 获取已打开Box数量
  int get openedCount => _openedBoxes.length;

  /// 获取所有已打开Box名称
  List<String> get openedBoxNames => _openedBoxes.keys.toList();
}
```

写入 `packages/key_value_storage/src/box_manager.dart`

- [ ] **Step 2: Commit**

```bash
git add packages/key_value_storage/src/box_manager.dart
git commit -m "feat(phase3.2): 创建BoxManager统一管理Hive Box

- getBox避免重复打开
- closeAll/close批量关闭
- deleteBox删除Box及其数据
- 中文注释说明Box生命周期管理

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 创建BoxService

**Files:**
- Create: `packages/key_value_storage/src/box_service.dart`

- [ ] **Step 1: 创建BoxService**

```dart
import 'package:hive/hive.dart';
import 'box_manager.dart';
import 'cache_data.dart';

/// Box服务
///
/// 职责：封装Box CRUD操作，提供便捷的缓存API
/// 使用：通过DI获取，如 `sl<BoxService<User>>()`
/// 特性：
///   - 基础CRUD：put/get/delete
///   - 批量操作：putAll/getAllValues
///   - 排序过滤：getSorted
///   - 过期机制：putWithExpiry/getWithExpiry
///
/// 注意：数据量大于50条时，排序过滤可能影响性能
class BoxService<T> {
  /// Box名称
  final String boxName;

  /// Box管理器
  final BoxManager _manager = BoxManager.instance;

  BoxService(this.boxName);

  /// 获取Box实例
  Future<Box<T>> _box() => _manager.getBox<T>(boxName);

  // ===== 基础CRUD =====

  /// 存储数据
  ///
  /// 参数：
  /// - key: 数据键
  /// - value: 数据值
  Future<void> put(String key, T value) async {
    final box = await _box();
    await box.put(key, value);
  }

  /// 获取数据
  ///
  /// 参数：
  /// - key: 数据键
  ///
  /// 返回：数据值，不存在返回null
  Future<T?> get(String key) async {
    final box = await _box();
    return box.get(key);
  }

  /// 删除数据
  ///
  /// 参数：
  /// - key: 数据键
  Future<void> delete(String key) async {
    final box = await _box();
    await box.delete(key);
  }

  /// 检查是否存在
  ///
  /// 参数：
  /// - key: 数据键
  ///
  /// 返回：true表示存在
  Future<bool> contains(String key) async {
    final box = await _box();
    return box.containsKey(key);
  }

  // ===== 批量操作 =====

  /// 批量存储
  ///
  /// 参数：
  /// - items: 数据映射表
  Future<void> putAll(Map<String, T> items) async {
    final box = await _box();
    await box.putAll(items);
  }

  /// 获取所有值
  ///
  /// 返回：所有数据值的列表
  Future<List<T>> getAllValues() async {
    final box = await _box();
    return box.values.toList();
  }

  /// 获取所有键
  ///
  /// 返回：所有数据键的列表
  Future<List<String>> getAllKeys() async {
    final box = await _box();
    return box.keys.toList().cast<String>();
  }

  /// 清空所有数据
  ///
  /// 注意：此操作不可恢复
  Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }

  // ===== 排序/过滤 =====

  /// 获取排序后的数据
  ///
  /// 使用comparator对数据进行排序
  ///
  /// 参数：
  /// - comparator: 比较函数
  ///
  /// 返回：排序后的数据列表
  ///
  /// 性能警告：数据量大于50条时慎用
  Future<List<T>> getSorted(Comparator<T> comparator) async {
    final values = await getAllValues();
    values.sort(comparator);
    return values;
  }

  /// 过滤数据
  ///
  /// 使用test函数过滤数据
  ///
  /// 参数：
  /// - test: 过滤条件函数
  ///
  /// 返回：过滤后的数据列表
  ///
  /// 性能警告：数据量大于50条时慎用
  Future<List<T>> where(bool test(T element)) async {
    final values = await getAllValues();
    return values.where(test).toList();
  }

  // ===== 过期机制 =====

  /// 存储带过期时间的数据
  ///
  /// 数据超过TTL后自动失效，getWithExpiry返回null
  ///
  /// 参数：
  /// - key: 数据键
  /// - value: 数据值
  /// - ttl: 过期时间（可选，默认24小时）
  Future<void> putWithExpiry(
    String key,
    T value,
    {Duration? ttl}
  ) async {
    // 使用CacheData包装数据
    final data = CacheData<T>(value, ttl: ttl);
    final box = await _manager.getBox<CacheData<T>>('${boxName}_cache');
    await box.put(key, data);
  }

  /// 获取带过期时间的数据
  ///
  /// 数据已过期返回null，并自动删除
  ///
  /// 参数：
  /// - key: 数据键
  ///
  /// 返回：数据值，过期或不存在返回null
  Future<T?> getWithExpiry(String key) async {
    final box = await _manager.getBox<CacheData<T>>('${boxName}_cache');
    final data = box.get(key);

    // 数据不存在
    if (data == null) return null;

    // 数据已过期
    if (data.isExpired) {
      await box.delete(key);
      return null;
    }

    // 数据有效
    return data.value;
  }

  // ===== 统计 =====

  /// 获取数据数量
  Future<int> get length async {
    final box = await _box();
    return box.length;
  }

  /// 检查是否为空
  Future<bool> get isEmpty async {
    final box = await _box();
    return box.isEmpty;
  }
}
```

写入 `packages/key_value_storage/src/box_service.dart`

- [ ] **Step 2: Commit**

```bash
git add packages/key_value_storage/src/box_service.dart
git commit -m "feat(phase3.2): 创建BoxService封装CRUD操作

- 基础CRUD：put/get/delete
- 批量操作：putAll/getAllValues
- 排序过滤：getSorted/where
- 过期机制：putWithExpiry/getWithExpiry
- 性能警告：数据量>50条慎用排序过滤

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: 创建CacheData

**Files:**
- Create: `packages/key_value_storage/src/cache_data.dart`

- [ ] **Step 1: 创建CacheData**

```dart
import 'package:hive/hive.dart';

/// 缓存数据包装类
///
/// 职责：为数据添加过期时间，支持TTL机制
/// 使用：BoxService.putWithExpiry自动使用
/// Hive Adapter：需要生成CacheDataAdapter
///
/// 示例：
/// ```dart
/// final cacheData = CacheData<User>(user, ttl: Duration(hours: 1));
/// if (!cacheData.isExpired) {
///   print(cacheData.value);
/// }
/// ```
@HiveType(typeId: 0)
class CacheData<T> {
  /// 数据值
  @HiveField(0)
  final T value;

  /// 过期时间
  ///
  /// 超过此时间，数据失效
  @HiveField(1)
  final DateTime expireAt;

  /// 构造函数
  ///
  /// 参数：
  /// - value: 数据值
  /// - ttl: 过期时长（可选，默认24小时）
  CacheData(this.value, {Duration? ttl})
    : expireAt = DateTime.now().add(ttl ?? const Duration(hours: 24));

  /// 判断是否过期
  ///
  /// 当前时间超过expireAt返回true
  bool get isExpired => DateTime.now().isAfter(expireAt);

  /// 获取剩余时间
  ///
  /// 返回：剩余时长，已过期返回Duration.zero
  Duration get remainingTime {
    final remaining = expireAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 判断是否即将过期
  ///
  /// 参数：
  /// - threshold: 预警阈值（默认5分钟）
  ///
  /// 返回：true表示即将过期
  bool isExpiringSoon({Duration threshold = const Duration(minutes: 5)}) {
    return remainingTime <= threshold;
  }
}
```

写入 `packages/key_value_storage/src/cache_data.dart`

- [ ] **Step 2: Commit**

```bash
git add packages/key_value_storage/src/cache_data.dart
git commit -m "feat(phase3.2): 创建CacheData支持TTL过期

- HiveType注解，typeId: 0
- isExpired判断是否过期
- remainingTime获取剩余时间
- isExpiringSoon判断即将过期
- 中文注释说明TTL机制

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 创建HiveRegistrar

**Files:**
- Create: `packages/key_value_storage/src/hive_registrar.dart`

- [ ] **Step 1: 创建HiveRegistrar**

```dart
import 'package:hive/hive.dart';

/// Hive Adapter注册器
///
/// 职责：统一注册所有Hive Adapter
/// 使用：在App启动时调用 `HiveRegistrar.registerAll()`
/// 顺序：
///   1. 先注册基础Adapter（CacheData）
///   2. 再注册业务Adapter（DomainHiveRegistrar）
///
/// TypeId分配：
///   - 0: CacheData（基础）
///   - 1+: DomainModels（业务）
class HiveRegistrar {
  /// 是否已注册
  static bool _registered = false;

  /// 注册所有Adapter
  ///
  /// 在App启动时调用，注册基础和业务Adapter
  /// 注意：只能调用一次，重复调用无效
  static Future<void> registerAll() async {
    if (_registered) return;

    // 注册基础Adapter
    Hive.registerAdapter(CacheDataAdapter());  // typeId: 0

    // 注册业务Adapter（由DomainHiveRegistrar负责）
    // DomainHiveRegistrar.registerAll();

    _registered = true;
  }

  /// 检查是否已注册
  static bool get isRegistered => _registered;
}
```

写入 `packages/key_value_storage/src/hive_registrar.dart`

- [ ] **Step 2: 导出hive_registrar**

修改 `packages/key_value_storage/lib/key_value_storage.dart`：

```dart
export 'package:hive/hive.dart';
export 'src/key_value_storage.dart';
export 'src/shared_preference_storage.dart';
// Phase 3.2新增
export 'src/box_manager.dart';
export 'src/box_service.dart';
export 'src/cache_data.dart';
export 'src/hive_registrar.dart';
```

- [ ] **Step 3: Commit**

```bash
git add packages/key_value_storage/src/hive_registrar.dart packages/key_value_storage/lib/key_value_storage.dart
git commit -m "feat(phase3.2): 创建HiveRegistrar统一注册Adapter

- registerAll注册所有Adapter
- CacheDataAdapter typeId: 0
- 防止重复注册
- 中文注释说明TypeId分配规则

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: 创建DomainHiveRegistrar

**Files:**
- Create: `packages/domain_models/src/hive/registrar.dart`
- Create: `packages/domain_models/src/hive/user_adapter.dart` (示例)

- [ ] **Step 1: 创建hive目录**

```bash
mkdir -p packages/domain_models/src/hive
```

- [ ] **Step 2: 创建DomainHiveRegistrar**

```dart
import 'package:hive/hive.dart';

/// Domain Models Hive Adapter注册器
///
/// 职责：注册业务模型的Hive Adapter
/// 使用：由HiveRegistrar调用，业务开发者不需直接调用
/// TypeId分配：
///   - 1: User（示例）
///   - 2+: 其他业务模型
///
/// 添加新模型步骤：
/// 1. 创建模型类，添加HiveType/HiveField注解
/// 2. 运行build_runner生成Adapter
/// 3. 在此文件注册Adapter
/// 4. 更新TypeId分配表
class DomainHiveRegistrar {
  /// 是否已注册
  static bool _registered = false;

  /// 注册所有业务Adapter
  ///
  /// 由HiveRegistrar.registerAll调用
  static void registerAll() {
    if (_registered) return;

    // 注册User Adapter（示例）
    // Hive.registerAdapter(UserAdapter());  // typeId: 1

    // TODO: 注册其他业务Adapter
    // Hive.registerAdapter(OrderAdapter());  // typeId: 2
    // Hive.registerAdapter<ProductAdapter());  // typeId: 3

    _registered = true;
  }

  /// 检查是否已注册
  static bool get isRegistered => _registered;
}
```

写入 `packages/domain_models/src/hive/registrar.dart`

- [ ] **Step 3: 创建UserAdapter示例（说明文件）**

```dart
// 示例：User模型及其Adapter
//
// 此文件展示如何为业务模型创建Hive Adapter
// 实际项目中，应使用build_runner生成
//
// 步骤：
// 1. 定义模型类，添加Hive注解
// 2. 运行 flutter pub run build_runner build
// 3. 生成的Adapter文件注册到DomainHiveRegistrar
//
// 示例模型：
// ```dart
// @HiveType(typeId: 1)
// class User {
//   @HiveField(0)
//   final String id;
//
//   @HiveField(1)
//   final String name;
//
//   @HiveField(2)
//   final String email;
//
//   User({required this.id, required this.name, required this.email});
// }
// ```
//
// build_runner生成后：
// Hive.registerAdapter(UserAdapter());
```

写入 `packages/domain_models/src/hive/user_adapter.dart`

- [ ] **Step 4: 更新HiveRegistrar调用DomainHiveRegistrar**

修改 `packages/key_value_storage/src/hive_registrar.dart`：

```dart
import 'package:hive/hive.dart';
// 如果domain_models有依赖关系，需导入
// import 'package:domain_models/src/hive/registrar.dart';

class HiveRegistrar {
  static bool _registered = false;

  static Future<void> registerAll() async {
    if (_registered) return;

    // 注册基础Adapter
    Hive.registerAdapter(CacheDataAdapter());

    // 注册业务Adapter
    // 注意：由于包依赖关系，DomainHiveRegistrar需要在App层调用
    // DomainHiveRegistrar.registerAll();

    _registered = true;
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add packages/domain_models/src/hive/
git commit -m "feat(phase3.2): 创建DomainHiveRegistrar注册业务Adapter

- TypeId分配说明（1+为业务模型）
- UserAdapter示例说明文件
- 添加新模型步骤说明
- 中文注释说明Adapter生成流程

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: 生成Hive Adapter代码

**Files:**
- Generated: `packages/key_value_storage/src/cache_data.g.dart`

- [ ] **Step 1: 添加hive_generator依赖**

确认 `pubspec.yaml` 已有：

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  hive_generator: ^2.0.0
```

运行：
```bash
flutter pub get
```

- [ ] **Step 2: 运行build_runner**

```bash
cd packages/key_value_storage
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: 生成 `cache_data.g.dart`

- [ ] **Step 3: 验证生成文件**

```bash
ls -la packages/key_value_storage/src/
cat packages/key_value_storage/src/cache_data.g.dart
```

Expected: CacheDataAdapter已生成

- [ ] **Step 4: Commit生成文件**

```bash
git add packages/key_value_storage/src/cache_data.g.dart
git commit -m "feat(phase3.2): 生成CacheData Hive Adapter

- build_runner生成CacheDataAdapter
- typeId: 0

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: 在App启动时注册Hive Adapter

**Files:**
- Modify: `lib/core/startup/initializer.dart`

- [ ] **Step 1: 更新SDKInitializer**

修改 `lib/core/startup/initializer.dart`，添加Hive初始化：

```dart
import 'package:flutter/foundation.dart';
import 'package:key_value_storage/key_value_storage.dart';

/// SDK初始化器
class SDKInitializer {
  /// 初始化第三方SDK
  Future<void> initPlugins() async {
    if (kDebugMode) {
      debugPrint('🚀 [SDKInitializer] initPlugins: 开始初始化...');
    }

    // 初始化Hive Adapter
    await HiveRegistrar.registerAll();
    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] Hive Adapter注册完成');
    }

    // TODO: 初始化其他SDK
    // 推送SDK、统计SDK、支付SDK等

    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] initPlugins: 初始化完成');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/startup/initializer.dart
git commit -m "feat(phase3.2): App启动时注册Hive Adapter

- SDKInitializer.initPlugins调用HiveRegistrar.registerAll
- 中文注释说明初始化流程

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: 在DI中注册BoxService

**Files:**
- Modify: `lib/core/di/setup.dart`

- [ ] **Step 1: 更新DI Setup**

修改 `lib/core/di/setup.dart`，添加BoxService注册：

```dart
// 在setupDependencies函数中添加：

  // ===== BoxService =====

  // User BoxService（单例）
  sl.registerSingleton<BoxService<User>>(
    BoxService<User>('user_box')
  );

  // Home BoxService（单例）
  sl.registerSingleton<BoxService<Map<String, dynamic>>>(
    BoxService<Map<String, dynamic>>('home_box')
  );
```

添加导入：
```dart
import 'package:key_value_storage/key_value_storage.dart';
import '../../features/home/repository/home_repository.dart';
```

注意：需要先在domain_models中定义User类（或使用现有模型）

- [ ] **Step 2: Commit**

```bash
git add lib/core/di/setup.dart
git commit -m "feat(phase3.2): DI注册BoxService

- User BoxService单例
- Home BoxService单例
- 中文注释说明BoxService使用

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 9: 创建README汇总文档

**Files:**
- Create: `packages/key_value_storage/README.md`

- [ ] **Step 1: 创建key_value_storage README**

```markdown
# KeyValueStorage包

## 概述
基于Hive的本地存储解决方案，提供统一缓存管理。

## 模块结构

### BoxManager
Box实例统一管理，避免重复打开。

### BoxService<T>
泛型Box服务，封装CRUD操作。
- 基础CRUD：put/get/delete
- 批量操作：putAll/getAllValues
- 排序过滤：getSorted/where（性能警告：数据量>50慎用）
- 过期机制：putWithExpiry/getWithExpiry

### CacheData
缓存数据包装，支持TTL过期。

### HiveRegistrar
Hive Adapter统一注册。

## 使用示例

### DI注册
```dart
sl.registerSingleton<BoxService<User>>(
  BoxService<User>('user_box')
);
```

### 基础使用
```dart
final userBox = sl<BoxService<User>>();

// 存储
await userBox.put('current_user', user);

// 获取
final user = await userBox.get('current_user');

// 带过期时间存储（1小时）
await userBox.putWithExpiry('temp_data', data, ttl: Duration(hours: 1));

// 获取（自动检查过期）
final data = await userBox.getWithExpiry('temp_data');
```

### 排序过滤
```dart
// 按名称排序
final sorted = await userBox.getSorted((a, b) => a.name.compareTo(b.name));

// 过滤活跃用户
final active = await userBox.where((u) => u.isActive);
```

## Hive Adapter注册

### 添加新模型
1. 创建模型类，添加Hive注解：
```dart
@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
}
```

2. 运行build_runner：
```bash
flutter pub run build_runner build
```

3. 注册Adapter：
```dart
Hive.registerAdapter(UserAdapter());
```

### TypeId分配
- 0: CacheData（基础）
- 1+: 业务模型（User, Order, Product等）

## 性能警告
- 排序过滤操作数据量>50条慎用
- 大量数据建议分页加载
- Box实例内存占用，App退出时调用closeAll释放

## 依赖关系
- hive: 本地存储引擎
- hive_generator: Adapter代码生成
- build_runner: 代码生成工具
```

写入 `packages/key_value_storage/README.md`

- [ ] **Step 2: Commit**

```bash
git add packages/key_value_storage/README.md
git commit -m "feat(phase3.2): 创建key_value_storage包README

- 模块结构说明
- 使用示例代码
- Hive Adapter注册流程
- TypeId分配规则
- 性能警告说明

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 10: 验证编译

**Files:**
- 无新文件

- [ ] **Step 1: 运行Flutter分析**

```bash
flutter analyze
```

Expected: 无错误

- [ ] **Step 2: 尝试编译**

```bash
flutter build apk --debug
```

Expected: 编译成功

- [ ] **Step 3: Final Commit**

```bash
git add -A
git commit -m "feat(phase3.2): Phase 3.2 Hive缓存扩展完成

完成内容：
- BoxManager: Box实例统一管理
- BoxService<T>: CRUD操作封装，支持过期机制
- CacheData: TTL过期数据包装
- HiveRegistrar: Adapter统一注册
- DomainHiveRegistrar: 业务Adapter注册（示例）
- build_runner生成Adapter
- App启动注册Hive Adapter
- DI注册BoxService
- 完整中文README文档

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Spec Coverage Check

| Design要求 | Plan任务覆盖 |
|-----------|-------------|
| BoxManager | Task 1 |
| BoxService | Task 2 |
| CacheData | Task 3 |
| Hive Adapter注册 | Task 4-5 |
| build_runner生成 | Task 6 |
| App启动注册 | Task 7 |
| DI注册BoxService | Task 8 |
| 中文README | Task 9 |

---

Plan complete and saved to `docs/superpowers/plans/2026-04-30-flutter-architecture-phase3b.md`.

继续生成Plan-3c和Plan-3d？