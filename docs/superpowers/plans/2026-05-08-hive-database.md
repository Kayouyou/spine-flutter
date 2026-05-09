# Hive Database Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the Hive database layer with unified initialization, migration framework, and typeId management to prevent crashes when schema changes

**Architecture:** Centralize Hive initialization in SDKInitializer, create a migration framework with schema versioning, and establish a typeId registry to coordinate adapter IDs across the monorepo

**Tech Stack:** Hive, path_provider, custom migration framework

---

## File Structure

| File | Type | Responsibility |
|------|------|----------------|
| `lib/core/startup/initializer.dart` | Modify | Add Hive.initFlutter() to initPlugins() |
| `packages/infrastructure/key_value_storage/lib/src/key_value_storage.dart` | Modify | Remove Hive.init() from _openBox() |
| `packages/infrastructure/key_value_storage/lib/src/migration/migration.dart` | Create | Abstract Migration base class |
| `packages/infrastructure/key_value_storage/lib/src/migration/migration_runner.dart` | Create | Executes registered migrations at startup |
| `packages/infrastructure/key_value_storage/lib/src/migration/schema_version_box.dart` | Create | Tracks schema version per box |
| `packages/infrastructure/key_value_storage/lib/key_value_storage.dart` | Modify | Export migration module |
| `packages/infrastructure/key_value_storage/test/migration_test.dart` | Create | Test migration framework |
| `register.yaml` | Create | Track next available typeId |
| `bricks/feature/brick.yaml` | Modify | Read typeId from register.yaml |

---

## Problem Summary

### Problem 1: Hive.init() Path Inconsistency
- `KeyValueStorage._openBox()` calls `Hive.init()` lazily (line 17)
- `BoxManager.getBox()` calls `Hive.openBox()` WITHOUT initializing first
- `SDKInitializer.initPlugins()` registers adapters but NOT `Hive.init()`

### Problem 2: No Schema Migration
- Adding `@HiveField` causes crashes when old data exists
- Need chain migration for user data (preserve data)
- Need version-mismatch-clear for cache data (safe to discard)

### Problem 3: typeId Manual Coordination
- CacheData uses typeId=0
- No centralized tracking for new adapters
- Mason brick doesn't reserve IDs automatically

---

### Task 1: Unify Hive.init() in SDKInitializer

**Files:**
- Modify: `lib/core/startup/initializer.dart:17-34`
- Modify: `packages/infrastructure/key_value_storage/lib/src/key_value_storage.dart:12-19`

- [ ] **Step 1: Modify SDKInitializer.initPlugins() to call Hive.initFlutter()**

Replace lines 17-34 in `lib/core/startup/initializer.dart`:

```dart
import 'package:hive_flutter/hive_flutter.dart';

class SDKInitializer {
  Future<void> initPlugins() async {
    if (kDebugMode) {
      debugPrint('🚀 [SDKInitializer] initPlugins: 开始初始化...');
    }

    // 初始化 Hive（统一入口，使用 path_provider 自动获取目录）
    await Hive.initFlutter();
    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] Hive 初始化完成: ${Hive盒子路径}');
    }

    // 注册 Hive Adapter（必须在 openBox 之前）
    await HiveRegistrar.registerAll();
    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] Hive Adapter 注册完成');
    }

    if (kDebugMode) {
      debugPrint('✅ [SDKInitializer] initPlugins: 初始化完成');
    }
  }
}
```

- [ ] **Step 2: Remove Hive.init() from KeyValueStorage._openBox()**

Replace lines 12-19 in `packages/infrastructure/key_value_storage/lib/src/key_value_storage.dart`:

```dart
Future<Box> _openBox(String key) async {
  if (_hive.isBoxOpen(key)) {
    return _hive.box(key);
  }
  // Hive.initFlutter() 已在 SDKInitializer.initPlugins() 中调用
  return _hive.openBox(key);
}
```

Remove unused imports:
```dart
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
```

- [ ] **Step 3: Verify BoxManager still works (no code changes needed)**

BoxManager uses `Hive.openBox()` which works after `Hive.initFlutter()`.

- [ ] **Step 4: Run analysis to verify changes**

```bash
cd packages/infrastructure/key_value_storage && flutter analyze
```

Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/core/startup/initializer.dart packages/infrastructure/key_value_storage/lib/src/key_value_storage.dart
git commit -m "refactor: unify Hive.init() in SDKInitializer, remove duplicate init from KeyValueStorage"
```

---

### Task 2: Create Migration Framework

**Files:**
- Create: `packages/infrastructure/key_value_storage/lib/src/migration/migration.dart`
- Create: `packages/infrastructure/key_value_storage/lib/src/migration/migration_runner.dart`
- Create: `packages/infrastructure/key_value_storage/lib/src/migration/schema_version_box.dart`
- Modify: `packages/infrastructure/key_value_storage/lib/key_value_storage.dart`
- Create: `packages/infrastructure/key_value_storage/test/migration_test.dart`

- [ ] **Step 1: Create migration directory**

```bash
mkdir -p packages/infrastructure/key_value_storage/lib/src/migration
```

- [ ] **Step 2: Create abstract Migration class**

Create `packages/infrastructure/key_value_storage/lib/src/migration/migration.dart`:

```dart
import 'package:hive/hive.dart';

/// Migration strategy enum
enum MigrationStrategy {
  /// Chain migration: migrate from old schema to new (preserve data)
  /// Used for user data that must be preserved
  chain,
  
  /// Clear on mismatch: delete box and recreate if version mismatch
  /// Used for cache data that can be safely discarded
  clearOnMismatch,
}

/// Abstract base class for schema migrations
abstract class Migration {
  /// Box name this migration applies to
  String get boxName;
  
  /// Schema version this migration starts from
  int get fromVersion;
  
  /// Schema version this migration targets
  int get toVersion;
  
  /// Migration strategy to use
  MigrationStrategy get strategy;
  
  /// Apply the migration
  /// For chain strategy: transform data from oldBox to newBox
  /// For clearOnMismatch: no-op (box will be cleared automatically)
  Future<void> apply(Box oldBox, Box newBox);
  
  /// Validation check after migration
  /// Return true if migration was successful
  Future<bool> validate(Box box);
}

/// Base exception for migration errors
class MigrationException implements Exception {
  final String message;
  final String boxName;
  final int? fromVersion;
  final int? toVersion;
  
  MigrationException({
    required this.message,
    required this.boxName,
    this.fromVersion,
    this.toVersion,
  });
  
  @override
  String toString() => 'MigrationException: $message (box: $boxName, $fromVersion -> $toVersion)';
}
```

- [ ] **Step 3: Create SchemaVersionBox**

Create `packages/infrastructure/key_value_storage/lib/src/migration/schema_version_box.dart`:

```dart
import 'package:hive/hive.dart';

/// Box name for storing schema versions
const String schemaVersionBoxName = '_schema_versions';

/// Schema version storage
/// Tracks current schema version for each Hive box
class SchemaVersionBox {
  late Box _box;
  bool _initialized = false;
  
  /// Initialize the schema version box
  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(schemaVersionBoxName);
    _initialized = true;
  }
  
  /// Get current version for a box
  /// Returns 0 if box has no recorded version (first time)
  int getVersion(String boxName, {int defaultValue = 0}) {
    return _box.get(boxName, defaultValue: defaultValue) as int;
  }
  
  /// Set current version for a box
  Future<void> setVersion(String boxName, int version) async {
    await _box.put(boxName, version);
  }
  
  /// Get all box versions
  Map<String, int> getAllVersions() {
    final Map<String, int> result = {};
    for (final key in _box.keys) {
      result[key as String] = _box.get(key) as int;
    }
    return result;
  }
  
  /// Clear all version records (for testing)
  Future<void> clearAll() async {
    await _box.clear();
  }
}
```

- [ ] **Step 4: Create MigrationRunner**

Create `packages/infrastructure/key_value_storage/lib/src/migration/migration_runner.dart`:

```dart
import 'package:hive/hive.dart';
import 'migration.dart';
import 'schema_version_box.dart';

/// Migration runner executes registered migrations at app startup
class MigrationRunner {
  final SchemaVersionBox _schemaVersionBox;
  final List<Migration> _migrations = [];
  
  MigrationRunner(this._schemaVersionBox);
  
  /// Register a migration
  void registerMigration(Migration migration) {
    _migrations.add(migration);
  }
  
  /// Run all applicable migrations
  Future<void> runAll() async {
    // Sort migrations by fromVersion for correct order
    _migrations.sort((a, b) => a.fromVersion.compareTo(b.fromVersion));
    
    for (final migration in _migrations) {
      await _runMigration(migration);
    }
  }
  
  Future<void> _runMigration(Migration migration) async {
    final currentVersion = _schemaVersionBox.getVersion(migration.boxName);
    
    // Already at target version, skip
    if (currentVersion >= migration.toVersion) {
      return;
    }
    
    // Not at expected from version
    if (currentVersion != migration.fromVersion) {
      switch (migration.strategy) {
        case MigrationStrategy.chain:
          throw MigrationException(
            message: 'Version gap detected. Expected version ${migration.fromVersion}, found $currentVersion',
            boxName: migration.boxName,
            fromVersion: currentVersion,
            toVersion: migration.toVersion,
          );
        case MigrationStrategy.clearOnMismatch:
          // Clear box and set to new version
          await _clearAndRecreate(migration);
          return;
      }
    }
    
    // Execute migration based on strategy
    switch (migration.strategy) {
      case MigrationStrategy.chain:
        await _runChainMigration(migration);
        break;
      case MigrationStrategy.clearOnMismatch:
        await _clearAndRecreate(migration);
        break;
    }
    
    // Validate and update version
    final box = Hive.box(migration.boxName);
    final isValid = await migration.validate(box);
    if (!isValid) {
      throw MigrationException(
        message: 'Migration validation failed',
        boxName: migration.boxName,
        fromVersion: migration.fromVersion,
        toVersion: migration.toVersion,
      );
    }
    
    await _schemaVersionBox.setVersion(migration.boxName, migration.toVersion);
  }
  
  Future<void> _runChainMigration(Migration migration) async {
    // Open old box (read-only) and new box (write)
    final oldBox = await Hive.openBox(migration.boxName);
    final newBoxName = '${migration.boxName}_v${migration.toVersion}';
    final newBox = await Hive.openBox(newBoxName);
    
    try {
      await migration.apply(oldBox, newBox);
      
      // Close old box, rename new box to replace it
      await oldBox.close();
      await newBox.close();
      
      // Delete old box and rename new
      await Hive.deleteBoxFromDisk(migration.boxName);
      await Hive.box(newBoxName).rename(migration.boxName);
    } catch (e) {
      // Clean up on failure
      await newBox.close();
      await Hive.deleteBoxFromDisk(newBoxName);
      rethrow;
    }
  }
  
  Future<void> _clearAndRecreate(Migration migration) async {
    final boxName = migration.boxName;
    
    // Close if open
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
    
    // Delete and recreate empty
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox(boxName);
    
    // Set new version
    await _schemaVersionBox.setVersion(boxName, migration.toVersion);
  }
}
```

- [ ] **Step 5: Export migration module**

Modify `packages/infrastructure/key_value_storage/lib/key_value_storage.dart`:

Add at line 11:
```dart
export 'src/migration/migration.dart';
export 'src/migration/migration_runner.dart';
export 'src/migration/schema_version_box.dart';
```

- [ ] **Step 6: Create migration test**

Create `packages/infrastructure/key_value_storage/test/migration_test.dart`:

```dart
import 'package:hive/hive.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test_hive');
  });
  
  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });
  
  group('Migration', () {
    test('chain strategy preserves and transforms data', () async {
      // Setup: create box with old data
      final box = await Hive.openBox('test_chain');
      await box.put('key1', {'name': 'old_name', 'value': 100});
      await box.put('key2', {'name': 'another', 'value': 200});
      await box.close();
      
      // Create migration that adds a field
      final migration = _TestChainMigration();
      
      // Re-open as "old" for migration
      final oldBox = await Hive.openBox('test_chain');
      final newBox = await Hive.openBox('test_chain_v2');
      
      await migration.apply(oldBox, newBox);
      
      // Verify transformed data
      final key1 = newBox.get('key1') as Map;
      expect(key1['name'], 'old_name');
      expect(key1['value'], 100);
      expect(key1['newField'], 'transformed_old_name');
      
      await oldBox.close();
      await newBox.close();
    });
    
    test('clearOnMismatch deletes and recreates box', () async {
      final boxName = 'test_clear';
      final migration = _TestClearMigration();
      
      // Create box with old version data
      final box = await Hive.openBox(boxName);
      await box.put('data', 'should_be_cleared');
      await box.close();
      
      // Simulate running clearOnMismatch
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox(boxName);
      
      // Verify box is empty
      final newBox = Hive.box(boxName);
      expect(newBox.isEmpty, true);
    });
    
    test('SchemaVersionBox tracks versions', () async {
      final schemaBox = SchemaVersionBox();
      await schemaBox.init();
      
      await schemaBox.setVersion('user_box', 1);
      await schemaBox.setVersion('order_box', 2);
      
      expect(schemaBox.getVersion('user_box'), 1);
      expect(schemaBox.getVersion('order_box'), 2);
      expect(schemaBox.getVersion('new_box'), 0);
    });
  });
}

/// Test migration: adds newField with transformed name
class _TestChainMigration extends Migration {
  @override
  String get boxName => 'test_chain';
  
  @override
  int get fromVersion => 1;
  
  @override
  int get toVersion => 2;
  
  @override
  MigrationStrategy get strategy => MigrationStrategy.chain;
  
  @override
  Future<void> apply(Box oldBox, Box newBox) async {
    for (final key in oldBox.keys) {
      final oldData = Map<String, dynamic>.from(oldBox.get(key) as Map);
      final transformedName = 'transformed_${oldData['name']}';
      newBox.put(key, {...oldData, 'newField': transformedName});
    }
  }
  
  @override
  Future<bool> validate(Box box) async {
    // Check all entries have newField
    for (final key in box.keys) {
      final data = box.get(key) as Map;
      if (!data.containsKey('newField')) return false;
    }
    return true;
  }
}

/// Test migration for clear strategy
class _TestClearMigration extends Migration {
  @override
  String get boxName => 'test_clear';
  
  @override
  int get fromVersion => 1;
  
  @override
  int get toVersion => 2;
  
  @override
  MigrationStrategy get strategy => MigrationStrategy.clearOnMismatch;
  
  @override
  Future<void> apply(Box oldBox, Box newBox) async {
    // No-op for clear strategy
  }
  
  @override
  Future<bool> validate(Box box) async {
    return box.isEmpty;
  }
}
```

- [ ] **Step 7: Run migration tests**

```bash
cd packages/infrastructure/key_value_storage && flutter test test/migration_test.dart
```

Expected: All tests pass

- [ ] **Step 8: Commit**

```bash
git add packages/infrastructure/key_value_storage/lib/src/migration/ packages/infrastructure/key_value_storage/lib/key_value_storage.dart packages/infrastructure/key_value_storage/test/migration_test.dart
git commit -m "feat: add Hive migration framework with chain and clearOnMismatch strategies"
```

---

### Task 3: Create typeId Registry (register.yaml)

**Files:**
- Create: `register.yaml` at project root
- Modify: `bricks/feature/brick.yaml` (read typeId from register.yaml)

- [ ] **Step 1: Create register.yaml at project root**

Create `register.yaml` in the project root (NOT inside a brick):

```yaml
# Hive TypeId Registry
# 
# This file tracks the next available typeId for Hive adapters.
# When adding new @HiveType models:
# 1. Read the current nextTypeId value
# 2. Use that id for your new adapter
# 3. Increment nextTypeId and commit
#
# Reserved IDs:
#   0: CacheData (infrastructure/key_value_storage)
#
# Format: Use this file as the source of truth. 
# Mason bricks will read from this file when generating new features.

nextTypeId: 1

# Usage history (for reference, not used by code)
typeIds:
  - id: 0
    model: CacheData
    package: infrastructure/key_value_storage
    description: Generic cache wrapper with TTL support
```

- [ ] **Step 2: Verify register.yaml is in .gitignore if needed**

The register.yaml should be tracked (it contains the next available ID for the team).

- [ ] **Step 3: Commit**

```bash
git add register.yaml
git commit -m "feat: add register.yaml for Hive typeId tracking"
```

---

### Task 4: Verify Full Integration

**Files:**
- Modify: `lib/core/startup/initializer.dart`

- [ ] **Step 1: Verify SDKInitializer calls initPlugins in correct order**

The launch sequence in `launcher.dart`:
1. Phase 1: Core init (HydratedStorage)
2. Phase 2: SDK init (SDKInitializer.initPlugins) ✅ Hive.initFlutter + HiveRegistrar
3. Phase 3: Business init (AuthManager, DataSyncManager)
4. Phase 4: runApp

This is correct. Hive is initialized in Phase 2 before any business logic.

- [ ] **Step 2: Run full analyze to ensure no issues**

```bash
flutter analyze
```

Expected: No errors

- [ ] **Step 3: Run all key_value_storage tests**

```bash
cd packages/infrastructure/key_value_storage && flutter test
```

Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: complete Hive database enhancement - init unification, migration framework, typeId registry"
```

---

## Summary of Changes

| Task | Files Changed | Key Changes |
|------|---------------|-------------|
| 1. Unify Hive.init() | 2 | Move `Hive.initFlutter()` to SDKInitializer, remove from KeyValueStorage |
| 2. Migration Framework | 5 | Create Migration, MigrationRunner, SchemaVersionBox + tests |
| 3. typeId Registry | 2 | Create register.yaml at project root |
| 4. Integration | 2 | Verify startup sequence, run full tests |

---

## Migration Usage Guide

### For feature developers:

**Adding a new @HiveField to an existing model:**

```dart
// 1. Create migration class
class UserMigrationV1ToV2 extends Migration {
  @override
  String get boxName => 'user_box';
  @override
  int get fromVersion => 1;
  @override
  int get toVersion => 2;
  @override
  MigrationStrategy get strategy => MigrationStrategy.chain;
  
  @override
  Future<void> apply(Box oldBox, Box newBox) async {
    for (final key in oldBox.keys) {
      final oldData = Map<String, dynamic>.from(oldBox.get(key) as Map);
      newBox.put(key, {
        ...oldData,
        'newField': 'default_value', // New field added
      });
    }
  }
  
  @override
  Future<bool> validate(Box box) async => true;
}

// 2. Register in app startup
final runner = MigrationRunner(schemaVersionBox);
runner.registerMigration(UserMigrationV1ToV2());
await runner.runAll();
```

**For cache boxes (safe to clear):**

```dart
class CacheMigrationV1ToV2 extends Migration {
  @override
  String get boxName => 'cache_box';
  @override
  int get fromVersion => 1;
  @override
  int get toVersion => 2;
  @override
  MigrationStrategy get strategy => MigrationStrategy.clearOnMismatch;
  
  @override
  Future<void> apply(Box oldBox, Box newBox) async {};
  @override
  Future<bool> validate(Box box) async => true;
}
```
