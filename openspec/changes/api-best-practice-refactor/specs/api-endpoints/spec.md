## ADDED Requirements

### Requirement: Endpoint registry as single file
An endpoint registry SHALL exist as a single `api_endpoints.dart` file in `packages/infrastructure/api/lib/src/`.

#### Scenario: Registry file location
- **WHEN** the project is opened
- **THEN** `packages/infrastructure/api/lib/src/api_endpoints.dart` exists as the single source of truth for all endpoint paths

#### Scenario: No inline endpoint strings outside registry
- **WHEN** a grep for `/api/` patterns runs on repository implementation files
- **THEN** no inline endpoint string literals are found outside `api_endpoints.dart`

#### Scenario: Registry exports through barrel file
- **WHEN** `packages/infrastructure/api/lib/api.dart` is imported
- **THEN** `api_endpoints.dart` is re-exported and accessible to all consumers

### Requirement: Base URL defined once
The base URL SHALL be defined in exactly one place within the endpoint registry and shared across all domain endpoint groups.

#### Scenario: Single baseUrl constant
- **WHEN** any domain group references its endpoints
- **THEN** all endpoint paths are relative to a single `_baseUrl` constant defined in `api_endpoints.dart`

#### Scenario: Base URL change propagates globally
- **WHEN** the `_baseUrl` constant is updated
- **THEN** all domain endpoint groups automatically reflect the change without individual updates

### Requirement: Endpoints grouped by domain
Endpoint definitions SHALL be organized into nested domain groups (auth, home, vehicle, etc.) within the registry.

#### Scenario: Domain groups structure
- **WHEN** `api_endpoints.dart` is read
- **THEN** endpoints are organized as nested classes or top-level constants per domain (e.g., `ApiEndpoints.auth.login`, `ApiEndpoints.home.list`)

#### Scenario: Domain groups match feature packages
- **WHEN** a new feature package is added
- **THEN** its corresponding domain group exists in the registry before the feature consumes endpoints

#### Scenario: Domain group for auth
- **WHEN** auth-related features need an endpoint
- **THEN** endpoints are accessed via `ApiEndpoints.auth.<name>` pattern

#### Scenario: Domain group for home
- **WHEN** home feature needs an endpoint
- **THEN** endpoints are accessed via `ApiEndpoints.home.<name>` pattern

#### Scenario: Domain group for vehicle
- **WHEN** vehicle feature needs an endpoint
- **THEN** endpoints are accessed via `ApiEndpoints.vehicle.<name>` pattern

### Requirement: Repository implementations reference endpoints via constants
All repository implementations SHALL reference endpoint paths through the registry constants, never as inline string literals.

#### Scenario: Repository uses ApiEndpoints constant
- **WHEN** a repository implementation makes a Dio HTTP call
- **THEN** the path argument uses `ApiEndpoints.auth.login` or equivalent constant, not a hardcoded string like `"/api/v1/auth/login"`

#### Scenario: No inline paths in repository files
- **WHEN** a static analysis check runs on feature repository implementations
- **THEN** no `dio.get('/api/')` or similar inline endpoint patterns are found

### Requirement: Token renewal path included as shared endpoint
The token renewal endpoint SHALL be included in the endpoint registry as a shared cross-domain endpoint.

#### Scenario: Token renewal endpoint defined
- **WHEN** `api_endpoints.dart` is examined
- **THEN** a token renewal path (e.g., `ApiEndpoints.tokenRenewal` or `ApiEndpoints.auth.renewToken`) is defined

#### Scenario: Token interceptor references registry
- **WHEN** the token renewal interceptor triggers a refresh
- **THEN** the renewal request URL is built from the registry constant, not an inline string

### Requirement: Adding a new domain endpoint requires only changes to the endpoints file
Adding a new endpoint for any domain SHALL require modification only to `api_endpoints.dart`, with no changes needed in repository implementations.

#### Scenario: New endpoint added
- **WHEN** a developer adds `ApiEndpoints.home.detail = '/api/v1/home/detail'` to the registry
- **THEN** no repository implementation files need editing to consume this new path

#### Scenario: Repository consumes new endpoint
- **WHEN** a new `HomeDetailRepositoryImpl` method is written
- **THEN** it references `ApiEndpoints.home.detail` and no other file is modified for the endpoint definition
