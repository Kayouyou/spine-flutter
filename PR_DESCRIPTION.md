## Summary

Fixes critical login token persistence bug where tokens were not being saved after successful login, causing AuthGuard to immediately redirect users back to /login.

## Problem

From SCAFFOLD_REVIEW.md P0-3 analysis:
- LoginCubit.login() success path was discarding LoginResult
- Token was never saved to TokenStorage
- AuthCubit state was never updated to loggedIn
- After login, AuthGuard would redirect back to /login, creating a login loop

## Solution

### Architecture Changes

**AuthManager.handleLoginSuccess()** - New method that coordinates token persistence:
- Saves token to TokenStorage
- Updates AuthCubit state to loggedIn
- Called by LoginCubit after successful login/register

**LoginCubit Integration** - Injects AuthManager dependency:
- login() and register() call handleLoginSuccess() on success
- Ensures token is persisted and auth state is updated

**AuthCubit Cleanup** - Removed dead code (P1-5):
- Removed login() and logout() methods (no production callers)
- Simplified constructor (no longer needs AuthRepository)
- Single source of truth: setAuthState()

### Data Flow (Before vs After)

**Before:**
```
User enters credentials → Login succeeds → Token discarded →
AuthCubit unchanged → AuthGuard redirects to /login → User stuck
```

**After:**
```
User enters credentials → Login succeeds →
AuthManager.handleLoginSuccess() →
Token saved + AuthCubit updated →
AuthGuard allows navigation → User reaches home page
```

## Changes

### Core Implementation
- `packages/services/auth/lib/src/manager.dart` - Added handleLoginSuccess()
- `packages/features/feature_auth/lib/src/cubit/login_cubit.dart` - Integrated AuthManager
- `packages/services/auth/lib/src/cubit/auth_cubit.dart` - Removed dead code

### Dependency Injection
- `packages/features/feature_auth/lib/src/di/setup.dart` - Updated DI config
- `packages/services/auth/lib/src/di/setup.dart` - Updated AuthCubit registration

### Tests
- Added 11 new test cases
- All 86 tests passing
- Pre-commit hook passes all checks

## Verification

- ✅ All 86 tests passing
- ✅ No new errors or warnings
- ✅ Pre-commit hook passes (R1/R3/R4 dependency checks, ARB consistency)
- ✅ Flutter analyze clean (only pre-existing warnings)
- ✅ No breaking changes

## Commits

1. `166a0d1` - feat(auth): add AuthManager.handleLoginSuccess for token persistence
2. `429d356` - feat(feature_auth): inject AuthManager into LoginCubit
3. `2627ceb` - feat(auth): integrate AuthManager with LoginCubit and clean up AuthCubit
4. `38959eb` - fix: remove unused import and update AuthCubit constructor
5. `8a3fe65` - docs: add P0-3 completion report

## Related Issues

- Fixes: P0-3 login token not persisted (from SCAFFOLD_REVIEW.md)
- Addresses: P1-5 AuthCubit.login/logout dead code (from SCAFFOLD_REVIEW.md)

## Documentation

- Design spec: `docs/superpowers/specs/2026-06-16-p0-3-login-token-persistence-design.md`
- Implementation plan: `docs/superpowers/plans/2026-06-16-p0-3-login-token-persistence.md`
- Completion report: `P0_3_COMPLETION_REPORT.md`

## Merge Strategy

Use **squash merge** to maintain linear history (per AGENTS.md §8.3).
