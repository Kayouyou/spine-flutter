# Flutter Scaffold Transformation Design Spec

**Document ID:** 2026-05-10-scaffold-transformation-design  
**Version:** 2.0  
**Status:** Draft  
**Target Score:** 9.0/10 (from 7.8/10)

---

## Overview

This document defines the transformation plan to elevate the my_app Flutter monorepo from its current architecture score of 7.8/10 to a target of 9.0/10. The transformation spans seven phases over approximately 18-28 days, addressing critical gaps between the scaffold's design intent and actual implementation consistency.

**Guiding Principles (Non-Negotiable):**

1. Each phase is independently verifiable - completion requires passing all acceptance criteria before proceeding
2. Maximum 3 packages modified per phase (Phases 0-3 strictly; Phases 4-6 may touch up to 4 where dependencies are cross-cutting) - limits blast radius and simplifies rollback
3. Full test pass required per phase - no regressions allowed
4. Self-contained document - provides sufficient context for readers unfamiliar with the evaluation

---

## Background

### Current State Assessment

The my_app Flutter monorepo uses Clean Architecture with Melos for multi-package management. A recent team audit revealed:

| Dimension | Design Intent | Actual Consistency | Gap |
|-----------|---------------|---------------------|-----|
| Overall Architecture | 8.8/10 | 7.x | 1.0+ |
| Auth DI | Intended DI injection | Bypassed in pages | Critical |
| Repository Pattern | Interface in domain | Template generates impl in feature | Moderate |
| Type Safety | Full typing | Map<String,dynamic> in domain | Moderate |
| DataSync | Required per spec | Empty implementation | Moderate |
| Routing | Module auto-registration | Manual assembly | Moderate |

### Root Causes Identified

1. **Template vs Reality Mismatch:** The Mason `feature` brick generates code that contradicts Clean Architecture principles (e.g., `{{name}}_repository.dart` in feature instead of domain interface)

2. **Runtime Bugs Present:** `errorCode.name` called on String (no .name property), causing runtime crashes

3. **Build Anti-Patterns:** `addPostFrameCallback` in `DetailPage` triggers data load on every rebuild, causing performance issues and inconsistent state

4. **Incomplete Testing:** Root app (`lib/`) lacks tests; only packages are covered in CI

5. **Documentation Drift:** README architecture rating (9.0/10) reflects optimistic self-assessment rather than reality

### Dependencies Between Phases

```
Phase 0 ──┬──► Phase 1 ──► Phase 2 ──┬──► Phase 3 ──► Phase 4
          │                          │
          │                          └──► Phase 5 (partial parallel)
          │
          └──► Phase 6 (depends on all)
```

- **P1 depends on P0:** Root tests in CI required for safe refactoring
- **P2 depends on P1:** Brick alignment must complete before type safety work
- **P3 depends on P1:** RouteModuleRegistry and brick alignment prerequisites
- **P4 partially parallel:** Can proceed independently of P2/P3 (different packages)
- **P5 partially parallel:** Can overlap with P3/P4 (storage/launcher are independent modules)
- **P6 depends on all:** Documentation and testing require complete prior work

---

## Phase 0: Stop the Bleeding

**Duration:** 1-2 days  
**Priority:** Critical  
**Packages Modified:** feature_home, feature_detail, lib/

### Goal

Fix critical runtime bugs and testing gaps that cause crashes or incorrect behavior. Establish baseline test coverage for the root app.

### Current State

- `errorCode.name` called on `String` in `home_page.dart:133` and `detail_page.dart:92` - `String` has no `.name` property
- `DetailPage` uses `addPostFrameCallback` in build method, triggering `loadData()` on every widget rebuild
- Root app (`lib/`) has zero test coverage; CI only runs `melos test` on packages

### Changes

1. **Fix Runtime Bug - errorCode.name:**
   - `home_page.dart:121`: change `_buildError(BuildContext context, errorCode)` implicit dynamic parameter to `String errorCode`
   - `home_page.dart:133`: change `${errorCode.name}` to `${errorCode}` (or simply pass the string directly)
   - `detail_page.dart:85`: change implicit dynamic parameter to `String errorCode`
   - `detail_page.dart:92`: change `${errorCode.name}` to `${errorCode}`
   - Root cause: freezed generates `errorCode` as `String`, but the method parameter is untyped (dynamic), allowing `.name` to compile but return null at runtime

2. **Fix DetailPage Build Trigger:**
   - Remove `addPostFrameCallback` from `build()` (detail_page.dart:18-21)
   - Move data loading to `LifecycleMixin.onPageEnter()` (project already has `LifecycleMixin` in routing package)
   - This ensures data loads once on navigation, never on rebuild

3. **Add Root App Tests:**
   - Add test directory to `lib/test/` or root-level test
   - Register in melos.yaml to include in CI test runs
   - Add root app to `.github/workflows/ci.yml` test step

4. **Update README Architecture Rating:**
   - Change "Architecture Rating: 9.0/10" to reflect actual 7.8/10
   - Add audit findings summary

### Acceptance Criteria

- [ ] `home_page.dart:133` and `detail_page.dart:92` no longer reference `.name` on String
- [ ] DetailPage loads data only once per navigation (not on every rebuild)
- [ ] Root app tests run in CI (`melos test` includes lib/ or separate step)
- [ ] README architecture rating corrected to 7.8/10 with explanation
- [ ] All existing tests pass
- [ ] `flutter analyze` passes with no errors

---

## Phase 1: Architecture Alignment

**Duration:** 3-5 days  
**Priority:** High  
**Packages Modified:** feature_auth, bricks/feature, infrastructure/routing *(domain interfaces already exist; no domain changes needed in this phase)*

### Goal

Align scaffold implementation with stated architecture: Repository interfaces in domain, proper DI throughout, and routing auto-registration.

### Current State

- **Auth DI Bypass:** `login_page.dart:16-17` and `register_page.dart:16-17` use `BlocProvider` with `MockAuthRepository()`, bypassing the DI container entirely
- **Template Generates Wrong Location:** `{{name}}_repository.dart` generated in feature instead of domain; `{{name}}_repository_impl.dart` imports incorrectly
- **Routing Manual Assembly:** All routes manually added in `app_router.dart`; no auto-registration
- **Routing Package Scope Unclear:** Package contains both primitives and application-specific route assembly

### Changes

1. **Unify Auth DI:**
   - Remove `BlocProvider(create: ... MockAuthRepository())` from login and register pages
   - Ensure `setupFeatureAuth` properly registers `LoginCubit` with injected `AuthRepository`
   - Pages should use `context.read<LoginCubit>()` without creating new instance

2. **Rewrite Feature Brick:**
   - Remove `{{name}}_repository.dart` template (interface belongs in domain)
   - Update `{{name}}_repository_impl.dart` to import domain interface
   - Add import for api package to use `toDomainException()` conversion

3. **Create RouteModuleRegistry:**
   - Define `RouteModuleRegistry` interface in routing package
   - Features register routes via DI (call `registry.register(...)` in their `setupFeatureXxx`)
   - `app.dart` traverses registry instead of hardcoded route list
   - Document that routing package contains "primitives only" (no app-specific assembly)

4. **Update Documentation:**
   - Clarify routing package scope in README
   - Document RouteModuleRegistry usage

5. **Establish DI Discipline Pattern (Design Decision):**
    - Features currently bypass proper DI by calling `GetIt.instance<IAppConfig>()` directly in home_page.dart
    - Feature Home also has direct dependencies on `Alice` and `Upgrader` packages in the page widget
    - Decision: All feature dependencies must flow through constructor injection or BlocProvider, never direct GetIt access. App-level concerns (Alice debug panel, Upgrader update check) belong in app layer, not features.
    - Note: Actual code cleanup for existing features happens in Phase 3 (packages modified there)

### Acceptance Criteria

- [ ] Login and Register pages obtain Cubit via DI (no `MockAuthRepository` in page code)
- [ ] Feature brick generates repository implementation that imports domain interface
- [ ] New feature routes auto-register via RouteModuleRegistry
- [ ] Routing package documentation clarifies "primitives only" scope
- [ ] DI discipline pattern documented as design decision (implementation in Phase 3)
- [ ] All tests pass

---

## Phase 2: Type Safety

**Duration:** 2-3 days  
**Priority:** High  
**Packages Modified:** feature_home, feature_detail, domain

### Goal

Replace `Map<String,dynamic>` with strongly-typed domain models throughout the codebase, eliminating runtime type uncertainty.

### Current State

- `HomeRepository` and `DetailRepository` interfaces use `Map<String,dynamic>` return types
- `HomeRepositoryImpl` (home_repository_impl.dart:37) explicitly downgrades typed API response via `response.toJson()`
- Typed API response exists but gets degraded to untyped Map
- **Storage Layer Overlap:** The storage layer has `SharedPreferenceStorage` overlapping with `KeyValueStorage` — this represents part of the "half-typed" problem where two similar storage abstractions coexist. The `KeyValueStorage` provides Hive-backed generic storage while `SharedPreferenceStorage` serves as a convenience wrapper. This overlap creates confusion about which to use and will be addressed in Phase 5.

### Changes

1. **Define Typed Domain Models:**
   - Create `HomeData` and `DetailData` in domain models
   - Use @freezed for immutability and equality

2. **Update Repository Interfaces:**
   - Change `Future<Map<String,dynamic>> getHomeData()` to `Future<HomeData> getHomeData()`
   - Apply same for Detail repository

3. **Update Repository Implementations:**
   - Remove `response.toJson()` downgrade
   - Return typed `HomeData` / `DetailData` directly from API response

4. **Synchronize State and UI:**
   - Update Cubit states to use typed models
   - Update UI to work with typed data (remove `dynamic` casts)

5. **Update Brick Template:**
   - Generate typed models instead of Maps
   - Template should create domain model + use in repository

### Acceptance Criteria

- [ ] HomeRepository and DetailRepository return typed domain models (not Map<String,dynamic>)
- [ ] RepositoryImpl no longer downgrades to Map
- [ ] Cubit states use typed models
- [ ] UI components work with typed data
- [ ] Brick template generates typed models
- [ ] All tests pass

---

## Phase 3: DI Discipline & Feature Template Quality

**Duration:** 2-3 days  
**Priority:** High  
**Packages Modified:** feature_home, feature_detail, bricks/feature

### Goal

Make feature templates demonstrate best-practice DI patterns, not demo shortcuts. Remove debug-only and app-level dependencies from feature templates.

### Current State

- **GetIt.instance in Features:** home_page.dart directly calls `GetIt.instance<IAppConfig>()` instead of using constructor injection
- **Alice/Upgrader Direct Deps:** Feature Home imports `alice` (debug panel) and `upgrader` (update checker) packages directly in the page widget, which are app-level concerns, not feature concerns
- **Cache Not in Template:** `ListCacheManager` exists but only HomeRepoImpl uses it; the feature brick template doesn't include caching integration

### Changes

1. **Remove GetIt.instance from Features:**
   - Replace `GetIt.instance<IAppConfig>()` in home_page.dart with constructor-injected IAppConfig
   - Pattern: Cubit receives IAppConfig via DI, page reads from Cubit state if needed
   - Or use BlocProvider to pass dependencies down the widget tree

2. **Remove Alice/Upgrader from Feature Template:**
   - Feature Home currently imports `alice` and `upgrader` packages directly
   - These are app-level concerns, not feature concerns
   - Move debug panel and update check to app-level widgets (app.dart or dedicated debug wrapper)
   - Keep feature template clean of debug-only and app-level dependencies

3. **Cache Integration in Brick Template:**
   - The ListCacheManager is available but only HomeRepoImpl uses it
   - Update the feature brick template to optionally include `ListCacheManager` wiring in generated RepositoryImpl
   - New features should get caching "for free" without manual wiring
   - Add a flag or template variable to enable/disable caching per feature

### Acceptance Criteria

- [ ] No `GetIt.instance<>()` calls in feature_home or feature_detail page widgets
- [ ] Alice/Upgrader imports removed from feature_home; debug panel moved to app layer
- [ ] Feature brick optionally generates cache-aware RepositoryImpl
- [ ] All tests pass
- [ ] `flutter analyze` passes with no errors

---

## Phase 4: Generation Pipeline

**Duration:** 3-5 days  
**Priority:** High  
**Packages Modified:** bricks/feature, lib/core/di, infrastructure/routing, makefile

### Goal

Automate feature creation end-to-end: code generation auto-registers routes, auto-adds DI, auto-adds pubspec dependencies.

### Current State

- `make create-feature` generates code but requires manual:
  - Route registration in routing package
  - DI registration in setup.dart
  - Pubspec dependency addition
- Current scripts use awk/text-append, fragile and undocumented

### Changes

1. **Auto-Register Routes:**
   - New feature calls `RouteModuleRegistry.register(...)` in its `di/setup.dart`
   - Post-generation hook triggers route registration

2. **Auto-Register DI:**
   - Feature `di/setup.dart` auto-imported via barrel file
   - Setup function called in root `setup.dart` via package introspection
   - Alternative: `setupFeatureXxx(sl)` auto-invoked if exported in barrel

3. **Auto-Add Pubspec:**
    - Melos discovers packages via `packages/features/*` glob pattern in melos.yaml
    - However, root `pubspec.yaml` still needs explicit path dependency added
    - Post-generation script should add `feature_xxx: path: packages/features/feature_xxx` to root pubspec dependencies

4. **Replace Fragile Scripts:**
   - Replace awk/text-append with structured insertion
   - Use marker comments (e.g., `// <<<< ROUTE_REGISTRATION >>>>`)
   - Generate clean diffs

5. **Add Post-Generation Validation:**
   - Auto-run `flutter analyze` after generation
   - Fail fast on generation errors

6. **api_gen_spec Full Chain:**
   - Extend `api_gen_spec` Mason brick post_gen.dart to not just generate DTO+API+barrel
   - Also generate or suggest: domain model, repository implementation skeleton, Hive adapter registration
   - The post_gen hook should read the JSON spec and produce a complete chain from API → DTO → Repository → Cache → Hive
   - Document the complete chain generation pattern

7. **hiveTypeId Safety:**
   - The current post_gen.dart defaults hiveTypeId to 0 when not specified, risking adapter conflicts
   - Fix: read `register.yaml` to auto-assign the next available TypeId
   - Or validate that the specified TypeId doesn't conflict with existing registrations
   - Add validation step to fail generation on conflict (no silent default 0)

### Acceptance Criteria

- [ ] `make create-feature name=xxx` produces fully registered feature (routes + DI)
- [ ] No manual steps required after generation
- [ ] Generation uses marker comments, produces clean diffs
- [ ] Post-generation analyze runs and reports failures
- [ ] api_gen_spec generates repository impl skeleton + Hive registration hints
- [ ] hiveTypeId auto-assigned or validated for conflicts (no silent default 0)
- [ ] Generated code compiles without manual fixes
- [ ] All tests pass

---

## Phase 5: Quality Foundation

**Duration:** 2-3 days  
**Priority:** Medium  
**Packages Modified:** services/data_sync, domain, infrastructure/component_library, lib/core

### Goal

Implement minimum viable versions of incomplete systems identified in audit: DataSync, DomainException, RequestContext, and Component Library tokens.

### Current State

- **DataSync:** Package exists but empty; no `DataSyncable` implementations
- **DomainException:** Single sealed class; lacks specific subtypes (Network, Auth, Validation)
- **RequestContext:** Uses global static; should be page-scoped
- **Component Library:** Uses literal values; needs design tokens

### Changes

1. **DataSync Minimal Closure:**
   - Create `UserProfileSyncable` implementing `DataSyncable`
   - Implement at least one `sync()` method that actually transfers data
   - Document pattern for adding more syncables

2. **DomainException Classification:**
   - Create subtype hierarchy: `NetworkException`, `AuthException`, `ValidationException`
   - Map API error codes to appropriate exceptions
   - Update repositories to return typed exceptions

3. **RequestContext Improvement:**
   - Replace global static approach with page-scoped context
   - Use `Provider` or ScopedLocator pattern
   - Ensure request ID propagates through async calls

4. **Component Library Design Tokens:**
   - Define `ColorToken`, `SpacingToken`, `TypographyToken` enums/classes
   - Create Button state matrix (default, pressed, disabled, loading)
   - Update components to use tokens instead of literals
   - Document token usage in README

5. **Storage Layer Cleanup:**
   - `SharedPreferenceStorage` in key_value_storage package overlaps with `KeyValueStorage`
   - Clarify responsibility: `KeyValueStorage` is the generic Hive-backed store
   - `SharedPreferenceStorage` should be deprecated or clearly documented as a convenience wrapper
   - Add migration guide for new features: prefer KeyValueStorage over SharedPreferenceStorage
   - Document the difference in package README

6. **Launcher Modularity:**
   - The `launcher.dart` currently handles 4 stages (core init → Sentry → auth → UI) in a single class
   - As startup responsibilities grow, this becomes a "god object"
   - Add a modular initializer pattern: each startup stage registers as an `AppInitializer` with priority
   - Launcher iterates through registered initializers
   - Document the pattern so future additions don't bloat a single file
   - New initializers should implement `AppInitializer` interface with `initialize()` method and priority

### Acceptance Criteria

- [ ] At least one DataSyncable implementation exists and functions
- [ ] DomainException has Network, Auth, Validation subtypes
- [ ] RequestContext is page-scoped (not global static)
- [ ] Component library uses design tokens
- [ ] SharedPreferenceStorage documented as convenience wrapper (or deprecated)
- [ ] Launcher supports modular initializer registration pattern
- [ ] All tests pass

---

## Phase 6: Documentation & Testing

**Duration:** 2-3 days  
**Priority:** Medium  
**Packages Modified:** lib/, docs/, packages/features/*

### Goal

Clean up documentation drift, upgrade test assertions from smoke to behavioral, and create a working "add a feature" walkthrough.

### Current State

- **Documentation Drift:** README shows old mixin API patterns; current implementation differs
- **Test Assertions Weak:** Tests use `isA<XState>()` smoke tests, not behavioral assertions
- **Walkthrough Broken:** DEVELOPMENT_GUIDE describes process that doesn't match current workflow
- **No End-to-End Walkthrough:** No single document walks through adding a new feature

### Changes

1. **Clean Up README:**
   - Remove references to deprecated mixin API
   - Update code examples to match current implementation
   - Fix any inconsistencies between documented and actual patterns
   - Also remove references to "架构评分 9.0/10" (already fixed in Phase 0, but verify no remnants remain)

2. **Upgrade Test Assertions:**
   - Replace `isA<XState>()` with behavioral assertions
   - Test actual state transitions, not just state type
   - Example: verify `emit(...)` called with specific values, not just correct type
   - api_gen_spec generated tests should also be behavioral (not just type checks)
   - Generated tests should verify actual state field values and API response handling

3. **Sync DEVELOPMENT_GUIDE:**
   - Update to reflect current Retrofit/Mason workflow
   - Remove obsolete references
   - Document current commands and their effects

4. **Add End-to-End Walkthrough:**
   - Create "Add a Feature" guide in docs/
   - Walk through: `make create-feature` → verify auto-registration → add simple UI element → run app
   - Include screenshots or command output
   - Verify walkthrough actually works

### Acceptance Criteria

- [ ] README code examples match current implementation
- [ ] At least 50% of feature-level tests (home_cubit_test, detail_cubit_test, login_cubit_test, and any generated feature tests) use behavioral assertions that verify specific state field values, not just state type via `isA<>()`
- [ ] DEVELOPMENT_GUIDE reflects current workflow
- [ ] New "Add a Feature" walkthrough exists and works
- [ ] All tests pass

---

## Risk Matrix

| Risk | Phase | Likelihood | Impact | Mitigation |
|------|-------|------------|--------|------------|
| Template changes break existing features | P1, P4 | Medium | High | Test each generated feature after changes; maintain backward compatibility in templates |
| RouteModuleRegistry introduces routing bugs | P1 | Low | High | Extensive UI testing; fallback to manual routes if issues arise |
| Type changes cascade through many files | P2 | High | Medium | Incremental changes; test after each file; use LSP refactor |
| DI changes break existing feature behavior | P3 | Medium | Medium | Phase 3 modifies feature_home and feature_detail; verify all existing tests pass before proceeding |
| API generation changes produce uncompilable code | P4 | Medium | High | Post-generation validation runs analyze; fail fast on errors |
| DataSync implementation reveals larger scope | P5 | Medium | Medium | Scope to minimum viable; document future enhancements |
| Documentation changes conflict with reality | P6 | Low | Low | Version control; cross-reference with actual code before committing |

---

## Summary

This seven-phase transformation addresses the 1.2-point gap between the scaffold's design intent (8.8/10) and actual implementation consistency (7.8/10). By following the non-negotiable principles of independent verifiability, limited blast radius, and no regressions, the team can methodically elevate the codebase to 9.0/10.

**Total Estimated Duration:** 18-28 days  
**Critical Path:** P0 → P1 → P2/P3 → P4 → P6  
**Parallel Opportunities:** P3 and P5 can partially overlap

---

## Appendix: Key Architecture Decisions

The following decisions were made prior to this spec and are considered constraints:

1. **RouteModuleRegistry:** Self-registration pattern chosen over pushing assembly back to routing package
2. **scaffolding-feature:** Implemented as Make target wrapping Mason; generates model + feature + registration
3. **feature_auth:** Retained as demo module post-unification; not removed
4. **Routing Package Scope:** "Primitives only" - contains GoRouter setup, not app-specific route definitions
