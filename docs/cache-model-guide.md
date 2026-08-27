# 缓存模型规范（Cache Model Guide）

> 适用：新增「需要本地缓存的 API / 数据源」时
> 配套：迁移框架见 `packages/infrastructure/key_value_storage/lib/src/migration/`
> 关联：`docs/QUICK_REFERENCE.md`（速查卡 §5）、`docs/di-discipline.md`、`docs/api-layer-guide.md`

---

## 1. 为什么是三层？

一个数据在不同场景下有**三种不同形态**，必须分开看待，否则 API 改一个字段就会牵动缓存、牵动业务：

| 层 | 名称 | 职责 | 所在位置 | 依赖 |
|---|------|------|----------|------|
| **DTO** | Data Transfer Object | 描述「网络线格式」(JSON 字段、命名、嵌套)，只负责序列化 | `features/*/data/...` 或 `infrastructure/api` 的 model | 可依赖 `json_serializable` / `Retrofit`；**不依赖业务** |
| **Entity** | 领域实体 | 描述「业务语义」，纯净、可测、与框架无关 | `domain` 包 | **不依赖任何 Flutter / 网络 / 存储框架** |
| **CacheModel** | 缓存模型 | 描述「持久化格式」(是否需要 TTL / 脏标记 / 与 API 解耦) | `infrastructure/key_value_storage` 或各 data 层 | 可依赖 `hive`（`@HiveType`）；**不依赖 domain 业务规则** |

> 对应硬约束：**R2** domain 不得 import Flutter；**R6** 新 API 必须走 Retrofit + Dio 拦截器栈。这三层正是 R2/R6 的物理落点。

---

## 2. DTO ⇄ Entity：何时合并、何时分离

### 2.1 可以合并（薄映射）
当 API 返回结构与业务实体**完全一致**（字段名、类型、嵌套都一样）时，DTO 直接充当 Entity，不必多写一层。

```dart
// DTO 即 Entity：UserProfile 同时用于网络与业务
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({ required String id, required String name }) = _UserProfile;
  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
```

### 2.2 必须分离
出现以下任一情况时，**DTO 与 Entity 分离**：
- API 字段命名/结构与业务语义不一致（`created_at`、`u_name` vs `createdAt`、`userName`）
- API 嵌套过深，业务只需扁平字段
- 同一 Entity 由多个 DTO 聚合而成（如 `OrderDetail` = 订单 DTO + 商品 DTO + 用户 DTO）

```dart
// DTO（线格式）
class UserDto {
  final String u_id;
  final String u_name;
  UserDto.fromJson(Map<String, dynamic> j) : u_id = j['u_id'], u_name = j['u_name'];
}

// Entity（业务语义，纯净）
class UserProfile {
  const UserProfile(this.id, this.name);
}

// 在 data 层做映射（Repository 内）
UserProfile toEntity(UserDto dto) => UserProfile(dto.u_id, dto.u_name);
```

**原则**：映射逻辑只发生在 `data` 层 / Repository 实现内，**domain 层永远只看到 Entity**。

---

## 3. CacheModel：何时需要独立

缓存框架已提供两层能力：
- **泛型容器 `CacheData<T>`**（`cache_data.dart`）：包一层 `value` + `expireAt`，自带 TTL / `isExpired`，已自动处理「过期即丢弃」。
- **`BoxService<T>`**（`box_service.dart`）：`putWithExpiry` / `getWithExpiry` 已把 `CacheData<T>` 包好，开箱即用。

### 3.1 复用 DTO / Entity 即可（无需独立 CacheModel）
当缓存数据**与 API 返回结构一致且稳定**，直接用现有类型 + `CacheData`：

```dart
final box = BoxService<UserProfile>('user_profile');
await box.putWithExpiry('me', profile, ttl: const Duration(hours: 1));
final cached = await box.getWithExpiry('me'); // 过期自动返回 null 并删除
```

→ 没有任何额外模型，DTO/Entity 复用为缓存值。

### 3.2 必须独立建 CacheModel
出现以下任一情况时，建**独立的 `@HiveType` CacheModel**，与 DTO 解耦：
- 需要 DTO 没有的字段：**`expiredAt` / `dirty` 脏标记 / `fetchedAt` / 本地草稿态**
- 缓存结构需**独立于 API 演进**（API 改了，缓存不跟着崩）→ 这正是 `MigrationRunner` 的用武之地
- 缓存值是多个 DTO 的聚合快照

```dart
@HiveType(typeId: 10)
class UserCacheModel {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final bool dirty;        // DTO 没有：本地脏标记
  @HiveField(3) final int schemaVersion; // 独立演进用
  UserCacheModel(this.id, this.name, this.dirty, this.schemaVersion);
}
```

独立 CacheModel 的代价是：**每次写入要 DTO/Entity → CacheModel 映射，读取要 CacheModel → Entity 映射**。只在确实需要上述能力时才付出这个成本。

---

## 4. 版本与迁移（框架已在，必须接）

`key_value_storage` 已内置完整迁移框架，**新增独立 CacheModel 时必须注册迁移**，否则老用户升级后会读到旧 schema：

| 组件 | 文件 | 作用 |
|------|------|------|
| `Migration` (抽象) | `migration/migration.dart` | 定义 `boxName` / `fromVersion` / `toVersion` / `strategy` / `apply` / `validate` |
| `MigrationRunner` | `migration/migration_runner.dart` | 启动时按 `fromVersion` 升序跑所有注册迁移 |
| `SchemaVersionBox` | `migration/schema_version_box.dart` | 记录每个 box 当前版本号 |
| `MigrationStrategy` | `migration/migration.dart` | `chain`（保留数据，逐版迁移）/ `clearOnMismatch`（版本对不上直接清） |

```dart
class UserCacheMigrationV1ToV2 extends Migration {
  @override String get boxName => 'user_cache';
  @override int get fromVersion => 1;
  @override int get toVersion => 2;
  @override MigrationStrategy get strategy => MigrationStrategy.chain; // 保留数据
  @override Future<void> apply(Box oldBox, Box newBox) async { /* 旧→新字段映射 */ }
  @override Future<bool> validate(Box box) async => box.isNotEmpty; // 校验
}

// 在 AppLauncher / 初始化入口注册：
migrationRunner.registerMigration(UserCacheMigrationV1ToV2());
await migrationRunner.run();
```

**策略选择**：
- 用户数据（资料、设置）→ `chain`，宁可写迁移也别丢数据
- 可安全重建的缓存（列表快照、搜索历史）→ `clearOnMismatch`，版本对不上直接清，省事

---

## 5. 新增「可缓存 API」标准 5 步 checklist

1. **定义 DTO**：在 data 层定义 API 线格式（`Retrofit` 接口 + `fromJson`）。结构 = 业务则跳到 3。
2. **定义 Entity**：在 `domain` 定义纯净业务实体；若 DTO ≠ Entity，在 data 层写映射函数。
3. **决定缓存值类型**：
   - 结构与 API 一致且稳定 → 直接用 DTO/Entity + `BoxService<T>.putWithExpiry`；
   - 需 TTL/脏标记/独立演进 → 建 `@HiveType` CacheModel + `hive_registrar` 注册 `TypeAdapter`。
4. **接迁移（仅独立 CacheModel）**：实现 `Migration`，在启动入口 `registerMigration` + `migrationRunner.run()`；选 `chain` 或 `clearOnMismatch`。
5. **Repository 收口**：Repository 实现内组装「remote（Dio）→ 内存 Entity → 写入缓存」「读缓存命中且未过期 → 直接返 Entity；否则走网络并回写」。对外只暴露 Entity，**UI 永远看不到 DTO / CacheModel**。

---

## 6. 反例（禁止）

- ❌ 把 `Map<String, dynamic>` 直接塞进 `Box`，无模型、无版本 → schema 变更必崩
- ❌ domain 包 import `hive` / `Retrofit` → 违反 R2
- ❌ 在 UI 层直接 `box.get(...)` 读缓存 → 绕过 Repository，缓存策略失控
- ❌ 独立 CacheModel 不注册 `Migration` → 老用户升级读到旧 schema
- ❌ 缓存值用 `dynamic` / `Object` → 失去类型安全，迁移无法校验
