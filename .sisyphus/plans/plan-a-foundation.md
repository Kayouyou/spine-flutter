# Plan A: Foundation (Phase 0 + Phase 1)

**Covers:** Phase 0 (Stop Bleeding) + Phase 1 (Architecture Alignment)
**Duration:** 4-7 days
**Pre-condition:** Spec v2.0 approved, all existing tests pass
**Post-condition:** Root app in CI, auth unified, brick aligned, routes auto-registering

---

## Task List

### Phase 0: Stop the Bleeding (4 tasks)

- [ ] **T0.1 Fix errorCode.name runtime bug**
  - Goal: Replace `.name` access on String errorCode with direct interpolation
  - Files: `packages/features/feature_home/lib/src/ui/home_page.dart`, `packages/features/feature_detail/lib/src/ui/detail_page.dart`
  - Changes: 
    - home_page.dart:121 change `_buildError(BuildContext context, errorCode)` implicit dynamic → `String errorCode`
    - home_page.dart:133 change `${errorCode.name}` → `${errorCode}`
    - detail_page.dart:85 change `_buildError(BuildContext context, errorCode)` implicit dynamic → `String errorCode`
    - detail_page.dart:92 change `${errorCode.name}` → `${errorCode}`
  - Verify: `melos run analyze` passes, run app and trigger error state — see actual error message not "null"
  - Rollback: `git checkout -- packages/features/feature_home/lib/src/ui/home_page.dart packages/features/feature_detail/lib/src/ui/detail_page.dart`

- [ ] **T0.2 Fix DetailPage build() repeated loadData**
  - Goal: Remove addPostFrameCallback from build() and use LifecycleMixin instead
  - Files: `packages/features/feature_detail/lib/src/ui/detail_page.dart`
  - Changes:
    - Remove lines 18-21 (WidgetsBinding.instance.addPostFrameCallback block)
    - Change DetailPage from StatelessWidget to StatefulWidget
    - Add `with LifecycleMixin<DetailPage>`
    - Add `@override void onPageEnter()` that calls `context.read<DetailCubit>().loadData(id!)`
  - Verify: Navigate to detail page multiple times — data loads once per navigation, not on rebuild
  - Depends on: T0.1 (same file)
  - Rollback: `git checkout -- packages/features/feature_detail/lib/src/ui/detail_page.dart`

- [ ] **T0.3 Add root app to melos.yaml + CI**
  - Goal: Include root app (lib/) in test coverage
  - Files: `melos.yaml`, `.github/workflows/ci.yml`
  - Changes:
    - melos.yaml: Add `lib/` to packages list (below packages/features/*)
    - ci.yml: Modify test job to include root app test — change `melos test` to run both `melos exec -- flutter test` AND `cd lib && flutter test` (or add root test step)
  - Verify: `melos test` includes lib/ output, CI test job runs root app tests
  - Rollback: `git checkout -- melos.yaml .github/workflows/ci.yml`

- [ ] **T0.4 Update README architecture rating**
  - Goal: Correct documentation to reflect actual 7.8/10
  - Files: `README.md`
  - Changes: 
    - Line with "当前架构评分：**9.0/10**" → "**7.8/10**"
    - Add audit findings summary (see spec section "Current State Assessment" gap table)
  - Verify: README shows 7.8/10, search for "9.0" returns no results
  - Rollback: `git checkout -- README.md`

---

### Phase 1: Architecture Alignment (6-7 tasks)

- [ ] **T1.1 Unify Auth DI: Remove BlocProvider from LoginPage**
  - Goal: LoginPage uses DI-injected LoginCubit instead of self-creating one
  - Files: `packages/features/feature_auth/lib/src/ui/login_page.dart`
  - Changes: 
    - Delete lines 16-19 (BlocProvider wrapping LoginPageView)
    - Delete line 7 (`import '../repository/mock_auth_repository.dart';`)
    - LoginPage becomes: `return LoginPageView(redirect: redirect);` (relies on ancestor BlocProvider)
    - Ensure route registration provides LoginCubit via BlocProvider
  - Verify: `cd packages/features/feature_auth && flutter test`; login route still navigable
  - Depends on: T0.3 (CI setup)
  - Rollback: `git checkout -- packages/features/feature_auth/lib/src/ui/login_page.dart`

- [ ] **T1.2 Unify Auth DI: Remove BlocProvider from RegisterPage**
  - Goal: RegisterPage uses DI-injected LoginCubit instead of self-creating one
  - Files: `packages/features/feature_auth/lib/src/ui/register_page.dart`
  - Changes:
    - Delete lines 16-19 (BlocProvider wrapping RegisterPageView)
    - Delete line 7 (`import '../repository/mock_auth_repository.dart';`)
    - RegisterPage becomes: `return RegisterPageView(redirect: redirect);`
  - Verify: `cd packages/features/feature_auth && flutter test`; register route still navigable
  - Depends on: T1.1
  - Rollback: `git checkout -- packages/features/feature_auth/lib/src/ui/register_page.dart`

- [ ] **T1.3 Unify Auth DI: Wire LoginCubit to real AuthRepository in setup**
  - Goal: setupFeatureAuth registers LoginCubit with injected AuthRepository (not MockAuthRepository)
  - Files: `packages/features/feature_auth/lib/src/di/setup.dart`
  - Changes:
    - Check if real `AuthRepository` interface exists in domain (should use that instead of MockAuthRepository)
    - Update setup to: `sl.registerFactory<LoginCubit>(() => LoginCubit(sl<AuthRepository>()));`
    - Remove or deprecate MockAuthRepository usage (keep for demo fallback if needed)
  - Verify: LoginCubit test passes with real repository injection
  - Depends on: T1.2
  - Rollback: `git checkout -- packages/features/feature_auth/lib/src/di/setup.dart`

- [ ] **T1.4 Rewrite Feature Brick: Delete repository interface template**
  - Goal: Remove {{name}}_repository.dart template (interface belongs in domain)
  - Files: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart`
  - Changes: Delete the entire template file
  - Documentation: Update brick README to note "repository interfaces are defined in domain package"
  - Verify: Generate new feature with mason and verify no repository.dart file created
  - Depends on: T1.3 (DI pattern established)
  - Rollback: `git checkout -- bricks/feature/__brick__/lib/src/repository/{{name}}_repository.dart`

- [ ] **T1.5 Rewrite Feature Brick: Fix repository_impl imports**
  - Goal: Update {{name}}_repository_impl.dart to import domain interface
  - Files: `bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart`
  - Changes:
    - Change import `'{{name}}_repository.dart'` → domain package import (e.g., `package:domain/domain.dart`)
    - Assume domain has `{{name.pascalCase()}}Repository` interface pre-defined
    - Add import for api package to use `toDomainException()` conversion
  - Verify: Generated feature compiles (mock run: `mason make feature --name test_feature --dry-run`)
  - Depends on: T1.4
  - Rollback: `git checkout -- bricks/feature/__brick__/lib/src/repository/{{name}}_repository_impl.dart`

- [ ] **T1.6 Create RouteModuleRegistry in routing package**
  - Goal: Define registry interface for feature route self-registration
  - Files: `packages/infrastructure/routing/lib/src/routes/` (new file or extend existing)
  - Changes:
    - Create `route_module_registry.dart` with `abstract class RouteModuleRegistry`
    - Define `void register(String featureName, RouteModule module)` method
    - Create singleton implementation `RouteModuleRegistryImpl`
  - Verify: Registry compiles, new feature can import and use it
  - Depends on: T1.5 (brick generates compatible code)
  - Rollback: `git checkout -- packages/infrastructure/routing/lib/src/routes/`

- [ ] **T1.7 Update feature DI setups to register routes via registry**
  - Goal: Features auto-register routes in their setupFeatureXxx()
  - Files: `packages/features/feature_home/lib/src/di/setup.dart`, `packages/features/feature_detail/lib/src/di/setup.dart`, any other feature setups
  - Changes:
    - Each feature's setup.dart calls `registry.register('feature_name', SomeRouteModule(ctx))`
    - Remove manual route assembly from app.dart (or update to traverse registry)
  - Verify: Routes work after full app rebuild, no duplicate routes
  - Depends on: T1.6
  - Rollback: `git checkout -- packages/features/*/lib/src/di/setup.dart`

- [ ] **T1.DD Design Decision: Document DI discipline pattern**
  - Goal: Establish that features use constructor injection, never GetIt.instance directly
  - Files: `docs/superpowers/specs/2026-05-10-scaffold-transformation-design.md` (or separate design doc)
  - Changes: Add section documenting: "All feature dependencies must flow through constructor injection or BlocProvider. App-level concerns (Alice debug panel, Upgrader update check) belong in app layer, not features."
  - Note: Actual code cleanup for existing features happens in Phase 3
  - Verify: Document exists and is linked from README or architecture docs
  - Depends on: None (pure documentation)
  - Rollback: Revert documentation changes

---

## Dependency Graph

```
Phase 0 (Stop Bleeding)
├─ T0.1 (errorCode.name fix) ──────┐
├─ T0.2 (DetailPage build fix)    ├──► Phase 1 starts after all T0 complete
├─ T0.3 (root app in CI)          │
└─ T0.4 (README fix)              │    Phase 1 (Architecture Alignment)
                                    ├──► T1.1 (LoginPage DI) ──┐
                                    ├──► T1.2 (RegisterPage DI)│
                                    ├──► T1.3 (setup wired)   ├──► T1.4 → T1.5 → T1.6 → T1.7
                                    ├──► T1.4 (brick: delete)  │
                                    ├──► T1.5 (brick: impl)   │
                                    ├──► T1.6 (registry)      │
                                    ├──► T1.7 (auto-register) │
                                    └──► T1.DD (docs only)

Legend: ──► = depends on
```

---

## Verification Checklist

Run these commands in order after completing all tasks:

```bash
# Phase 0 verification
melos run analyze              # Must pass with no errors
melos run test                 # Must pass all tests
grep -r "errorCode.name" --include="*.dart"  # Should return nothing
grep -r "addPostFrameCallback" packages/features/feature_detail/  # Should return nothing related to loadData
grep -r "Architecture Rating.*9.0" README.md  # Should return nothing

# Phase 1 verification
flutter test packages/features/feature_auth/  # Auth tests pass
mason make feature --name test_verify --dry-run  # Verify brick outputs correct files
# Manually verify routes auto-register in a running app
```

---

## Timeline (4-7 days)

| Day | Focus | Tasks |
|-----|-------|-------|
| 1 | Critical bugs | T0.1, T0.2 |
| 2 | Infrastructure | T0.3, T0.4 |
| 3-4 | Auth DI | T1.1, T1.2, T1.3 |
| 5 | Brick alignment | T1.4, T1.5 |
| 6 | Routing registry | T1.6, T1.7 |
| 7 | Documentation | T1.DD, final verification |

---

## Rollback Strategy

All tasks have single-command rollback via `git checkout`. If any task introduces regression:
1. Run rollback command immediately
2. Re-run verification for that task
3. Investigate before retrying

If broader rollback needed (multiple tasks):
- Phase 0 issues → restart Phase 0
- Phase 1 issues → restart from T1.1

---

## Pre-Implementation Notes

1. **Test baseline**: Run `melos run validate` before starting to confirm clean state
2. **Incremental verify**: Each task's verification must pass before moving to next
3. **Document decisions**: T1.DD should happen in parallel with implementation tasks
4. **Feature brick test**: After T1.5, generate a test feature and verify it compiles before proceeding to T1.6
