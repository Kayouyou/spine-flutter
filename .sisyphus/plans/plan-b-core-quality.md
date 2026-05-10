# Plan B: Core Quality (Phase 2 + Phase 3)

**Covers:** Phase 2 (Type Safety) + Phase 3 (DI Discipline & Feature Template Quality)
**Duration:** 4-6 days
**Pre-condition:** Plan A complete, all existing tests pass
**Post-condition:** Typed domain models throughout, proper DI discipline in features, cache-integrated feature template

---

## Task List

### Phase 2: Type Safety (9 tasks)

- [ ] **T2.1 Create HomeData domain model (@freezed)**
  - Goal: Create strongly-typed HomeData model in domain package
  - Files: `packages/domain/lib/src/models/home_data.dart`, `packages/domain/lib/src/models/home_data.g.dart`
  - Changes:
    - Create `HomeData` class with @freezed annotation
    - Include fields matching API response (e.g., title, items, metadata)
    - Add factory constructor from JSON constructor
  - Verify: `cd packages/domain && flutter test`; model compiles with `freezed` generated code
  - Rollback: `git checkout -- packages/domain/lib/src/models/home_data.dart`

- [ ] **T2.2 Create DetailData domain model (@freezed)**
  - Goal: Create strongly-typed DetailData model in domain package
  - Files: `packages/domain/lib/src/models/detail_data.dart`, `packages/domain/lib/src/models/detail_data.g.dart`
  - Changes:
    - Create `DetailData` class with @freezed annotation
    - Include fields matching API response (e.g., id, content, relatedItems)
    - Add factory constructor from JSON constructor
  - Verify: Model compiles with freezed generated code
  - Depends on: T2.1
  - Rollback: `git checkout -- packages/domain/lib/src/models/detail_data.dart`

- [ ] **T2.3 Update HomeRepository interface (Map→HomeData)**
  - Goal: Change repository interface return type from Map<String,dynamic> to HomeData
  - Files: `packages/domain/lib/src/repositories/home_repository.dart`
  - Changes:
    - Change `Future<Map<String,dynamic>> getHomeData()` to `Future<HomeData> getHomeData()`
    - Update any other methods that return Map
  - Verify: Interface compiles, implementers will need updating
  - Depends on: T2.1
  - Rollback: `git checkout -- packages/domain/lib/src/repositories/home_repository.dart`

- [ ] **T2.4 Update DetailRepository interface (Map→DetailData)**
  - Goal: Change repository interface return type from Map<String,dynamic> to DetailData
  - Files: `packages/domain/lib/src/repositories/detail_repository.dart`
  - Changes:
    - Change `Future<Map<String,dynamic>> getDetailData(String id)` to `Future<DetailData> getDetailData(String id)`
    - Update any other methods that return Map
  - Verify: Interface compiles
  - Depends on: T2.2
  - Rollback: `git checkout -- packages/domain/lib/src/repositories/detail_repository.dart`

- [ ] **T2.5 Update HomeRepositoryImpl: remove response.toJson() downgrade**
  - Goal: Remove Map downgrade and return typed HomeData directly
  - Files: `packages/features/feature_home/lib/src/repository/home_repository_impl.dart`
  - Changes:
    - Remove `response.toJson()` call that degrades typed response to Map
    - Convert API response directly to HomeData via `HomeData.fromJson(response.data)`
    - Return typed `HomeData` instead of `Map<String,dynamic>`
  - Verify: Repository compiles, tests pass
  - Depends on: T2.3
  - Rollback: `git checkout -- packages/features/feature_home/lib/src/repository/home_repository_impl.dart`

- [ ] **T2.6 Update DetailRepositoryImpl: same as T2.5**
  - Goal: Remove Map downgrade and return typed DetailData directly
  - Files: `packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart`
  - Changes:
    - Remove `response.toJson()` downgrade
    - Convert API response directly to DetailData via `DetailData.fromJson(response.data)`
    - Return typed `DetailData` instead of `Map<String,dynamic>`
  - Verify: Repository compiles, tests pass
  - Depends on: T2.4
  - Rollback: `git checkout -- packages/features/feature_detail/lib/src/repository/detail_repository_impl.dart`

- [ ] **T2.7 Update HomeState + HomeCubit + HomePage to use typed model**
  - Goal: Update state management to work with typed HomeData instead of Map
  - Files: `packages/features/feature_home/lib/src/cubit/home_state.dart`, `packages/features/feature_home/lib/src/cubit/home_cubit.dart`, `packages/features/feature_home/lib/src/ui/home_page.dart`
  - Changes:
    - home_state.dart: Change `Map<String,dynamic>? data` to `HomeData? data`
    - home_cubit.dart: Update state emissions to use typed data
    - home_page.dart: Remove dynamic casts, access typed fields directly (e.g., `state.data.title` instead of `state.data['title']`)
  - Verify: Home feature tests pass, UI renders correctly with typed data
  - Depends on: T2.5
  - Rollback: `git checkout -- packages/features/feature_home/lib/src/cubit/ packages/features/feature_home/lib/src/ui/home_page.dart`

- [ ] **T2.8 Update DetailState + DetailCubit + DetailPage to use typed model**
  - Goal: Update state management to work with typed DetailData instead of Map
  - Files: `packages/features/feature_detail/lib/src/cubit/detail_state.dart`, `packages/features/feature_detail/lib/src/cubit/detail_cubit.dart`, `packages/features/feature_detail/lib/src/ui/detail_page.dart`
  - Changes:
    - detail_state.dart: Change `Map<String,dynamic>? data` to `DetailData? data`
    - detail_cubit.dart: Update state emissions to use typed data
    - detail_page.dart: Remove dynamic casts, access typed fields directly
  - Verify: Detail feature tests pass, UI renders correctly with typed data
  - Depends on: T2.6
  - Rollback: `git checkout -- packages/features/feature_detail/lib/src/cubit/ packages/features/feature_detail/lib/src/ui/detail_page.dart`

- [ ] **T2.9 Update feature brick to generate typed models (not Map)**
  - Goal: Modify Mason template to generate typed domain models instead of Map return types
  - Files: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart` (template), `bricks/feature/__brick__/lib/src/cubit/{{name}}_state.dart` (template)
  - Changes:
    - Update repository template to import domain model and return typed model
    - Update state template to use typed model instead of Map<String,dynamic>
    - Add @freezed model generation to post_gen hook
  - Verify: Generate test feature, verify it compiles with typed models
  - Depends on: T2.7, T2.8
  - Rollback: `git checkout -- bricks/feature/`

---

### Phase 3: DI Discipline & Feature Template Quality (4 tasks)

- [ ] **T3.1 Remove GetIt.instance<IAppConfig>() from home_page.dart**
  - Goal: Replace direct GetIt access with proper constructor injection
  - Files: `packages/features/feature_home/lib/src/ui/home_page.dart`, `packages/features/feature_home/lib/src/cubit/home_cubit.dart`
  - Changes:
    - home_cubit.dart: Add `final IAppConfig _config` to constructor
    - home_cubit.dart: Use `_config` instead of `GetIt.instance<IAppConfig>()`
    - home_page.dart: Remove `import 'package:get_it/get_it.dart';` if only used for GetIt.instance
    - setup.dart: Ensure IAppConfig is registered in DI container
  - Verify: Home feature works, no GetIt.instance calls in home_page.dart
  - Rollback: `git checkout -- packages/features/feature_home/`

- [ ] **T3.2 Remove Alice/Upgrader imports from feature_home**
  - Goal: Move app-level debug/upgrade concerns to app layer
  - Files: `packages/features/feature_home/lib/src/ui/home_page.dart`, `lib/app.dart` (or new debug wrapper)
  - Changes:
    - home_page.dart: Remove `import 'package:alice/core/alice_shell.dart';` and `import 'package:upgrader/upgrader.dart';`
    - lib/app.dart: Add Alice debug panel wrapper at app level (not feature level)
    - lib/app.dart: Add UpgradeAlert widget at app level if needed
  - Verify: Home page still works without Alice/Upgrader imports
  - Rollback: `git checkout -- packages/features/feature_home/lib/src/ui/home_page.dart lib/app.dart`

- [ ] **T3.3 Remove GetIt.instance from feature_detail (if present)**
  - Goal: Apply same DI discipline to detail feature
  - Files: `packages/features/feature_detail/lib/src/ui/detail_page.dart`, `packages/features/feature_detail/lib/src/cubit/detail_cubit.dart`
  - Changes:
    - Search for any `GetIt.instance` calls in detail feature
    - Replace with constructor injection via Cubit
  - Verify: Detail feature works, no GetIt.instance in feature code
  - Rollback: `git checkout -- packages/features/feature_detail/`

- [ ] **T3.4 Add cache integration to feature brick template**
  - Goal: New features should get ListCacheManager "for free"
  - Files: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart`
  - Changes:
    - Add optional cache parameter to repository constructor
    - Add ListCacheManager field with configurable CacheConfig
    - Add template variable to enable/disable caching per feature
    - Update DI setup template to optionally register cache manager
  - Verify: Generate test feature with caching enabled, verify it compiles with cache wiring
  - Depends on: T2.9 (brick changes)
  - Rollback: `git checkout -- bricks/feature/`

---

## Dependency Graph

```
Phase 2 (Type Safety)
├── T2.1 (HomeData model) ──────┐
├── T2.2 (DetailData model)    │
├── T2.3 (HomeRepo interface)  ├──► T2.5 (HomeRepoImpl)
├── T2.4 (DetailRepo interface)├──► T2.6 (DetailRepoImpl)
├── T2.5 (HomeRepoImpl)       ├──► T2.7 (HomeState/Cubit/Page)
├── T2.6 (DetailRepoImpl)     ├──► T2.8 (DetailState/Cubit/Page)
├── T2.7 (Home UI typed)      ───► T2.9 (Brick template typed)
└── T2.8 (Detail UI typed)    ───► T2.9 (Brick template typed)

Phase 3 (DI Discipline)
├── T3.1 (Remove GetIt home)  ──┐
├── T3.2 (Remove Alice/Upgrader)│
├── T3.3 (Remove GetIt detail) ├──► Phase 3 complete
└── T3.4 (Cache in brick)      ──► T3.4 depends on T2.9

Legend: ──► = depends on
```

---

## Verification Checklist

Run these commands in order after completing all tasks:

```bash
# Phase 2 verification
melos run analyze                                          # Must pass with no errors
cd packages/domain && flutter test                        # Domain tests pass
cd packages/features/feature_home && flutter test       # Home tests pass
cd packages/features/feature_detail && flutter test      # Detail tests pass
grep -r "Map<String,dynamic>" packages/features/feature_home/lib/src/   # Should return nothing (except comments)
grep -r "Map<String,dynamic>" packages/features/feature_detail/lib/src/ # Should return nothing (except comments)

# Phase 3 verification
grep -r "GetIt.instance<IAppConfig>" packages/features/feature_home/    # Should return nothing
grep -r "GetIt.instance<IAppConfig>" packages/features/feature_detail/   # Should return nothing
grep -r "alice" packages/features/feature_home/lib/src/                  # Should return nothing
grep -r "upgrader" packages/features/feature_home/lib/src/               # Should return nothing
mason make feature --name test_verify --dry-run                           # Verify brick generates cache-aware code

# Full verification
melos run test                                            # All tests pass
```

---

## Timeline (4-6 days)

| Day | Focus | Tasks |
|-----|-------|-------|
| 1 | Domain models | T2.1, T2.2 |
| 2 | Repository interfaces + impl | T2.3, T2.4, T2.5, T2.6 |
| 3 | State + Cubit + UI | T2.7, T2.8 |
| 4 | Brick template | T2.9 |
| 5 | DI discipline | T3.1, T3.2, T3.3 |
| 6 | Template quality | T3.4, final verification |

---

## Rollback Strategy

All tasks have single-command rollback via `git checkout`. If any task introduces regression:
1. Run rollback command immediately
2. Re-run verification for that task
3. Investigate before retrying

If broader rollback needed (multiple tasks):
- Phase 2 issues → restart from T2.1
- Phase 3 issues → restart from T3.1

---

## Pre-Implementation Notes

1. **Test baseline**: Run `melos run validate` before starting to confirm clean state
2. **Incremental verify**: Each task's verification must pass before moving to next
3. **Model first**: T2.1 and T2.2 are foundation for all other type safety work
4. **Brick last**: T2.9 should happen after all type safety work is verified in existing features
5. **Cache pattern**: Review HomeRepositoryImpl existing cache usage before T3.4

---

## Notes from Design Spec

- Phase 2 addresses: "Typed API response exists but gets degraded to untyped Map"
- Phase 3 addresses: "Features currently bypass proper DI by calling GetIt.instance<IAppConfig>() directly"
- Phase 3 addresses: "Feature Home also has direct dependencies on Alice and Upgrader packages"
- Phase 3 addresses: "ListCacheManager is available but only HomeRepoImpl uses it; the feature brick template doesn't include caching integration"
