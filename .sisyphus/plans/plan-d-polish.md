# Plan D: Polish (Phase 6)

**Covers:** Phase 6 (Documentation & Testing)
**Duration:** 2-3 days
**Pre-condition:** All Phase 0-5 tasks completed and verified
**Post-condition:** Documentation aligned, test assertions upgraded, working walkthrough exists

---

## Task List

### Phase 6: Documentation & Testing (8 tasks)

- [ ] **T6.1 Clean up README: remove deprecated mixin API references**
  - Goal: Update README to match current implementation patterns
  - Files: `README.md`
  - Changes:
    - Review README sections for outdated patterns
    - Remove references to deprecated mixin API (if any exist in documentation)
    - Update code examples to match current Cubit/Repository patterns
    - Verify any example code snippets compile correctly
  - Verify: README code examples match actual implementation in codebase
  - Depends on: None (documentation-only)
  - Rollback: `git checkout -- README.md`

- [ ] **T6.2 Verify no remaining "9.0/10" architecture rating references**
  - Goal: Confirm Phase 0 fix is complete, no remnants exist
  - Files: `README.md`, any docs files
  - Changes:
    - Search entire codebase for "9.0/10" or "架构评分 9.0"
    - Verify README shows corrected 7.8/10 rating
    - Check docs/ directory for any similar references
  - Verify: `grep -r "9.0/10" --include="*.md"` returns no results
  - Depends on: None (verification task)
  - Rollback: N/A (verification only)

- [ ] **T6.3 Upgrade home_cubit_test: replace isA<>() with behavioral assertions**
  - Goal: Replace type-only assertions with state field value assertions
  - Files: `packages/features/feature_home/test/cubit/home_cubit_test.dart`
  - Changes:
    - Review current test assertions using `isA<HomeState>()` 
    - Replace with behavioral assertions that verify:
      - Specific state field values (e.g., `expect(state.data, equals(expectedData))`)
      - Status enum values (e.g., `expect(state.status, equals(HomeStatus.loaded))`)
      - Error message content when in error state
    - Test actual state transitions, not just final state type
  - Verify: Tests pass with new assertions, coverage maintained or improved
  - Depends on: T6.2
  - Rollback: `git checkout -- packages/features/feature_home/test/cubit/home_cubit_test.dart`

- [ ] **T6.4 Upgrade detail_cubit_test: replace isA<>() with behavioral assertions**
  - Goal: Replace type-only assertions with state field value assertions
  - Files: `packages/features/feature_detail/test/cubit/detail_cubit_test.dart`
  - Changes:
    - Same pattern as T6.3 for DetailCubit states
    - Verify state.data field values match expected
    - Verify loading/error/loaded status transitions
  - Verify: Tests pass with new assertions
  - Depends on: T6.3
  - Rollback: `git checkout -- packages/features/feature_detail/test/cubit/detail_cubit_test.dart`

- [ ] **T6.5 Upgrade login_cubit_test: replace isA<>() with behavioral assertions**
  - Goal: Replace type-only assertions with state field value assertions
  - Files: `packages/features/feature_auth/test/cubit/login_cubit_test.dart`
  - Changes:
    - Same pattern as T6.3/T6.4 for LoginCubit states
    - Verify authentication state fields (e.g., token, user data)
    - Verify error states contain expected error information
  - Verify: Tests pass with new assertions
  - Depends on: T6.4
  - Rollback: `git checkout -- packages/features/feature_auth/test/cubit/login_cubit_test.dart`

- [ ] **T6.6 Sync DEVELOPMENT_GUIDE to current Retrofit/Mason workflow**
  - Goal: Update development guide to match actual workflow
  - Files: `DEVELOPMENT_GUIDE.md` (or similar doc in docs/)
  - Changes:
    - Review existing DEVELOPMENT_GUIDE content
    - Update commands to match current makefile targets
    - Remove obsolete workflow references
    - Document Retrofit API generation: `make gen-api-mason spec=xxx.json`
    - Document Mason feature creation: `make create-feature name=xxx`
  - Verify: DEVELOPMENT_GUIDE accurately describes current workflow commands
  - Depends on: T6.5
  - Rollback: `git checkout -- DEVELOPMENT_GUIDE.md`

- [ ] **T6.7 Create "Add a Feature" end-to-end walkthrough document**
  - Goal: Create working guide for adding new features
  - Files: New file in `docs/` (e.g., `docs/add-feature-walkthrough.md`)
  - Changes:
    - Create comprehensive walkthrough covering:
      1. Run `make create-feature name=feature_name`
      2. What files are generated
      3. How auto-registration works (routes + DI)
      4. Add simple UI element example
      5. Run app to verify
    - Include actual command output or screenshots
    - Document what happens under the hood (Mason → melos bs → build_runner)
  - Verify: Document created with all sections
  - Depends on: T6.6
  - Rollback: `git checkout -- docs/add-feature-walkthrough.md` (or delete if new file)

- [ ] **T6.8 Verify walkthrough works by following it exactly**
  - Goal: Ensure the walkthrough actually works end-to-end
  - Files: Test execution against T6.7 created document
  - Changes:
    - Follow the walkthrough exactly as written
    - Run `make create-feature name=test_walkthrough`
    - Verify generated feature compiles and runs
    - If any step fails, update the walkthrough document
  - Verify: New test feature created successfully following walkthrough
  - Depends on: T6.7
  - Rollback: Remove generated test_walkthrough feature and revert any walkthrough doc fixes

---

## Dependency Graph

```
Phase 6 (Documentation & Testing)
├─ T6.1 (README cleanup) ───────┐
├─ T6.2 (verify 9.0/10 removed)  ├──► Sequential verification
├─ T6.3 (home_cubit_test)        │
├─ T6.4 (detail_cubit_test)      │
├─ T6.5 (login_cubit_test)       ├──► Sequential upgrade path
├─ T6.6 (DEVELOPMENT_GUIDE sync) │
├─ T6.7 (create walkthrough)    │
└─ T6.8 (verify walkthrough)    ──► Final verification

Legend: ──► = depends on
```

---

## Verification Checklist

Run these commands in order after completing all tasks:

```bash
# Documentation verification
melos run analyze              # Must pass with no errors
grep -r "9.0/10" --include="*.md"  # Should return nothing
grep -r "架构评分.*9" --include="*.md"  # Should return nothing

# Test verification
melos run test                 # Must pass all tests
# Verify behavioral assertions are in place:
grep -r "isA<>" packages/features/*/test/  # Should return nothing (or minimal)
grep -r "expect(state\." packages/features/*/test/  # Should have many hits

# Walkthrough verification
ls -la docs/add-feature-walkthrough.md  # File exists
make create-feature name=test_verify_polish
cd packages/features/feature_test_verify_polish && flutter analyze  # Compiles
```

---

## Timeline (2-3 days)

| Day | Focus | Tasks |
|-----|-------|-------|
| 1 | Documentation cleanup | T6.1, T6.2 |
| 2 | Test assertions | T6.3, T6.4, T6.5 |
| 3 | Walkthrough creation | T6.6, T6.7, T6.8 |

---

## Rollback Strategy

All tasks have single-command rollback via `git checkout`. If any task introduces regression:

1. Run rollback command immediately
2. Re-run verification for that task
3. Investigate before retrying

If broader rollback needed:
- Test assertion issues → restart from T6.3
- Documentation issues → restart from T6.1

---

## Pre-Implementation Notes

1. **Test baseline**: Run `melos run validate` before starting to confirm clean state
2. **Incremental verify**: Each task's verification must pass before moving to next
3. **Acceptance criteria from spec**: At least 50% of feature-level tests should use behavioral assertions verifying specific state field values, not just state type via `isA<>()`
4. **Walkthrough verification**: T6.8 is critical — the walkthrough must actually work when followed exactly
