# token-refresh-modularization Specification

## Purpose
TBD - created by archiving change refactor-api-package. Update Purpose after archive.
## Requirements
### Requirement: Token refresh interceptor is split into 4 single-responsibility files

The 716-line `renewal_token_intercaptor.dart` SHALL be split into 4 files, each holding one cohesive responsibility. The split boundary is defined by the 8 sections already analyzed in this change's `design.md`.

#### Scenario: File split mapping
- **WHEN** the refactor completes
- **THEN** the source code is distributed as:
  - `lib/src/refresh/refresh_queue.dart` (≤120 lines) — holds `TokenRenewalState` enum (was line 57-69), `PendingRequest` class (was line 72-105), `_pendingRequests` set, `_addToPendingRequests`, `_drain` (the merged helper)
  - `lib/src/refresh/refresh_api.dart` (≤250 lines) — holds `_performTokenRenewal` (was line 399-457), `_processRenewalResponse` (was line 460-492), `_retryRequestWithRetry` (was line 603-620), `_retryRequest` (was line 623-658), `_executeRenewalRequest` (was line 674-699), `_configureProxy` (was line 702-715)
  - `lib/src/refresh/token_renewal_interceptor.dart` (≤220 lines, kept in same relative path `lib/src/dio/` to preserve imports) — holds the class shell (was line 107-153), `onResponse` (was line 185-301), `_handleRenewalResponse` (was line 304-396), `_shouldRenewToken` (was line 661-671)
  - The Mermaid documentation block (was line 13-54) is moved into `design.md` of this change as the canonical architecture diagram

#### Scenario: Class and method counts preserved
- **WHEN** the refactor completes
- **THEN**:
  - 1 `enum` (TokenRenewalState) exists (same as before)
  - 1 `class` extends `Interceptor` exists (TokenRenewalInterceptor, same as before)
  - 12 private methods existed before; after refactor, 3 private methods in interceptor + 6 private methods in RefreshApi + 1 private method in RefreshQueue = 10 total. The 2 methods merged into `_drain` (`_retryAllPendingRequests` + `_completeAllPendingRequestsWithOriginalResponse`) account for the reduction

#### Scenario: No new public API surface
- **WHEN** the refactor completes
- **THEN** `TokenRenewalInterceptor` constructor signature `(Dio, {TokenStorage?})` is unchanged
- **AND** `dio_factory.dart` line 51 `TokenRenewalInterceptor(dio, tokenStorage: tokenStorage)` continues to compile without modification

### Requirement: The two ~50-line boilerplate drain methods are merged into one parameterized helper

`_retryAllPendingRequests` (was line 495-551) and `_completeAllPendingRequestsWithOriginalResponse` (was line 555-600) SHALL be merged into a single `_drain(Future<void> Function(_PendingRequest) processor, {int batchSize, bool fireAndForget})` helper. The merge SHALL be **bytecode-equivalent** to the original two methods.

#### Scenario: Behavior preservation for success path
- **WHEN** token renewal succeeds and `_pendingRequests` contains N entries
- **THEN** `_drain(processor: _retryRequestWithRetry, batchSize: 5, fireAndForget: false)` produces the same Dio request sequence (HTTP method, URL, headers, all 14 `Options` fields per line 634-649) as the pre-refactor `_retryAllPendingRequests`

#### Scenario: Behavior preservation for failure path
- **WHEN** token renewal fails and `_pendingRequests` contains N entries
- **THEN** `_drain(processor: (p) => p.completer.complete(p.originalResponse), batchSize: 10, fireAndForget: true)` produces the same `Completer` completions as the pre-refactor `_completeAllPendingRequestsWithOriginalResponse`

#### Scenario: Batch sizes and delays preserved
- **WHEN** `_drain` processes a queue of 12 entries with `batchSize: 5`
- **THEN** it dispatches 3 batches (5 + 5 + 2), with 50ms `Future.delayed` between batch 1 and batch 2, and between batch 2 and batch 3, matching the original line 544 / 593 delay

#### Scenario: fire-and-forget semantics preserved
- **WHEN** `_drain` is called with `fireAndForget: true`
- **THEN** the returned `Future` is not awaited by the caller (matching original line 271 / 282 fire-and-forget pattern), and `Future.wait` inside `_drain` runs in the background

### Requirement: One byte-equivalent bug is fixed

The constant `String.fromEnvironment('ovsx-app-token')` at line 420 SHALL be replaced with `String.fromEnvironment('')` (or the explicit empty string), because the original name `ovsx-app-token` is a VSCode marketplace token name with no semantic relation to token renewal. The fix produces identical bytecode: when the environment variable is not set, both expressions resolve to the empty string `''` at compile time.

#### Scenario: Compile-time equivalence
- **WHEN** the dart compiler resolves `const String.fromEnvironment('ovsx-app-token')` and `const String.fromEnvironment('')` with no `--dart-define` flag set
- **THEN** both produce the identical constant `''`

#### Scenario: Runtime equivalence
- **WHEN** a request is sent through `_performTokenRenewal` after the fix
- **THEN** the `accessKeyId` header value is `''` (same as before the fix)

### Requirement: Five invariants are preserved as constraints

The refactor SHALL NOT change the following 5 invariants, each verifiable by reading the diff:

#### Scenario: batchSize asymmetry preserved
- **WHEN** inspecting the post-refactor source
- **THEN** the success-path call site passes `batchSize: 5` and the failure-path call site passes `batchSize: 10` (no unification)

#### Scenario: Timing constants preserved
- **WHEN** inspecting the post-refactor source
- **THEN** the following literals appear unchanged: 200ms (line 619 retry interval), 10s (line 313-319 Completer timeout), 50ms (line 544/593 batch delay), 5 seconds (line 253-256 success-reuse window)

#### Scenario: Set deduplication preserved
- **WHEN** inspecting the post-refactor source
- **THEN** `_PendingRequest` retains its custom `operator ==` (path + method + queryParameters + data) and `hashCode` overrides (no switch to a different data structure)

#### Scenario: Fire-and-forget preserved
- **WHEN** inspecting the post-refactor source
- **THEN** the failure-path drain call site uses bare `unawaited(_drain(...))` or an equivalent pattern that does not block the calling `Future`

#### Scenario: Dio injection preserved
- **WHEN** inspecting the post-refactor source
- **THEN** the renewal request uses `_dio.request(...)` (the constructor-injected Dio, not a fresh `Dio()` instance). The only fresh `Dio()` remains inside `_executeRenewalRequest` for proxy/header isolation

### Requirement: External observable behavior is preserved (4 verifications)

The refactor SHALL NOT change any externally observable behavior, verified by these 4 specific checks.

#### Scenario: Dio interceptor push order unchanged
- **WHEN** comparing `dio_factory.dart` pre- and post-refactor
- **THEN** the `interceptors.addAll([...])` order is byte-identical, and the constructed `TokenRenewalInterceptor` receives the same `tokenStorage` argument

#### Scenario: Renewal HTTP request identical
- **WHEN** capturing a token renewal request via a Dio mock or `HttpClient` interceptor
- **THEN** the URL, HTTP method, request headers (including `accessKeyId` and the 8 `HeaderInterceptor`-produced headers), and the 14 `Options` fields are byte-identical pre- and post-refactor

#### Scenario: Sentry error stack preserved
- **WHEN** triggering a renewal failure with `IErrorReporter` (Sentry) enabled
- **THEN** the captured stack trace's frames, line numbers, and `HttpEventBus.commit(EventKeys.logout)` invocation timing (line 470) are unchanged

#### Scenario: Queue and lock semantics preserved
- **WHEN** inspecting the post-refactor source
- **THEN** the number of `_renewalLock.synchronized` call sites is unchanged (1 site at the original line 232), and `Set<_PendingRequest>` ordering (timestamp-based sort at the original line 506 / 566) is preserved

### Requirement: At least 12 new unit tests are added

The refactor SHALL add unit tests for the 2 new files (`refresh_queue.dart` and `refresh_api.dart`), covering the testable pure functions.

#### Scenario: refresh_queue_test.dart coverage
- **WHEN** the test file is added
- **THEN** it contains at least 6 test cases covering:
  - `_PendingRequest.==` returns true for same path+method+params+data
  - `_PendingRequest.==` returns false for different paths
  - `_PendingRequest.hashCode` matches `==` contract
  - `_drain` with empty queue: no processor call, immediate completion
  - `_drain` with N=12 + `batchSize: 5`: 3 batches dispatched, 50ms delays observed
  - `_drain` with `fireAndForget: true`: caller `Future` resolves before processors complete

#### Scenario: refresh_api_test.dart coverage
- **WHEN** the test file is added
- **THEN** it contains at least 6 test cases covering:
  - `_shouldRenewToken` returns true when `code == HttpConstant.reTokenCode`
  - `_shouldRenewToken` returns false for other codes
  - `_shouldRenewToken` returns false for non-JSON or null data
  - `_retryRequest` rebuilds all 14 `Options` fields from the original `RequestOptions`
  - `_configureProxy` produces an `IOHttpClientAdapter` with `findProxy` callback that routes through the configured proxy host:port
  - `_executeRenewalRequest` accepts any HTTP status (via `validateStatus: (status) => true`)

#### Scenario: Existing tests unaffected
- **WHEN** running the 9 pre-existing tests in `token_renewal_interceptor_test.dart` + 3 in `auto_cancel_interceptor_test.dart` + 3 in `dio_factory_test.dart`
- **THEN** all 15 tests pass without modification (their import paths are unchanged because `TokenRenewalInterceptor` retains its `lib/src/dio/renewal_token_intercaptor.dart` path)

### Requirement: No new dependency is added

The refactor SHALL NOT add any new pubspec dependency. The existing dependencies `dio: ^5.2`, `synchronized: ^3.1`, `key_value_storage` (path), `crypto: ^3`, `uuid: ^4.5`, and the `package:event_bus` (if it remains used elsewhere) are sufficient.

#### Scenario: pubspec.yaml diff is empty
- **WHEN** inspecting the diff of `packages/infrastructure/api/pubspec.yaml`
- **THEN** the dependencies block is byte-identical, OR the only change is removing a dependency whose only consumer was a deleted file (e.g., `event_bus` if `http_event_bus.dart` was its only consumer)

