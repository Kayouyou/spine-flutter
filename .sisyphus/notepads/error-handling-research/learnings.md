# Error Handling Research - Learnings

## Research Date: 2026-05-06

## 1. Current Project State Assessment

### Active Code Path (working):
```
Repository (catch DioException)
  → DioExceptionMapper.toDomainException()    [extension on DioException]
  → throws DomainException (sealed)
```

### Dead Code (zero calls):
```
ErrorHandler.handleError()       → HttpsException
HttpsExceptionExtension.toDomainException()  → DomainException
NeedLogin, NeedAuth classes
```

### DomainException Hierarchy (current):
- `DomainException` (sealed base)
  - `NetworkException` (network, timeout, 5xx — with statusCode)
  - `UnauthorizedException` (401, tokenExpired)
  - `NotFoundException` (404)
  - `ValidationException` (invalidInput — with fieldErrors)

### ErrorCode Enum (16 values):
- `networkError`, `requestCancelled`, `connectionTimeout`, `unauthorized`, `tokenExpired`, `forbidden`, `notFound`, `serverError`, `invalidInput`, `unknown`

## 2. Open-Source Project Patterns

### Pattern A: ntminhdn/Flutter-Bloc-CleanArchitecture (542★)
**Approach: Single AppException hierarchy + RemoteExceptionKind enum**

```
AppException (abstract base, AppExceptionType enum)
├── RemoteException (Dio/HTTP errors)
│   ├── kind: RemoteExceptionKind (noInternet, network, serverDefined, serverUndefined,
│   │         badCertificate, decodeError, refreshTokenFailed, timeout, cancellation, unknown)
│   ├── httpErrorCode: int?
│   ├── serverError: ServerError?  (parsed from server response body)
│   └── rootException: Object?     (original exception)
├── ParseException
├── ValidationException
└── UncaughtException
```

**Key design decisions:**
- SINGLE `RemoteException` class with `RemoteExceptionKind` enum — NOT multiple subclasses per error type
- Two sub-kinds for server errors: `serverDefined` (server sent error body) vs `serverUndefined` (no body)
- `DioExceptionMapper` extends `ExceptionMapper<RemoteException>` — strategy pattern
- `BaseErrorResponseMapper` abstracts parsing of server error responses
- `ExceptionMessageMapper` maps AppException to localized user messages
- `ExceptionHandler` handles UI actions (dialogs, retry, logout)
- Uses `throw RemoteException` — NOT Either pattern
- Has separate `noInternet` and `network` kinds for connectivity vs SocketException

**Link**: https://github.com/ntminhdn/Flutter-Bloc-CleanArchitecture

### Pattern B: Reso Coder / Flutter Studio (canonical Clean Architecture)
**Approach: Either<Failure, T> with typed failure hierarchy**

```
Data Sources: throw typed exceptions (ServerException, CacheException)
Repository: catch exceptions → return Either<Failure, T>
Use Cases: pass through Either
UI (BLoC): fold() Either into states
```

**Failure hierarchy:**
```
Failure (abstract)
├── ServerFailure
├── CacheFailure
├── NetworkFailure
└── (feature-specific failures like AuthFailure)
```

**Key design decisions:**
- `Either<Failure, T>` from dartz/fpdart — compile-time enforced error handling
- No exceptions cross layer boundaries — caught at Repository boundary
- Failure types map 1:1 to Exception types from data sources
- Exceptions are _thrown_ in data sources (by third-party SDKs), _caught and mapped_ in Repository
- Two-part system: Exception (technical) → Failure (domain/UI)

**Link**: https://resocoder.com/flutter-tdd-clean-architecture-course/

### Pattern C: rddewan/YouCanCode-Mobile (33★)
**Approach: Simple Failure class + DioExceptionMapper mixin**

```
DioExceptionMapper mixin → mapDioExceptionToFailure(DioException) → Failure
Failure: freezed class with {message, statusCode?, exception?, stackTrace}
```

**Key design decisions:**
- SIMPLE: single Failure class (not a hierarchy)
- Mixin-based: repos `with DioExceptionMapper`
- Tracks both original exception and stack trace
- Hardcoded user-facing messages per status code
- 498 (refresh token expired) special handling

## 3. Community Best Practices (2026)

### Flutter Official Docs (flutter.dev/app-architecture/recommendations)
- Strongly recommends: separation of concerns, unidirectional data flow
- Repository pattern is the standard
- Use typed commands/events for user interactions
- Errors should be normalized before reaching UI

### Common consensus across sources:
1. **Repository is the error boundary**: Always catch exceptions at Repository, NEVER let raw DioException/SocketException reach UI
2. **Translate at the boundary**: Map technical exceptions to domain-meaningful errors
3. **Sealed hierarchies enable exhaustive handling**: Either sealed Failure subclasses or sealed DomainException with exhaustive switch
4. **Server-defined vs server-undefined distinction matters**: When server sends an error body (with code/message), treat it differently from transport-level errors
5. **400 client errors should NOT always be thrown**: Some blogs recommend treating 4xx as business logic responses, not exceptions

## 4. Key Debates

### Either<Failure, T> vs throw DomainException

| Aspect | Either/Left | throw Exception |
|--------|-------------|-----------------|
| Compile safety | Forces handling via fold() | No enforcement |
| Boilerplate | Heavy (fold(), nested indirection) | Minimal |
| Ecosystem compat | Poor (FutureBuilder/AsyncValue expect throw) | Native |
| Error propagation | Explicit in return type | Implicit (doc-only) |
| Learning curve | Higher (dartz/fpdart) | Lower |

**Current project choice**: `throw DomainException` — reasonable given existing codebase.

### Multiple exception classes vs single class with enum
- **ntminhdn**: SINGLE `RemoteException` + enum → less classes, more flexible
- **Reso Coder**: MULTIPLE Failure subclasses → better type safety, exhaustive matching
- **Current project**: Hybrid — sealed subclasses for key types + ErrorCode enum for granularity

## 5. Recommended Error Hierarchy

```
DomainException (sealed)
├── NetworkException (connectivity, timeout, 5xx)    — retryable
├── AuthException (401, 403, tokenExpired)           — needs re-login
├── NotFoundException (404)                          — data missing
├── ValidationException (400, 422)                   — user input error
└── ServerException (500, 502, 503)                  — server fault
```

Each carries `ErrorCode` for internationalization.

## 6. What to Clean Up

1. Delete `HttpsException`, `NeedLogin`, `NeedAuth`, `HttpsExceptionExtension` — all dead code
2. Delete `ErrorHandler.handleError()` — dead code
3. Delete `HttpEventBus` references — dead code
4. Keep `DioExceptionMapper.toDomainException()` — it's the correct active path
5. Rename/reorganize `ErrorCode` to be the single source of truth for I18n keys
6. Add `ServerException` subclass to domain for 500-range errors
