## ADDED Requirements

### Requirement: DioExceptionMapper.toDomainException() is the canonical error mapping
`DioExceptionMapper.toDomainException()` SHALL be the single, canonical function for converting Dio exceptions to domain exceptions across the entire codebase.

#### Scenario: Single entry point for error mapping
- **WHEN** any DioException occurs in a repository implementation
- **THEN** the exception is routed through `DioExceptionMapper.toDomainException()` as the sole entry point

#### Scenario: Function signature
- **WHEN** `DioExceptionMapper.toDomainException()` is called with a DioException
- **THEN** it returns a typed `DomainException` subtype (never a raw `HttpsException` or generic `Exception`)

#### Scenario: All import paths point to one function
- **WHEN** a grep for `DioException` handling runs across the codebase
- **THEN** all invocations of DioException-to-domain conversion reference `DioExceptionMapper.toDomainException()` exclusively

### Requirement: All HTTP status codes map to correct DomainException subtypes
Every relevant HTTP status code SHALL map to the correct sealed `DomainException` subtype through the mapper.

#### Scenario: 401 maps to NeedLogin
- **WHEN** the mapper receives a DioException with status code 401
- **THEN** it returns `DomainException.needLogin` or equivalent unauthenticated exception

#### Scenario: 403 maps to NeedAuth
- **WHEN** the mapper receives a DioException with status code 403
- **THEN** it returns `DomainException.needAuth` or equivalent forbidden exception

#### Scenario: 404 maps to NotFound
- **WHEN** the mapper receives a DioException with status code 404
- **THEN** it returns `DomainException.notFound` or equivalent not-found exception

#### Scenario: 422 maps to ValidationError
- **WHEN** the mapper receives a DioException with status code 422
- **THEN** it returns `DomainException.validationError` or equivalent validation exception

#### Scenario: 500+ maps to ServerError
- **WHEN** the mapper receives a DioException with status code 500 or above
- **THEN** it returns `DomainException.serverError` or equivalent server error exception

#### Scenario: Network error maps to NetworkError
- **WHEN** the mapper receives a DioException caused by a network issue (no internet, timeout, DNS failure)
- **THEN** it returns `DomainException.networkError` or equivalent connectivity exception

### Requirement: ErrorHandler, NeedLogin, NeedAuth, HttpsExceptionExtension are removed
The following dead code files and classes SHALL be deleted: `ErrorHandler`, `NeedLogin`, `NeedAuth`, `HttpsExceptionExtension`.

#### Scenario: ErrorHandler file deleted
- **WHEN** the codebase is scanned for `ErrorHandler`
- **THEN** no file in `packages/infrastructure/api/` defines or references `ErrorHandler`

#### Scenario: NeedLogin exception removed
- **WHEN** the codebase is scanned for `NeedLogin`
- **THEN** no file in `packages/infrastructure/api/` defines or references `NeedLogin`

#### Scenario: NeedAuth exception removed
- **WHEN** the codebase is scanned for `NeedAuth`
- **THEN** no file in `packages/infrastructure/api/` defines or references `NeedAuth`

#### Scenario: HttpsExceptionExtension removed
- **WHEN** the codebase is scanned for `HttpsExceptionExtension`
- **THEN** no file in `packages/infrastructure/api/` defines or references `HttpsExceptionExtension`

#### Scenario: Barrel file exports cleaned
- **WHEN** `packages/infrastructure/api/lib/api.dart` is examined
- **THEN** none of `ErrorHandler`, `NeedLogin`, `NeedAuth`, or `HttpsExceptionExtension` are exported

### Requirement: Repository implementations catch DioException and use toDomainException()
All repository implementations SHALL catch `DioException` in HTTP calls and convert via `DioExceptionMapper.toDomainException()` before propagating to the cubit layer.

#### Scenario: Repository try-catch on HTTP call
- **WHEN** a repository implementation makes a `dio.get()` or equivalent call
- **THEN** it wraps the call in a try-catch that catches `DioException` and rethrows `toDomainException(exception)`

#### Scenario: Cubit receives DomainException only
- **WHEN** a cubit calls a repository method that fails
- **THEN** the catch block in the cubit receives a `DomainException` subtype, never a raw `DioException`

#### Scenario: Multiple Dio calls in one method
- **WHEN** a repository method makes multiple sequential Dio calls
- **THEN** each call independently catches DioException and maps to the appropriate DomainException

### Requirement: No duplicate error mapping paths exist
The codebase SHALL contain exactly one path for mapping DioException to DomainException, with no alternative mapping functions, extension methods, or ad-hoc conversions.

#### Scenario: No alternative mapping functions
- **WHEN** a search runs for functions that convert DioException to any domain exception type
- **THEN** only `DioExceptionMapper.toDomainException()` is found

#### Scenario: No extension-based error mapping
- **WHEN** `HttpsExceptionExtension` is deleted
- **THEN** no other extension on DioException or HttpsException performs error-to-domain conversion

#### Scenario: No inline error mapping in repositories
- **WHEN** repository implementation files are reviewed
- **THEN** no `switch` or `if-else` chains on DioException status codes exist outside `DioExceptionMapper`
