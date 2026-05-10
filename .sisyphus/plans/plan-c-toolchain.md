# Plan C: Toolchain (Phase 4 + Phase 5)

**Covers:** Phase 4 (Generation Pipeline) + Phase 5 (Quality Foundation)
**Duration:** 5-8 days
**Pre-condition:** Plan A complete, Phase 1-3 work complete (or Plan B/C covering them)
**Post-condition:** Fully automated feature creation, quality foundations in place

---

## Task List

### Phase 4: Generation Pipeline (7 tasks)

- [ ] **T4.1 Auto-register routes: Feature calls RouteModuleRegistry in DI setup**
  - Goal: New feature automatically registers its routes via registry call in di/setup.dart
  - Files: `bricks/feature/__brick__/lib/src/di/setup.dart`, generated features
  - Changes:
    - Modify feature brick template to call `RouteModuleRegistry.instance.register(...)` in generated setup
    - Register function signature: `register(String featureName, RouteModule module)`
    - Feature name derived from brick variable `{{name}}`
  - Verify: Generate test feature, check its setup.dart contains registry.register call
  - Depends on: T1.6 (RouteModuleRegistry exists from Plan A)
  - Rollback: `git checkout -- bricks/feature/__brick__/`

- [ ] **T4.2 Auto-register DI: Setup functions auto-imported via barrel file**
  - Goal: Feature setup functions auto-discovered and called in root setup.dart
  - Files: `lib/core/di/setup.dart`, `packages/features/*/lib/feature_*.dart`
  - Changes:
    - Create or update barrel export in each feature package that exports di/setup.dart
    - Root setup.dart uses package introspection or convention to discover all setupFeatureXxx functions
    - Alternative: Standardized naming `setupFeature<PascalName>(sl)` enables simple grep-based discovery
  - Verify: Add new feature, run app — DI automatically registers new feature's services
  - Depends on: T4.1
  - Rollback: `git checkout -- lib/core/di/setup.dart`

- [ ] **T4.3 Auto-add pubspec: Script adds path dependency to root pubspec.yaml**
  - Goal: Post-generation script automatically adds feature package to root pubspec.yaml
  - Files: `makefile` (create-feature target), `scripts/`, `pubspec.yaml`
  - Changes:
    - Modify `create-feature` make target to append path dependency to pubspec.yaml
    - Use marker comments for structured insertion: `# <<<< FEATURE_DEPENDENCIES >>>>`
    - Format: `feature_xxx:\n    path: packages/features/feature_xxx`
  - Verify: Run `make create-feature name=test_auto_dep`, check pubspec.yaml contains new entry
  - Depends on: None
  - Rollback: `git checkout -- pubspec.yaml`

- [ ] **T4.4 Replace awk/text-append with marker-comment structured insertion**
  - Goal: All generation scripts use structured insertion with marker comments
  - Files: `makefile`, `scripts/*.sh`, `scripts/*.dart`
  - Changes:
    - Audit all scripts for fragile awk/append patterns
    - Add marker comments: `# <<<< MARKER_NAME >>>>` and `# >>>>> MARKER_NAME`
    - Rewrite insertion logic to use text between markers
    - Produces clean, reviewable git diffs
  - Verify: Generate multiple features, check git diff is readable and reversible
  - Depends on: T4.3
  - Rollback: `git checkout -- makefile scripts/`

- [ ] **T4.5 Add post-generation validation (auto-run analyze)**
  - Goal: After code generation, automatically run flutter analyze to catch errors
  - Files: `makefile`, `bricks/feature/`
  - Changes:
    - Add `flutter analyze` step to `create-feature` make target
    - Fail fast if analyze reports errors (exit non-zero)
    - Optionally add in brick's post_gen.dart hook
  - Verify: Create feature with intentional syntax error — generation should fail with analyze output
  - Depends on: T4.4
  - Rollback: `git checkout -- makefile bricks/feature/`

- [ ] **T4.6 api_gen_spec full chain: Extend post_gen to generate repository impl skeleton + Hive hints**
  - Goal: api_gen_spec brick generates complete chain from API to storage
  - Files: `bricks/api_gen_spec/`, `packages/infrastructure/api/spec/*.json`
  - Changes:
    - Extend brick's post_gen.dart to read JSON spec and generate:
      - Repository implementation skeleton (imports domain interface, calls API, returns typed result)
      - Hive adapter registration hints (typeId reference to register.yaml)
      - Barrel file updates
    - Generate code that compiles with minimal manual intervention
  - Verify: Run `make gen-api-mason spec=user.json`, check output includes repository impl file
  - Depends on: None (independent of other T4 tasks)
  - Rollback: `git checkout -- bricks/api_gen_spec/`

- [ ] **T4.7 hiveTypeId safety: Auto-assign from register.yaml, validate no conflicts**
  - Goal: Prevent silent TypeId conflicts in Hive adapter registration
  - Files: `packages/infrastructure/key_value_storage/`, `bricks/api_gen_spec/`, `bricks/hive_model/`
  - Changes:
    - Create script to read register.yaml and find next available TypeId
    - Or validate that specified TypeId doesn't conflict with existing registrations
    - Update post_gen.dart to fail on conflict (no silent default to 0)
    - Document required TypeId assignment workflow for new Hive models
  - Verify: Attempt to create hive model with duplicate TypeId — should fail with clear error
  - Depends on: None (independent)
  - Rollback: `git checkout -- packages/infrastructure/key_value_storage/ bricks/`

---

### Phase 5: Quality Foundation (6 tasks)

- [ ] **T5.1 DataSync minimal closure: Create UserProfileSyncable**
  - Goal: Implement at least one working DataSyncable to prove the pattern works
  - Files: `packages/services/data_sync/lib/src/`, `packages/domain/lib/src/models/`
  - Changes:
    - Create `UserProfileSyncable` class implementing `DataSyncable` interface
    - Implement `sync()` method that transfers data (e.g., local profile → API)
    - Document the pattern for adding more syncables in code comments
  - Verify: Call sync operation, verify data transfers correctly
  - Depends on: None (Phase 5 can run independently)
  - Rollback: `git checkout -- packages/services/data_sync/`

- [ ] **T5.2 DomainException classification: Create NetworkException, AuthException, ValidationException**
  - Goal: Replace generic DomainException with typed exception hierarchy
  - Files: `packages/domain/lib/src/exceptions/`
  - Changes:
    - Create `NetworkException` (timeout, no connection, server error)
    - Create `AuthException` (unauthorized, token expired, forbidden)
    - Create `ValidationException` (invalid input, business rule violation)
    - Update API layer to map DioException → appropriate DomainException subtype
  - Verify: Trigger each exception type, verify correct type propagates
  - Depends on: None
  - Rollback: `git checkout -- packages/domain/lib/src/exceptions/`

- [ ] **T5.3 RequestContext improvement: Replace global static with page-scoped**
  - Goal: RequestContext is no longer a global static, but scoped to navigation/page
  - Files: `packages/infrastructure/api/lib/src/`, `packages/infrastructure/routing/lib/src/`
  - Changes:
    - Replace static RequestContext with Provider or ScopedLocator pattern
    - Request ID propagates through async calls via context injection
    - Each page/request gets isolated context
  - Verify: Multiple concurrent requests don't share context IDs
  - Depends on: None
  - Rollback: `git checkout -- packages/infrastructure/api/lib/src/`

- [ ] **T5.4 Component library design tokens: Define ColorToken, SpacingToken, TypographyToken**
  - Goal: Replace literal values with design tokens throughout component library
  - Files: `packages/infrastructure/component_library/lib/src/`
  - Changes:
    - Create `ColorToken` enum or class with all app colors
    - Create `SpacingToken` enum for consistent spacing (xs, sm, md, lg, xl)
    - Create `TypographyToken` for text styles
    - Update Button component to use tokens (default/pressed/disabled/loading states)
    - Document token usage in package README
  - Verify: Components render correctly with token values, search for literal color values in components returns nothing
  - Depends on: None
  - Rollback: `git checkout -- packages/infrastructure/component_library/`

- [ ] **T5.5 Storage layer cleanup: Document SharedPreferenceStorage vs KeyValueStorage**
  - Goal: Clarify storage responsibilities, reduce confusion between overlapping abstractions
  - Files: `packages/infrastructure/key_value_storage/README.md`, `packages/infrastructure/component_library/` (if SharedPreferenceStorage exists)
  - Changes:
    - Document that `KeyValueStorage` is the primary generic Hive-backed store
    - Document that `SharedPreferenceStorage` (if exists) is a convenience wrapper for simple key-value needs
    - Add migration guide: "For new features, prefer KeyValueStorage"
    - Mark SharedPreferenceStorage as deprecated if redundant
  - Verify: Documentation clearly explains when to use which storage
  - Depends on: None
  - Rollback: `git checkout -- packages/infrastructure/key_value_storage/README.md`

- [ ] **T5.6 Launcher modularity: Implement AppInitializer pattern**
  - Goal: Break launcher.dart into modular initializers with priority ordering
  - Files: `lib/core/startup/`, `lib/core/launcher.dart`
  - Changes:
    - Create `AppInitializer` abstract class with `initialize()` method and `priority` field
    - Convert existing initialization stages to initializers:
      - CoreInitInitializer (priority: 100)
      - SentryInitializer (priority: 90)
      - AuthInitializer (priority: 80)
      - UIInitializer (priority: 10)
    - Launcher iterates registered initializers in priority order
    - Document pattern for adding future initializers
  - Verify: App starts correctly, initializers run in priority order
  - Depends on: None
  - Rollback: `git checkout -- lib/core/startup/ lib/core/launcher.dart`

---

## Dependency Graph

```
Phase 4 (Generation Pipeline)
├── T4.1 (auto-register routes) ────────────┐
├── T4.2 (auto-register DI) ──► T4.1        │
├── T4.3 (auto-add pubspec)                  │
├── T4.4 (marker comments) ──► T4.3          │
├── T4.5 (post-gen validate) ──► T4.4        │
├── T4.6 (api_gen_spec chain) (independent)  │
└── T4.7 (hiveTypeId safety) (independent)   │

Phase 5 (Quality Foundation)
├── T5.1 (DataSync) ────────────────────────┤
├── T5.2 (DomainException)                   │
├── T5.3 (RequestContext)                    │
├── T5.4 (Design Tokens)                     │
├── T5.5 (Storage Docs)                      │
└── T5.6 (App Initializer)                   │
    (all T5 tasks independent of each other)
```

---

## Verification Checklist

Run these commands in order after completing all tasks:

```bash
# Phase 4 verification
make create-feature name=verify_chain      # Full feature creation
git diff --stat                            # Check reasonable file counts
melos run analyze                          # Post-gen analyze passes
grep -r "<<<<<<" makefile scripts/         # Verify marker comments exist

# Check api_gen_spec chain
make gen-api-mason spec=user.json 2>&1 | head -20
ls packages/infrastructure/api/lib/src/user/  # Verify output includes impl

# Check hiveTypeId safety
make create-hive-model name=TestDuplicate typeId=0 2>&1  # Should warn/error

# Phase 5 verification
flutter test packages/services/data_sync/   # DataSync tests
grep -r "NetworkException\|AuthException\|ValidationException" packages/domain/  # Verify subtypes exist
grep -r "static.*RequestContext" packages/infrastructure/api/  # Should return nothing
grep -r "ColorToken\|SpacingToken" packages/infrastructure/component_library/  # Verify tokens used
cat packages/infrastructure/key_value_storage/README.md | grep -A5 "SharedPreferenceStorage"  # Verify docs

# Final
melos run test                              # All tests pass
```

---

## Timeline (5-8 days)

| Day | Focus | Tasks |
|-----|-------|-------|
| 1 | Auto-registration | T4.1, T4.2 |
| 2 | Pubspec + markers | T4.3, T4.4 |
| 3 | Validation + api_gen | T4.5, T4.6 |
| 4 | Hive safety + Buffer | T4.7, T5.1 |
| 5-6 | Quality foundations | T5.2, T5.3, T5.4 |
| 7 | Docs + cleanup | T5.5, T5.6 |
| 8 | Final verification | All tests, full pipeline test |

---

## Rollback Strategy

All tasks have single-command rollback via `git checkout`. If any task introduces regression:

1. Run rollback command immediately
2. Re-run verification for that task
3. Investigate before retrying

If broader rollback needed (multiple tasks):
- Phase 4 issues → restart from T4.1
- Phase 5 issues → restart from T5.1

---

## Pre-Implementation Notes

1. **Test baseline**: Run `melos run validate` before starting to confirm clean state
2. **Independent T5**: Phase 5 tasks can run in parallel (all independent)
3. **T4.6/T4.7 independence**: These tasks can start immediately, don't wait for other T4
4. **Marker comment format**:
  ```dart
  // <<<< ROUTE_REGISTRATION >>>>
  // ... generated code ...
  // >>>> ROUTE_REGISTRATION
  ```
5. **Design tokens**: Start with existing literal values in component library, convert to enum
6. **AppInitializer priority**: 100=highest (core), 10=lowest (UI)

